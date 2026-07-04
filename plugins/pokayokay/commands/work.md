---
description: Start or continue orchestrated work session
argument-hint: "[supervised|semi-auto|auto|unattended] [-n N|auto] [--worktree|--in-place] [--epic ID|--story ID|--all] [--continue] [--skip-design] [--skip-brainstorm] [--skip-auto-fix]"
skill: work-session
---

# Work Session Workflow

Start or continue a development session with configurable human control.

**Mode**: `$ARGUMENTS` (default: supervised)
**Parallel**: Extract `-n N` or `--parallel N` from arguments (default: 1, "auto" for adaptive)

## Argument Parsing

Parse `$ARGUMENTS` to extract:
1. **Mode**: First word if it matches supervised|semi-auto|auto|unattended, else "supervised"
2. **Parallel**: Value after `-n` or `--parallel` flag. Values: `auto`, or `1`-`5`. Default: `1`
3. **Scope**: `--epic <id>`, `--story <id>`, or `--all` (limits which tasks to work on)
4. **Continue**: `--continue` flag (resume from previous session's WIP)
5. **Skip design**: `--skip-design` flag (bypass the Design Review Gate for all tasks this session)
6. **Skip brainstorm**: `--skip-brainstorm` flag (skip the Brainstorm Gate for all tasks this session)
7. **Skip auto-fix**: `--skip-auto-fix` flag (disable auto-fixer dispatch on test failures for this session)

Example arguments:
- `semi-auto -n 3` → mode=semi-auto, parallel=3 (fixed)
- `semi-auto -n auto` → mode=semi-auto, parallel=adaptive (starts at 2)
- `--parallel 2` → mode=supervised, parallel=2 (fixed)
- `auto` → mode=auto, parallel=1
- `unattended` → mode=unattended, parallel=1 (never pauses, for overnight runs)
- `semi-auto --epic epic-abc123` → mode=semi-auto, scope=epic:epic-abc123
- `auto --story story-def456 -n 3` → scope=story:story-def456, parallel=3
- `--continue` → resume from WIP, inherit previous scope
- `--all` → work on all available tasks (no scope filter)
- `auto --skip-design` → mode=auto, design review gate bypassed

Note: `-p` is commonly reserved by AI runtime CLIs for prompt input. Use `-n` for parallel count.

## Worktree Argument Parsing

Extract worktree flags from `$ARGUMENTS`:
1. **--worktree**: Force worktree creation (even for chores)
2. **--in-place**: Force in-place work (skip worktree)

Example arguments:
- `semi-auto --worktree` → mode=semi-auto, forceWorktree=true
- `--in-place` → mode=supervised, forceInPlace=true
- `auto -n 3` → mode=auto, parallel=3, useSmartDefault=true

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

### Session Chaining

When a session reaches context limits:

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

## Adaptive Parallel Sizing

When `-n auto` is specified, parallel count adjusts based on batch outcomes.

### Rules

| Event | Change | Rationale |
|-------|--------|-----------|
| Batch completes fully | +1 (max 4) | System handling load well |
| Context pressure detected | End session (chain) | See Proactive Context Shutdown |
| Task blocked mid-batch | No change | Not a sizing issue |
| Task failed review (3x) | -1 (min 2) | Reduce concurrent load |
| New session (fresh start) | Reset to 2 | Conservative start |
| `--continue` session | Inherit last value | Maintain momentum |

### Tracking

The coordinator tracks adaptive state in-memory during the session:

```python
adaptive_state = {
    "current_n": 2,        # Current parallel count
    "mode": "auto",        # "auto" or "fixed"
    "batches_completed": 0,
    "batches_failed": 0,
    "last_outcome": None,  # "completed", "interrupted", "failed"
}

def adjust_parallel(outcome):
    if adaptive_state["mode"] != "auto":
        return  # Fixed mode, no adjustment

    if outcome == "completed":
        adaptive_state["current_n"] = min(adaptive_state["current_n"] + 1, 4)
        adaptive_state["batches_completed"] += 1
    elif outcome in ("interrupted", "failed"):
        adaptive_state["current_n"] = max(adaptive_state["current_n"] - 1, 2)
        adaptive_state["batches_failed"] += 1

    adaptive_state["last_outcome"] = outcome
```

### Display

When adaptive sizing changes, log it:
```markdown
Parallel sizing: 2 → 3 (batch completed successfully)
```

Or:
```markdown
Parallel sizing: 3 → 2 (batch interrupted by context fill)
```

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

## Session Start

### 0. Load Configuration
Read `.pokayokay/config.json` for headless and work settings. If it does not exist, fall back to `.claude/pokayokay.json` so existing Claude Code projects keep working.

### 0.5 Load Project Learnings
MEMORY.md is already in your system prompt. Additionally check topic files when relevant:
- `memory/recurring-failures.md` — review failure patterns to include as "Known Pitfalls" in implementer prompts
- `memory/spike-results.md` — closed spike investigations (avoid re-investigating)
- `memory/chain-learnings.md` — session chain progress history

### 1. Scope Validation (if auto/unattended or --continue)
If mode is `auto` or `unattended` or `--continue` flag is set, verify scope:
- If `--epic <id>` → filter tasks to this epic only
- If `--story <id>` → filter tasks to this story only
- If `--all` → no filter (explicit opt-in)
- If none → PAUSE and require user to pick a scope

### 1.5 Initialize Chain State (if auto/unattended + scope, NOT --continue)

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

### 2. Get Session Context
Use ohno MCP `get_session_context` to understand:
- Previous session notes
- Current blockers
- In-progress tasks

### 3. Resume Check (if --continue)

When `--continue` flag is set, resume from previous WIP instead of starting fresh:

1. **Restore coordinator state**: Read `.pokayokay/pokayokay-chain-state.json`, falling back to `.claude/pokayokay-chain-state.json`. If it contains extended fields (`adaptive_n`, `failed_tasks`, etc.), restore them:
   - `adaptive_state.current_n = chain_state.adaptive_n` (instead of reset to 2)
   - `adaptive_state.batches_completed = chain_state.batches_completed`
   - `adaptive_state.batches_failed = chain_state.batches_failed`
   - `failed_blocked = chain_state.failed_tasks` (skip these tasks)
   - `conflict_tasks = chain_state.conflict_tasks` (flag for manual resolution)
2. **Find resumable tasks**: Check `get_session_context()` for in_progress tasks with WIP data
3. **Select task to resume**: Pick the task with most recent `wip_updated_at`
4. **Load WIP**: Get full task via `get_task(task_id, fields="full")` to access `work_in_progress`
5. **Load handoff**: Call `get_task_handoff(task_id)` for the implementer's previous handoff data (summary, files_changed, full_details with self-review findings). If absent, continue with WIP-only resume.
6. **Display resume context**:

```markdown
## Resuming: {task.title} ({task.id})

**Phase**: {wip.phase}
**Last activity**: {task.wip_updated_at}
**Files modified**: {wip.files_modified}
**Last commit**: {wip.last_commit}
**Uncommitted changes**: {wip.uncommitted_changes}

**Next step**: {wip.next_step}

**Decisions made**:
{wip.decisions | formatted}

**Test results**: {wip.test_results.passed} passed, {wip.test_results.failed} failed
```

6. **Skip brainstorming**: Task already has context, go directly to implementation
7. **Dispatch implementer with WIP + handoff context**:

```
Task tool:
  subagent_type: "pokayokay:yokay-implementer"
  description: "Resume: {task.title}"
  mode: "bypassPermissions"
  prompt: [Fill implementer template with ADDITIONAL section:]

  ## Resuming from Previous Session
  This task was partially completed. Here is the saved state:
  - Phase: {wip.phase}
  - Files already modified: {wip.files_modified}
  - Last commit: {wip.last_commit}
  - Uncommitted changes: {wip.uncommitted_changes}
  - Decisions already made: {wip.decisions}
  - Test results: {wip.test_results}
  - Errors encountered: {wip.errors}
  - Next step: {wip.next_step}

  ## Previous Implementation Context
  (from implementer handoff — skip this section if no handoff data)
  - Status: {handoff.status}
  - Summary: {handoff.summary}
  - Files changed: {handoff.files_changed}
  - Self-review findings: {handoff.full_details}

  Pick up from where the previous session left off. Do NOT redo work
  that was already committed. Start from the "next step" above.
```

If no in_progress tasks with WIP exist, fall through to normal task selection.

### 4. Read Project Context
If `.claude/PROJECT.md` exists, read it for:
- Project overview
- Tech stack
- Conventions

### 5. Get Next Task
```bash
npx @stevestomp/ohno-cli next
```
Or use ohno MCP `get_next_task`.

When scope is set, filter the result to only include tasks within scope.

### 6. Worktree Decision

After getting the next task, determine whether to use a worktree.

#### Smart Defaults by Task Type

| Task Type | Default Behavior |
|-----------|------------------|
| `feature` | Worktree |
| `bug` | Worktree |
| `spike` | Worktree |
| `chore` | In-place |
| `docs` | In-place |
| `test` | Same as parent task |

#### Decision Logic

```javascript
function shouldUseWorktree(task, flags) {
  // Explicit flags override everything
  if (flags.forceWorktree) return true;
  if (flags.forceInPlace) return false;

  // Smart defaults by task type
  const worktreeTypes = ['feature', 'bug', 'spike'];
  const inPlaceTypes = ['chore', 'docs'];

  if (worktreeTypes.includes(task.task_type)) return true;
  if (inPlaceTypes.includes(task.task_type)) return false;

  // test type: inherit from parent task if exists
  if (task.task_type === 'test' && task.story_id) {
    // Check other tasks in same story
    const storyTasks = await mcp.ohno.get_tasks({ story_id: task.story_id });
    const parentType = storyTasks.find(t => t.id !== task.id)?.task_type;
    if (parentType) {
      return worktreeTypes.includes(parentType);
    }
  }

  return true; // Default to worktree for unknown types
}
```

#### Propagating Force Flags to the Worktree Hook

The `setup-worktree` hook runs in a separate hook process that cannot see
environment variables exported by the coordinator. When `--worktree` or
`--in-place` was passed, write the flags into the task state file BEFORE
marking the task `in_progress`:

```bash
mkdir -p .pokayokay
printf '{"force_worktree": %s, "force_inplace": %s}\n' "true" "false" \
  > .pokayokay/pokayokay-task-state.json
```

The bridge merges these flags with the task id on the `in_progress`
transition and passes them to `setup-worktree.sh` as
`FORCE_WORKTREE`/`FORCE_INPLACE`. Without flags, skip this step — the hook
applies the smart defaults above.

#### Worktree Setup Flow

If worktree is needed:

1. **Check for story worktree reuse**
   ```javascript
   if (task.story_id) {
     const existing = await findStoryWorktree(task.story_id);
     if (existing) {
       // Reuse existing story worktree
       cd(existing.path);
       return { reused: true, path: existing.path };
     }
   }
   ```

2. **Create new worktree**
   ```javascript
   const name = generateWorktreeName(task);
   const baseBranch = await getDefaultBranch();
   const result = await createWorktree(name, baseBranch);
   ```

3. **Install dependencies**
   ```javascript
   const setupResult = await setupWorktree(result.path);
   console.log(formatSetupOutput(setupResult));
   ```

4. **Report and change directory**
   ```markdown
   Creating worktree for task-42-user-auth...
     ✓ Branch created: task-42-user-auth
     ✓ Worktree ready at .worktrees/task-42-user-auth

   Installing dependencies...
     Detected: bun (bun.lockb)
     ✓ Dependencies installed (4.2s)

   Ready to work on: Add user authentication
   ```

5. **Handle setup failures**
   ```markdown
   Installing dependencies...
     Detected: npm (package-lock.json)
     ✗ npm install failed: ERESOLVE peer dependency conflict

   Options:
     1. Retry with --legacy-peer-deps
     2. Skip dependencies (manual install later)
     3. Abort worktree creation
   ```

## Parallel State Tracking

When running with `-n N` where N > 1 (or `-n auto`):

### State Variables

Track these during the work loop:
- **active_agents**: Map of {task_id: agent_status} for in-flight implementers
- **queued_tasks**: List of task IDs ready to dispatch
- **completed_this_batch**: List of task IDs completed since last checkpoint
- **failed_blocked**: List of task IDs that failed or got blocked
- **adaptive_state**: Current parallel count, mode, batch outcomes (see Adaptive Parallel Sizing)

### Filling the Queue

1. Call `get_tasks(status="todo")` to get available tasks
2. Filter out tasks where `blockedBy` contains any task NOT in "done" status
3. Filter out tasks where `blockedBy` contains any task in `active_agents`
4. Add up to N tasks to `queued_tasks`

### Invariant

At any time: `len(active_agents) + len(queued_tasks) <= N`

### 7. Start the Task
```bash
npx @stevestomp/ohno-cli start <task-id>
```

## Work Loop

### Sequential Mode (parallel=1)

For each task:

1. **Get next task**: `get_next_task()` from ohno
2. **Understand the task**: Read task details via `get_task()`
3. **Route to skill** (if needed): Based on task type
4. **Brainstorm gate** (conditional): See Brainstorm Gate section
5. **Pre-implementation validation**: Verify description quality, dependencies, skill hint
6. **Design review gate** (conditional): See Design Review Gate section — produces the pre-validated approach
7. **Dispatch implementer**: Single Task tool call, `{APPROACH}` filled from the design review
8. **Auto-fix test failures** (conditional): See Auto-Fix section
9. **Browser verification** (conditional): See Browser Verification section
10. **Task review**: Spec compliance + code quality (incl. design compliance)
11. **Complete task**: Mark done, trigger hooks
12. **Checkpoint**: Based on mode

### Parallel Mode (parallel > 1)

Coordinator maintains N concurrent implementers:

#### Initial Dispatch

1. **Fill queue**: Get up to N tasks that are:
   - Status = "todo"
   - No unmet `blockedBy` dependencies
   - Not blocked by another task in active_agents

2. **File conflict check**: Before dispatching, scan task descriptions for implicit file-level conflicts:

   ```python
   def detect_file_conflicts(tasks):
       """Scan tasks for likely file-level conflicts that would cause merge issues."""
       task_files = {}  # task_id -> set of likely affected files/modules

       for task in tasks:
           text = (task.title + " " + task.description).lower()
           affected = set()

           # Extract file paths (e.g., src/auth/login.ts)
           import re
           paths = re.findall(r'[\w/.-]+\.\w{1,4}', text)
           affected.update(paths)

           # Extract module/directory references
           dirs = re.findall(r'(?:src|lib|app|components|hooks|utils|services)/[\w/-]+', text)
           affected.update(dirs)

           # Extract database table references
           tables = re.findall(r'(?:table|model|schema|migration)\s+[`"]?([\w_]+)[`"]?', text)
           affected.update(f"table:{t}" for t in tables)

           task_files[task.id] = affected

       # Find conflicts: tasks with overlapping affected files
       conflicts = []
       task_ids = list(task_files.keys())
       for i in range(len(task_ids)):
           for j in range(i + 1, len(task_ids)):
               overlap = task_files[task_ids[i]] & task_files[task_ids[j]]
               if overlap:
                   conflicts.append((task_ids[i], task_ids[j], overlap))

       return conflicts

   conflicts = detect_file_conflicts(queued_tasks)
   if conflicts:
       # Serialize conflicting tasks, parallelize the rest
       # Keep first task in each conflict pair, defer second to next batch
       deferred = set()
       for t1, t2, overlap in conflicts:
           if t1 not in deferred:
               deferred.add(t2)
           log(f"File conflict: {t1} and {t2} both touch {overlap}. Serializing {t2}.")
       queued_tasks = [t for t in queued_tasks if t.id not in deferred]
   ```

3. **Design review gate (per task)**: Before batching implementer dispatches, run the Design Review Gate (Step 3.7) for EACH queued task:
   - Apply the skip conditions per task (chore/docs type, `--skip-design`, trivial change)
   - For non-skipped tasks, dispatch `yokay-design-reviewer` (these read-only dispatches may run in parallel)
   - Store each task's APPROVED approach; it fills that task's `{APPROACH}` in the implementer template and later its quality-review dispatch
   - NEEDS_DISCUSSION follows the same mode handling as sequential (auto/unattended: log and proceed without approach)

4. **Parallel dispatch**: Send SINGLE message with N Task tool calls:
   ```
   Task tool:
     subagent_type: "pokayokay:yokay-implementer"
     description: "Implement: {task1.title}"
     mode: "bypassPermissions"
     prompt: [template for task1]

   Task tool:
     subagent_type: "pokayokay:yokay-implementer"
     description: "Implement: {task2.title}"
     mode: "bypassPermissions"
     prompt: [template for task2]

   ... up to N tasks
   ```

5. **Track state**: Add all dispatched tasks to `active_agents`

#### Processing Results

As each agent returns:

1. **Remove from active_agents**
2. **Run task review** (spec + quality in one pass)
3. **Handle result**:
   - PASS: Add to `completed_this_batch`, attempt commit
   - NEEDS_REDESIGN: Handle per "Handling NEEDS_REDESIGN" (Step 4) — one redesign cycle, then block
   - FAIL: Re-dispatch or add to `failed_blocked`
4. **Refill**: If `len(active_agents) < N` and queue not empty:
   - Run the Design Review Gate (Step 3.7) for the next task, then dispatch it
   - Replenish queue from ohno if needed

#### Commit Handling

Each task commits independently when its review passes:
- Git conflicts at commit time → try rebase once
- If rebase fails → flag task, continue with others

#### Checkpoint Behavior

| Mode | Sequential | Parallel |
|------|------------|----------|
| supervised | After each task | After each task completes |
| semi-auto | Log & continue | Log & continue |
| auto | Skip | Skip |
| unattended | Skip | Skip |

Story/epic boundaries trigger pauses per mode settings (except unattended, which never pauses).

## Git Conflict Handling (Parallel Mode)

When multiple agents complete around the same time, git conflicts may occur at commit.

### Detection

After implementer completes and reviews pass, the commit hook runs. If commit fails:

1. Check if failure is a merge conflict (exit code + stderr contains "conflict")
2. If yes, attempt resolution
3. If no, report error and continue

### Resolution Strategy

```
1. Run: git fetch origin && git rebase origin/$(git branch --show-current)
2. If rebase succeeds:
   - Run: git add -A && git rebase --continue
   - Commit should now succeed
