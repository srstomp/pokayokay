---
name: worktrees
description: Use when managing isolated git worktrees for task development. Handles worktree creation by task type, story-based reuse, dependency installation, and cleanup. Integrated into /work workflow.
disable-model-invocation: true
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

1. Task type determines worktree vs in-place (see table above)
2. Story worktrees are reused across related tasks
3. Dependencies auto-install based on detected lockfiles
4. On completion: merge to main, create PR, keep, or discard
5. Troubleshoot with `git worktree list` if issues arise

## When NOT to Use

- **Starting a work session** — Use `work-session`; worktree creation happens automatically during `/work`
- **Using git worktrees outside pokayokay** — This skill is pokayokay-specific; for general git worktrees use git directly

## References

| Reference | Description |
|-----------|-------------|
| [worktree-management.md](references/worktree-management.md) | Lifecycle, completion options, dependency install, troubleshooting |
| [cleanup-strategies.md](references/cleanup-strategies.md) | Cleanup criteria, detection, disk management, scheduled cleanup |
| [parallel-worktrees.md](references/parallel-worktrees.md) | Parallel execution worktree isolation, conflict prevention |
