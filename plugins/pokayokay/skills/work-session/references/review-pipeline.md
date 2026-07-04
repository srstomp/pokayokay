# Two-Stage Review Pipeline

After the implementer completes, run two sequential reviews: spec compliance (adversarial), then code quality with design compliance.

> **Runtime note:** On Codex there is no subagent dispatch — run each review
> inline by reading the agent's `agents/yokay-<name>.md` and following its
> Output Contract. Never skip review stages because dispatch is unavailable.

Fill EVERY placeholder in both templates — never dispatch a prompt containing literal `{PLACEHOLDER}` text.

## Stage 1: Spec Compliance Review

**Agent**: `pokayokay:yokay-spec-reviewer` | **Template**: `agents/templates/spec-review-prompt.md`

| Variable | Source |
|----------|--------|
| `{TASK_ID}` | Original task |
| `{TASK_TITLE}` | Original task |
| `{TASK_DESCRIPTION}` | Original task (post-brainstorm) |
| `{ACCEPTANCE_CRITERIA}` | Original task (post-brainstorm) |
| `{IMPLEMENTATION_SUMMARY}` | Implementer's ohno handoff via `get_task_handoff(task_id)` — the inline report is minimal |
| `{FILES_CHANGED}` | Implementer handoff / `git diff --name-only` |
| `{COMMIT_INFO}` | Implementer's commit (hash + message) |
| `{BASE_COMMIT}` | Recorded by coordinator at implementer dispatch (work.md Step 4); primary diff baseline, includes working tree |
| `{WORKING_DIRECTORY}` | Task's worktree path or project root |

The coordinator branches on the reviewer's final `VERDICT:` line (`VERDICT: PASS | FAIL | BLOCKED`), not on prose or evidence rows:

- **VERDICT: FAIL**: Re-dispatch implementer with spec issues. Skip quality review.
- **VERDICT: PASS**: Proceed to Stage 2.
- **VERDICT: BLOCKED**: Reviewer could not review (missing input). Does not consume a review cycle; fix the named input, re-dispatch the reviewer once, then `set_blocker` if still BLOCKED.

## Stage 2: Code Quality Review

Only runs if spec review passes.

**Agent**: `pokayokay:yokay-quality-reviewer` | **Template**: `agents/templates/quality-review-prompt.md`

| Variable | Source |
|----------|--------|
| `{TASK_ID}` | Original task |
| `{TASK_TITLE}` | Original task |
| `{ACCEPTANCE_CRITERIA}` | Original task (post-brainstorm) — input for the Test-AC Mapping check |
| `{FILES_CHANGED}` | Implementer handoff / `git diff --name-only` |
| `{COMMIT_INFO}` | Implementer's commit (hash + message) |
| `{BASE_COMMIT}` | Recorded by coordinator at implementer dispatch (work.md Step 4); primary diff baseline, includes working tree |
| `{APPROACH}` | Design review output (stored at the design review gate), or `None — design review was skipped` |
| `{WORKING_DIRECTORY}` | Task's worktree path or project root |

The quality reviewer uses `{APPROACH}` for its design-compliance post-check;
when it is `None`, the reviewer marks design compliance `N/A` (this covers
`/fix` and `/hotfix`, which deliberately run no design review).

Branch on the final `VERDICT:` line here too:

- **VERDICT: FAIL**: Re-dispatch implementer with quality issues.
- **VERDICT: PASS**: Proceed to task completion.
- **VERDICT: BLOCKED**: Same handling as Stage 1 — no review cycle consumed; fix input, re-dispatch reviewer once, then `set_blocker`.

## Review Flow

Each review returns a terminal `VERDICT: PASS | FAIL | BLOCKED` line; the coordinator branches on it.

```
IMPLEMENT ──► SPEC REVIEW ──VERDICT: FAIL──► RE-IMPLEMENT (with spec issues)
                  │      └──VERDICT: BLOCKED──► fix input, re-review once
                  │
          VERDICT: PASS                   │
                  │                       │
                  ▼                       │
             QUALITY REVIEW ◄─────────────┘
                  │
                  │──VERDICT: FAIL──► RE-IMPLEMENT (with quality issues)
                  │──VERDICT: BLOCKED──► fix input, re-review once
                  │
          VERDICT: PASS
                  │
                  ▼
             COMPLETE TASK
```

`NEEDS_REDESIGN` from the implementer is NOT a review failure — handle it via
the redesign cycle in [dispatch-preparation.md](dispatch-preparation.md).

## Review Loop Control

Maximum review cycles: 3. BLOCKED verdicts do not count against the cycle budget.

After 3 failed review cycles, escalate per mode:

- **supervised / semi-auto**: Log escalation via `add_task_activity`, block the task with `set_blocker`, and PAUSE — present the review history and options to the human. Also pause when a reviewer returns BLOCKED twice for the same task.
- **auto / unattended**: Do NOT pause. Call `mcp__ohno__set_needs_rework(task_id, reason)` (or `set_blocker` when rework does not apply), log via `add_task_activity`, and continue to the next task.

**Hard rule**: A task whose review did not end in PASS is NEVER marked done.

## ohno Activity Logging

Log review results after each stage:
- `add_task_activity(task_id, "note", "Spec review: PASS")`
- `add_task_activity(task_id, "note", "Quality review: PASS")`
- `add_task_activity(task_id, "note", "Spec review: FAIL - [issues]")`
