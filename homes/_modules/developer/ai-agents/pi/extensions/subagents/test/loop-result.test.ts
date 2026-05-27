import assert from "node:assert/strict";
import test from "node:test";
import type { SingleResult, UsageStats } from "../result.ts";
import { formatLoopRenderResult, formatLoopToolText, sumLoopUsage, type LoopDetails } from "../loop-result.ts";

function usage(overrides: Partial<UsageStats> = {}): UsageStats {
  return { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 0, ...overrides };
}

function step(overrides: Partial<SingleResult> = {}): SingleResult {
  return {
    agent: "worker",
    agentSource: "user",
    task: "work",
    exitCode: 0,
    messages: [{ role: "assistant", content: [{ type: "text", text: "output" }] } as any],
    stderr: "",
    usage: usage({ input: 10, output: 5, cost: 0.01, turns: 1 }),
    ...overrides,
  };
}

function details(overrides: Partial<LoopDetails> = {}): LoopDetails {
  return {
    status: "done",
    task: "ship feature",
    maxIterations: 5,
    agentScope: "user",
    projectAgentsDir: null,
    finalFeedback: "complete",
    iterations: [
      {
        index: 1,
        steps: [{ id: "work", result: step() }],
        decision: { status: "done", feedback: "complete" },
      },
    ],
    usage: usage({ input: 10, output: 5, cost: 0.01, turns: 1 }),
    ...overrides,
  };
}

test("sumLoopUsage aggregates all step usage", () => {
  assert.deepEqual(
    sumLoopUsage([
      { index: 1, steps: [{ id: "a", result: step({ usage: usage({ input: 1, output: 2, turns: 1 }) }) }] },
      { index: 2, steps: [{ id: "b", result: step({ usage: usage({ input: 3, output: 4, cacheRead: 5, cacheWrite: 6, cost: 0.7, turns: 2 }) }) }] },
    ]),
    { input: 4, output: 6, cacheRead: 5, cacheWrite: 6, cost: 0.7, turns: 3 },
  );
});

test("formatLoopToolText summarizes final status and last iteration", () => {
  const text = formatLoopToolText(details());

  assert.match(text, /Loop status: done/);
  assert.match(text, /Iterations: 1\/5/);
  assert.match(text, /Final feedback: complete/);
  assert.match(text, /### work \(worker\)/);
  assert.match(text, /output/);
});

test("formatLoopRenderResult includes usage and decision", () => {
  const text = formatLoopRenderResult(details(), false);

  assert.match(text, /loop done 1\/5/);
  assert.match(text, /1 turn ↑10 ↓5 \$0\.0100/);
  assert.match(text, /decision: done - complete/);
});