3. If rebase fails (complex conflict):
   - Run: git rebase --abort
   - Flag task: "Git conflict - needs manual resolution"
   - Add to failed_blocked list
   - Continue with other tasks
```

### Reporting

At checkpoint, report conflict status:

```markdown
## Parallel Batch Status

✓ task-001: completed, committed
✓ task-002: completed, committed
⚠️ task-003: completed, git conflict (flagged for manual resolution)
⟳ task-004: implementing...

Continue? [y/n/resolve task-003]
```

### User Options

- **y**: Continue with remaining tasks
- **n**: Stop session
- **resolve task-XXX**: Pause to manually resolve conflict, then continue

---

## Work Loop Details

The following sections provide detailed implementation guidance for each step:

### 1. Understand the Task
Read task details via ohno MCP `get_task`.

### 2. Route to Skill (if needed)

Route by **keywords in task title/description**, not by layer. Each task is a vertical slice — skill routing picks the dominant domain.

**By keywords**:
- "endpoint", "REST", "GraphQL" → Load `api-design` skill
- "schema", "migration", "query" → Load `database-design` skill
- "refactor", "module boundary" → Load `architecture-review` skill
- "integrate", "third-party", "webhook" → Load `api-integration` skill
- "pipeline", "deploy", "CI/CD" → Load `ci-cd` skill
- "logging", "metrics", "tracing" → Load `observability` skill
- "test", "coverage", "TDD" → Load `testing-strategy` skill
- "security", "auth", "OWASP" → Load `security-audit` skill

**By task type**:
- spike → Load `spike` skill (enforce time-box)
- bug → Load `error-handling` skill

### 2.5 Design Task Routing (Conditional)

Before brainstorming or implementation, check if the task is design-related and should be routed to the design plugin.

#### Design Task Detection

A task is considered design-related if ANY of these conditions are met:

**Task Type Check:**
- `task_type` is one of: `design`, `ux`, `ui`, `persona`, `accessibility`, `a11y`

**Keyword Check:**
Check task title and description for design-related keywords:
- Design work: `design`, `wireframe`, `mockup`, `prototype`
- UX work: `ux`, `user experience`, `flow`, `journey`, `interaction`
- UI work: `ui`, `visual`, `component`, `design system`, `tokens`
- Persona work: `persona`, `user research`, `empathy map`
- Accessibility work: `accessibility`, `a11y`, `wcag`, `screen reader`

#### Detection Logic

```python
def is_design_task(task):
    design_types = ['design', 'ux', 'ui', 'persona', 'accessibility', 'a11y']

    # Check task_type
    if task.task_type in design_types:
        return True

    # Check title/description for design keywords
    design_keywords = ['design', 'ux', 'ui', 'user experience', 'persona',
                       'accessibility', 'a11y', 'wireframe', 'mockup', 'prototype',
                       'flow', 'journey', 'interaction', 'visual', 'component',
                       'design system', 'tokens', 'user research', 'empathy map',
                       'wcag', 'screen reader']
    text = (task.title + ' ' + task.description).lower()
    if any(kw in text for kw in design_keywords):
        return True

    return False
