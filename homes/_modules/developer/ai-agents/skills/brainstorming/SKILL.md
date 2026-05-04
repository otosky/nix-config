---
name: brainstorming
description: Collaborative design exploration before implementation. Use when the user asks to design, brainstorm, compare approaches, clarify requirements, or think through a feature/fix before coding.
---

<!-- Inspired by obra/superpowers brainstorming: https://github.com/obra/superpowers/blob/main/skills/brainstorming/SKILL.md -->

# Brainstorming

Use this skill to turn a rough idea, feature request, bug, or workflow change into an approved design before implementation.

## Core Rule

Do not implement, edit files, or make code changes while using this skill unless the user explicitly approves the proposed design and asks you to proceed.

You may inspect the repository, read relevant files, and run narrow discovery commands when needed to understand context.

## Workflow

1. Restate the problem or goal in your own words.
2. Ask only the clarifying questions that materially affect the design. If the direction is clear, proceed without questions.
3. Explore 2–3 viable approaches when there is meaningful uncertainty.
4. Compare tradeoffs: complexity, maintainability, testability, user experience, and risk.
5. Recommend one approach and explain why.
6. Present a concrete design with expected behavior, affected files or areas, and test strategy.
7. Stop and wait for user approval before implementation.

## Output Shape

Keep the response concise and structured:

```markdown
## Goal
[Restated goal]

## Options
1. [Option A] — pros/cons
2. [Option B] — pros/cons

## Recommendation
[Recommended approach and why]

## Proposed Design
- [Specific design point]
- [Specific design point]

## Test Strategy
- [How we would verify it]

## Approval
If this looks right, say so and I can implement it.
```

## Guidance

- Prefer the smallest design that solves the current problem.
- Avoid speculative infrastructure and broad rewrites.
- Call out assumptions explicitly.
- If the user has already chosen an approach, do not over-brainstorm; refine that approach.
- If the request is actually ready for implementation, still confirm the intended design before coding.
