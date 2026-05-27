import assert from "node:assert/strict";
import { registerHooks } from "node:module";
import test from "node:test";
import type { AgentConfig } from "../agents.ts";
import type { LoopParams, LoopRunner } from "../loop.ts";
import { formatLoopToolText } from "../loop-result.ts";
import type { SingleResult } from "../result.ts";

const piTuiStubUrl = `data:text/javascript,${encodeURIComponent("export class Text { constructor(text, paddingX, paddingY) { this.text = text; this.paddingX = paddingX; this.paddingY = paddingY; } }")}`;
registerHooks({
  resolve(specifier, context, nextResolve) {
    if (specifier === "@earendil-works/pi-tui") return { url: piTuiStubUrl, shortCircuit: true };
    return nextResolve(specifier, context);
  },
});

const { default: registerLoop, executeLoop, validateLoopParams, validateRequestedLoopAgents } = await import("../loop.ts");

function params(overrides: Partial<LoopParams> = {}): LoopParams {
  return {
    task: "ship feature",
    steps: [
      { id: "work", agent: "worker", task: "Work on {task}" },
      { id: "review", agent: "reviewer", task: "Review {step:work}" },
    ],
    deciderStep: "review",
    maxIterations: 5,
    ...overrides,
  };
}

test("validateLoopParams accepts a final decider step", () => {
  assert.doesNotThrow(() => validateLoopParams(params()));
});

test("loop render functions create text components", () => {
  let tool: any;
  const pi = {
    registerTool(registeredTool: any) {
      tool = registeredTool;
    },
  };
  const theme = {
    bold: (text: string) => text,
    fg: (_color: string, text: string) => text,
  };

  registerLoop(pi as any, () => "/builtin-agents");

  const call = tool.renderCall(params(), theme);
  const result = tool.renderResult(
    { details: { status: "done", task: "ship feature", iterations: [], finalFeedback: "complete" } },
    { expanded: false },
    theme,
  );

  assert.match(call.text, /loop/);
  assert.match(call.text, /2 steps/);
  assert.match(result.text, /done/);
});

test("validateLoopParams rejects empty steps", () => {
  assert.throws(() => validateLoopParams(params({ steps: [] })), /at least one step/);
});

test("validateLoopParams rejects duplicate step ids", () => {
  assert.throws(
    () => validateLoopParams(params({ steps: [{ id: "work", agent: "worker", task: "a" }, { id: "work", agent: "reviewer", task: "b" }] })),
    /unique step id/,
  );
});

test("validateLoopParams rejects missing decider", () => {
  assert.throws(() => validateLoopParams(params({ deciderStep: "missing" })), /deciderStep/);
});

test("validateLoopParams rejects non-final decider for v1", () => {
  assert.throws(() => validateLoopParams(params({ deciderStep: "work" })), /final step/);
});

test("validateLoopParams rejects maxIterations over the hard cap", () => {
  assert.throws(() => validateLoopParams(params({ maxIterations: 11 })), /maxIterations must be between 1 and 10/);
});

const agents: AgentConfig[] = [
  { name: "worker", description: "Worker", systemPrompt: "", source: "builtin", filePath: "/agents/worker.md" },
  { name: "reviewer", description: "Reviewer", systemPrompt: "", source: "builtin", filePath: "/agents/reviewer.md" },
];

function singleResult(agent: string, task: string, output: string, exitCode = 0): SingleResult {
  return {
    agent,
    agentSource: "builtin",
    task,
    exitCode,
    messages: [{ role: "assistant", content: [{ type: "text", text: output }] } as any],
    stderr: exitCode === 0 ? "" : output,
    usage: { input: 1, output: 2, cacheRead: 0, cacheWrite: 0, cost: 0.001, turns: 1 },
  };
}

test("validateRequestedLoopAgents rejects unknown agents", () => {
  assert.throws(
    () =>
      validateRequestedLoopAgents(
        params({
          steps: [
            { id: "work", agent: "worker", task: "Work on {task}" },
            { id: "review", agent: "missing-reviewer", task: "Review {step:work}" },
          ],
        }),
        agents,
      ),
    /Unknown loop agent.*missing-reviewer/,
  );
});

test("executeLoop rejects unknown later-step agents before calling runner", async () => {
  let calls = 0;
  const runner: LoopRunner = async ({ agentName, task }) => {
    calls += 1;
    return singleResult(agentName, task, "should not run");
  };

  await assert.rejects(
    () =>
      executeLoop({
        params: params({
          steps: [
            { id: "work", agent: "worker", task: "Work on {task}" },
            { id: "review", agent: "missing-reviewer", task: "Review {step:work}" },
          ],
        }),
        agents,
        agentScope: "user",
        projectAgentsDir: null,
        defaultCwd: "/repo",
        runner,
      }),
    /Unknown loop agent.*missing-reviewer/,
  );
  assert.equal(calls, 0);
});

