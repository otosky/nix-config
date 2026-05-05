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
- Use `deps` for dependency and package additions, removals, or updates, including Nix package list changes and flake updates.
- Never discard, reset, or overwrite user changes unless explicitly asked.
- Do not amend commits unless explicitly requested.
- Do not force-push unless explicitly requested, and never force-push to main or master.
- Prefer Git Town for branch, sync, and PR workflows when it is installed.

## Branch Naming

- Before creating a branch, check the repository's `CONTRIBUTING.md` and `README.md` for project-specific branch naming guidance. Follow those guidelines if they conflict with these defaults.
- Otherwise, use short, descriptive, lowercase kebab-case branch names.
- Do not use `/` in branch names. Slash-separated names are messy with git worktrees and filesystem-derived worktree paths.
- Use only lowercase letters, digits, and hyphens when possible: `^[a-z0-9]+(-[a-z0-9]+)*$`.
- Prefer intent-oriented names based on the planned diff, for example `chore-branch-naming-conventions`, `fix-login-timeout`, or `feat-search-filter`.
- A Conventional Commit type prefix is optional but useful when obvious: `feat-`, `fix-`, `docs-`, `chore-`, etc.
- Do not include agent names, model names, `ai`, `wip`, timestamps, or implementation noise unless the repository explicitly asks for them.
- For stacked changes, let Git Town track parent/child relationships; do not encode stack hierarchy in the branch name.

## Pull Requests

- Before creating a pull request, check the repository's `CONTRIBUTING.md` and `README.md` for project-specific PR title guidance. Follow those guidelines if they conflict with these defaults.
- Otherwise, pull request titles must use Conventional Commits: `type(scope): summary`, `type: summary`, or `type!: summary`.
- Allowed PR title types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `deps`, `build`, `ci`, `perf`, `revert`.
- Scopes are optional but encouraged when they add useful context.
- Synthesize the PR title from the actual diff, not just the branch name or first commit.
- Make your best call on title type/scope without asking; the user can edit the PR later.
- Use `deps` for dependency and package additions, removals, or updates, including Nix package list changes and flake updates.
- Use `chore` for routine maintenance that is not dependency or package related unless another type is clearly more accurate.

## Reviews

- When asked to review, prioritize bugs, security issues, behavioral regressions, and missing tests.
- Lead with findings ordered by severity and include file and line references when possible.
- If there are no findings, say so explicitly and mention residual risks or testing gaps.

## Verification

- Run the most targeted formatter, test, build, or evaluation command that matches the change.
- If verification cannot be run, explain why and state what remains unverified.
