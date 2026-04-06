---
name: worktrees
description: "Creates, lists, switches, removes, and cleans up git worktrees for isolated parallel development. Use when the user asks about git worktrees, working on multiple branches simultaneously, isolating task work, managing parallel workspaces, or cleaning up stale worktrees."
---

# Worktrees

Guide for managing git worktrees in pokayokay.

## When Worktrees Are Created

| Task Type | Default | Override |
|-----------|---------|----------|
| feature | Worktree | --in-place |
| bug | Worktree | --in-place |
| spike | Worktree | --in-place |
| chore | In-place | --worktree |
| docs | In-place | --worktree |
| test | Inherits | explicit flag |

## Key Principles

- **Story-based reuse** — Tasks in the same story share a worktree for related changes
- **Auto dependency install** — Dependencies install automatically on worktree creation
- **Clean completion** — Choose merge, PR, keep, or discard when done
- **Isolation** — All worktrees live in `.worktrees/` (auto-ignored by git)

## Quick Start Checklist

1. **Create** a worktree for the task:
   ```bash
   git worktree add .worktrees/<branch-name> -b <branch-name>
   ```
2. **Verify** creation succeeded:
   ```bash
   git worktree list
   ```
3. Dependencies auto-install based on detected lockfiles (npm, yarn, pnpm).
4. Story worktrees are reused — check for an existing worktree before creating a new one.
5. **On completion**, choose an action:
   - Merge: `git merge <branch-name>` from main branch
   - PR: push branch and open pull request
   - Discard: `git worktree remove .worktrees/<branch-name>`
6. **Validate clean state** before merging: confirm no uncommitted changes in the worktree.

## References

| Reference | Description |
|-----------|-------------|
| [worktree-management.md](references/worktree-management.md) | Lifecycle, completion options, dependency install, troubleshooting |
| [cleanup-strategies.md](references/cleanup-strategies.md) | Cleanup criteria, detection, disk management, scheduled cleanup |
| [parallel-worktrees.md](references/parallel-worktrees.md) | Parallel execution worktree isolation, conflict prevention |