test("executeLoop exposes malformed decider output in failed details", async () => {
  const badOutput = "review notes without a decision block";
  const runner: LoopRunner = async ({ agentName, task }) => {
    if (agentName === "worker") return singleResult(agentName, task, "implemented once");
    return singleResult(agentName, task, badOutput);
  };

  const details = await executeLoop({
    params: params({ maxIterations: 1 }),
    agents,
    agentScope: "user",
    projectAgentsDir: null,
    defaultCwd: "/repo",
    runner,
  });

  assert.equal(details.status, "failed");
  const deciderResult = details.iterations[0]?.steps[1]?.result;
  assert.match(deciderResult?.errorMessage ?? "", /Decider output must include a fenced JSON decision block/);
  assert.match(deciderResult?.errorMessage ?? "", /review notes without a decision block/);
  assert.match(formatLoopToolText(details), /Decider output must include a fenced JSON decision block/);
  assert.match(formatLoopToolText(details), /review notes without a decision block/);
});

test("executeLoop emits running step updates from the runner", async () => {
  const updates: string[] = [];
  const runner: LoopRunner = async ({ agentName, task, onUpdate }) => {
    onUpdate?.({
      ...singleResult(agentName, task, ""),
      exitCode: -1,
      progress: {
        status: "running",
        currentActivity: `running ${agentName}`,
        recentTools: [],
        recentText: [],
        startedAt: 0,
        updatedAt: 0,
        turns: 0,
      },
    });
    if (agentName === "worker") return singleResult(agentName, task, "implemented once");
    return singleResult(agentName, task, 'review ok\n```json\n{"status":"done","feedback":"complete"}\n```');
  };

  await executeLoop({
    params: params({ maxIterations: 1 }),
    agents,
    agentScope: "user",
    projectAgentsDir: null,
    defaultCwd: "/repo",
    runner,
    onUpdate: (details) => updates.push(details.iterations.at(-1)?.steps.at(-1)?.result.progress?.currentActivity ?? ""),
  });

  assert.ok(updates.includes("running worker"));
  assert.ok(updates.includes("running reviewer"));
});

test("executeLoop stops when decider returns done", async () => {
  const calls: Array<{ agent: string; task: string }> = [];
  const runner: LoopRunner = async ({ agentName, task }) => {
    calls.push({ agent: agentName, task });
    if (agentName === "worker") return singleResult(agentName, task, "implemented once");
    return singleResult(agentName, task, 'review ok\n```json\n{"status":"done","feedback":"complete"}\n```');
  };

  const details = await executeLoop({
    params: params({ maxIterations: 5 }),
    agents,
    agentScope: "user",
    projectAgentsDir: null,
    defaultCwd: "/repo",
    runner,
  });

  assert.equal(details.status, "done");
  assert.equal(details.iterations.length, 1);
  assert.equal(details.finalFeedback, "complete");
  assert.equal(calls.length, 2);
});

test("executeLoop feeds decider feedback into the next iteration", async () => {
  const workerTasks: string[] = [];
  let reviewCount = 0;
  const runner: LoopRunner = async ({ agentName, task }) => {
    if (agentName === "worker") {
      workerTasks.push(task);
      return singleResult(agentName, task, `worker ${workerTasks.length}`);
    }
    reviewCount += 1;
    if (reviewCount === 1) return singleResult(agentName, task, 'needs tests\n```json\n{"status":"continue","feedback":"add tests"}\n```');
    return singleResult(agentName, task, 'ok\n```json\n{"status":"done","feedback":"complete"}\n```');
  };

  const details = await executeLoop({
    params: params({
      maxIterations: 3,
      steps: [
        { id: "work", agent: "worker", task: "Work on {task}. Feedback: {feedback}. History: {history}" },
        { id: "review", agent: "reviewer", task: "Review {step:work}" },
      ],
    }),
    agents,
    agentScope: "user",
    projectAgentsDir: null,
    defaultCwd: "/repo",
    runner,
  });

  assert.equal(details.status, "done");
  assert.equal(details.iterations.length, 2);
  assert.match(workerTasks[1] ?? "", /Feedback: add tests/);
  assert.match(workerTasks[1] ?? "", /Iteration 1: continue - add tests/);
});

test("executeLoop returns max_iterations after final continue", async () => {
  const runner: LoopRunner = async ({ agentName, task }) => {
    if (agentName === "worker") return singleResult(agentName, task, "work");
    return singleResult(agentName, task, 'again\n```json\n{"status":"continue","feedback":"keep going"}\n```');
  };

  const details = await executeLoop({
    params: params({ maxIterations: 2 }),
    agents,
    agentScope: "user",
    projectAgentsDir: null,
    defaultCwd: "/repo",
    runner,
  });

  assert.equal(details.status, "max_iterations");
  assert.equal(details.iterations.length, 2);
  assert.equal(details.finalFeedback, "keep going");
});

test("executeLoop fails when a non-decider step fails", async () => {
  const runner: LoopRunner = async ({ agentName, task }) => singleResult(agentName, task, "worker failed", 1);

  const details = await executeLoop({
    params: params({ maxIterations: 2 }),
    agents,
    agentScope: "user",
    projectAgentsDir: null,
    defaultCwd: "/repo",
    runner,
  });

  assert.equal(details.status, "failed");
  assert.equal(details.iterations.length, 1);
  assert.equal(details.iterations[0]?.steps.length, 1);
});
