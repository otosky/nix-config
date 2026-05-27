import assert from "node:assert/strict";
import test from "node:test";
import { appendDeciderInstructions, parseLoopDecision } from "../loop-decision.ts";

test("appendDeciderInstructions appends the required JSON contract", () => {
  const text = appendDeciderInstructions("Review the work.");

  assert.match(text, /Review the work\./);
  assert.match(text, /Loop decision instructions/);
  assert.match(text, /"status": "done" \| "continue"/);
});

test("parseLoopDecision reads fenced JSON decision", () => {
  assert.deepEqual(
    parseLoopDecision('Review looks good.\n```json\n{"status":"done","feedback":"no more changes"}\n```'),
    { status: "done", feedback: "no more changes" },
  );
});

test("parseLoopDecision uses the last fenced JSON block", () => {
  assert.deepEqual(
    parseLoopDecision('```json\n{"status":"continue","feedback":"old"}\n```\nFinal:\n```json\n{"status":"done","feedback":"final"}\n```'),
    { status: "done", feedback: "final" },
  );
});

test("parseLoopDecision rejects invalid status", () => {
  assert.throws(() => parseLoopDecision('```json\n{"status":"maybe","feedback":"unclear"}\n```'), /status must be/);
});

test("parseLoopDecision rejects missing feedback", () => {
  assert.throws(() => parseLoopDecision('```json\n{"status":"continue"}\n```'), /feedback must be a string/);
});

test("parseLoopDecision rejects responses without fenced JSON", () => {
  assert.throws(() => parseLoopDecision('{"status":"done","feedback":"ok"}'), /fenced JSON decision block/);
});