```

#### Design Plugin Availability Check

Check if `/design:*` commands are available in the current environment:

```python
def is_design_plugin_available():
    # Claude Code plugin system handles command availability
    # Check for design plugin manifest or command registration
    return has_command('/design:ux') or has_command('/design:ui')
```

#### Routing Logic

If task is design-related, determine the appropriate design command:

```python
def get_design_command(task):
    """Map task to appropriate /design:* command"""
    type_map = {
        'ux': '/design:ux',
        'ui': '/design:ui',
        'persona': '/design:persona',
        'accessibility': '/design:a11y',
        'a11y': '/design:a11y'
    }

    # Check task_type first
    if task.task_type in type_map:
        return type_map[task.task_type]

    # Check keywords in title/description
    text = (task.title + ' ' + task.description).lower()
    if 'persona' in text or 'user research' in text or 'empathy map' in text:
        return '/design:persona'
    if 'accessibility' in text or 'a11y' in text or 'wcag' in text:
        return '/design:a11y'
    if 'ui' in text or 'visual' in text or 'component' in text or 'design system' in text:
        return '/design:ui'
    if 'ux' in text or 'flow' in text or 'journey' in text or 'interaction' in text:
        return '/design:ux'

    # Default for generic design tasks
    return '/design:ux'
```

#### Design Routing Flow

**When design plugin IS available:**

1. Detect design task using `is_design_task()`
2. Determine appropriate command using `get_design_command()`
3. Route to the design command:
   ```markdown
   Design task detected: {task.title}

   Routing to {design_command} for specialized design workflow.

   The design plugin will handle:
   - Design artifacts creation
   - Design system integration
   - Accessibility compliance
   - Design review process

   Executing: {design_command}
   ```
4. Invoke the design command for this task
5. When design command completes, mark task as done via `update_task_status(task_id, "done")`
6. Continue the work loop (get next task)
7. Log activity:
   ```
   add_task_activity(task_id, "note", "Routed to {design_command}")
   ```

**When design plugin is NOT available:**

1. Detect design task using `is_design_task()`
2. Show installation suggestion:
   ```markdown
   ⚠️ Design task detected but design plugin not available.

   This task appears to require design work:
   - Task: {task.title}
   - Suggested command: {get_design_command(task)}

   The design plugin provides specialized workflows for:
   - UX flows and user journeys (/design:ux)
   - Visual design and components (/design:ui)
   - User personas and research (/design:persona)
   - Accessibility audits (/design:a11y)
   - Marketing pages (/design:marketing)

   To enable design workflows, install the design plugin:
     claude plugin install design

   Alternatively, continue with standard implementation (may miss design artifacts).

   Continue without design plugin? [y/n]
   ```
3. Handle response:
   - **auto or unattended mode**: Auto-resolve as **y**. Log decision and continue.
     ```
     add_task_activity(task_id, "decision", "Auto-resolved: continuing without design plugin (auto/unattended mode)")
     ```
   - **y**: Log decision and continue to Brainstorm Gate (Step 3)
   - **n**: Pause session, suggest plugin installation

#### Design Command Mapping

| Task Type/Keywords | Design Command | Purpose |
|-------------------|----------------|---------|
| `ux`, flow, journey, interaction | `/design:ux` | UX flows, IA, user journeys |
| `ui`, visual, component, tokens | `/design:ui` | Visual system, components |
| `persona`, user research | `/design:persona` | User personas, empathy maps |
| `accessibility`, `a11y`, wcag | `/design:a11y` | Accessibility audits |
| Generic `design` | `/design:ux` | Default to UX workflow |

#### Logging

Log all design routing decisions:
```
add_task_activity(task_id, "note", "Design task detected, routing to {command}")
add_task_activity(task_id, "note", "Design plugin not available, user chose to continue")
```

### 3. Brainstorm Gate (Conditional)

Before dispatching the implementer, check if the task needs brainstorming.

#### Trigger Conditions

Brainstorm triggers when ANY of these are true:

| Condition | Check | Rationale |
|-----------|-------|-----------|
| Short description | `len(description) < 100 chars` | Likely underspecified |
| No acceptance criteria | `acceptance_criteria is empty` | No clear success definition |
| Spike type | `task_type == "spike"` | Investigation required |
| Ambiguous keywords | Contains "investigate", "explore", "figure out" | Unclear scope |

#### Skip Conditions

Brainstorm is skipped when ANY of these are true:

| Condition | Check | Rationale |
|-----------|-------|-----------|
| Bug type | `task_type == "bug"` | Usually well-defined |
| Chore type | `task_type == "chore"` | Usually mechanical |
| Well-specified | Has description AND criteria AND no ambiguous keywords | Ready to implement |
| Manual skip | `--skip-brainstorm` flag passed | Human override |

#### Gate Logic

```python
# Pseudocode
def needs_brainstorm(task, skip_flag=False):
    # Skip conditions (check first)
    if skip_flag:
        return False
    if task.task_type in ["bug", "chore"]:
        return False
    if (len(task.description) >= 100 and
        task.acceptance_criteria and
        not has_ambiguous_keywords(task)):
        return False

    # Trigger conditions
    if len(task.description) < 100:
        return True, "Short description"
    if not task.acceptance_criteria:
        return True, "No acceptance criteria"
    if task.task_type == "spike":
        return True, "Spike investigation"
    if has_ambiguous_keywords(task):
        return True, "Ambiguous scope"

    return False
