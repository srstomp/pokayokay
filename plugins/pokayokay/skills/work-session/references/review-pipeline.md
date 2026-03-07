# Two-Stage Review Pipeline

After implementer completes, run two sequential reviews: spec compliance (adversarial), then code quality.

## Stage 1: Spec Compliance Review

**Agent**: `yokay-spec-reviewer` | **Template**: `agents/templates/spec-review-prompt.md`

| Variable | Source |
|----------|--------|
| `{TASK_ID}` | Original task |
| `{TASK_TITLE}` | Original task |
| `{TASK_DESCRIPTION}` | Original task |
| `{ACCEPTANCE_CRITERIA}` | Original task |
| `{IMPLEMENTATION_SUMMARY}` | Implementer report |
| `{FILES_CHANGED}` | Implementer report |
| `{COMMIT_INFO}` | Implementer report |
| `{COMMIT_HASH}` | Implementer report |
| `{WORKING_DIRECTORY}` | Coordinator |

- **FAIL**: Re-dispatch implementer with spec issues. Skip quality review.
- **PASS**: Proceed to Stage 2.

## Stage 2: Code Quality Review

Only runs if spec review passes.

**Agent**: `yokay-quality-reviewer` | **Template**: `agents/templates/quality-review-prompt.md`

| Variable | Source |
|----------|--------|
| `{TASK_ID}` | Original task |
| `{TASK_TITLE}` | Original task |
| `{FILES_CHANGED}` | Implementer report |
| `{COMMIT_INFO}` | Implementer report |
| `{COMMIT_HASH}` | Implementer report |
| `{WORKING_DIRECTORY}` | Coordinator |

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
