# Simulated Response: Resume Payments Epic in Auto Mode

This documents the step-by-step response Claude would produce when guided by the `work-session` skill, including all MCP tool calls and coordinator logic.

---

## Session Start

### Step 0: Load Configuration

Read `.claude/pokayokay.json` for headless and work settings.

### Step 0.5: Load Project Learnings

MEMORY.md is already in the system prompt. Additionally check topic files for relevance:
- `memory/recurring-failures.md` — review failure patterns to include as "Known Pitfalls" in implementer prompts
- `memory/spike-results.md` — closed spike investigations
- `memory/chain-learnings.md` — session chain progress history

### Step 1: Scope Validation

The user requested **auto** mode. Auto mode requires explicit scope to prevent runaway sessions. The user mentioned "the payments epic" but did not provide an explicit `--epic <id>`. The coordinator would need to identify the epic ID.

**Action**: Call ohno to find the payments epic.

```
MCP call: mcp__ohno__get_epics()
```

From the result, locate the epic with a title matching "payments" and extract its ID (e.g., `epic-payments-abc123`).

Since auto mode requires scope, the coordinator sets: `scope = { type: "epic", id: "epic-payments-abc123" }`.

### Step 1.5: Initialize Chain State

Since this is auto mode with scope and NOT a `--continue` session, write the chain state file:

```
Write .claude/pokayokay-chain-state.json:
{
  "chain_id": "chain-1741219200",
  "chain_index": 0,
  "scope_type": "epic",
  "scope_id": "epic-payments-abc123",
  "tasks_completed": 0,
  "adaptive_n": 2,
  "batches_completed": 0,
  "batches_failed": 0,
  "failed_tasks": [],
  "conflict_tasks": [],
  "last_session_summary": ""
}
```

### Step 2: Get Session Context

```
MCP call: mcp__ohno__get_session_context()
```

**Expected return**: Previous session notes indicating story-1 is complete and story-2 is partially done. In-progress tasks from yesterday's session. Blockers if any. The session context from ohno provides continuity across conversations -- this is the primary mechanism for understanding where the user left off.

**Coordinator announces**:

```markdown
## Session Start

**Mode**: auto
**Scope**: epic-payments-abc123 (Payments)
**Checkpoint behavior**: task complete → skip, story complete → log, epic complete → PAUSE

## Previous Session Context

(from get_session_context)
- Story 1: COMPLETE (all tasks done)
- Story 2: IN PROGRESS (3/6 tasks done, task-xyz in_progress)
- No active blockers
- Last session ended normally yesterday
```

### Step 3: Resume Check — Find In-Progress Tasks

The user said they were "half of story-2" done. The coordinator checks for in-progress tasks with WIP data.

```
MCP call: mcp__ohno__get_tasks(status="in_progress")
```

Filter results to only tasks within the payments epic scope. If a task is found with status `in_progress` (e.g., `task-xyz`), that is the resume candidate.

```
MCP call: mcp__ohno__get_task(task_id="task-xyz")
```

This returns the full task details including any `work_in_progress` data saved by the previous session.

```
MCP call: mcp__ohno__get_task_handoff(task_id="task-xyz")
```

This returns the implementer's previous handoff data (summary, files_changed, full_details with self-review findings), if available.

**Coordinator displays resume context**:

```markdown
## Resuming: Implement payment webhook handler (task-xyz)

**Phase**: implementation
**Last activity**: 2026-03-05T17:42:00Z
**Files modified**: src/webhooks/stripe.ts, src/webhooks/stripe.test.ts
**Last commit**: a1b2c3d
**Uncommitted changes**: Added error retry logic (not yet committed)

**Next step**: Add idempotency key validation and complete tests

**Decisions made**:
- Using Stripe webhook signature verification
- Retry with exponential backoff (max 3 attempts)

**Test results**: 4 passed, 2 failed (idempotency tests pending)
```

### Step 4: Worktree Decision

Check if there is an existing story worktree for story-2:

```bash
git worktree list --porcelain | grep "story-{story2-id}-"
```

