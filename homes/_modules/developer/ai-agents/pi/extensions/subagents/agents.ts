import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

export type AgentScope = "user" | "project" | "both";
export type AgentSource = "builtin" | "user" | "project";

export interface AgentConfig {
  name: string;
  description: string;
  tools?: string[];
  model?: string;
  systemPrompt: string;
  source: AgentSource;
  filePath: string;
}

export interface DiscoverAgentsOptions {
  cwd: string;
  scope: AgentScope;
  builtinDir?: string;
  userDir?: string;
}

export interface AgentDiscoveryResult {
  agents: AgentConfig[];
  projectAgentsDir: string | null;
}

interface ParsedMarkdown {
  frontmatter: Record<string, string>;
  body: string;
}

function parseFrontmatter(content: string): ParsedMarkdown {
  if (!content.startsWith("---\n")) return { frontmatter: {}, body: content };
  const end = content.indexOf("\n---", 4);
  if (end === -1) return { frontmatter: {}, body: content };

  const rawFrontmatter = content.slice(4, end);
  const bodyStart = content.slice(end).startsWith("\n---\n") ? end + 5 : end + 4;
  const frontmatter: Record<string, string> = {};

  for (const line of rawFrontmatter.split("\n")) {
    const separator = line.indexOf(":");
    if (separator === -1) continue;
    const key = line.slice(0, separator).trim();
    const value = line.slice(separator + 1).trim().replace(/^['\"]|['\"]$/g, "");
    if (key) frontmatter[key] = value;
  }

  return { frontmatter, body: content.slice(bodyStart) };
}

function loadAgentsFromDir(dir: string | undefined, source: AgentSource): AgentConfig[] {
  if (!dir || !fs.existsSync(dir)) return [];

  let entries: fs.Dirent[];
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return [];
  }

  const agents: AgentConfig[] = [];
  for (const entry of entries) {
    if (!entry.name.endsWith(".md")) continue;
    if (!entry.isFile() && !entry.isSymbolicLink()) continue;

    const filePath = path.join(dir, entry.name);
    let content: string;
    try {
      content = fs.readFileSync(filePath, "utf-8");
    } catch {
      continue;
    }

    const { frontmatter, body } = parseFrontmatter(content);
    if (!frontmatter.name || !frontmatter.description) continue;

    const tools = frontmatter.tools
      ?.split(",")
      .map((tool) => tool.trim())
      .filter(Boolean);

    agents.push({
      name: frontmatter.name,
      description: frontmatter.description,
      tools: tools && tools.length > 0 ? tools : undefined,
      model: frontmatter.model || undefined,
      systemPrompt: body.trim(),
      source,
      filePath,
    });
  }

  return agents;
}

function isDirectory(filePath: string): boolean {
  try {
    return fs.statSync(filePath).isDirectory();
  } catch {
    return false;
  }
}

function findNearestProjectAgentsDir(cwd: string): string | null {
  let current = path.resolve(cwd);
  while (true) {
    const candidate = path.join(current, ".pi", "agents");
    if (isDirectory(candidate)) return candidate;

    const parent = path.dirname(current);
    if (parent === current) return null;
    current = parent;
  }
}

function defaultUserAgentsDir(): string {
  return path.join(os.homedir(), ".pi", "agent", "agents");
}

export function discoverAgents(options: DiscoverAgentsOptions): AgentDiscoveryResult {
  const projectAgentsDir = findNearestProjectAgentsDir(options.cwd);
  const builtinAgents = loadAgentsFromDir(options.builtinDir, "builtin");
  const userAgents = options.scope === "project" ? [] : loadAgentsFromDir(options.userDir ?? defaultUserAgentsDir(), "user");
  const projectAgents = options.scope === "user" || !projectAgentsDir ? [] : loadAgentsFromDir(projectAgentsDir, "project");

  const agentMap = new Map<string, AgentConfig>();
  for (const agent of builtinAgents) agentMap.set(agent.name, agent);
  for (const agent of userAgents) agentMap.set(agent.name, agent);
  for (const agent of projectAgents) agentMap.set(agent.name, agent);

  return { agents: [...agentMap.values()], projectAgentsDir };
}

export function throwToolError(message: string): never {
  throw new Error(message);
}

export function assertProjectAgentConfirmationAllowed(options: {
  agentScope: AgentScope;
  confirmProjectAgents: boolean | undefined;
  hasUI: boolean;
  projectAgents: AgentConfig[];
  projectAgentsDir: string | null;
}): void {
  if (options.projectAgents.length === 0) return;
  if (options.agentScope !== "project" && options.agentScope !== "both") return;
  if (options.confirmProjectAgents === false) return;
  if (options.hasUI) return;

  throwToolError(
    `Project-local subagents require interactive confirmation. Re-run with confirmProjectAgents: false only if you trust ${options.projectAgentsDir ?? "the project agents directory"}.`,
  );
}

export function applyPreviousPlaceholder(task: string, previous: string): string {
  return task.replaceAll("{previous}", previous);
}

export function getFinalAssistantText(messages: Array<{ role?: string; content?: Array<{ type?: string; text?: string }> }>): string {
  for (let i = messages.length - 1; i >= 0; i--) {
    const message = messages[i];
    if (message?.role !== "assistant") continue;
    const text = message.content?.find((part) => part.type === "text" && typeof part.text === "string")?.text;
    if (text) return text;
  }
  return "";
}
