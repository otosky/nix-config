import type { AgentScope } from "./agents.ts";
import type { LoopDecision } from "./loop-decision.ts";
import { formatResultProgress } from "./progress.ts";
import { formatUsage, resultOutput, type SingleResult, type UsageStats } from "./result.ts";

export type LoopStatus = "running" | "done" | "max_iterations" | "failed";

export interface LoopStepResult {
  id: string;
  result: SingleResult;
}

export interface LoopIterationResult {
  index: number;
  steps: LoopStepResult[];
  decision?: LoopDecision;
}

export interface LoopDetails {
  status: LoopStatus;
  task: string;
  maxIterations: number;
  agentScope: AgentScope;
  projectAgentsDir: string | null;
  iterations: LoopIterationResult[];
  finalFeedback: string;
  usage: UsageStats;
}

export function emptyLoopUsage(): UsageStats {
  return { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 0 };
}

export function sumLoopUsage(iterations: LoopIterationResult[]): UsageStats {
  return iterations.flatMap((iteration) => iteration.steps).reduce(
    (total, step) => ({
      input: total.input + step.result.usage.input,
      output: total.output + step.result.usage.output,
      cacheRead: total.cacheRead + step.result.usage.cacheRead,
      cacheWrite: total.cacheWrite + step.result.usage.cacheWrite,
      cost: total.cost + step.result.usage.cost,
      turns: total.turns + step.result.usage.turns,
    }),
    emptyLoopUsage(),
  );
}

export function formatLoopToolText(details: LoopDetails): string {
  const lines = [`Loop status: ${details.status}`, `Iterations: ${details.iterations.length}/${details.maxIterations}`];
  if (details.finalFeedback) lines.push(`Final feedback: ${details.finalFeedback}`);

  const last = details.iterations.at(-1);
  if (last) {
    lines.push("", `## Last iteration (${last.index})`);
    for (const step of last.steps) {
      lines.push("", `### ${step.id} (${step.result.agent})`, "", resultOutput(step.result));
    }
  }

  return lines.join("\n");
}

export function formatLoopRenderResult(details: LoopDetails | undefined, expanded: boolean): string {
  if (!details) return "loop (no details)";

  const lines = [`loop ${details.status} ${details.iterations.length}/${details.maxIterations}`];
  const usage = formatUsage(details.usage);
  if (usage) lines.push(`Total: ${usage}`);

  const last = details.iterations.at(-1);
  const latestStep = last?.steps.at(-1);
  if (latestStep) {
    lines.push(`current: iteration ${last.index} step ${latestStep.id}`);
    if (latestStep.result.progress) lines.push(formatResultProgress(latestStep.result));
  }
  if (last?.decision) lines.push(`decision: ${last.decision.status} - ${last.decision.feedback}`);

  if (expanded) {
    for (const iteration of details.iterations) {
      lines.push("", `Iteration ${iteration.index}`);
      for (const step of iteration.steps) {
        lines.push(`- ${step.id} (${step.result.agent}): ${resultOutput(step.result)}`);
      }
    }
  }

  return lines.join("\n");
}
