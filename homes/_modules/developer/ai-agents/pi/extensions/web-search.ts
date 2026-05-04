import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { StringEnum } from "@mariozechner/pi-ai";
import type { AgentToolResult, ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";

type SearchResult = {
	title: string;
	url: string;
	snippet: string;
};

const SearchProvider = {
	Auto: "auto",
	Codex: "codex",
	Tavily: "tavily",
	Brave: "brave",
} as const;
type SearchProvider = (typeof SearchProvider)[keyof typeof SearchProvider];
type SearchBackend = Exclude<SearchProvider, typeof SearchProvider.Auto>;
const searchProviders = Object.values(SearchProvider) as SearchProvider[];
const DEFAULT_SEARCH_PROVIDER: SearchProvider = SearchProvider.Auto;

const CodexSearchFreshness = {
	Cached: "cached",
	Live: "live",
} as const;
type CodexSearchFreshness = (typeof CodexSearchFreshness)[keyof typeof CodexSearchFreshness];
const codexSearchFreshnesses = Object.values(CodexSearchFreshness) as CodexSearchFreshness[];
const DEFAULT_CODEX_SEARCH_FRESHNESS: CodexSearchFreshness = CodexSearchFreshness.Cached;

type CodexSearchDetails = {
	provider: typeof SearchProvider.Codex;
	query: string;
	freshness: CodexSearchFreshness;
	sourceCount: number;
	sources: SearchResult[];
	summary: string;
};

// Codex-backed web search is adapted from the approach documented by
// https://github.com/Winds-AI/pi-native-codex-web-search: call the same
// ChatGPT Codex backend endpoint with Codex OAuth credentials and the native
// Responses API web_search tool, rather than shelling out to the Codex CLI.
const CODEX_API_ENDPOINT = "https://chatgpt.com/backend-api/codex/responses";
const CODEX_AUTH_PATH = join(homedir(), ".codex", "auth.json");
const DEFAULT_CODEX_MODEL = "gpt-5.4-mini";
const SEARCH_TIMEOUT_MS = 120_000;

function isSearchProvider(value: string): value is SearchProvider {
	return searchProviders.includes(value as SearchProvider);
}

const codexOutputSchema = {
	type: "object",
	additionalProperties: false,
	properties: {
		summary: { type: "string" },
		sources: {
			type: "array",
			items: {
				type: "object",
				additionalProperties: false,
				properties: {
					title: { type: "string" },
					url: { type: "string" },
					snippet: { type: "string" },
				},
				required: ["title", "url", "snippet"],
			},
		},
	},
	required: ["summary", "sources"],
};

async function searchTavily(query: string, maxResults: number, apiKey: string, signal?: AbortSignal): Promise<SearchResult[]> {
	const res = await fetch("https://api.tavily.com/search", {
		method: "POST",
		headers: { "Content-Type": "application/json" },
		body: JSON.stringify({ query, max_results: maxResults, api_key: apiKey }),
		signal,
	});
	if (!res.ok) throw new Error(`Tavily: HTTP ${res.status}`);
	const data = (await res.json()) as {
		results?: Array<{ title?: string; url?: string; content?: string }>;
	};
	return (data.results ?? []).slice(0, maxResults).map((r) => ({
		title: r.title ?? "",
		url: r.url ?? "",
		snippet: (r.content ?? "").slice(0, 300),
	}));
}

async function searchBrave(query: string, maxResults: number, apiKey: string, signal?: AbortSignal): Promise<SearchResult[]> {
	const res = await fetch(
		`https://api.search.brave.com/res/v1/web/search?q=${encodeURIComponent(query)}&count=${maxResults}`,
		{ headers: { Accept: "application/json", "X-Subscription-Token": apiKey }, signal },
	);
	if (!res.ok) throw new Error(`Brave Search: HTTP ${res.status}`);
	const data = (await res.json()) as {
		web?: { results?: Array<{ title?: string; url?: string; description?: string }> };
	};
	return (data.web?.results ?? []).slice(0, maxResults).map((r) => ({
		title: r.title ?? "",
		url: r.url ?? "",
		snippet: r.description ?? "",
	}));
}

async function getCodexAuth(): Promise<{ accessToken: string; accountId: string }> {
	const raw = await readFile(CODEX_AUTH_PATH, "utf-8").catch((error: NodeJS.ErrnoException) => {
		if (error.code === "ENOENT") throw new Error("Codex auth file not found. Run `codex login`.");
		throw error;
	});
	const auth = JSON.parse(raw) as { tokens?: { access_token?: string; account_id?: string } };
	if (!auth.tokens?.access_token) throw new Error("Codex auth file has no access token. Run `codex login`.");
	if (!auth.tokens?.account_id) throw new Error("Codex auth file has no account ID. Run `codex login`.");
	return { accessToken: auth.tokens.access_token, accountId: auth.tokens.account_id };
}

function buildCodexPrompt(query: string, maxResults: number, freshness: CodexSearchFreshness): string {
	return [
		"You are performing web research for a coding agent.",
		"Search the public web and answer the user's query using current online sources.",
		freshness === CodexSearchFreshness.Live
			? "Prioritize the most recent and up-to-date information available."
			: "Cached results are fine; prioritize accuracy over recency.",
		"Return ONLY a JSON object matching this schema:",
		JSON.stringify(codexOutputSchema),
		"Do not wrap the JSON in markdown fences or add any extra commentary.",
		`Keep the summary concise and useful. Limit sources to at most ${maxResults} items.`,
		"Prefer primary or official sources when available.",
		"Each source snippet should be short and directly relevant.",
		"",
		`User query: ${query}`,
	].join("\n");
}

function parseSseText(text: string): Array<{ type: string; data: Record<string, unknown> }> {
	const events: Array<{ type: string; data: Record<string, unknown> }> = [];
	let event = "";
	let dataLines: string[] = [];

	for (const line of text.split("\n")) {
		if (line.startsWith("event: ")) event = line.slice(7);
		else if (line.startsWith("data: ")) dataLines.push(line.slice(6));
		else if (line === "" && event && dataLines.length > 0) {
			try {
				events.push({ type: event, data: JSON.parse(dataLines.join("\n")) });
			} catch {
				// Ignore non-JSON stream events.
			}
			event = "";
			dataLines = [];
		}
	}

	return events;
}

async function searchCodex(
	query: string,
	maxResults: number,
	freshness: CodexSearchFreshness,
	signal?: AbortSignal,
): Promise<AgentToolResult<CodexSearchDetails>> {
	const auth = await getCodexAuth();
	const abortController = new AbortController();
	const timeoutId = setTimeout(() => abortController.abort(), SEARCH_TIMEOUT_MS);
	if (signal?.aborted) abortController.abort(signal.reason);
	signal?.addEventListener("abort", () => abortController.abort(signal.reason), { once: true });

	try {
		const response = await fetch(CODEX_API_ENDPOINT, {
			method: "POST",
			headers: {
				"Content-Type": "application/json",
				Authorization: `Bearer ${auth.accessToken}`,
				"ChatGPT-Account-ID": auth.accountId,
			},
			body: JSON.stringify({
				model: process.env.PI_CODEX_WEB_SEARCH_MODEL ?? DEFAULT_CODEX_MODEL,
				instructions: buildCodexPrompt(query, maxResults, freshness),
				input: [{ role: "user", content: `Search the web for: ${query}` }],
				tools: [{ type: "web_search" }],
				store: false,
				stream: true,
			}),
			signal: abortController.signal,
		});

		if (!response.ok) {
			const error = await response.text().catch(() => "Unknown error");
			if (response.status === 401) throw new Error("Codex authentication failed. Run `codex login`.");
			if (response.status === 429) throw new Error("Codex web search was rate limited. Try again later.");
			throw new Error(`Codex web search: HTTP ${response.status}: ${error}`);
		}

		let rawOutput = "";
		for (const event of parseSseText(await response.text())) {
			if (event.type === "response.output_text.delta") rawOutput += String(event.data.delta ?? "");
		}
		if (!rawOutput) throw new Error("Codex web search returned an empty response.");

		const parsed = JSON.parse(rawOutput) as { summary?: string; sources?: SearchResult[] };
		const summary = parsed.summary?.trim();
		if (!summary || !Array.isArray(parsed.sources)) throw new Error(`Invalid Codex web search response: ${rawOutput.slice(0, 200)}`);

		const sources = parsed.sources.slice(0, maxResults);
		return {
			content: [{ type: "text", text: formatResults(sources, query, SearchProvider.Codex, summary) }],
			details: { provider: SearchProvider.Codex, query, freshness, sourceCount: sources.length, sources, summary },
		};
	} finally {
		clearTimeout(timeoutId);
	}
}

function formatResults(results: SearchResult[], query: string, provider: SearchBackend, summary?: string): string {
	const metadata = `Search provider: ${provider}`;
	const resultText = results.length === 0
		? `No sources found for: "${query}"`
		: results.map((r, i) => `${i + 1}. **${r.title}**\n   ${r.url}\n   ${r.snippet}`).join("\n\n");
	return summary ? `${metadata}\n\n${summary}\n\nSources:\n${resultText}` : `${metadata}\n\n${resultText}`;
}

async function doSearch(
	query: string,
	maxResults: number,
	freshness: CodexSearchFreshness,
	signal?: AbortSignal,
): Promise<AgentToolResult<unknown>> {
	const provider = (process.env.PI_WEB_SEARCH_PROVIDER ?? DEFAULT_SEARCH_PROVIDER).toLowerCase();
	if (!isSearchProvider(provider)) {
		throw new Error(`PI_WEB_SEARCH_PROVIDER must be one of: ${searchProviders.join(", ")}.`);
	}

	if (provider === SearchProvider.Codex) return searchCodex(query, maxResults, freshness, signal);
	if (provider === SearchProvider.Tavily) {
		if (!process.env.PI_TAVILY_API_KEY) throw new Error("PI_WEB_SEARCH_PROVIDER=tavily requires PI_TAVILY_API_KEY.");
		const results = await searchTavily(query, maxResults, process.env.PI_TAVILY_API_KEY, signal);
		return { content: [{ type: "text", text: formatResults(results, query, SearchProvider.Tavily) }], details: { provider: SearchProvider.Tavily, results } };
	}
	if (provider === SearchProvider.Brave) {
		if (!process.env.PI_BRAVE_SEARCH_API_KEY) throw new Error("PI_WEB_SEARCH_PROVIDER=brave requires PI_BRAVE_SEARCH_API_KEY.");
		const results = await searchBrave(query, maxResults, process.env.PI_BRAVE_SEARCH_API_KEY, signal);
		return { content: [{ type: "text", text: formatResults(results, query, SearchProvider.Brave) }], details: { provider: SearchProvider.Brave, results } };
	}

	const tavilyKey = process.env.PI_TAVILY_API_KEY;
	if (tavilyKey) {
		const results = await searchTavily(query, maxResults, tavilyKey, signal);
		return { content: [{ type: "text", text: formatResults(results, query, SearchProvider.Tavily) }], details: { provider: SearchProvider.Tavily, results } };
	}
	const braveKey = process.env.PI_BRAVE_SEARCH_API_KEY;
	if (braveKey) {
		const results = await searchBrave(query, maxResults, braveKey, signal);
		return { content: [{ type: "text", text: formatResults(results, query, SearchProvider.Brave) }], details: { provider: SearchProvider.Brave, results } };
	}
	return searchCodex(query, maxResults, freshness, signal);
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "web_search",
		label: "Web Search",
		description:
			"Searches the web for up-to-date information beyond your knowledge cutoff. Prefer primary sources (official docs, papers, announcements) and corroborate key claims with multiple sources. Always include links for cited sources in your response.",
		promptSnippet: "web_search(query) — fetch current information from the web",
		promptGuidelines: [
			"Use web_search when you are unsure about a fact instead of guessing.",
			"When using web_search, prefer primary sources (official docs, specs, papers) over blog summaries or aggregators.",
			"When using web_search for time-sensitive topics, note publication dates and prefer recent sources.",
			"When web_search sources conflict, acknowledge the discrepancy and note which seems more authoritative.",
			"When using web_search, cite sources inline and include links in your final response.",
		],
		parameters: Type.Object({
			query: Type.String({ description: "Web search query" }),
			maxResults: Type.Optional(
				Type.Integer({
					description: "Maximum results to return (1–10, default 5)",
					minimum: 1,
					maximum: 10,
					default: 5,
				}),
			),
			freshness: Type.Optional(
				StringEnum(codexSearchFreshnesses, {
					description: "For Codex-backed search, use 'cached' for stable topics or 'live' for time-sensitive queries.",
					default: DEFAULT_CODEX_SEARCH_FRESHNESS,
				}),
			),
		}),
		async execute(_id, { query, maxResults, freshness }, signal, _onUpdate, _ctx): Promise<AgentToolResult<unknown>> {
			return doSearch(query, maxResults ?? 5, freshness ?? DEFAULT_CODEX_SEARCH_FRESHNESS, signal);
		},
	});
}
