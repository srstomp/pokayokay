# Chain State & Headless Sessions

Single source for headless configuration, the chain state file contract,
proactive context shutdown, and the chain completion audit. `/work` (work.md)
summarizes each of these and points here.

## Headless Configuration

Headless mode enables automatic session chaining when context fills up.

### Configuration

Read headless config from `.pokayokay/config.json` when present, falling back to `.claude/pokayokay.json` for existing Claude Code projects:

```json
{
  "headless": {
    "max_chains": 10,
    "report": "on_complete",
    "notify": "terminal"
  }
}
```

| Setting | Values | Default | Description |
|---------|--------|---------|-------------|
| `max_chains` | 1-50 | 10 | Maximum sessions to chain before stopping |
| `report` | `on_complete`, `on_failure`, `always`, `never` | `on_complete` | When to generate chain report |
| `notify` | `terminal`, `none` | `terminal` | How to notify on chain completion |

### Scope Requirement

**Headless mode requires explicit scope to prevent runaway sessions.**

When running headless (auto/unattended mode or `--continue` from chain):
- `--epic <id>`: Only work on tasks within the specified epic
- `--story <id>`: Only work on tasks within the specified story
- `--all`: Explicitly allow working on all available tasks

If no scope is provided in auto/unattended/headless mode, PAUSE and ask:
```markdown
Headless/auto/unattended mode requires a scope to prevent runaway sessions.

Which tasks should this session work on?
  1. --epic <id>  (work within a specific epic)
  2. --story <id> (work within a specific story)
  3. --all        (all available tasks)
```

### Scope Filtering

When scope is set, filter `get_next_task` and `get_next_batch` results:

```python
def get_scoped_tasks(scope):
    if scope.type == "epic":
        return get_tasks(epic_id=scope.id, status="todo")
    elif scope.type == "story":
        return get_tasks(story_id=scope.id, status="todo")  # via story filter
    else:  # "all"
        return get_next_batch()
```

## Initializing Chain State (Session Start)

When starting a NEW auto or unattended session with scope (not `--continue`), write the chain state file
so that SessionEnd hooks can spawn continuation sessions:

```
Write .pokayokay/pokayokay-chain-state.json:
{
  "chain_id": "chain-<current-unix-timestamp>",
  "chain_index": 0,
  "scope_type": "<epic|story|all>",
  "scope_id": "<id or empty string>",
  "tasks_completed": 0,
  "adaptive_n": 2,
  "batches_completed": 0,
  "batches_failed": 0,
  "failed_tasks": [],
  "conflict_tasks": [],
  "last_session_summary": ""
}
```

Use the Write tool. Generate chain_id from current unix timestamp.

