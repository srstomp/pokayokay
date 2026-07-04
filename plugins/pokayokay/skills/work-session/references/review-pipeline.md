# Two-Stage Review Pipeline

After the implementer completes, run two sequential reviews: spec compliance (adversarial), then code quality with design compliance.

> **Runtime note:** On Codex there is no subagent dispatch — run each review
> inline by reading the agent's `agents/yokay-<name>.md` and following its
> Output Contract. Never skip review stages because dispatch is unavailable.

Fill EVERY placeholder in both templates — never dispatch a prompt containing literal `{PLACEHOLDER}` text.

## Stage 1: Spec Compliance Review

**Agent**: `yokay-spec-reviewer` | **Template**: `agents/templates/spec-review-prompt.md`

| Variable | Source |
|----------|--------|
| `{TASK_ID}` | Original task |
| `{TASK_TITLE}` | Original task |
| `{TASK_DESCRIPTION}` | Original task (post-brainstorm) |
| `{ACCEPTANCE_CRITERIA}` | Original task (post-brainstorm) |
| `{IMPLEMENTATION_SUMMARY}` | Implementer's ohno handoff via `get_task_handoff(task_id)` — the inline report is minimal |
| `{FILES_CHANGED}` | Implementer handoff / `git diff --name-only` |
| `{COMMIT_INFO}` | Implementer's commit (hash + message) |
| `{COMMIT_HASH}` | Bare commit hash — used in the templates' `git diff` verification commands |
| `{WORKING_DIRECTORY}` | Task's worktree path or project root |

- **FAIL**: Re-dispatch implementer with spec issues. Skip quality review.
- **PASS**: Proceed to Stage 2.

## Stage 2: Code Quality Review

Only runs if spec review passes.

**Agent**: `yokay-quality-reviewer` | **Template**: `agents/templates/quality-review-prompt.md`

| Variable | Source |
|----------|--------|
| `{TASK_ID}` | Original task |
| `{TASK_TITLE}` | Original task |
| `{FILES_CHANGED}` | Implementer handoff / `git diff --name-only` |
| `{COMMIT_INFO}` | Implementer's commit (hash + message) |
| `{COMMIT_HASH}` | Bare commit hash |
| `{APPROACH}` | Design review output (stored at the design review gate), or `None — design review was skipped` |
| `{WORKING_DIRECTORY}` | Task's worktree path or project root |

The quality reviewer uses `{APPROACH}` for its design-compliance post-check;
when it is `None`, the reviewer marks design compliance `N/A` (this covers
`/fix` and `/hotfix`, which deliberately run no design review).

- **FAIL**: Re-dispatch implementer with quality issues.
- **PASS**: Proceed to task completion.

## Review Flow

```
IMPLEMENT ──► SPEC REVIEW ──FAIL──► RE-IMPLEMENT (with spec issues)
                  │                       │
                 PASS                     │
                  │                       │
                  ▼                       │
             QUALITY REVIEW ◄─────────────┘
                  │
                  │──FAIL──► RE-IMPLEMENT (with quality issues)
                  │
                 PASS
                  │
                  ▼
             COMPLETE TASK
```

`NEEDS_REDESIGN` from the implementer is NOT a review failure — handle it via
the redesign cycle in [dispatch-preparation.md](dispatch-preparation.md).

## Review Loop Control

Maximum review cycles: 3

After 3 failed review cycles:
1. Log escalation to ohno via `add_task_activity`
2. Block task with `set_blocker`
3. PAUSE for human intervention

## ohno Activity Logging

Log review results after each stage:
- `add_task_activity(task_id, "note", "Spec review: PASS")`
- `add_task_activity(task_id, "note", "Quality review: PASS")`
- `add_task_activity(task_id, "note", "Spec review: FAIL - [issues]")`