If a story worktree exists from the previous session (e.g., `.worktrees/story-s2-payments-processing`), `cd` into it. Story tasks reuse the same worktree. If not found, create one following the worktree setup flow.

### Step 5: Dispatch Implementer for Resumed Task

Since this is a resume (WIP exists), the coordinator **skips brainstorming** and dispatches the implementer directly with WIP + handoff context appended.

**Skill routing**: Based on task type and keywords (payments, webhook, Stripe), route to `api-integration` or `api-design` skill.

**Dispatch**:

```
Task tool call:
  subagent_type: pokayokay:yokay-implementer
  mode: bypassPermissions
  prompt: [Filled implementer-prompt.md template with:]

    ## Task Information
    **Task ID**: task-xyz
    **Title**: Implement payment webhook handler
    **Description**: [full description from ohno]
    **Acceptance Criteria**: [from task]

    ## Context
    Story: Payments Processing (story-2)
    [story context, dependency context]

    ## Recommended Skill
    api-design (or api-integration)

    ## Resuming from Previous Session
    This task was partially completed. Here is the saved state:
    - Phase: implementation
    - Files already modified: src/webhooks/stripe.ts, src/webhooks/stripe.test.ts
    - Last commit: a1b2c3d
    - Uncommitted changes: Added error retry logic (not yet committed)
    - Decisions already made: Stripe webhook signature verification, exponential backoff
    - Test results: 4 passed, 2 failed
    - Next step: Add idempotency key validation and complete tests

    ## Previous Implementation Context
    - Status: in_progress
    - Summary: [from handoff]
    - Files changed: [from handoff]
    - Self-review findings: [from handoff]

    Pick up from where the previous session left off. Do NOT redo work
    that was already committed. Start from the "next step" above.
```

### Step 6: Process Implementer Result

When the implementer returns, the coordinator:

1. Receives the implementation report (files changed, commit hash, summary)
2. Validates against acceptance criteria

### Step 7: Two-Stage Review

**Stage 1: Spec Compliance Review**

```
Task tool call:
  subagent_type: pokayokay:yokay-spec-reviewer
  mode: bypassPermissions
  prompt: [Filled spec-review-prompt.md with task description,
           acceptance criteria, implementation summary, files changed,
           commit info]
```

- If FAIL: Re-dispatch implementer with spec issues. Loop up to 3 times.
- If PASS: Proceed to Stage 2.

**Stage 2: Code Quality Review**

```
Task tool call:
  subagent_type: pokayokay:yokay-quality-reviewer
  mode: bypassPermissions
  prompt: [Filled quality-review-prompt.md with task info,
           files changed, commit info]
```

- If FAIL: Re-dispatch implementer with quality issues.
- If PASS: Proceed to task completion.

### Step 8: Complete the Resumed Task

```
MCP call: mcp__ohno__update_task_status(task_id="task-xyz", status="done")
```

```
MCP call: mcp__ohno__add_task_activity(
  task_id="task-xyz",
  activity_type="note",
  description="Spec review: PASS. Quality review: PASS. Task completed."
)
```

Post-task hooks fire automatically: `sync.sh`, `commit.sh`, `detect-spike.sh`.

### Step 9: Auto Mode Checkpoint (Task Complete)

In **auto** mode, task completion is handled with **skip** -- no pause, no log. The coordinator proceeds immediately to the next task.

```markdown
Task task-xyz complete → skip checkpoint (auto mode) → next task
```

### Step 10: Continue Work Loop (Remaining Story-2 Tasks)

The coordinator now enters the standard work loop for the remaining tasks in story-2.

```
MCP call: mcp__ohno__get_next_task()
```

Filter result to only tasks within `epic-payments-abc123`. The next todo task in story-2 is returned (e.g., `task-abc`).

```
MCP call: mcp__ohno__update_task_status(task_id="task-abc", status="in_progress")
```

For each remaining task, the coordinator repeats:

