export type ProgressStatus = "running" | "done" | "failed";
export type ToolProgressStatus = "running" | "done" | "failed";

export interface ToolProgress {
  name: string;
  preview: string;
  status: ToolProgressStatus;
}

export interface SubagentProgress {
  status: ProgressStatus;
  currentActivity: string;
  recentTools: ToolProgress[];
  recentText: string[];
  startedAt: number;
  updatedAt: number;
  turns: number;
}

const MAX_RECENT_TOOLS = 8;
const MAX_RECENT_TEXT = 5;
const MAX_TEXT_LENGTH = 200;

export function createProgress(now = Date.now()): SubagentProgress {
  return {
    status: "running",
    currentActivity: "starting...",
    recentTools: [],
    recentText: [],
    startedAt: now,
    updatedAt: now,
    turns: 0,
  };
}

function truncate(text: string, maxLength: number): string {
  const normalized = text.replace(/\s+/g, " ").trim();
  if (normalized.length <= maxLength) return normalized;
  return `${normalized.slice(0, maxLength - 1)}…`;
}

function truncateTextDelta(text: string, maxLength: number): string {
  const normalized = text.replace(/\s+/g, " ");
  if (normalized.length <= maxLength) return normalized;
  return `${normalized.slice(0, maxLength - 1)}…`;
}

function toolPreview(toolName: string, args: Record<string, unknown> | undefined): string {
  if (!args) return "";
  if (toolName === "bash") return truncate(String(args.command ?? ""), 120);
  if (toolName === "read") return truncate(String(args.path ?? args.file_path ?? ""), 120);
  if (toolName === "grep") return truncate(`${String(args.pattern ?? "")} in ${String(args.path ?? ".")}`, 120);
  if (toolName === "find") return truncate(`${String(args.pattern ?? "*")} in ${String(args.path ?? ".")}`, 120);
  if (toolName === "ls") return truncate(String(args.path ?? "."), 120);
  if (toolName === "edit" || toolName === "write") return truncate(String(args.path ?? args.file_path ?? ""), 120);
  return truncate(JSON.stringify(args), 120);
}

function pushRecentText(progress: SubagentProgress, text: string): void {
  const delta = truncateTextDelta(text, MAX_TEXT_LENGTH);
  const previous = progress.recentText.at(-1);
  if (!delta.trim()) {
    if (previous && previous.length < MAX_TEXT_LENGTH) {
      progress.recentText[progress.recentText.length - 1] = truncateTextDelta(`${previous}${delta}`, MAX_TEXT_LENGTH);
    }
    return;
  }

  if (previous && previous.length < MAX_TEXT_LENGTH && !previous.endsWith("\n")) {
    progress.recentText[progress.recentText.length - 1] = truncate(`${previous}${delta}`, MAX_TEXT_LENGTH);
  } else {
    progress.recentText.push(truncate(delta, MAX_TEXT_LENGTH));
  }

  if (progress.recentText.length > MAX_RECENT_TEXT) {
    progress.recentText.splice(0, progress.recentText.length - MAX_RECENT_TEXT);
  }
}

function pushTool(progress: SubagentProgress, tool: ToolProgress): void {
  progress.recentTools.push(tool);
  if (progress.recentTools.length > MAX_RECENT_TOOLS) {
    progress.recentTools.splice(0, progress.recentTools.length - MAX_RECENT_TOOLS);
  }
}

function findLatestTool(progress: SubagentProgress, toolName: string): ToolProgress | undefined {
  for (let i = progress.recentTools.length - 1; i >= 0; i--) {
    if (progress.recentTools[i]?.name === toolName) return progress.recentTools[i];
  }
  return undefined;
}

export function updateProgressFromEvent(progress: SubagentProgress, event: any, now = Date.now()): boolean {
  progress.updatedAt = now;

  if (event.type === "turn_start") {
    progress.currentActivity = "waiting for model...";
    return true;
  }

  if (event.type === "turn_end") {
    progress.turns += 1;
    progress.currentActivity = "finished turn";
    return true;
  }

  if (event.type === "tool_execution_start") {
    const name = String(event.toolName ?? "tool");
    const preview = toolPreview(name, event.args ?? event.input);
    pushTool(progress, { name, preview, status: "running" });
    progress.currentActivity = preview ? `running ${name}: ${preview}` : `running ${name}`;
    return true;
  }

  if (event.type === "tool_execution_update") {
    const name = String(event.toolName ?? "tool");
    const tool = findLatestTool(progress, name);
    if (tool) tool.status = "running";
    progress.currentActivity = `running ${name}`;
    return true;
  }

  if (event.type === "tool_execution_end") {
    const name = String(event.toolName ?? "tool");
    const failed = Boolean(event.isError);
    const tool = findLatestTool(progress, name);
    if (tool) tool.status = failed ? "failed" : "done";
    progress.currentActivity = failed ? `failed ${name}` : `finished ${name}`;
    return true;
  }

  if (event.type === "message_update") {
    const assistantEvent = event.assistantMessageEvent;
    if (assistantEvent?.type === "thinking_delta") {
      progress.currentActivity = "thinking...";
      return true;
    }
    if (assistantEvent?.type === "text_delta") {
      pushRecentText(progress, String(assistantEvent.delta ?? ""));
      progress.currentActivity = "responding...";
      return true;
    }
  }

  if (event.type === "message_end") {
    progress.currentActivity = "message complete";
    return true;
  }

  return false;
}

function formatDuration(ms: number): string {
  const seconds = Math.max(0, Math.round(ms / 1000));
  if (seconds < 60) return `${seconds}s`;
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = seconds % 60;
  return remainingSeconds ? `${minutes}m${remainingSeconds}s` : `${minutes}m`;
}

function statusIcon(status: ProgressStatus): string {
  if (status === "done") return "✓";
  if (status === "failed") return "✗";
  return "⏳";
}

function toolIcon(status: ToolProgressStatus): string {
  if (status === "done") return "✓";
  if (status === "failed") return "✗";
  return "→";
}

export function formatResultProgress(
  result: { agent: string; progress?: SubagentProgress; exitCode?: number },
  now = Date.now(),
): string {
  const progress = result.progress;
  if (!progress) return `${result.agent} (no progress)`;

  const status = progress.status;
  const lines = [`${statusIcon(status)} ${result.agent} ${status} ${formatDuration(now - progress.startedAt)}`];
  if (progress.currentActivity) lines.push(`  ${progress.currentActivity}`);

  for (const tool of progress.recentTools.slice(-5)) {
    const preview = tool.preview ? `: ${tool.preview}` : "";
    lines.push(`  ${toolIcon(tool.status)} ${tool.status} ${tool.name}${preview}`);
  }

  for (const text of progress.recentText.slice(-2)) {
    lines.push(`  ${text}`);
  }

  return lines.join("\n");
}
