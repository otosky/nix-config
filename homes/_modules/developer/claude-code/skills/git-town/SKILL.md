---
name: git-town
description: Git Town workflow commands for branching, syncing, and shipping changes. Use when creating branches, syncing with upstream, creating PRs, or managing stacked changes.
---

## Git Town Workflow

When git-town is available, ALWAYS prefer git-town commands over raw git for
branch and sync operations.

### Detection

Before using git-town commands, verify it's installed by running `git town version`.
If not installed, fall back to raw git commands.

### Command Mapping

| Instead of                  | Use                     |
| --------------------------- | ----------------------- |
| `git checkout -b feature`   | `git town hack feature` |
| `git pull && git rebase main` | `git town sync`       |
| `gh pr create`              | `git town propose`      |

### Shipping Work

DO NOT use `git town ship` - PRs are always merged through the remote VCS.

Workflow:

1. `git town propose` - create the PR
2. Merge via the web UI (GitHub, GitLab, etc.)
3. `git town sync` - detects merged branches, cleans up

---

## Stacked Changes (Dependent PRs)

Use stacking when changes depend on each other.

### Creating Stacks

- `git town append <name>` - new branch as CHILD of current
- `git town prepend <name>` - new branch as PARENT of current

### Navigating Stacks

- `git town up` - move to child branch
- `git town down` - move to parent branch
- `git town branch` - visualize the stack hierarchy

### Stack Operations (always use -s flag)

When working in a stack, ALWAYS use the `-s` flag:

| Command                | What it does                         |
| ---------------------- | ------------------------------------ |
| `git town sync -s`     | Sync all branches in the stack       |
| `git town propose -s`  | Create PRs for entire stack          |
| `git town compress -s` | Squash commits on all stack branches |

### Managing Stacks

- `git town merge` - merge current branch into its parent
- `git town detach` - remove branch from stack
- `git town swap` - swap position with parent branch
- `git town set-parent` - reassign parent branch

### Shipping Stacks

1. `git town propose -s` to create PRs for entire stack
2. Merge PRs via remote VCS (bottom-up)
3. `git town sync -s` to clean up

---

## Branch Types

| Command                        | Sync behavior                           |
| ------------------------------ | --------------------------------------- |
| `git town feature <branch>`    | Normal - syncs with parent              |
| `git town prototype <branch>`  | Like feature, but won't push to remote  |
| `git town contribute <branch>` | Syncs with remote only, not parent      |
| `git town observe <branch>`    | Pull-only, won't push changes           |
| `git town park <branch>`       | Excluded from sync entirely             |

### View Configuration

- `git town branch` - show branch hierarchy and types
- `git town config` - show full configuration

---

## Error Recovery

When a command encounters conflicts:

1. Resolve conflicts manually
2. Stage resolved files: `git add <files>`
3. Resume: `git town continue`

Other recovery commands:

- `git town skip` - skip current branch in multi-branch operations
- `git town status` - check status of paused operation
- `git town runlog` - view what happened in previous commands

---

## Destructive Commands - ALWAYS ASK FIRST

NEVER run these without explicit user confirmation:

| Command             | Why ask                                |
| ------------------- | -------------------------------------- |
| `git town undo`     | Can discard work from previous command |
| `git town delete`   | Permanently removes a branch           |
| `git town compress` | Squashes commits, rewrites history     |

Always explain what the command will do and wait for confirmation.
