import assert from "node:assert/strict";
import test from "node:test";
import { createProgress, formatResultProgress, updateProgressFromEvent } from "../progress.ts";

test("updateProgressFromEvent records tool lifecycle activity", () => {
  const progress = createProgress(1000);

  updateProgressFromEvent(progress, {
    type: "tool_execution_start",
    toolName: "bash",
    args: { command: "git diff --stat -- README.md" },
  }, 1500);

  assert.equal(progress.status, "running");
  assert.equal(progress.currentActivity, "running bash: git diff --stat -- README.md");
  assert.deepEqual(progress.recentTools, [{ name: "bash", preview: "git diff --stat -- README.md", status: "running" }]);

  updateProgressFromEvent(progress, { type: "tool_execution_end", toolName: "bash", isError: false }, 2000);

  assert.equal(progress.currentActivity, "finished bash");
  assert.equal(progress.recentTools[0]?.status, "done");
});

test("updateProgressFromEvent records streaming text and thinking", () => {
  const progress = createProgress(1000);

  updateProgressFromEvent(progress, { type: "message_update", assistantMessageEvent: { type: "thinking_delta", delta: "checking" } }, 1200);
  assert.equal(progress.currentActivity, "thinking...");

  updateProgressFromEvent(progress, { type: "message_update", assistantMessageEvent: { type: "text_delta", delta: "Reading files" } }, 1300);

  assert.equal(progress.currentActivity, "responding...");
  assert.deepEqual(progress.recentText, ["Reading files"]);
});

test("updateProgressFromEvent preserves spaces between adjacent text deltas", () => {
  const progress = createProgress(1000);

  updateProgressFromEvent(progress, { type: "message_update", assistantMessageEvent: { type: "text_delta", delta: "Reading" } }, 1200);
  updateProgressFromEvent(progress, { type: "message_update", assistantMessageEvent: { type: "text_delta", delta: " files" } }, 1300);

  assert.deepEqual(progress.recentText, ["Reading files"]);
});

test("updateProgressFromEvent preserves spaces that arrive as separate text deltas", () => {
  const progress = createProgress(1000);

  for (const delta of ["Reading", " ", "files"]) {
    updateProgressFromEvent(progress, { type: "message_update", assistantMessageEvent: { type: "text_delta", delta } }, 1200);
  }

  assert.deepEqual(progress.recentText, ["Reading files"]);
});

test("formatResultProgress shows status, duration, tools, and recent text", () => {
  const progress = createProgress(1000);
  updateProgressFromEvent(progress, { type: "tool_execution_start", toolName: "read", args: { path: "src/index.ts" } }, 2000);
  updateProgressFromEvent(progress, { type: "message_update", assistantMessageEvent: { type: "text_delta", delta: "Inspecting implementation" } }, 2500);

  const text = formatResultProgress({ agent: "reviewer", progress }, 3000);

  assert.match(text, /⏳ reviewer running 2s/);
  assert.match(text, /running read: src\/index\.ts/);
  assert.match(text, /Inspecting implementation/);
});
