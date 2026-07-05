# Kaizen Review-Failure Handling

How the coordinator acts on the post-review-fail hook's kaizen outcome after a
spec or quality review fails. `/work` (work.md "Review Failure Hook
Integration") summarizes this flow and points here.

## Hook Invocation (Automatic)

When either spec or quality review fails, `bridge.py` detects the FAIL in the
reviewer's Task output (PostToolUse) and invokes the post-review-fail hook
**automatically**. Do NOT run `hooks/post-review-fail.sh` yourself — manual
invocation risks double execution (duplicate kaizen fix-task suggestions),
and in consuming projects the script may not exist at all.

The bridge resolves the hook from the *project's* `hooks/post-review-fail.sh`
(so projects can supply their own kaizen wiring). When the script is absent,
the failure is still tracked locally (recurring-failure detection +
graduate-rules) and the outcome is `kaizen_action: LOGGED`.

The hook result surfaces as hook output context after the reviewer's Task
call, with a `kaizen_action` of AUTO, SUGGEST, or LOGGED (plus `fix_task`
details when available). The coordinator's only job is to act on that
outcome.

## 1. AUTO Action (High Confidence)

Hook detects a well-known failure pattern and auto-creates a fix task.

```json
{
  "action": "AUTO",
  "fix_task": {
    "title": "Fix: Missing error handling in API endpoint",
    "description": "Review failed due to missing error handling...",
    "type": "bug",
    "estimate": 2
  }
}
```

Coordinator behavior:
1. Create fix task in ohno:
   ```bash
   npx @stevestomp/ohno-cli create "${fix_task.title}" \
     -t ${fix_task.type} \
     --description "${fix_task.description}" \
     -e ${fix_task.estimate} \
     --source "kaizen-fix"
   ```
2. Block current task on the fix task:
   ```bash
   npx @stevestomp/ohno-cli dep add <current-task-id> <fix-task-id>
   npx @stevestomp/ohno-cli block <current-task-id> "Blocked by fix task ${fix_task_id}"
   ```
3. Log activity:
   ```bash
   add_task_activity(task_id, "note", "Review failed, fix task auto-created: ${fix_task_id}")
   ```
4. Get next task and continue work loop

## 2. SUGGEST Action (Medium Confidence)

Hook has a suggestion but needs user confirmation.

```json
{
  "action": "SUGGEST",
  "fix_task": {
    "title": "Fix: Improve test coverage for edge cases",
    "description": "Review suggests adding tests for...",
    "type": "test",
    "estimate": 3
  },
  "confidence": "medium"
}
```

Coordinator behavior (mode-aware, mirroring the NEEDS_DISCUSSION split in the
Design Review Gate, work.md Step 3.7):

**supervised / semi-auto:**
1. Present suggestion to user:
   ```markdown
   Review failed. Suggested fix task:
   - Title: ${fix_task.title}
   - Type: ${fix_task.type}
   - Estimate: ${fix_task.estimate}h
   - Description: ${fix_task.description}

   Create fix task? (yes/no/customize)
   ```
2. Handle user response:
   - **yes**: Create fix task, block current task, get next task
   - **no**: Continue with existing re-dispatch behavior (max 3 cycles)
   - **customize**: Let user modify fix_task details, then create

**auto / unattended:**

Do NOT prompt. Log the suggestion and auto-resolve:
1. Log: `add_task_activity(task_id, "note", "Review-fail SUGGEST auto-resolved (auto/unattended): ${fix_task.title}")`
2. If review cycles remain (<3 used): continue with the existing re-dispatch behavior (the "no" path)
3. If this failure consumed the final review cycle: create the suggested fix task, block the current task on it, and get the next task (the "yes" path) — the suggestion is not lost

## 3. LOGGED Action (Low Confidence)

Hook cannot confidently suggest a fix task, only logs the failure.

```json
{
  "action": "LOGGED",
  "message": "Failure logged to kaizen database"
}
```

Coordinator behavior:
1. Log activity:
   ```bash
   add_task_activity(task_id, "note", "Review failed: ${FAILURE_DETAILS}")
   ```
2. Continue with existing re-dispatch behavior (max 3 cycles)

## Hook Integration Flow

```
Review FAIL
     │
     ▼
┌─────────────────┐
│ bridge.py runs  │
│ post-review-fail│
│ (automatic)     │
└────────┬────────┘
         │
         ▼
 Read kaizen_action
 from hook output
         │
    ┌────┴─────┬─────────────┐
    │          │             │
    ▼          ▼             ▼
┌──────┐  ┌─────────┐  ┌──────────┐
│ AUTO │  │ SUGGEST │  │ LOGGED   │
└───┬──┘  └────┬────┘  └─────┬────┘
    │          │              │
    ▼          ▼              │
┌──────────┐  ┌──────────┐   │
│ Create   │  │ Prompt   │   │
│ fix task │  │ user     │   │
└─────┬────┘  └────┬─────┘   │
      │            │         │
      │       ┌────┴─────┐   │
      │       │          │   │
      │      yes        no   │
      │       │          │   │
      ▼       ▼          ▼   ▼
┌─────────────────────────────┐
│ Block current task          │
│ Get next task               │
└─────────────────────────────┘
                  OR
┌─────────────────────────────┐
│ Re-dispatch implementer     │
│ (existing behavior)         │
└─────────────────────────────┘
```
