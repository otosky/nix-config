import assert from "node:assert/strict";
import test from "node:test";
import { expandLoopTemplate, formatLoopHistory, type LoopTemplateState } from "../loop-template.ts";

test("expandLoopTemplate replaces loop placeholders", () => {
  const state: LoopTemplateState = {
    task: "ship the feature",
    iteration: 2,
    previous: "worker output",
    feedback: "fix tests",
    history: "Iteration 1: continue - fix tests",
    stepOutputs: new Map([
      ["work", "worker output"],
      ["review", "review output"],
    ]),
  };

  assert.equal(
    expandLoopTemplate("Task={task}; i={iteration}; prev={previous}; feedback={feedback}; history={history}; work={step:work}; missing={step:missing}", state),
    "Task=ship the feature; i=2; prev=worker output; feedback=fix tests; history=Iteration 1: continue - fix tests; work=worker output; missing=",
  );
});

test("expandLoopTemplate leaves unknown placeholders unchanged", () => {
  const state: LoopTemplateState = {
    task: "task",
    iteration: 1,
    previous: "",
    feedback: "",
    history: "",
    stepOutputs: new Map(),
  };

  assert.equal(expandLoopTemplate("Keep {unknown} here", state), "Keep {unknown} here");
});

test("formatLoopHistory summarizes prior decisions and feedback", () => {
  assert.equal(
    formatLoopHistory([
      { index: 1, status: "continue", feedback: "add tests" },
      { index: 2, status: "continue", feedback: "tighten validation" },
    ]),
    "Iteration 1: continue - add tests\nIteration 2: continue - tighten validation",
  );
});
