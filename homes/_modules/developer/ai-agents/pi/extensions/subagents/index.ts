import { spawn } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { fileURLToPath } from "node:url";
import type { AgentToolResult } from "@earendil-works/pi-agent-core";
import type { Message } from "@earendil-works/pi-ai";
import { StringEnum } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import {
  applyPreviousPlaceholder,
  assertProjectAgentConfirmationAllowed,
  discoverAgents,
  getFinalAssistantText,
  throwToolError,
  type AgentConfig,
  type AgentScope,
} from "./agents.ts";
import { createProgress, formatResultProgress, updateProgressFromEvent } from "./progress.ts";
import { failedToolResult, formatRenderResult, isFailed, resultOutput, type SingleResult, type SubagentDetails, type UsageStats } from "./result.ts";

const CHILD_ENV = "PI_SUBAGENTS_CHILD";
const MAX_PARALLEL_TASKS = 6;
const MAX_CONCURRENCY = 4;
const MAX_CHAIN_STEPS = 6;

type SubagentUpdate = (partial: AgentToolResult<SubagentDetails>) => void;

function emptyUsage(): UsageStats {
  return { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 0 };
}

function getExtensionDir(): string {
  return path.dirname(fileURLToPath(import.meta.url));
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

async function mapWithConcurrencyLimit<TIn, TOut>(
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

async function runSingleAgent(
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

const TaskItem = Type.Object({
  agent: Type.String({ description: "Name of the agent to invoke" }),
  task: Type.String({ description: "Task to delegate" }),
  cwd: Type.Optional(Type.String({ description: "Working directory for this child process" })),
});

const ChainItem = Type.Object({
  agent: Type.String({ description: "Name of the agent to invoke" }),
  task: Type.String({ description: "Task template. Use {previous} for the prior step's final output." }),
  cwd: Type.Optional(Type.String({ description: "Working directory for this child process" })),
});

const AgentScopeSchema = StringEnum(["user", "project", "both"] as const, {
  description: "Agent directories to use. Builtin agents are always available. Default: user.",
  default: "user",
});

const SubagentParams = Type.Object({
  agent: Type.Optional(Type.String({ description: "Agent name for single mode" })),
  task: Type.Optional(Type.String({ description: "Task for single mode" })),
  tasks: Type.Optional(Type.Array(TaskItem, { description: "Parallel tasks" })),
  chain: Type.Optional(Type.Array(ChainItem, { description: "Sequential agent chain" })),
  agentScope: Type.Optional(AgentScopeSchema),
  confirmProjectAgents: Type.Optional(Type.Boolean({ default: true })),
  cwd: Type.Optional(Type.String({ description: "Working directory for single mode" })),
});

export default function registerSubagents(pi: ExtensionAPI): void {
  if (process.env[CHILD_ENV] === "1") return;

  pi.registerTool({
    name: "subagent",
    label: "Subagent",
    description: [
      "Run focused child Pi agents with isolated context.",
      "Modes: single (agent + task), parallel (tasks), chain (sequential with {previous}).",
      "Builtin and user agents are available by default; project agents require agentScope project or both.",
    ].join(" "),
    parameters: SubagentParams,

    async execute(_toolCallId, params, signal, onUpdate, ctx) {
      const agentScope: AgentScope = params.agentScope ?? "user";
      const discovery = discoverAgents({
        cwd: ctx.cwd,
        scope: agentScope,
        builtinDir: path.join(getExtensionDir(), "agents"),
      });
      const agents = discovery.agents;
      const hasSingle = Boolean(params.agent && params.task);
      const hasParallel = (params.tasks?.length ?? 0) > 0;
      const hasChain = (params.chain?.length ?? 0) > 0;
      const modeCount = Number(hasSingle) + Number(hasParallel) + Number(hasChain);
      const mode = hasChain ? "chain" : hasParallel ? "parallel" : "single";
      const makeDetails = (results: SingleResult[]): SubagentDetails => ({
        mode,
        agentScope,
        projectAgentsDir: discovery.projectAgentsDir,
        results,
      });

      if (modeCount !== 1) {
        const available = agents.map((agent) => `${agent.name} (${agent.source}): ${agent.description}`).join("; ") || "none";
        throwToolError(`Invalid parameters. Provide exactly one mode. Available agents: ${available}`);
      }

      if ((agentScope === "project" || agentScope === "both") && (params.confirmProjectAgents ?? true)) {
        const requested = new Set<string>();
        if (params.agent) requested.add(params.agent);
        for (const task of params.tasks ?? []) requested.add(task.agent);
        for (const step of params.chain ?? []) requested.add(step.agent);
        const projectAgents = [...requested]
          .map((name) => agents.find((agent) => agent.name === name))
          .filter((agent): agent is AgentConfig => agent?.source === "project");
        assertProjectAgentConfirmationAllowed({
          agentScope,
          confirmProjectAgents: params.confirmProjectAgents,
          hasUI: Boolean(ctx.hasUI),
          projectAgents,
          projectAgentsDir: discovery.projectAgentsDir,
        });
        if (projectAgents.length > 0) {
          const ok = await ctx.ui.confirm(
            "Run project-local subagents?",
            `Agents: ${projectAgents.map((agent) => agent.name).join(", ")}\nSource: ${discovery.projectAgentsDir ?? "unknown"}\n\nProject agents are repository-controlled. Continue only for trusted repositories.`,
          );
          if (!ok) {
            return { content: [{ type: "text", text: "Canceled: project-local subagents were not approved." }], details: makeDetails([]) };
          }
        }
      }

      if (params.chain?.length) {
        if (params.chain.length > MAX_CHAIN_STEPS) {
          throwToolError(`Too many chain steps (${params.chain.length}). Max is ${MAX_CHAIN_STEPS}.`);
        }

        const results: SingleResult[] = [];
        let previous = "";
        for (let index = 0; index < params.chain.length; index++) {
          const step = params.chain[index];
          const task = applyPreviousPlaceholder(step.task, previous);
          const chainUpdate: SubagentUpdate | undefined = onUpdate
            ? (partial) => {
                const current = partial.details?.results[0];
                if (!current) return;
                onUpdate({ content: partial.content, details: makeDetails([...results, current]) });
              }
            : undefined;
          const result = await runSingleAgent(ctx.cwd, agents, step.agent, task, step.cwd, index + 1, signal, chainUpdate, makeDetails);
          results.push(result);
          if (isFailed(result)) {
            return failedToolResult(`Chain stopped at step ${index + 1} (${step.agent}): ${resultOutput(result)}`, makeDetails(results));
          }
          previous = getFinalAssistantText(result.messages);
        }
        return { content: [{ type: "text", text: previous || "(no output)" }], details: makeDetails(results) };
      }

      if (params.tasks?.length) {
        if (params.tasks.length > MAX_PARALLEL_TASKS) {
          throwToolError(`Too many parallel tasks (${params.tasks.length}). Max is ${MAX_PARALLEL_TASKS}.`);
        }

        const runningResults: SingleResult[] = params.tasks.map((task) => ({
          agent: task.agent,
          agentSource: "unknown",
          task: task.task,
          exitCode: -1,
          messages: [],
          stderr: "",
          usage: emptyUsage(),
          progress: createProgress(),
        }));
        const emitParallelUpdate = () => {
          const done = runningResults.filter((result) => result.exitCode !== -1).length;
          const progress = runningResults.map((result) => formatResultProgress(result)).join("\n\n");
          onUpdate?.({ content: [{ type: "text", text: `Parallel: ${done}/${runningResults.length} done\n\n${progress}` }], details: makeDetails([...runningResults]) });
        };

        const results = await mapWithConcurrencyLimit(params.tasks, MAX_CONCURRENCY, async (task, index) => {
          const result = await runSingleAgent(
            ctx.cwd,
            agents,
            task.agent,
            task.task,
            task.cwd,
            undefined,
            signal,
            (partial) => {
              if (partial.details?.results[0]) {
                runningResults[index] = partial.details.results[0];
                emitParallelUpdate();
              }
            },
            makeDetails,
          );
          runningResults[index] = result;
          emitParallelUpdate();
          return result;
        });

        const successCount = results.filter((result) => !isFailed(result)).length;
        const summaries = results.map((result) => `### ${result.agent} ${isFailed(result) ? "failed" : "completed"}\n\n${resultOutput(result)}`);
        const text = `Parallel: ${successCount}/${results.length} succeeded\n\n${summaries.join("\n\n---\n\n")}`;
        if (successCount !== results.length) return failedToolResult(text, makeDetails(results));
        return {
          content: [{ type: "text", text }],
          details: makeDetails(results),
        };
      }

      if (params.agent && params.task) {
        const result = await runSingleAgent(ctx.cwd, agents, params.agent, params.task, params.cwd, undefined, signal, onUpdate, makeDetails);
        const text = resultOutput(result);
        if (isFailed(result)) return failedToolResult(text, makeDetails([result]));
        return {
          content: [{ type: "text", text }],
          details: makeDetails([result]),
        };
      }

      throwToolError("Invalid parameters.");
    },

    renderCall(args, theme, _context) {
      if (args.chain?.length) {
        return new Text(
          `${theme.fg("toolTitle", theme.bold("subagent"))} ${theme.fg("accent", `chain (${args.chain.length})`)}`,
          0,
          0,
        );
      }
      if (args.tasks?.length) {
        return new Text(
          `${theme.fg("toolTitle", theme.bold("subagent"))} ${theme.fg("accent", `parallel (${args.tasks.length})`)}`,
          0,
          0,
        );
      }
      return new Text(
        `${theme.fg("toolTitle", theme.bold("subagent"))} ${theme.fg("accent", args.agent ?? "...")}`,
        0,
        0,
      );
    },

    renderResult(result, { expanded }, theme, _context) {
      const details = result.details as SubagentDetails | undefined;
      const text = formatRenderResult(result as any, expanded);
      const hasError = Boolean(result.isError) || details?.results.some((entry) => isFailed(entry));
      const color = hasError ? "error" : details?.results.some((entry) => entry.progress?.status === "running") ? "warning" : "toolOutput";
      return new Text(theme.fg(color as any, text), 0, 0);
    },
  });
}