1. **Get task details**: `mcp__ohno__get_task(task_id)`
2. **Brainstorm gate**: Evaluate if task needs brainstorming (check description length, acceptance criteria, ambiguous keywords)
3. **Skill routing**: Route based on task type/keywords
4. **Dispatch implementer**: Fill template, invoke Task tool with `yokay-implementer`
5. **Two-stage review**: Spec reviewer, then quality reviewer
6. **Complete task**: `mcp__ohno__update_task_status(task_id, "done")`
7. **Auto checkpoint**: Skip (task level), log (story level), PAUSE (epic level)

### Step 11: Story Boundary Detection

When the last task in story-2 completes, ohno returns boundary metadata indicating story completion.

In **auto** mode, story completion triggers **log and continue**:

```markdown
## Story Complete: Payments Processing (story-2)

Tasks completed: 6/6
All tests passing.

Logging and continuing to next story...
```

Post-boundary hooks fire: `test.sh`, `audit-gate.sh`.

```
MCP call: mcp__ohno__add_task_activity(
  task_id="last-task-in-story-2",
  activity_type="note",
  description="Story story-2 completed. All 6 tasks done."
)
```

### Step 12: Continue to Next Story in Epic

```
MCP call: mcp__ohno__get_next_task()
```

Filtered to the payments epic. If story-3 exists, the coordinator picks up its first task and continues the loop.

### Step 13: Worktree Handling at Story Boundary

When story-2 completes, the story worktree needs disposition. In auto mode, the coordinator merges to main automatically (no pause):

```bash
git checkout main && git merge --no-ff story-s2-payments-processing
git worktree remove .worktrees/story-s2-payments-processing
git branch -d story-s2-payments-processing
```

Then sets up a new worktree for story-3 if needed.

### Step 14: Epic Boundary (if reached)

If all stories in the payments epic are completed, auto mode triggers **PAUSE**:

```markdown
## CHECKPOINT: Epic Complete

**Epic**: Payments (epic-payments-abc123)
**Stories completed**: 3/3
**Total tasks**: 18/18

### Summary
Implemented full payment processing pipeline including webhook handlers,
refund logic, and subscription management.

### Your Options

1. **Continue** → Proceed to next epic
2. **Review** → I'll wait while you check the code
3. **End** → Stop session here

What would you like to do?
```

### Context Pressure Handling

Throughout the session, the coordinator monitors for context pressure. If compaction is detected:

1. Stop dispatching new tasks
2. Wait for in-flight agents to finish
3. Save WIP for any incomplete work via `mcp__ohno__update_task_wip()`
4. Update chain state file with current progress
5. End session gracefully -- SessionEnd hook spawns continuation via `session-chain.sh`

---

## Summary of MCP Calls (in order)

| # | Call | Purpose |
|---|------|---------|
| 1 | `get_epics()` | Find payments epic ID |
| 2 | `get_session_context()` | Previous session state, blockers, WIP |
| 3 | `get_tasks(status="in_progress")` | Find resumable tasks |
| 4 | `get_task(task_id)` | Full details of in-progress task |
| 5 | `get_task_handoff(task_id)` | Previous implementer's handoff data |
| 6 | `update_task_status(task_id, "done")` | Complete resumed task (after review passes) |
| 7 | `add_task_activity(task_id, ...)` | Log review results |
| 8 | `get_next_task()` | Get next task in epic scope |
| 9 | `update_task_status(task_id, "in_progress")` | Start next task |
| 10+ | Repeat 8-9 for each remaining task | Work loop continues |

## Subagent Dispatches (per task)

| Agent | Purpose | Conditional |
|-------|---------|-------------|
| `yokay-brainstormer` | Refine ambiguous tasks | Only if description < 100 chars, no AC, or ambiguous keywords |
| `yokay-implementer` | Implement the task (TDD) | Always |
| `yokay-spec-reviewer` | Adversarial spec compliance check | Always (full pipeline) |
| `yokay-quality-reviewer` | Code quality review | Only if spec review passes |
| `yokay-fixer` | Auto-retry on test failures | Only if implementer's tests fail |