```

#### Dispatching Brainstormer

If brainstorm triggers:

1. Dispatch brainstormer:
   ```
   Task tool:
     subagent_type: "pokayokay:yokay-brainstormer"
     description: "Brainstorm: {task.title}"
     prompt: [Fill template from agents/templates/brainstorm-prompt.md]
   ```

2. Process brainstorm result:
   - Update ohno task with refined requirements:
     ```
     update_task(task_id, {
       description: refined_description,
       acceptance_criteria: proposed_criteria
     })
     ```
   - If open questions:
     - **auto mode**: Auto-resolve — log open questions as assumptions, proceed with brainstormer's best judgment.
       ```
       add_task_activity(task_id, "decision", "Auto-resolved open questions as assumptions (auto mode): {questions}")
       ```
     - **other modes**: PAUSE for human input
   - If refined: Proceed to Step 3.5 (validation), then the Design Review Gate (Step 3.7)

3. Log activity:
   ```
   add_task_activity(task_id, "note", "Brainstorm: Refined requirements")
   ```

#### Brainstorm Flow

```
┌──────────────┐
│  Get Task    │
└──────┬───────┘
       │
       ▼
┌──────────────┐     NO      ┌──────────────┐
│ Needs        │────────────►│ Skip to      │
│ Brainstorm?  │             │ Design Review│
└──────┬───────┘             └──────────────┘
       │ YES
       ▼
