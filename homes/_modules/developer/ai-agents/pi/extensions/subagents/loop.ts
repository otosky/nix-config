import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import {
  assertProjectAgentConfirmationAllowed,
  discoverAgents,
  throwToolError,
  type AgentConfig,
  type AgentScope,
} from "./agents.ts";
import { appendDeciderInstructions, parseLoopDecision } from "./loop-decision.ts";
import { formatLoopHistory, expandLoopTemplate, type LoopHistoryItem } from "./loop-template.ts";
import {
  formatLoopRenderResult,
  formatLoopToolText,
  sumLoopUsage,
  type LoopDetails,
  type LoopIterationResult,
} from "./loop-result.ts";
import { isFailed, resultOutput, type SingleResult } from "./result.ts";
import { runSingleAgent } from "./runner.ts";

const MAX_LOOP_ITERATIONS = 10;
const DEFAULT_LOOP_ITERATIONS = 5;

const LoopStepSchema = {
  type: "object",
  properties: {
    id: { type: "string", description: "Unique step id used for placeholders and deciderStep" },
    agent: { type: "string", description: "Name of the agent to invoke" },
    task: { type: "string", description: "Task template for this step" },
    cwd: { type: "string", description: "Working directory for this step" },
  },
  required: ["id", "agent", "task"],
  additionalProperties: false,
} as const;

const LoopParamsSchema = {
  type: "object",
  properties: {
    task: { type: "string", description: "Original loop objective" },
    steps: { type: "array", items: LoopStepSchema, description: "Sequential steps to run each iteration" },
    deciderStep: { type: "string", description: "ID of the final step whose output controls loop termination" },
    maxIterations: { type: "number", description: "Maximum loop iterations. Default 5, max 10." },
    agentScope: {
      type: "string",
      enum: ["user", "project", "both"],
      description: "Agent directories to use. Builtin agents are always available. Default: user.",
      default: "user",
    },
    confirmProjectAgents: { type: "boolean", default: true },
  },
  required: ["task", "steps", "deciderStep"],
  additionalProperties: false,
} as const;

export interface LoopStepParams {
  id: string;
  agent: string;
  task: string;
  cwd?: string;
}

export interface LoopParams {
  task: string;
  steps: LoopStepParams[];
  deciderStep: string;
  maxIterations?: number;
  agentScope?: AgentScope;
  confirmProjectAgents?: boolean;
}

function createText(text: string): Text {
  return new Text(text, 0, 0);
}

export function validateLoopParams(params: LoopParams): void {
  if (!params.task.trim()) throwToolError("loop task must not be empty.");
  if (params.steps.length === 0) throwToolError("loop requires at least one step.");

  const ids = new Set<string>();
  for (const step of params.steps) {
    if (!step.id.trim()) throwToolError("Each loop step requires a non-empty unique step id.");
    if (ids.has(step.id)) throwToolError(`Each loop step must have a unique step id. Duplicate: ${step.id}`);
    ids.add(step.id);
    if (!step.agent.trim()) throwToolError(`Loop step ${step.id} requires an agent.`);
    if (!step.task.trim()) throwToolError(`Loop step ${step.id} requires a task.`);
  }

  const deciderIndex = params.steps.findIndex((step) => step.id === params.deciderStep);
  if (deciderIndex === -1) throwToolError(`deciderStep must match a step id. Received: ${params.deciderStep}`);
  if (deciderIndex !== params.steps.length - 1) throwToolError("deciderStep must be the final step for loop v1.");

  const maxIterations = params.maxIterations ?? DEFAULT_LOOP_ITERATIONS;
  if (!Number.isInteger(maxIterations) || maxIterations < 1 || maxIterations > MAX_LOOP_ITERATIONS) {
    throwToolError(`maxIterations must be between 1 and ${MAX_LOOP_ITERATIONS}.`);
  }
}

export function validateRequestedLoopAgents(params: LoopParams, agents: AgentConfig[]): void {
  const knownAgents = new Set(agents.map((agent) => agent.name));
  const unknownAgents = [...new Set(params.steps.map((step) => step.agent))].filter((agent) => !knownAgents.has(agent));
  if (unknownAgents.length > 0) throwToolError(`Unknown loop agent(s): ${unknownAgents.join(", ")}`);
}

