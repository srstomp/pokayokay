---
name: work-session
agents: [yokay-brainstormer, yokay-implementer, yokay-fixer, yokay-spec-reviewer, yokay-quality-reviewer, yokay-browser-verifier, yokay-test-runner]
description: "Fetches tasks from ohno, dispatches specialized subagents for implementation with TDD, runs two-stage code review, and manages checkpoints at task/story/epic boundaries. Use when starting a work session, continuing where you left off, picking up the next task, running in supervised or auto mode, or orchestrating multi-task development."
---

# Work Session

Orchestrate AI-assisted development with configurable human control, using ohno for task management via MCP.

## When NOT to Use

- **Planning work** — Use `planning` to create epics/stories/tasks before starting sessions
- **Quick one-off tasks** — Use `/quick` for simple tasks that don't need the full subagent pipeline
- **Revising a plan** — Use `plan-revision` to modify scope, dependencies, or task hierarchy
- **Running a spike** — Use `spike` for time-boxed investigation before committing to implementation

## Key Principles

- Fresh context per task via subagent dispatch (no context degradation)
- Configurable checkpoint control: supervised, semi-auto, auto, or unattended
- Smart worktree isolation by task type (feature/bug → worktree, chore/docs → in-place)
- Hooks handle lifecycle automatically (sync, commit, tests)
- ohno MCP provides session continuity across conversations

## Quick Start Checklist

1. Initialize ohno (if not already): `npx @stevestomp/ohno-cli init`
2. Get session context: MCP `get_session_context()` — loads prior WIP, completed tasks, and active blockers.
3. Get next task: MCP `get_next_task()` — returns the highest-priority unblocked task.
4. Dispatch subagent for implementation:
   - If task is ambiguous → dispatch `yokay-brainstormer` first for requirements clarification.
   - Otherwise → dispatch `yokay-implementer` with task details and skill routing from [skill-routing.md](references/skill-routing.md).
5. Review results at checkpoints (based on mode — see Operating Modes table).
6. **On failure**: if subagent fails or tests break, dispatch `yokay-fixer` for targeted retry. If task is blocked, call MCP `update_task_status({status: 'blocked'})` and move to the next task. See [error-recovery.md](references/error-recovery.md) for details.

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
| [parallel-execution.md](references/parallel-execution.md) | Parallel Execution: benefits, tradeoffs, dependency handling |
| [hook-integration.md](references/hook-integration.md) | Work loop with hooks, mode-specific behavior |
| [ohno-integration.md](references/ohno-integration.md) | MCP tools and CLI commands reference |
| [error-recovery.md](references/error-recovery.md) | Build failures, blocked tasks |
| [anti-patterns.md](references/anti-patterns.md) | Common mistakes and fixes |
| [bug-fix-pipeline.md](references/bug-fix-pipeline.md) | Agent pipeline for `/fix --thorough` and `/hotfix` commands |
| [pre-flight-checks.md](references/pre-flight-checks.md) | Checks run before unattended/headless sessions |