┌──────────────┐
│ Brainstormer │
│  Subagent    │
└──────┬───────┘
       │
       ▼
┌──────────────┐     QUESTIONS   ┌──────────────┐
│ Result?      │────────────────►│ PAUSE for    │
└──────┬───────┘                 │ human input  │
       │ REFINED                 └──────────────┘
       ▼
┌──────────────┐
│ Update ohno  │
│ with criteria│
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Design Review│
│  Gate (3.7)  │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Implementer  │
└──────────────┘
```

### 3.5 Pre-Implementation Validation

Before dispatching the implementer, verify the task is ready:

```python
def validate_task(task):
    issues = []

    # 1. Description quality
    if len(task.description or "") < 50:
        issues.append("BLOCK: Description too short for implementer")
    if not task.acceptance_criteria:
        issues.append("WARN: No acceptance criteria")

    # 2. Dependency check (belt-and-suspenders with get_next_task)
    deps = get_task_dependencies(task.id)
    blocked_by = [d for d in deps.blocked_by if d.status != "done"]
    if blocked_by:
        issues.append(f"BLOCK: {len(blocked_by)} unresolved dependencies")

    # 3. Skill hint
    if not task.skill_hint:
        issues.append("WARN: No skill assigned — will use default routing")

    return issues
```

**BLOCK issues**: Skip task, set blocker in ohno, move to next task.
**WARN issues**: Log and proceed — implementer can handle missing criteria if description is sufficient.

If task was just brainstormed (Step 3) and still has BLOCK issues, something went wrong. Log and skip rather than re-brainstorming.

### 3.7 Design Review Gate (Conditional)

Before dispatching the implementer, validate the implementation approach against the codebase. The design reviewer's APPROVED output becomes the implementer's blueprint via the `{APPROACH}` template variable, and is re-used later for the quality reviewer's design-compliance check.

#### Skip Conditions

Design review is skipped when ANY of these are true (keep consistent with the skip conditions in `agents/templates/design-review-prompt.md`):

| Condition | Check | Rationale |
|-----------|-------|-----------|
| Manual skip | `--skip-design` flag passed | Human override |
| Low-risk type | `task_type == "chore"` or `task_type == "docs"` | Low design risk |
| Trivial change | Fewer than 3 acceptance criteria AND touches <= 1 file | Not worth a dispatch |

```python
# Pseudocode
def skip_design_review(task, skip_flag=False):
    if skip_flag:
        return True  # --skip-design flag
    if task.task_type in ["chore", "docs"]:
        return True  # Low design risk
    ac_count = count_acceptance_criteria(task)
    if ac_count < 3 and estimated_files_touched(task) <= 1:
        return True  # Trivial change
    return False
```

**If skipped**: fill `{APPROACH}` in Step 4's implementer template with `Design review skipped — follow codebase patterns`. NEVER leave the literal `{APPROACH}` placeholder in a dispatched prompt.

#### Dispatching Design Reviewer

If the gate is not skipped:

1. Dispatch design reviewer (read-only agent):
   ```
   Task tool:
     subagent_type: "pokayokay:yokay-design-reviewer"
     description: "Design review: {task.title}"
     prompt: [Fill template from agents/templates/design-review-prompt.md]
   ```

   Template variables: `{TASK_ID}`, `{TASK_TITLE}`, `{TASK_DESCRIPTION}`, `{ACCEPTANCE_CRITERIA}`, `{CONTEXT}` (story + handoff notes + dependencies), `{WORKING_DIRECTORY}`.

2. Process design review result:
   - **APPROVED**: Store the approach (the `## Design Review: APPROVED` block). It fills:
     - `{APPROACH}` in Step 4's implementer template
     - `{APPROACH}` in Step 5 Stage 2's quality-review template (design-compliance post-check)
   - **NEEDS_DISCUSSION**: Handle per mode:
     - **supervised / semi-auto**: PAUSE — present the decision needed and options to the human, then re-run the gate with the decision appended to `{CONTEXT}`
     - **auto / unattended**: Do NOT pause. Log the open decision and proceed WITHOUT a validated approach — fill `{APPROACH}` with the skip text:
       ```
       add_task_activity(task_id, "decision", "Design review NEEDS_DISCUSSION — proceeding without validated approach (auto/unattended): {decision_needed}")
       ```

3. Log activity:
   ```
   add_task_activity(task_id, "note", "Design review: APPROVED — approach stored for implementer")
   ```

### 4. Dispatch Implementer Subagent

**CRITICAL: Do not implement inline. Always dispatch subagent.**

*Note: If brainstorm ran in Step 3, task now has refined requirements. Validation in Step 3.5 confirmed readiness. If design review ran in Step 3.7, its approach fills `{APPROACH}`.*

1. Extract full task details from ohno:
   ```
   task = get_task(task_id)
   ```

2. Prepare context for subagent:
   - Task description (full text)
   - Acceptance criteria (from task or brainstorm output)
   - Architectural context (where this fits in the project)
   - Relevant skill (determined in Step 2 or assigned by planner)
   - Pre-validated approach (from Step 3.7 — fills `{APPROACH}`; use `Design review skipped — follow codebase patterns` if the gate was skipped)
   - Known pitfalls (from `memory/recurring-failures.md` if file exists — include entries matching the task domain as a "## Known Pitfalls" section in the implementer prompt)

3. Dispatch subagent using Task tool:
   ```
   Task tool:
     subagent_type: "pokayokay:yokay-implementer"
     description: "Implement: {task.title}"
     mode: "bypassPermissions"
     prompt: [Fill template from agents/templates/implementer-prompt.md]
   ```

4. Process subagent result:
   - If questions: Answer and re-dispatch
   - If complete: Proceed to Step 4.5 (Auto-Fix Test Failures)
   - If NEEDS_REDESIGN: The pre-validated approach proved infeasible — see "Handling NEEDS_REDESIGN" below
   - If blocked: Set blocker via ohno MCP

#### Handling NEEDS_REDESIGN

The implementer reports NEEDS_REDESIGN (with evidence) when the pre-validated approach from Step 3.7 proves infeasible. Do NOT re-dispatch the implementer against the same approach, and do NOT treat it as a plain FAIL.

**Cap: ONE redesign cycle per task.**

1. Log the implementer's infeasibility evidence:
   ```
   add_task_activity(task_id, "note", "NEEDS_REDESIGN: {implementer's evidence}")
   ```
2. Re-dispatch `yokay-design-reviewer` (Step 3.7 template) with the implementer's evidence appended to `{CONTEXT}` under a `### Prior Approach Infeasible` heading
3. On APPROVED: re-dispatch the implementer with the revised `{APPROACH}`
4. If the implementer returns NEEDS_REDESIGN **again** (or the redesign comes back NEEDS_DISCUSSION), stop the cycle:
   - Set blocker: `set_blocker(task_id, "Approach infeasible after one redesign cycle: {evidence}")`
   - **supervised / semi-auto / auto**: PAUSE for human decision
   - **unattended**: leave the task blocked and move to the next task

**Why subagent?**
- Fresh context per task (no accumulated confusion)
- Subagent can ask questions before/during work
- Context discarded after task (token efficiency)