export interface LoopRunnerInput {
  agentName: string;
  task: string;
  cwd?: string;
  stepNumber: number;
}

export type LoopRunner = (input: LoopRunnerInput) => Promise<SingleResult>;

export interface ExecuteLoopOptions {
  params: LoopParams;
  agents: AgentConfig[];
  agentScope: AgentScope;
  projectAgentsDir: string | null;
  defaultCwd: string;
  runner: LoopRunner;
  onUpdate?: (details: LoopDetails) => void;
}

export function makeDetails(options: {
  status: LoopDetails["status"];
  params: LoopParams;
  agentScope: AgentScope;
  projectAgentsDir: string | null;
  iterations: LoopIterationResult[];
  finalFeedback: string;
}): LoopDetails {
  return {
    status: options.status,
    task: options.params.task,
    maxIterations: options.params.maxIterations ?? DEFAULT_LOOP_ITERATIONS,
    agentScope: options.agentScope,
    projectAgentsDir: options.projectAgentsDir,
    iterations: options.iterations,
    finalFeedback: options.finalFeedback,
    usage: sumLoopUsage(options.iterations),
  };
}

export async function executeLoop(options: ExecuteLoopOptions): Promise<LoopDetails> {
  validateLoopParams(options.params);
  validateRequestedLoopAgents(options.params, options.agents);

  const maxIterations = options.params.maxIterations ?? DEFAULT_LOOP_ITERATIONS;
  const iterations: LoopIterationResult[] = [];
  const history: LoopHistoryItem[] = [];
  let feedback = "";

  for (let iterationIndex = 1; iterationIndex <= maxIterations; iterationIndex++) {
    const stepOutputs = new Map<string, string>();
    const iteration: LoopIterationResult = { index: iterationIndex, steps: [] };
    iterations.push(iteration);
    let previous = "";

    for (let stepIndex = 0; stepIndex < options.params.steps.length; stepIndex++) {
      const step = options.params.steps[stepIndex]!;
      const expanded = expandLoopTemplate(step.task, {
        task: options.params.task,
        iteration: iterationIndex,
        previous,
        feedback,
        history: formatLoopHistory(history),
        stepOutputs,
      });
      const task = step.id === options.params.deciderStep ? appendDeciderInstructions(expanded) : expanded;
      const result = await options.runner({ agentName: step.agent, task, cwd: step.cwd, stepNumber: stepIndex + 1 });
      iteration.steps.push({ id: step.id, result });
      previous = resultOutput(result);
      stepOutputs.set(step.id, previous);

      if (isFailed(result)) {
        const details = makeDetails({
          status: "failed",
          params: options.params,
          agentScope: options.agentScope,
          projectAgentsDir: options.projectAgentsDir,
          iterations,
          finalFeedback: feedback,
        });
        options.onUpdate?.(details);
        return details;
      }
    }

    const deciderStep = iteration.steps.at(-1)!;
    const deciderOutput = resultOutput(deciderStep.result);
    try {
      iteration.decision = parseLoopDecision(deciderOutput);
    } catch (error) {
      deciderStep.result.exitCode = 1;
      const parseError = error instanceof Error ? error.message : String(error);
      deciderStep.result.errorMessage = `${parseError}\n\nOriginal decider output:\n${deciderOutput}`;
      const details = makeDetails({
        status: "failed",
        params: options.params,
        agentScope: options.agentScope,
        projectAgentsDir: options.projectAgentsDir,
        iterations,
        finalFeedback: feedback,
      });
      options.onUpdate?.(details);
      return details;
    }

    feedback = iteration.decision.feedback;
    history.push({ index: iterationIndex, status: iteration.decision.status, feedback: iteration.decision.feedback });

    if (iteration.decision.status === "done") {
      const details = makeDetails({
        status: "done",
        params: options.params,
        agentScope: options.agentScope,
        projectAgentsDir: options.projectAgentsDir,
        iterations,
        finalFeedback: feedback,
      });
      options.onUpdate?.(details);
      return details;
    }

    if (iterationIndex === maxIterations) {
      const details = makeDetails({
        status: "max_iterations",
        params: options.params,
        agentScope: options.agentScope,
        projectAgentsDir: options.projectAgentsDir,
        iterations,
        finalFeedback: feedback,
      });
      options.onUpdate?.(details);
      return details;
    }
  }

  return makeDetails({
    status: "max_iterations",
    params: options.params,
    agentScope: options.agentScope,
    projectAgentsDir: options.projectAgentsDir,
    iterations,
    finalFeedback: feedback,
  });
}

