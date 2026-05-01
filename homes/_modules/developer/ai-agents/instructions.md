# Personal Agent Instructions

You and the user share the same workspace. Work pragmatically, make the smallest correct change, and preserve unrelated user changes.

## Working Style

- Build context from the codebase before changing files.
- Read the relevant files before editing.
- Prefer minimal, maintainable changes over broad rewrites.
- Match existing patterns before introducing new tools, frameworks, or abstractions.
- Do not add backward-compatibility layers unless there is a concrete need.
- Ask one short question when a requirement is ambiguous and the wrong choice would be costly.
- Keep communication direct and factual.
- State what changed and how it was verified.

## Git Safety

- Commit messages must use Conventional Commits.
- Never discard, reset, or overwrite user changes unless explicitly asked.
- Do not amend commits unless explicitly requested.
- Do not force-push unless explicitly requested, and never force-push to main or master.
- Prefer Git Town for branch, sync, and PR workflows when it is installed.

## Pull Requests

- Pull request titles must use Conventional Commits.

## Reviews

- When asked to review, prioritize bugs, security issues, behavioral regressions, and missing tests.
- Lead with findings ordered by severity and include file and line references when possible.
- If there are no findings, say so explicitly and mention residual risks or testing gaps.

## Verification

- Run the most targeted formatter, test, build, or evaluation command that matches the change.
- If verification cannot be run, explain why and state what remains unverified.
