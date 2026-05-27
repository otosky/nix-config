import type { AgentToolResult } from "@earendil-works/pi-agent-core";
import type { Message } from "@earendil-works/pi-ai";
import { getFinalAssistantText, type AgentConfig, type AgentScope } from "./agents.ts";
import { formatResultProgress, type SubagentProgress } from "./progress.ts";

export interface UsageStats {
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
  cost: number;
  turns: number;
}

export interface SingleResult {
  agent: string;
  agentSource: AgentConfig["source"] | "unknown";
  task: string;
  exitCode: number;
  messages: Message[];
  stderr: string;
  usage: UsageStats;
  model?: string;
  stopReason?: string;
  errorMessage?: string;
  step?: number;
  progress?: SubagentProgress;
}

export interface SubagentDetails {
  mode: "single" | "parallel" | "chain";
  agentScope: AgentScope;
  projectAgentsDir: string | null;
  results: SingleResult[];
}

export function isFailed(result: SingleResult): boolean {
  if (result.exitCode === -1) return false;
  return result.exitCode !== 0 || result.stopReason === "error" || result.stopReason === "aborted";
}

export function resultOutput(result: SingleResult): string {
  if (isFailed(result)) {
    return result.errorMessage || result.stderr || getFinalAssistantText(result.messages) || "(no output)";
  }
  return getFinalAssistantText(result.messages) || "(no output)";
}

export function failedToolResult(text: string, details: SubagentDetails): AgentToolResult<SubagentDetails> {
  return {
    content: [{ type: "text", text }],
    details,
    isError: true,
  };
}

export function formatUsage(usage: UsageStats | undefined): string {
  if (!usage) return "";
  const parts: string[] = [];
  if (usage.turns) parts.push(`${usage.turns} turn${usage.turns === 1 ? "" : "s"}`);
  if (usage.input) parts.push(`↑${usage.input}`);
  if (usage.output) parts.push(`↓${usage.output}`);
  if (usage.cacheRead) parts.push(`R${usage.cacheRead}`);
  if (usage.cacheWrite) parts.push(`W${usage.cacheWrite}`);
  if (usage.cost) parts.push(`$${usage.cost.toFixed(4)}`);
  return parts.join(" ");
}

function sumUsage(results: SingleResult[]): UsageStats {
  return results.reduce(
    (total, result) => ({
      input: total.input + result.usage.input,
      output: total.output + result.usage.output,
      cacheRead: total.cacheRead + result.usage.cacheRead,
      cacheWrite: total.cacheWrite + result.usage.cacheWrite,
      cost: total.cost + result.usage.cost,
      turns: total.turns + result.usage.turns,
    }),
    { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 0 },
  );
}

function contentText(result: { content?: Array<{ type?: string; text?: string }> }): string {
  return result.content
    ?.filter((part) => part.type === "text" && typeof part.text === "string")
    .map((part) => part.text)
    .join("\n")
    .trim() ?? "";
}

export function formatDetailsForRender(details: SubagentDetails | undefined, expanded: boolean): string {
  if (!details || details.results.length === 0) return "subagent (no results)";

  const lines: string[] = [];
  if (details.mode !== "single") {
    lines.push(`subagent ${details.mode} (${details.results.length})`);
    const totalUsage = formatUsage(sumUsage(details.results));
    if (totalUsage) lines.push(`Total: ${totalUsage}`);
  }

  for (const result of details.results) {
    lines.push(formatResultProgress(result));
    const usage = formatUsage(result.usage);
    if (usage) lines.push(`  ${usage}`);
    if (expanded) {
      lines.push(`  task: ${result.task}`);
      const output = resultOutput(result);
      if (output && output !== "(no output)") lines.push("", output.trim());
    }
    lines.push("");
  }

  return lines.join("\n").trimEnd();
}

export function formatRenderResult(result: { content?: Array<{ type?: string; text?: string }>; details?: SubagentDetails }, expanded: boolean): string {
  if (result.details && result.details.results.length > 0) return formatDetailsForRender(result.details, expanded);
  return contentText(result) || "subagent (no results)";
}
