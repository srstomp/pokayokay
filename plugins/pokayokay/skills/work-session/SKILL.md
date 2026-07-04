---
name: work-session
description: Use when starting AI development sessions, resuming interrupted work, managing multi-session projects, or orchestrating work with human checkpoint control (supervised, semi-auto, auto, or unattended modes).
disable-model-invocation: true
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
- Evidence before completion claims (`verification-before-completion`)
- Root-cause-first bug handling (`systematic-debugging`)
- Explicit branch finish choice: merge, PR, keep, or discard (`finishing-branch`)
- Token-aware dispatch: stay inline for tiny work, use focused agents when isolation or parallelism is worth the cost

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
| [dispatch-preparation.md](references/dispatch-preparation.md) | Task extraction, brainstorm gate, design review gate, skill routing, template filling |
| [review-pipeline.md](references/review-pipeline.md) | Two-stage review: spec compliance then code quality (+ design compliance) |
| [dispatch-errors.md](references/dispatch-errors.md) | Recovery when ohno, routing, or dispatch fails |
| [checkpoint-types.md](references/checkpoint-types.md) | PAUSE, REVIEW, NOTIFY checkpoint patterns |
| [skill-routing.md](references/skill-routing.md) | Task type to skill mapping |
| [operating-modes.md](references/operating-modes.md) | Supervised, semi-auto, auto, unattended details |
| [worktree-management.md](references/worktree-management.md) | Setup, completion, merge/PR workflows |
| [parallel-execution.md](references/parallel-execution.md) | Parallel Execution: benefits, tradeoffs, dependency handling |
| [hook-integration.md](references/hook-integration.md) | Work loop with hooks, mode-specific behavior |
| [ohno-integration.md](references/ohno-integration.md) | MCP tools and CLI commands reference |
| [error-recovery.md](references/error-recovery.md) | Build failures, blocked tasks |
| [approval-policy.md](references/approval-policy.md) | Runtime approval defaults for safe pokayokay automation |
| [token-budgeting.md](references/token-budgeting.md) | Token/context budgeting rules for agents, skills, parallelism, and handoffs |
| [anti-patterns.md](references/anti-patterns.md) | Common mistakes and fixes |
| [bug-fix-pipeline.md](references/bug-fix-pipeline.md) | Agent pipeline for `/fix --thorough` and `/hotfix` commands |
| [pre-flight-checks.md](references/pre-flight-checks.md) | Checks run before unattended/headless sessions |

## Runtime Notes

- **Claude Code**: the coordinator dispatches `yokay-*` agents via the Task tool as described in [dispatch-preparation.md](references/dispatch-preparation.md).
- **Codex**: there is no subagent dispatch. Run the pipeline inline in the current session — for each stage, read the corresponding `agents/yokay-<name>.md` and follow its Behavioral Defaults, Critical Rules, and Output Contract. Execute stages (design review (conditional) → implement → spec review → quality review) as separate, sequential passes; do not skip review stages because dispatch is unavailable. Parallel batch execution ([parallel-execution.md](references/parallel-execution.md)) is Claude Code-only — process tasks sequentially on Codex.
