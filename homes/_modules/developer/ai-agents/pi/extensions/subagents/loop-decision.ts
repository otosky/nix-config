export type LoopDecisionStatus = "done" | "continue";

export interface LoopDecision {
  status: LoopDecisionStatus;
  feedback: string;
}

export const LOOP_DECIDER_INSTRUCTIONS = `

Loop decision instructions:
At the end of your response, include exactly one JSON decision block fenced as \`\`\`json.
The JSON must match this shape:
{
  "status": "done" | "continue",
  "feedback": "..."
}
Use "done" only when no further iteration is needed.
Use "continue" when another iteration should run, and put the requested changes or next focus in "feedback".`;

export function appendDeciderInstructions(task: string): string {
  return `${task.trimEnd()}${LOOP_DECIDER_INSTRUCTIONS}`;
}

export function parseLoopDecision(output: string): LoopDecision {
  const matches = [...output.matchAll(/```json\s*([\s\S]*?)\s*```/gi)];
  const last = matches.at(-1);
  if (!last?.[1]) {
    throw new Error("Decider output must include a fenced JSON decision block.");
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(last[1]);
  } catch (error) {
    throw new Error(`Decider JSON could not be parsed: ${error instanceof Error ? error.message : String(error)}`);
  }

  if (!parsed || typeof parsed !== "object") {
    throw new Error("Decider JSON must be an object.");
  }

  const candidate = parsed as { status?: unknown; feedback?: unknown };
  if (candidate.status !== "done" && candidate.status !== "continue") {
    throw new Error('Decider status must be "done" or "continue".');
  }
  if (typeof candidate.feedback !== "string") {
    throw new Error("Decider feedback must be a string.");
  }

  return { status: candidate.status, feedback: candidate.feedback };
}
