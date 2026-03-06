## Session Configuration

**Mode**: unattended (no human checkpoints)
**Parallel**: 3 (fixed)
**Scope**: Need the epic ID for the notifications epic

Before I can launch this, I need the epic ID. Let me look it up.

**MCP Call**: `get_epics()` to find the notifications epic and retrieve its ID.

Assuming the result returns something like `epic-notif-abc123` for the notifications epic, here is the full plan:

---

## Pre-Flight Checks (Automatic)

When unattended mode starts, `bridge.py` triggers `pre-flight.sh` automatically at SessionStart. These checks run before any work begins to prevent a wasted overnight session:

| Check | Level | What It Validates |
|-------|-------|-------------------|
| Git clean | Blocking | No uncommitted changes in working tree |
| ohno responsive | Blocking | MCP server can list tasks |
| Tasks available | Blocking | Ready task count > 0 within the notifications epic |
| Disk space | Warning | >1GB free disk space |
| Worktree locks | Warning | No stale `.lock` files in `.worktrees/` |
| Chain state | Blocking | `.claude/pokayokay-chain-state.json` is valid JSON (if it exists) |

**If any blocking check fails**, the session reports all issues and stops immediately -- you would see the failure in your terminal in the morning. No work is wasted.

**If only warnings**, they are logged and the session continues.

---

## Command to Run

```bash
claude --headless --dangerously-skip-permissions --prompt="/pokayokay:work unattended -n 3 --epic <epic-id>"
```

Breaking this down:

- `--headless`: No interactive terminal needed (overnight)
- `--dangerously-skip-permissions`: Bypass Bash/Edit/Write approval prompts (required since no human is present to approve)
- `unattended`: Never pauses at task, story, or epic boundaries
- `-n 3`: Run 3 implementer agents in parallel (fixed count, not adaptive)
- `--epic <epic-id>`: Scope the session to only tasks within the notifications epic (prevents runaway work on unrelated tasks)

---

## What Happens Overnight (Step by Step)

### 1. Session Initialization

- Read `.claude/pokayokay.json` for headless config (max chains, reporting)
- Call `get_session_context()` via MCP to pick up any prior session state
- Pre-flight checks execute (see above)
- Set `YOKAY_WORK_MODE=unattended` for hooks

### 2. Work Loop (Repeats Until No Tasks Remain)

For each iteration:

**a. Fetch batch of tasks**

MCP call: `get_next_batch()` filtered to epic scope, returns up to 3 tasks with unmet dependencies excluded.

**b. Worktree decision (per task)**

Each task gets evaluated independently:
- `feature`, `bug`, `spike` tasks get isolated git worktrees in `.worktrees/`
- `chore`, `docs` tasks work in-place
- Tasks within the same story reuse an existing story worktree

**c. Parallel dispatch**

3 `yokay-implementer` agents are dispatched simultaneously via the Task tool, each with:
- Fresh context (no degradation from prior tasks)
- Filled implementer prompt template with task description, acceptance criteria, story context, handoff notes
- Skill routing based on task type and keywords
- `permissionMode: bypassPermissions` on the agent definition

Each implementer follows TDD: write tests, implement, verify tests pass, commit.

**d. Wait for all 3 agents to complete**

**e. Two-stage review (sequential, per task)**

For each completed task:
1. **Spec review** (`yokay-spec-reviewer`): Adversarial check that implementation matches acceptance criteria
2. **Quality review** (`yokay-quality-reviewer`): Code quality standards check (only runs if spec review passes)

If either review fails, the implementer is re-dispatched with the specific issues. Maximum 3 review cycles per task before it gets blocked and the loop moves on.

**f. Post-task hooks fire automatically**

- `sync.sh`: Sync task state to ohno
- `commit.sh`: Ensure git commit with proper message
- `detect-spike.sh`: Check for scope creep

If a story completes (all its tasks done): `test.sh` and `audit-gate.sh` also run.
If the epic completes: `audit-gate.sh` runs.

**g. Checkpoint behavior (unattended)**

All checkpoints are skipped:
- Task complete: skip
- Story complete: skip
- Epic complete: skip

No pauses. Work continues to next batch immediately.

### 3. Dependency Handling

The ohno `blockedBy` graph prevents unsafe parallelism:
- If Task B depends on Task A, B will not appear in a batch until A is marked done
- Only independent tasks are dispatched concurrently
- No additional conflict detection needed beyond the dependency graph

### 4. Session Chaining

When context pressure is detected (conversation compaction, system reminders about limits):

1. Stop dispatching new tasks
2. Wait for in-flight agents to finish
3. Save WIP for any incomplete work via `update_task_wip()`
4. Write coordinator state to `.claude/pokayokay-chain-state.json`:
   - Current parallel count (stays at 3 since fixed, not adaptive)
   - Batches completed/failed counts
   - Failed/blocked task IDs
5. SessionEnd hook fires, `session-chain.sh` spawns the next session:
   ```bash
   claude --headless --dangerously-skip-permissions --prompt="/pokayokay:work --continue --epic <epic-id>"
   ```
6. The new session picks up where the previous one left off, up to `max_chains` (default 10)

### 5. Session End

When all tasks in the notifications epic are complete (or max chains reached):

- Final sync to ohno
- `session-summary` hook runs with token cost tracking
- Chain report generated at `.ohno/reports/chain-{id}-report.md` containing:
  - Total sessions in chain
  - Tasks completed, failed, remaining
  - Total duration
  - Key decisions extracted from task handoffs

---

## What You Will See in the Morning

1. **Terminal output** with the chain completion notification
2. **Chain report** at `.ohno/reports/chain-{id}-report.md` summarizing the entire overnight run
3. **Git history** with individual commits per task (proper messages, task IDs)
4. **ohno task states** showing which tasks completed, which (if any) are blocked with reasons
5. **Review activity logs** in ohno for each task showing spec review and quality review pass/fail results

### If Something Went Wrong

- Failed tasks are marked `blocked` in ohno with the failure reason
- Pre-flight failures stop the session before any work begins (clean failure)
- Build failures during a task trigger the `yokay-fixer` agent for auto-retry
- After 3 failed review cycles on a single task, it gets blocked and the loop moves to the next task

---

## Before You Walk Away

I need one thing from you: **the notifications epic ID**. Run:

```
/pokayokay:work unattended -n 3 --epic <paste-epic-id-here>
```

Or if you want me to look it up now, I can call `get_epics()` to find it.

Once you confirm the epic ID and launch the command, the pre-flight checks will validate everything is clean, and the session will run autonomously through the night.
