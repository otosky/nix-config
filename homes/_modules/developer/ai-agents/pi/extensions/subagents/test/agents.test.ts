import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";
import {
  applyPreviousPlaceholder,
  assertProjectAgentConfirmationAllowed,
  discoverAgents,
  getFinalAssistantText,
  throwToolError,
  type AgentConfig,
} from "../agents.ts";

test("discoverAgents loads markdown agent frontmatter and body", () => {
  const root = mkdtempSync(path.join(tmpdir(), "subagents-test-"));
  const userDir = path.join(root, "user-agents");
  mkdirSync(userDir, { recursive: true });
  writeFileSync(
    path.join(userDir, "reviewer.md"),
    `---\nname: reviewer\ndescription: Reviews code\ntools: read, grep, bash\nmodel: anthropic/claude-sonnet-4-5\n---\n\nReview carefully.\n`,
  );

  const result = discoverAgents({ cwd: root, scope: "user", userDir });

  assert.equal(result.agents.length, 1);
  assert.equal(result.agents[0]?.name, "reviewer");
  assert.deepEqual(result.agents[0]?.tools, ["read", "grep", "bash"]);
  assert.equal(result.agents[0]?.model, "anthropic/claude-sonnet-4-5");
  assert.equal(result.agents[0]?.systemPrompt.trim(), "Review carefully.");
  assert.equal(result.agents[0]?.source, "user");
});

test("project agents override user agents only when scope is both", () => {
  const root = mkdtempSync(path.join(tmpdir(), "subagents-test-"));
  const userDir = path.join(root, "user-agents");
  const projectDir = path.join(root, ".pi", "agents");
  mkdirSync(userDir, { recursive: true });
  mkdirSync(projectDir, { recursive: true });
  writeFileSync(path.join(userDir, "scout.md"), `---\nname: scout\ndescription: User scout\n---\n\nUser prompt\n`);
  writeFileSync(path.join(projectDir, "scout.md"), `---\nname: scout\ndescription: Project scout\n---\n\nProject prompt\n`);

  const userOnly = discoverAgents({ cwd: root, scope: "user", userDir });
  const both = discoverAgents({ cwd: root, scope: "both", userDir });

  assert.equal(userOnly.agents[0]?.description, "User scout");
  assert.equal(both.agents[0]?.description, "Project scout");
  assert.equal(both.agents[0]?.source, "project");
});

test("applyPreviousPlaceholder replaces every chain placeholder", () => {
  assert.equal(
    applyPreviousPlaceholder("Review this:\n{previous}\nAgain: {previous}", "plan output"),
    "Review this:\nplan output\nAgain: plan output",
  );
});

test("getFinalAssistantText returns the last assistant text part", () => {
  const messages = [
    { role: "assistant", content: [{ type: "text", text: "first" }] },
    { role: "user", content: [{ type: "text", text: "ignored" }] },
    { role: "assistant", content: [{ type: "text", text: "final" }] },
  ];

  assert.equal(getFinalAssistantText(messages), "final");
});

test("project agents require interactive confirmation unless confirmation is disabled", () => {
  const projectAgent: AgentConfig = {
    name: "local",
    description: "Local agent",
    systemPrompt: "Project prompt",
    source: "project",
    filePath: "/repo/.pi/agents/local.md",
  };

  assert.throws(
    () =>
      assertProjectAgentConfirmationAllowed({
        agentScope: "project",
        confirmProjectAgents: undefined,
        hasUI: false,
        projectAgents: [projectAgent],
        projectAgentsDir: "/repo/.pi/agents",
      }),
    /Project-local subagents require interactive confirmation/,
  );
  assert.doesNotThrow(() =>
    assertProjectAgentConfirmationAllowed({
      agentScope: "project",
      confirmProjectAgents: false,
      hasUI: false,
      projectAgents: [projectAgent],
      projectAgentsDir: "/repo/.pi/agents",
    }),
  );
});

test("throwToolError signals tool failures by throwing", () => {
  assert.throws(() => throwToolError("Invalid parameters."), /Invalid parameters/);
});
