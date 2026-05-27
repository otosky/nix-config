import assert from "node:assert/strict";
import test from "node:test";
import { failedToolResult, formatDetailsForRender, formatRenderResult, isFailed, type SingleResult } from "../result.ts";

function result(overrides: Partial<SingleResult> = {}): SingleResult {
  return {
    agent: "reviewer",
    agentSource: "user",
    task: "review",
    exitCode: 0,
    messages: [],
    stderr: "",
    usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 0 },
    ...overrides,
  };
}

test("formatRenderResult shows thrown tool error text when details are absent", () => {
  const text = formatRenderResult({ content: [{ type: "text", text: "tool exploded" }] }, false);

  assert.equal(text, "tool exploded");
});

test("formatRenderResult shows content text when details have no results", () => {
  const text = formatRenderResult(
    {
      content: [{ type: "text", text: "subagent cancelled" }],
      details: { mode: "single", agentScope: "user", projectAgentsDir: null, results: [] },
    },
    false,
  );

  assert.equal(text, "subagent cancelled");
});

test("running results are not treated as failed or complete", () => {
  assert.equal(isFailed(result({ exitCode: -1 })), false);
});

test("failedToolResult preserves content, details, and error status", () => {
  const details = {
    mode: "single" as const,
    agentScope: "user" as const,
    projectAgentsDir: null,
    results: [result({ exitCode: 1, stderr: "failed" })],
  };

  assert.deepEqual(failedToolResult("failed", details), {
    content: [{ type: "text", text: "failed" }],
    details,
    isError: true,
  });
});

test("formatDetailsForRender shows per-agent cost in collapsed TUI output", () => {
  const text = formatDetailsForRender(
    {
      mode: "single",
      agentScope: "user",
      projectAgentsDir: null,
      results: [result({ usage: { input: 100, output: 25, cacheRead: 5, cacheWrite: 1, cost: 0.0123, turns: 2 } })],
    },
    false,
  );

  assert.match(text, /2 turns ↑100 ↓25 R5 W1 \$0\.0123/);
});

test("formatDetailsForRender shows aggregate cost for multi-agent TUI output", () => {
  const text = formatDetailsForRender(
    {
      mode: "parallel",
      agentScope: "user",
      projectAgentsDir: null,
      results: [
        result({ agent: "reviewer-a", usage: { input: 100, output: 25, cacheRead: 0, cacheWrite: 0, cost: 0.01, turns: 1 } }),
        result({ agent: "reviewer-b", usage: { input: 200, output: 50, cacheRead: 10, cacheWrite: 0, cost: 0.02, turns: 2 } }),
      ],
    },
    false,
  );

  assert.match(text, /Total: 3 turns ↑300 ↓75 R10 \$0\.0300/);
});
