import { spawn } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { AgentToolResult } from "@earendil-works/pi-agent-core";
import type { Message } from "@earendil-works/pi-ai";
import { createProgress, formatResultProgress, updateProgressFromEvent } from "./progress.ts";
import { isFailed, type SingleResult, type SubagentDetails, type UsageStats } from "./result.ts";
import type { AgentConfig } from "./agents.ts";

const CHILD_ENV = "PI_SUBAGENTS_CHILD";

export type SubagentUpdate = (partial: AgentToolResult<SubagentDetails>) => void;

export function isSubagentChildProcess(): boolean {
  return process.env[CHILD_ENV] === "1";
}

export function emptyUsage(): UsageStats {
  return { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 0 };
}

function getPiInvocation(args: string[]): { command: string; args: string[] } {
  const currentScript = process.argv[1];
  const isBunVirtualScript = currentScript?.startsWith("/$bunfs/root/");
  if (currentScript && !isBunVirtualScript && fs.existsSync(currentScript)) {
    return { command: process.execPath, args: [currentScript, ...args] };
  }
  return { command: "pi", args };
}

async function writePromptToTempFile(agentName: string, prompt: string): Promise<{ dir: string; filePath: string }> {
  const dir = await fs.promises.mkdtemp(path.join(os.tmpdir(), "pi-subagents-"));
  const safeName = agentName.replace(/[^\w.-]+/g, "_");
  const filePath = path.join(dir, `${safeName}.md`);
  await fs.promises.writeFile(filePath, prompt, { encoding: "utf-8", mode: 0o600 });
  return { dir, filePath };
}

function addUsage(result: SingleResult, message: Message): void {
  result.usage.turns += 1;
  const usage = message.usage;
  if (!usage) return;
  result.usage.input += usage.input || 0;
  result.usage.output += usage.output || 0;
  result.usage.cacheRead += usage.cacheRead || 0;
  result.usage.cacheWrite += usage.cacheWrite || 0;
  result.usage.cost += usage.cost?.total || 0;
}

export async function mapWithConcurrencyLimit<TIn, TOut>(
  items: TIn[],
  concurrency: number,
  fn: (item: TIn, index: number) => Promise<TOut>,
): Promise<TOut[]> {
  const results = new Array<TOut>(items.length);
  let nextIndex = 0;
  const workerCount = Math.min(Math.max(1, concurrency), items.length);
  const workers = Array.from({ length: workerCount }, async () => {
    while (true) {
      const index = nextIndex++;
      if (index >= items.length) return;
      results[index] = await fn(items[index], index);
    }
  });
  await Promise.all(workers);
  return results;
}

export async function runSingleAgent(
  defaultCwd: string,
  agents: AgentConfig[],
  agentName: string,
  task: string,
  cwd: string | undefined,
  step: number | undefined,
  signal: AbortSignal | undefined,
  onUpdate: SubagentUpdate | undefined,
  makeDetails: (results: SingleResult[]) => SubagentDetails,
): Promise<SingleResult> {
  const agent = agents.find((candidate) => candidate.name === agentName);
  if (!agent) {
    const available = agents.map((candidate) => `"${candidate.name}"`).join(", ") || "none";
    return {
      agent: agentName,
      agentSource: "unknown",
      task,
      exitCode: 1,
      messages: [],
      stderr: `Unknown agent: "${agentName}". Available agents: ${available}.`,
      usage: emptyUsage(),
      step,
      progress: { ...createProgress(), status: "failed", currentActivity: "unknown agent" },
    };
  }

  const args = ["--mode", "json", "-p", "--no-session"];
  if (agent.model) args.push("--model", agent.model);
  if (agent.tools && agent.tools.length > 0) args.push("--tools", agent.tools.join(","));

  let tmpDir: string | undefined;
  const current: SingleResult = {
    agent: agent.name,
    agentSource: agent.source,
    task,
    exitCode: -1,
    messages: [],
    stderr: "",
    usage: emptyUsage(),
    model: agent.model,
    step,
    progress: createProgress(),
  };

  const emitUpdate = () => {
    onUpdate?.({
      content: [{ type: "text", text: formatResultProgress(current) }],
      details: makeDetails([current]),
    });
  };

  try {
    if (agent.systemPrompt.trim()) {
      const tmp = await writePromptToTempFile(agent.name, agent.systemPrompt);
      tmpDir = tmp.dir;
      args.push("--append-system-prompt", tmp.filePath);
    }
    args.push(`Task: ${task}`);

    let wasAborted = false;
    const exitCode = await new Promise<number>((resolve) => {
      const invocation = getPiInvocation(args);
      const proc = spawn(invocation.command, invocation.args, {
        cwd: cwd ?? defaultCwd,
        env: { ...process.env, [CHILD_ENV]: "1" },
        shell: false,
        stdio: ["ignore", "pipe", "pipe"],
      });
      let buffer = "";

      const processLine = (line: string) => {
        if (!line.trim()) return;
        let event: any;
        try {
          event = JSON.parse(line);
        } catch {
          return;
        }

        if (current.progress && updateProgressFromEvent(current.progress, event)) {
          emitUpdate();
        }

        if (event.type === "message_end" && event.message) {
          const message = event.message as Message;
          current.messages.push(message);
          if (message.role === "assistant") {
            addUsage(current, message);
            if (!current.model && message.model) current.model = message.model;
            if (message.stopReason) current.stopReason = message.stopReason;
            if (message.errorMessage) current.errorMessage = message.errorMessage;
          }
          emitUpdate();
        }

        if (event.type === "tool_result_end" && event.message) {
          current.messages.push(event.message as Message);
          emitUpdate();
        }
      };

      proc.stdout.on("data", (data) => {
        buffer += data.toString();
        const lines = buffer.split("\n");
        buffer = lines.pop() || "";
        for (const line of lines) processLine(line);
      });
      proc.stderr.on("data", (data) => {
        current.stderr += data.toString();
      });
      proc.on("close", (code) => {
        if (buffer.trim()) processLine(buffer);
        resolve(code ?? 0);
      });
      proc.on("error", () => resolve(1));

      const killChild = () => {
        wasAborted = true;
        proc.kill("SIGTERM");
        setTimeout(() => {
          if (!proc.killed) proc.kill("SIGKILL");
        }, 5000).unref();
      };
      if (signal?.aborted) killChild();
      else signal?.addEventListener("abort", killChild, { once: true });
    });

    current.exitCode = exitCode;
    if (wasAborted) current.stopReason = "aborted";
    if (current.progress) {
      current.progress.status = isFailed(current) ? "failed" : "done";
      current.progress.currentActivity = isFailed(current) ? "failed" : "complete";
      current.progress.updatedAt = Date.now();
    }
    emitUpdate();
    return current;
  } finally {
    if (tmpDir) await fs.promises.rm(tmpDir, { recursive: true, force: true });
  }
}