### 4.5 Auto-Fix Test Failures (Conditional)

After the implementer completes, run tests to verify the implementation. If tests fail, automatically attempt to fix them before proceeding to review.

#### Configuration

Auto-fix behavior is controlled by configuration and task type:

```json
{
  "work": {
    "max_test_retries": 3,
    "auto_fix": true
  }
}
```

#### Task Type Defaults

| Task Type | Auto-fix Enabled |
|-----------|------------------|
| `bug` | Yes |
| `feature` | Yes |
| `chore` | Yes |
| `spike` | No (failures are data) |
| `docs` | No (usually no tests) |

#### Auto-Fix Flow

After implementer completes:

1. **Run tests**: Execute test suite for changed files
   ```bash
   # Detect test framework and run
   npm test -- --testPathPattern="<changed-files>"
   # or equivalent
   ```

2. **Evaluate result**:
   - **PASS**: Skip to Browser Verification (Step 4.6)
   - **FAIL + auto-fix enabled**: Proceed to step 3 below (Dispatch fixer)
   - **FAIL + auto-fix disabled**: Log failure, skip to Browser Verification
   - **FAIL + spike task**: Log failure as finding, skip to Browser Verification

3. **Dispatch fixer**: If test fails and auto-fix enabled:
   ```
   Task tool:
     subagent_type: "pokayokay:yokay-fixer"
     description: "Fix test failure: {task.title}"
     mode: "bypassPermissions"
     prompt: [Include task details, test output, "Max attempts: 3"]
   ```

4. **Process fixer result**:
   - **PASS**: Fixer fixed the issue → Continue to Browser Verification
   - **FAIL**: Fixer couldn't fix within attempt limit → Mark task blocked

5. **Handle fixer failure**:
   ```bash
   # Mark task as blocked
   npx @stevestomp/ohno-cli block <task-id> "Test failures could not be auto-fixed"

   # Log activity
   add_task_activity(task_id, "note", "Auto-fix failed after N attempts: [reason]")
   ```