**Skip this step** if:
- Mode is NOT auto/unattended (supervised/semi-auto don't chain)
- No scope is set (chaining requires scope)
- `--continue` flag is set (state file already exists from previous session)

## Proactive Context Shutdown

When session chaining is active (chain state file exists), the coordinator MUST
proactively end the session when context pressure is detected — **before** quality
degrades from repeated compaction.

### Detection

Context pressure is detected when **any** of these occur:
1. The active runtime compacts the conversation (for example, Claude Code shows "Compacting conversation..." in output)
2. A system reminder mentions context limits
3. You notice repeated information loss from prior context

### Behavior

When context pressure is detected during a chained session:

1. **Stop dispatching new tasks** — do not start another batch
2. **Wait for in-flight agents** — let current implementers finish (they have their own context)
3. **Save WIP** for any incomplete work:
   ```
   For each in-progress task with uncommitted changes:
     update_task_wip(task_id, { files_modified, last_commit, uncommitted_changes, next_step })
   ```
4. **Save coordinator state** to chain state file:
   ```
   Read existing .pokayokay/pokayokay-chain-state.json, falling back to .claude/pokayokay-chain-state.json
   Update with:
     adaptive_n: current parallel count
     batches_completed: count
     batches_failed: count
     failed_tasks: [task IDs that failed/blocked]
     conflict_tasks: [task IDs with git conflicts]
     last_session_summary: "Completed X tasks, Y failed, Z conflicts"
   Write back to .pokayokay/pokayokay-chain-state.json
   ```
5. **Log session summary**:
   ```
   add_task_activity(task_id, "note", "Session ending: context pressure detected, chaining to next session")
   ```
6. **End the session** — output a brief summary and stop. This triggers:
   - SessionEnd hook → bridge.py reads chain state → session-chain.sh spawns/prepares the next runtime session

### Why Proactive?

Without proactive shutdown:
- Context fills → Claude Code compacts → quality degrades → compacts again → eventually dies
- Each compaction loses coordinator context (task state, batch tracking, decisions)
- Subagents returning to a degraded coordinator get confused

With proactive shutdown:
- First compaction detected → graceful exit → fresh session chains with full context
- No quality degradation
- WIP preserved for seamless resume

### Non-Chained Sessions

In supervised or semi-auto sessions (no chain state file), compaction is handled
normally by the active runtime. The coordinator does NOT need to proactively end — the user
is present and can decide.

## Session Chaining (Session End)

When a session reaches context limits (or ends with remaining work in scope):

1. Save current WIP to ohno (automatic via hooks)
2. Generate chain report if configured
3. Exit with chain metadata:
   ```json
   {
     "chain_id": "chain-abc123",
     "chain_index": 3,
     "max_chains": 10,
     "scope": {"type": "epic", "id": "epic-abc123"},
     "tasks_completed": 5,
     "tasks_remaining": 8
   }
   ```
4. SessionEnd hook spawns or prepares the next session using the active runtime:
   ```bash
   # Claude Code
   claude -p "/work --continue --epic epic-abc123"

   # Codex
   codex --prompt="/work --continue --epic epic-abc123"
   ```

In detail, on SessionEnd:

1. SessionEnd hook calls `session-chain.sh`
2. Script checks remaining ready tasks via ohno
3. If tasks remain and chain limit not reached:
   - Spawns/prepares the next session using the active runtime, for example `claude -p "/work --continue <scope-flag>"` or `codex --prompt="/work --continue <scope-flag>"`
4. If chain complete or limit reached:
   - Generates report to `.ohno/reports/chain-{id}-report.md`
   - Notifies via configured method
   - Deletes chain state file

### Chain Reporting

On chain completion (all tasks done or max_chains reached), generate report:

```
.ohno/reports/chain-{id}-report.md

# Session Chain Report
- Chain ID: chain-abc123
- Sessions: 4
- Scope: epic-4fcd1e3c (Context Efficiency Redesign)
- Tasks completed: 12
- Tasks failed: 1 (task-xyz: test failures)
- Tasks remaining: 2
- Total duration: ~45 minutes
- Decisions made: [extracted from task handoffs]
```

Report is generated BEFORE memory decay compacts handoff details.

## Chain State File

Chain state is communicated between the coordinator and hooks via `.pokayokay/pokayokay-chain-state.json`, with `.claude/pokayokay-chain-state.json` retained as a legacy fallback.

**The coordinator MUST write this file at session start** when running auto mode with scope.
Use the Write tool to create it:

```json
{
  "chain_id": "chain-<unix-timestamp>",
  "chain_index": 0,
  "scope_type": "all",
  "scope_id": "",
  "tasks_completed": 0,
  "adaptive_n": 2,
  "batches_completed": 0,
  "batches_failed": 0,
  "failed_tasks": [],
  "conflict_tasks": [],
  "last_session_summary": ""
}
```

### Chain State Fields

- `chain_id`: Generate as `chain-<unix-timestamp>` (e.g., `chain-1738764000`)
- `chain_index`: Start at 0, auto-incremented by bridge.py on each chain
- `scope_type`: "epic", "story", or "all" (from `--epic`, `--story`, or `--all` flag)
- `scope_id`: The epic/story ID (empty string for "all")
- `tasks_completed`: Starts at 0, auto-incremented by bridge.py on each task completion
- `adaptive_n`: Current parallel count (written by coordinator before shutdown)
- `batches_completed`: Successful batch count (for adaptive sizing decisions)
- `batches_failed`: Failed batch count (for adaptive sizing decisions)
- `failed_tasks`: Task IDs that failed or got blocked (skip on resume)
- `conflict_tasks`: Task IDs with git conflicts (flag for manual resolution)
- `last_session_summary`: Brief summary of what the last session accomplished

**When `--continue`**: Read the existing state file. Do NOT overwrite it — bridge.py
already incremented `chain_index` and tracks `tasks_completed`. Restore coordinator state
from extended fields (`adaptive_n`, `failed_tasks`, etc.).

**When NOT auto or no scope**: Do NOT write the state file. Non-chaining sessions
should not have a state file.

Bridge.py handles:
- Reading the state file on SessionEnd to pass to session-chain.sh
- Incrementing `tasks_completed` on each task completion
- Incrementing `chain_index` when spawning the next session
- Deleting the state file when the chain completes or hits the limit

## Chain Completion Audit

When all tasks in scope are done, the chain runs a completeness audit before declaring success.

### How It Works

1. `session-chain.sh` detects `READY_COUNT == 0` but `CHAIN_AUDITED != true`
2. Returns `audit_pending` instead of `complete`
3. `bridge.py` sets `chain_state.audit_pending = true` (does NOT delete chain state)
4. On next session start (via chain continue), coordinator detects `audit_pending`:

**Coordinator audit logic (run at session start when `--continue` and audit_pending):**

```
Read chain state → check audit_pending == true

If audit_pending:
  1. Find the concept doc / PRD:
     - Check docs/plans/*.md, docs/concepts/*.md
     - Check epic description if scope is epic
     - Check PROJECT.md
  2. Dispatch `pokayokay:yokay-auditor` (Task tool subagent_type):
     - Pass: concept doc content + scope info
     - Instruction: "Verify all requirements are implemented. Return PASS or FAIL with gap list."
  3. Process result:
     - PASS:
       - Set chain_state.audit_passed = true
       - Set chain_state.audit_pending = false
       - Save chain state
       - Session ends → session-chain.sh sees CHAIN_AUDITED=true → "complete"
     - FAIL with gaps:
       - Create remediation tasks in ohno for each gap
       - Set chain_state.audit_pending = false (audit ran, even if failed)
       - Continue working on remediation tasks
       - When those complete, audit runs again (next chain end)
```

### Audit Tracking Fields

The following fields are added to the chain state for audit tracking:

```json
{
  "audit_pending": false,
  "audit_passed": false
}
```

- `audit_pending`: Set to `true` by bridge.py when all tasks done but audit not yet run
- `audit_passed`: Set to `true` by coordinator when audit passes. Passed to session-chain.sh as `CHAIN_AUDITED`
