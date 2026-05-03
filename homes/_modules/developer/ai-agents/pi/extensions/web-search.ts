import { Type } from "@mariozechner/pi-ai";
import type { AgentToolResult, ExtensionAPI } from "@mariozechner/pi-coding-agent";

type SearchResult = {
	title: string;
	url: string;
	snippet: string;
};

async function searchTavily(query: string, maxResults: number, apiKey: string): Promise<SearchResult[]> {
	const res = await fetch("https://api.tavily.com/search", {
		method: "POST",
		headers: { "Content-Type": "application/json" },
		body: JSON.stringify({ query, max_results: maxResults, api_key: apiKey }),
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

async function searchBrave(query: string, maxResults: number, apiKey: string): Promise<SearchResult[]> {
	const res = await fetch(
		`https://api.search.brave.com/res/v1/web/search?q=${encodeURIComponent(query)}&count=${maxResults}`,
		{ headers: { Accept: "application/json", "X-Subscription-Token": apiKey } },
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

function formatResults(results: SearchResult[], query: string): string {
	if (results.length === 0) return `No results found for: "${query}"`;
	return results.map((r, i) => `${i + 1}. **${r.title}**\n   ${r.url}\n   ${r.snippet}`).join("\n\n");
}

async function doSearch(query: string, maxResults: number): Promise<SearchResult[]> {
	const tavilyKey = process.env.TAVILY_API_KEY;
	if (tavilyKey) return searchTavily(query, maxResults, tavilyKey);
	const braveKey = process.env.BRAVE_SEARCH_API_KEY;
	if (braveKey) return searchBrave(query, maxResults, braveKey);
	throw new Error("No search provider configured. Set TAVILY_API_KEY or BRAVE_SEARCH_API_KEY.");
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "web_search",
		label: "Web Search",
		description:
			"Searches the web for up-to-date information beyond your knowledge cutoff. Prefer primary sources (official docs, papers, announcements) and corroborate key claims with multiple sources. Always include links for cited sources in your response.",
		promptSnippet: "web_search(query) — fetch current information from the web",
		promptGuidelines: [
			"If unsure about a fact, search instead of guessing.",
			"Prefer primary sources (official docs, specs, papers) over blog summaries or aggregators.",
			"Note publication dates when recency affects relevance; prefer recent sources for time-sensitive topics.",
			"When sources conflict, acknowledge the discrepancy and note which seems more authoritative.",
			"Always cite sources inline and include links in your final response.",
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
		}),
		async execute(_id, { query, maxResults }, _signal, _onUpdate, _ctx): Promise<AgentToolResult<SearchResult[]>> {
			const results = await doSearch(query, maxResults ?? 5);
			return {
				content: [{ type: "text", text: formatResults(results, query) }],
				details: results,
			};
		},
	});

}