export default function registerLoop(pi: ExtensionAPI, getBuiltinAgentsDir: () => string): void {
  pi.registerTool({
    name: "loop",
    label: "Loop",
    description: "Run sequential subagent steps repeatedly until a final decider step returns done or maxIterations is reached.",
    parameters: LoopParamsSchema,
    async execute(_toolCallId, params, signal, onUpdate, ctx) {
      validateLoopParams(params);
      const agentScope: AgentScope = params.agentScope ?? "user";
      const discovery = discoverAgents({ cwd: ctx.cwd, scope: agentScope, builtinDir: getBuiltinAgentsDir() });
      validateRequestedLoopAgents(params, discovery.agents);
      const requestedAgents = new Set(params.steps.map((step) => step.agent));
      const projectAgents = [...requestedAgents]
        .map((name) => discovery.agents.find((agent) => agent.name === name))
        .filter((agent): agent is AgentConfig => agent?.source === "project");

      assertProjectAgentConfirmationAllowed({
        agentScope,
        confirmProjectAgents: params.confirmProjectAgents,
        hasUI: Boolean(ctx.hasUI),
        projectAgents,
        projectAgentsDir: discovery.projectAgentsDir,
      });

      if (projectAgents.length > 0 && (params.confirmProjectAgents ?? true)) {
        const ok = await ctx.ui.confirm(
          "Run project-local loop agents?",
          `Agents: ${projectAgents.map((agent) => agent.name).join(", ")}\nSource: ${discovery.projectAgentsDir ?? "unknown"}\n\nProject agents are repository-controlled. Continue only for trusted repositories.`,
        );
        if (!ok) {
          const details: LoopDetails = {
            status: "failed",
            task: params.task,
            maxIterations: params.maxIterations ?? DEFAULT_LOOP_ITERATIONS,
            agentScope,
            projectAgentsDir: discovery.projectAgentsDir,
            iterations: [],
            finalFeedback: "Canceled: project-local loop agents were not approved.",
            usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 0 },
          };
          return { content: [{ type: "text", text: details.finalFeedback }], details, isError: true };
        }
      }

      const details = await executeLoop({
        params,
        agents: discovery.agents,
        agentScope,
        projectAgentsDir: discovery.projectAgentsDir,
        defaultCwd: ctx.cwd,
        runner: ({ agentName, task, cwd, stepNumber }) =>
          runSingleAgent(ctx.cwd, discovery.agents, agentName, task, cwd, stepNumber, signal, undefined, () => ({
            mode: "single",
            agentScope,
            projectAgentsDir: discovery.projectAgentsDir,
            results: [],
          })),
        onUpdate: (details) => onUpdate?.({ content: [{ type: "text", text: formatLoopToolText(details) }], details }),
      });

      return { content: [{ type: "text", text: formatLoopToolText(details) }], details, isError: details.status === "failed" };
    },
    renderCall(args, theme) {
      return createText(`${theme.fg("toolTitle", theme.bold("loop"))} ${theme.fg("accent", `${args.steps?.length ?? 0} steps`)}`);
    },
    renderResult(result, { expanded }, theme) {
      const details = result.details as LoopDetails | undefined;
      const color = result.isError || details?.status === "failed" ? "error" : details?.status === "max_iterations" ? "warning" : "toolOutput";
      return createText(theme.fg(color as any, formatLoopRenderResult(details, expanded)));
    },
  });
}
