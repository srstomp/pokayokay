---
name: project-harness
description: Orchestrates long-running AI development sessions with human checkpoint control. Uses ohno for task management, manages progress tracking, routes work to appropriate skills, and implements supervised/semi-auto/auto/unattended modes. Use this skill when starting work sessions, resuming interrupted work, or managing multi-session projects.
---

# Project Harness

Orchestrate AI-assisted development with configurable human control, using ohno for task management via MCP.

## Key Principles

- Fresh context per task via subagent dispatch (no context degradation)
- Configurable checkpoint control: supervised, semi-auto, auto, or unattended
- Smart worktree isolation by task type (feature/bug → worktree, chore/docs → in-place)
- Hooks handle lifecycle automatically (sync, commit, tests)
- ohno MCP provides session continuity across conversations

## Quick Start Checklist

1. Initialize ohno: `npx @stevestomp/ohno-cli init`
2. Get session context: MCP `get_session_context()`
3. Get next task: MCP `get_next_task()`
4. Dispatch subagent for implementation
5. Review results at checkpoints (based on mode)

## Operating Modes

| Mode | Task Complete | Story Complete | Epic Complete |
|------|--------------|----------------|---------------|
| supervised | PAUSE | PAUSE | PAUSE |
| semi-auto | log | PAUSE | PAUSE |
| auto | skip | log | PAUSE |
| unattended | skip | skip | skip |

## References

| Reference | Description |
|-----------|-------------|
| [subagent-dispatch.md](references/subagent-dispatch.md) | Coordinator vs implementer roles, dispatch mechanics |
| [session-protocol.md](references/session-protocol.md) | Session start/end checklists, MCP workflow |
| [checkpoint-types.md](references/checkpoint-types.md) | PAUSE, REVIEW, NOTIFY checkpoint patterns |
| [skill-routing.md](references/skill-routing.md) | Task type to skill mapping |
| [operating-modes.md](references/operating-modes.md) | Supervised, semi-auto, auto, unattended details |
| [worktree-management.md](references/worktree-management.md) | Setup, completion, merge/PR workflows |
| [parallel-execution.md](references/parallel-execution.md) | Benefits, tradeoffs, dependency handling |
| [hook-integration.md](references/hook-integration.md) | Work loop with hooks, mode-specific behavior |
| [ohno-integration.md](references/ohno-integration.md) | MCP tools and CLI commands reference |
| [error-recovery.md](references/error-recovery.md) | Build failures, blocked tasks |
| [anti-patterns.md](references/anti-patterns.md) | Common mistakes and fixes |