6. **Continue queue**: Get next task and continue work loop (don't stop the session)

#### Fixer Agent Behavior

The yokay-fixer agent:
- Parses test failure output
- Identifies root cause (assertion failure, type error, missing await, etc.)
- Makes targeted code edits (using Edit tool only)
- Re-runs tests after each fix
- Attempt limit set by coordinator dispatch (default: 3 for /work, 2 for /hotfix)
- Reports PASS or FAIL with detailed handoff

#### Flow Diagram

```
Implementer Completes
        │
        ▼
    Run Tests
        │
   ┌────┴────┐
   │         │
  PASS      FAIL
   │         │
   │    ┌────┴────────────────┐
   │    │                     │
   │  Spike?            Auto-fix enabled?
   │    │                     │
   │   YES                   YES
   │    │                     │
   │    ▼                     ▼
   │  Log as             Dispatch Fixer
   │  finding            (max 3 attempts)
   │    │                     │
   │    │                ┌────┴────┐
   │    │                │         │
   │    │              PASS       FAIL
   │    │                │         │
   │    │                │         ▼
   │    │                │    Block Task
   │    │                │    Get Next Task
   │    │                │         │
   └────┴────────────────┴─────────┘
        │
        ▼
  Browser Verification
  (Section 4.6)
```

#### Logging

Log all auto-fix activities:

```bash
# Test failure detected
add_task_activity(task_id, "note", "Tests failed, spawning auto-fixer")

# Fixer success
add_task_activity(task_id, "note", "Auto-fix: PASS - Fixed [issue]")

# Fixer failure
add_task_activity(task_id, "note", "Auto-fix: FAIL - Unable to fix after 3 attempts")
```

#### Skip Auto-Fix

To disable auto-fix for a specific session:

```bash
# Add flag to arguments
/pokayokay:work semi-auto --skip-auto-fix
```

Or set in configuration:
```json
{
  "work": {
    "auto_fix": false
  }
}
```

### 4.6 Browser Verification (Conditional)

After the implementer completes, check if browser verification should run.

#### Testability Checks

All three conditions must pass:

1. **Browser tools available**: Check for Playwright MCP (`mcp__plugin_playwright_*`) or Chrome extension tools
2. **Server running**: HTTP server on ports 3000-9999, or can be started via package.json
3. **Renderable files changed**: Task modified `.html`, `.css`, `.tsx`, `.jsx`, `.vue`, `.svelte`, or files in `components/`, `views/`, `ui/`, `pages/`

If any check fails, silently skip to Step 5 (Review).

#### Verification Flow

If all checks pass:

1. Dispatch browser verifier:
   ```
   Task tool:
     subagent_type: "pokayokay:yokay-browser-verifier"
     description: "Browser verify: {task.title}"
     mode: "bypassPermissions"
     prompt: [Include task details, server URL, changed files]
   ```

2. Process verification result:
   - **PASS**: Continue to Step 5 (Review)
   - **ISSUE**: Re-dispatch implementer with visual/functional issues
   - **SKIP**: User provided reason, continue with warning flag

3. Log activity:
   ```
   add_task_activity(task_id, "note", "Browser verification: PASS/ISSUE/SKIP")
   ```

#### Detection Pseudocode

```python
def should_verify_browser(task, changed_files):
    # Check 1: Browser tools
    has_playwright = any_tool_matches("mcp__plugin_playwright_*")
    has_chrome = any_tool_matches("mcp__claude-in-chrome__*")
    if not (has_playwright or has_chrome):
        return False, "No browser tools"

    # Check 2: Server running
    server = detect_server([3000, 9999])
    if not server and not can_start_server():
        return False, "No server"

    # Check 3: Renderable files
    renderable_exts = ['.html', '.css', '.scss', '.tsx', '.jsx', '.vue', '.svelte']
    renderable_paths = ['components/', 'views/', 'ui/', 'pages/']

    has_renderable = any(
        f.endswith(tuple(renderable_exts)) or
        any(p in f for p in renderable_paths)
        for f in changed_files
    )
    if not has_renderable:
        return False, "No UI changes"

    return True, server
```

#### Advisory Behavior

This is advisory, not blocking:
- User can skip with a reason
- Skip reason is logged in task notes
- Work continues to review with warning flag

See `skills/browser-verification/SKILL.md` for full details.

### 5. Task Review (Two-Stage)

After implementer completes, run spec compliance and code quality reviews sequentially:

#### Task Context for Review Hooks

No setup needed. When the task moved to `in_progress`, the bridge recorded its
id in the task state file (`.pokayokay/pokayokay-task-state.json`), and the
post-review-fail hook reads the active task from there to capture failures and
integrate with kaizen automatically.

Do NOT try to `export CURRENT_OHNO_TASK_ID` from a Bash call — every Bash tool
call is a fresh shell and hooks are spawned by the runtime, so an exported
variable can never reach the hook process.

#### Stage 1: Spec Compliance Review (Adversarial)

1. Dispatch spec reviewer:
   ```
   Task tool:
     subagent_type: "pokayokay:yokay-spec-reviewer"
     description: "Spec review: {task.title}"
     prompt: [Fill template from agents/templates/spec-review-prompt.md]
   ```

   Fill `{IMPLEMENTATION_SUMMARY}` from the implementer's ohno handoff (`get_task_handoff(task_id)`), NOT from its inline report — the inline report is minimal; the AC verification table lives in the handoff details. Fill `{COMMIT_HASH}` with the bare hash from the implementer's commit (the template's `git diff` commands depend on it).

2. Process result:
   - **PASS**: Proceed to Stage 2 (quality review)
   - **FAIL**: Re-dispatch implementer with spec issues (skip quality review)

**What the spec reviewer checks:**
- All acceptance criteria met against actual code (not implementer's claims)
- No missing requirements
- No scope creep (extra work = FAIL)

#### Stage 2: Code Quality Review

Only runs if spec review passes.

1. Dispatch quality reviewer:
   ```
   Task tool:
     subagent_type: "pokayokay:yokay-quality-reviewer"
     description: "Quality review: {task.title}"
     mode: "bypassPermissions"
     prompt: [Fill template from agents/templates/quality-review-prompt.md]
   ```

   Fill `{APPROACH}` with the design-review approach stored in Step 3.7, or `None — design review was skipped` when the gate was skipped. Also fill `{COMMIT_HASH}` (bare hash) for the template's `git diff` commands.

2. Process result:
   - **PASS**: Proceed to task completion (Step 6)
   - **FAIL**: Re-dispatch implementer with quality issues

**What the quality reviewer checks:**
- Code structure, readability, appropriate abstractions
- Test quality, edge case coverage
- Project conventions compliance
- Design compliance (post-check): did the implementation follow the pre-validated approach from Step 3.7? (N/A when design review was skipped)

#### Review Failure Hook Integration

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
outcome:

**1. AUTO Action (High Confidence)**

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

**2. SUGGEST Action (Medium Confidence)**

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

Coordinator behavior:
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

**3. LOGGED Action (Low Confidence)**

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

**Hook Integration Flow:**

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

#### Review Loop

```
┌──────────────┐
│ Implementer  │
│  completes   │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Run Tests   │
└──────┬───────┘
       │
   ┌───┴───┐
   │       │
  PASS    FAIL
   │       │
   │   ┌───┴──────────────┐
   │   │                  │
   │  Spike?         Auto-fix?
   │   │                  │
   │  YES                YES
   │   │                  │
   │   ▼                  ▼
   │  Log           Dispatch Fixer
   │   │            (max 3 attempts)
   │   │                  │
   │   │             ┌────┴────┐
   │   │             │         │
   │   │           PASS       FAIL
   │   │             │         │
   │   │             │         ▼
   │   │             │    Block Task
   │   │             │    Get Next
   └───┴─────────────┘         │
       │                       │
       ▼                  ┌────┘
┌──────────────┐          │
│ UI changes?  │  NO      │
│              │─────┐    │
└──────┬───────┘     │    │
       │ YES         │    │
       ▼             │    │
┌──────────────┐     │    │
│   Browser    │ISSUE│    │
│   Verify     │────►│    │
└──────┬───────┘     │    │
       │ PASS/SKIP   │    │
       ▼             ▼    │
┌──────────────┐  ┌──────┴────┐
│ Task Review  │  │Re-dispatch│
│(two-stage)│  │implementer│
└──────┬───────┘  └─────▲─────┘
       │ PASS      FAIL │
       │           ┌────┘
       │           │ Review FAIL
       │ ▼
       │ ┌─────────────────┐
       │ │ post-review-    │
       │ │ fail.sh hook    │
       │ └────────┬────────┘
       │          │
       │     ┌────┴─────┬──────────┐
       │     │          │          │
       │     ▼          ▼          ▼
       │ ┌──────┐  ┌────────┐  ┌───────┐
       │ │ AUTO │  │SUGGEST │  │LOGGED │
       │ └───┬──┘  └───┬────┘  └───┬───┘
       │     │         │           │
       │     ▼         ▼           │
       │ ┌────────┐ ┌──────┐      │
       │ │ Create │ │Prompt│      │
       │ │fix task│ │ user │      │
       │ └───┬────┘ └──┬───┘      │
       │     │      yes│ │no      │
       │     │      ┌──┘ │        │
       │     ▼      ▼    ▼        ▼
       │ ┌────────────────────────────┐
       │ │ Block current, get next    │
       │ └────────────────────────────┘
       │              OR
       │ ┌────────────────────────────┐
       └─┤ Re-dispatch implementer    │
         │ (max 3 cycles)             │
         └────────────────────────────┘
       ▼
┌──────────────┐
│   Complete   │
│    Task      │
└──────────────┘
```

**Re-dispatch rules:**
- Include specific issues from review
- Reference original acceptance criteria
- Maximum 3 review cycles (then escalate to human)

#### Logging Reviews to ohno

After review, log activity:
```
add_task_activity(task_id, "note", "Task review: PASS")
```

Or for failures:
```
add_task_activity(task_id, "note", "Task review: FAIL - Missing requirement X")
```

### 6. Complete Task

After reviews pass (Step 5), coordinator:
- Logs activity to ohno
- Triggers post-task hooks

```bash
npx @stevestomp/ohno-cli done <task-id> --notes "What was done"
```

### 7. Checkpoint (based on mode)

#### Sequential Mode

**Supervised** (default):
- PAUSE after every task
- Ask user: Continue / Modify / Stop / Switch task?

**Semi-auto**:
- Log task completion, continue
- PAUSE at story/epic boundaries

**Auto**:
- Log and continue
- Only PAUSE at epic boundaries

**Unattended**:
- Log and continue
- NEVER pause (not even at epic boundaries)
- For overnight/headless runs only
- Requires `--dangerously-skip-permissions` for true unattended execution

#### Parallel Mode

**Supervised** (default):
- PAUSE after each task completes (not waiting for batch)
- Show batch status table
- Ask user: Continue / Modify / Stop / Drain / Resolve conflict?

**Semi-auto**:
- Log each completion
- PAUSE at story/epic boundaries
- Show batch status at pause

**Auto**:
- Log and continue
- PAUSE at epic boundaries
- Show summary at pause

**Unattended**:
- Log and continue
- NEVER pause
- Chain to next session on context pressure

#### Batch Status Table

When pausing in parallel mode, show:

```markdown
## Parallel Batch Status

| Task | Title | Status | Notes |
|------|-------|--------|-------|
| task-001 | User auth | ✓ completed | committed abc123 |
| task-002 | Login endpoint | ✓ completed | committed def456 |
| task-003 | Password hash | ⚠️ conflict | needs resolution |
| task-004 | Session mgmt | ⟳ implementing | agent-xyz |

**Queue**: 3 tasks waiting
**Completed this session**: 5 tasks

Options:
- **continue** / **c**: Keep going
- **drain**: Finish active, don't start new
- **resolve <task>**: Pause to fix conflict
- **stop**: End session now
```

### 8. Repeat
Get next task and continue until:
- No more tasks
- User requests stop
- Checkpoint triggers pause

## Hook System

Hooks execute automatically at lifecycle points:

- **pre-session**: Verifies clean git state (plus pre-flight in unattended mode, crash recovery)
- **pre-task**: Checks blockers, suggests skills, sets up worktree
- **post-task**: Syncs ohno, commits, detects spikes, captures knowledge
- **post-story**: Runs tests, story integration, audit gate
- **post-session**: Final sync, session summary, memory curation, session chaining

Hooks run identically in **every** work mode — mode controls pause points,
not hook behavior. Sync and commit are guaranteed on every task completion.

### Customizing Hooks

There is no per-project hook configuration file — hook routing and action
lists are code-controlled in the plugin's `hooks/actions/bridge.py`. Do not
create `.yokay/hooks.yaml` or similar; nothing reads it.

See `hooks/HOOKS.md` for full documentation.

## Task Completion with Worktree

After task is marked done in ohno, handle worktree lifecycle.

### Single Task (no story)

Always prompt on completion:

```markdown
Task 42 complete. What would you like to do?

  1. Merge to [default-branch]
  2. Create Pull Request
  3. Keep worktree (continue later)
  4. Discard work

Which option?
```

**Option handling:**

1. **Merge to default branch**
   ```bash
   git checkout [default-branch]
   git merge --no-ff [worktree-branch]
   git worktree remove .worktrees/[name]
   git branch -d [worktree-branch]
   ```

2. **Create Pull Request**
   ```bash
   git push -u origin [worktree-branch]
   gh pr create --title "[task-title]" --body "Closes task #[id]"
   ```
   Keep worktree for PR review/iteration.

3. **Keep worktree**
   Do nothing, worktree remains available.

4. **Discard work**
   ```bash
   git worktree remove --force .worktrees/[name]
   git branch -D [worktree-branch]
   ```

### Task Within Story

Commit and continue, don't prompt:

```markdown
Task 42 complete (part of Story 12).

  ✓ Committed to story-12-user-auth branch

Story has 2 more tasks remaining.
Continue with next task? [Y/n]
```

### Story Completion

When all tasks in story are done, prompt:

```markdown
Story 12 complete (3/3 tasks done).

  1. Merge to [default-branch]
  2. Create Pull Request
  3. Keep worktree
  4. Discard work

Which option?
```

### Integration with ohno Boundary Metadata

When `update_task_status` returns boundary metadata:

```javascript
const result = await mcp.ohno.update_task_status(taskId, 'done');

if (result.boundaries) {
  if (result.boundaries.story_completed) {
    // Story is complete, show story completion prompt
    await handleStoryCompletion(result.boundaries.story);
  } else if (result.boundaries.epic_completed) {
    // Epic is complete (rare), show epic completion prompt
    await handleEpicCompletion(result.boundaries.epic);
  }
}
```

### In-Place Work (no worktree)

If working in-place (chore, docs, or --in-place flag):
- No worktree prompts
- Standard commit flow
- No merge/PR prompts

## Session End

### 1. Update Session Notes
Use ohno MCP to log:
- What was accomplished
- Any blockers encountered
- Recommended next steps

### 2. Report to User
- Tasks completed this session
- Current project status
- Next recommended task

*Post-session hooks handle final sync, summary, and chain spawning.*

### 3. Session Chaining (if headless)

When session ends with remaining work in scope:

1. SessionEnd hook calls `session-chain.sh`
2. Script checks remaining ready tasks via ohno
3. If tasks remain and chain limit not reached:
   - Spawns/prepares the next session using the active runtime, for example `claude -p "/work --continue <scope-flag>"` or `codex --prompt="/work --continue <scope-flag>"`
4. If chain complete or limit reached:
   - Generates report to `.ohno/reports/chain-{id}-report.md`
   - Notifies via configured method
   - Deletes chain state file

#### Chain State File

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

### 4. Chain Completion Audit

When all tasks in scope are done, the chain runs a completeness audit before declaring success.

#### How It Works

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

#### Chain State Fields

The following fields are added to the chain state for audit tracking:

```json
{
  "audit_pending": false,
  "audit_passed": false
}
```

- `audit_pending`: Set to `true` by bridge.py when all tasks done but audit not yet run
- `audit_passed`: Set to `true` by coordinator when audit passes. Passed to session-chain.sh as `CHAIN_AUDITED`

## Modes Reference

| Mode | Task Complete | Story Complete | Epic Complete | Scope Required | Chaining |
|------|--------------|----------------|---------------|----------------|----------|
| supervised | PAUSE | PAUSE | PAUSE | No | No |
| semi-auto | log | PAUSE | PAUSE | No | No |
| auto | skip | log | PAUSE | Yes | Yes (headless) |
| unattended | skip | skip | skip | Yes | Yes (headless) |

## Spike Task Protocol

When working on a spike task:

### 1. Time-Box Reminder
At session start, announce time limit:
```markdown
## Spike: [Question]
**Time Box**: [hours from task estimate]
**Started**: [timestamp]
**Must Conclude By**: [timestamp + time-box]
```

### 2. Checkpoint at 50%
Halfway through time-box, assess progress:
```markdown
## Spike Checkpoint (50%)
**Progress**: [summary of findings so far]
**On Track?**: Yes / No / Pivoting
**Remaining Time**: [hours]
```

### 3. Mandatory Conclusion
At time-box end, MUST produce decision:
- **GO**: Create implementation tasks from findings
- **NO-GO**: Document why not feasible, close spike
- **PIVOT**: Create new spike with adjusted question
- **MORE-INFO**: (Rare) Create follow-up spike, max 1 re-spike

### 4. Output Location
Save spike report to `.claude/spikes/[name]-[date].md`

## Bug Discovery During Work

If you discover a bug while working on a feature:

### Minor Bugs (< 30 min fix)
1. Fix immediately
2. Add to current commit with note
3. Continue with original task

### Larger Bugs
1. Log in ohno: `npx @stevestomp/ohno-cli create "Bug: [description]" -t bug -p P1`
2. Continue with original task
3. Address bug in future `/pokayokay:work` session

### Blocking Bugs
1. Block current task: `npx @stevestomp/ohno-cli block <task-id> "Blocked by bug"`
2. Create bug task with P0 priority
3. Switch to bug fix immediately

## Headless Examples

```bash
# Work through an entire epic autonomously (pauses at epic boundary)
/work auto --epic epic-4fcd1e3c

# Work on one story, chaining if needed
/work auto --story story-2f3c465d -n 2

# Continue from a previous chained session
/work --continue --epic epic-4fcd1e3c

# Interactive with scope (no chaining, just filters tasks)
/work semi-auto --epic epic-4fcd1e3c

# Overnight unattended run (NEVER pauses, for headless CLI use)
# Run with your active runtime's non-interactive mode, for example:
# claude -p --dangerously-skip-permissions "/work unattended -n auto --all"
# codex --prompt="..."
/work unattended -n auto --all
```

## Related Commands

- `/pokayokay:plan` - Create tasks before working
- `/pokayokay:handoff` - End session with context preservation
- `/pokayokay:audit` - Check feature completeness
- `/pokayokay:review` - Analyze session patterns
- `/pokayokay:worktrees` - Manage worktrees (list, cleanup, switch, remove)
