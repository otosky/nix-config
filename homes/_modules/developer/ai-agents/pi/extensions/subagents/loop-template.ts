export interface LoopTemplateState {
  task: string;
  iteration: number;
  previous: string;
  feedback: string;
  history: string;
  stepOutputs: Map<string, string>;
}

export interface LoopHistoryItem {
  index: number;
  status: "done" | "continue";
  feedback: string;
}

export function formatLoopHistory(items: LoopHistoryItem[]): string {
  return items.map((item) => `Iteration ${item.index}: ${item.status} - ${item.feedback}`).join("\n");
}

export function expandLoopTemplate(template: string, state: LoopTemplateState): string {
  return template.replace(/\{([^{}]+)\}/g, (match, key: string) => {
    if (key === "task") return state.task;
    if (key === "iteration") return String(state.iteration);
    if (key === "previous") return state.previous;
    if (key === "feedback") return state.feedback;
    if (key === "history") return state.history;
    if (key.startsWith("step:")) return state.stepOutputs.get(key.slice("step:".length)) ?? "";
    return match;
  });
}
