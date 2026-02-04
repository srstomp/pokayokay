# Context Efficiency Redesign

**Date:** 2025-02-04
**Status:** Draft
**Scope:** pokayokay, ohno

## Problem Statement

Work sessions are interrupted when the context window fills up, forcing manual restart and losing progress. Analysis of 16,462 sessions over 30 days identified four main context consumers:

1. **Subagent results accumulating** - Each Task tool call returns full output that stays in context
2. **ohno tool verbosity** - Every query returns complete objects even when minimal data is needed
3. **Upfront analysis overhead** - Planning/prioritization consumes context before work begins
4. **Skill/reference loading** - Full skill content loads and stays in context

Additional friction points:
- Batch sizes too ambitious (6+ tasks) for session limits
- No automatic session continuation when context fills
- No auto-retry mechanism for recoverable test failures

## Design Overview

Seven solutions addressing context efficiency and session resilience:

| # | Area | Solution | Impact |
|---|------|----------|--------|
| 1 | Subagent Results | ohno-native handoffs + memory decay | High |
| 2 | ohno Verbosity | Response modes (minimal/standard/full) | Medium |
| 3 | Upfront Analysis | Hook-triggered work queue | Medium |
| 4 | Skill Loading | Lazy loading + scoped skills | Low |
| 5 | Batch Sizing | Adaptive `--parallel` | Medium |
| 6 | Headless Chaining | Auto-spawn sessions on context fill | High |
| 7 | Auto-retry | yokay-fixer agent for test failures | Medium |

## Solution 1: ohno-native Handoffs with Memory Decay

### Problem

Subagents (implementer, spec-reviewer, quality-reviewer) return full output to the coordinator. With 6 tasks × 3 agents = 18 substantial returns per batch, context fills quickly.

### Solution

Store handoff data in ohno's SQLite database instead of returning to coordinator.

#### New Database Table

```sql
task_handoffs (
  task_id TEXT PRIMARY KEY,
  status TEXT,              -- PASS | FAIL | BLOCKED
  summary TEXT,             -- 2-3 sentence outcome
  files_changed JSON,       -- ["src/auth.ts", ...]
  full_details TEXT,        -- complete output (for debugging)
  created_at TIMESTAMP,
  compacted_at TIMESTAMP    -- when summary replaced full_details
)
```

#### New ohno Tools

```
mcp__ohno__set_task_handoff(task_id, status, summary, files_changed, full_details)
  → Returns: {"status": "PASS", "summary": "..."}  # Minimal

mcp__ohno__get_task_handoff(task_id, include_details=false)
  → Returns: summary only by default, full_details on request
```

#### Memory Decay Timeline

| Event | Action |
|-------|--------|
| Task complete | Store full handoff |
| Story complete | Compact: keep summary, discard full_details |
| Epic complete | Archive/delete story handoffs |
| Failed/blocked task | Never auto-compact (preserve for debugging) |

#### Hook Integration

Cleanup triggered by boundary metadata from ohno:

```python
# In bridge.py on update_task_status(done)
if boundaries.story_completed:
    # Archive handoffs for this story
    archive_handoffs(story_id)

if boundaries.epic_completed:
    # Delete archived handoffs for this epic
    cleanup_archive(epic_id)
```

## Solution 2: Work-in-Progress Tracking

### Problem

When context fills mid-task, progress is lost. No way to resume from where work stopped.

### Solution

Continuous WIP updates via hooks (automatic) and agent calls (optional enrichment).

#### Database Changes

```sql
-- Add to tasks table
work_in_progress JSON,      -- continuously updated state
wip_updated_at TIMESTAMP
```

#### WIP Structure

```json
{
  "phase": "testing",
  "files_modified": ["src/auth.ts", "src/types.ts"],
  "uncommitted_changes": true,
  "last_commit": "a1b2c3d",
  "decisions": [
    {"decision": "JWT over sessions", "reason": "Stateless, scales better"}
  ],
  "test_results": {
    "ran": true,
    "passed": 12,
    "failed": 1,
    "failing_test": "auth.test.ts:validateToken expired"
  },
  "errors": [
    {"type": "type_error", "file": "src/auth.ts:42", "message": "..."}
  ],
  "context": "Implementing auth hook for story S-12",
  "next_step": "Fix failing test - token expiry edge case"
}
```

#### Automatic Capture via Hooks

| Tool | Auto-captured to WIP |
|------|---------------------|
| Edit, Write | `files_modified[]`, `uncommitted_changes=true` |
| Bash (test commands) | `test_results{}` |
| Bash (git commit) | `last_commit`, `uncommitted_changes=false` |
| Bash (errors) | `errors[]` |

#### New ohno Tool

```
mcp__ohno__update_task_wip(task_id, wip_data)
  → Merges wip_data into existing WIP
```

Agents can optionally call this to add decisions, context, next_step.

#### Resume Flow

```
New session starts
  → get_session_context() returns tasks with WIP
  → Coordinator displays: "Resuming T-42 from: testing phase, next: fix failing test"
  → Implementer picks up with full context
```

## Solution 3: Response Modes for ohno

### Problem

Every ohno query returns full objects. `get_tasks()` returns complete task data even when listing.

### Solution

Add `fields` parameter to control response verbosity.

#### Modes

| Mode | Fields Returned | Use Case |
|------|-----------------|----------|
| `minimal` | id, title, status | Listing, status checks |
| `standard` | + description, acceptance_criteria | Starting work |
| `full` | + context_summary, handoff_notes, wip | Resuming interrupted work |

#### Defaults

```
get_tasks(fields="minimal")        # Default for lists
get_task(fields="standard")        # Default for single task
get_session_context()              # minimal for lists, standard for suggested_next
```

#### Example

```
get_tasks(status="todo", fields="minimal")
→ [{"id": "T-43", "title": "Add auth", "status": "todo"}, ...]

get_task("T-43", fields="full")
→ Full task with WIP, handoff_notes, context_summary
```

## Solution 4: Hook-triggered Work Queue

### Problem

`/work` spends time analyzing priorities and dependencies before any coding, consuming context for planning.

### Solution

Maintain a pre-computed work queue in ohno, updated via triggers.

#### Database Table

```sql
work_queue (
  task_id TEXT PRIMARY KEY,
  priority_score FLOAT,      -- computed from epic priority, dependencies, age
  batch_group INT,           -- tasks that can run in parallel
  blocked_by JSON,           -- current blockers
  ready BOOLEAN,             -- no unresolved blockers
  computed_at TIMESTAMP
)
```

#### Triggers

| Event | Queue Action |
|-------|--------------|
| `create_task` | Insert with computed priority |
| `update_task_status(done)` | Remove, recompute dependents |
| `update_task_status(blocked)` | Mark not ready, recompute dependents |
| `add_dependency` | Recompute both tasks |
| Epic priority change | Recompute all tasks in epic |

#### New ohno Tool

```
mcp__ohno__get_next_batch(limit=3)
→ [T-42, T-43, T-44]  # Pre-computed, ready to execute
```

#### Result

`/work` calls `get_next_batch()` and starts immediately. No analysis phase.

## Solution 5: Lazy Loading for Skills

### Problem

Skills load full content (SKILL.md + references) that stays in context even when no longer needed.

### Solution

Tiered skill structure with on-demand reference loading.

#### Structure

```
skills/
└── api-design/
    ├── SKILL.md              # Core only (50 lines max)
    ├── quick-reference.md    # Cheatsheet (20 lines)
    └── references/
        ├── rest-conventions.md    # Deep dive - load on demand
        ├── error-handling.md
        └── versioning.md
```

#### Loading Strategy

1. **Core skill** always loads (minimal)
2. **References** loaded only when agent needs specific guidance
3. **Task-type scoping**: Only load skills relevant to current task type

| Task Type | Skills Loaded |
|-----------|---------------|
| `feature` | Core implementation only |
| `api` | api-design (core) |
| `bug` | debugging (core) |
| `test` | testing-strategy (core) |

## Solution 6: Adaptive Batch Sizing

### Problem

Fixed large batches (6+) often fail mid-batch when context fills.

### Solution

Start small, grow on success. Consolidate with `--parallel` flag.

#### Behavior

```
Session starts
├── --parallel 2 (conservative start)
│   └── Completed → increase to 3
├── --parallel 3
│   └── Completed → increase to 4
├── --parallel 4 (max)
│   └── Stay at 4
```

#### Rules

| Condition | Change |
|-----------|--------|
| Batch completes fully | +1 (max 4) |
| Batch interrupted/failed | -1 (min 2) |
| Task blocked mid-batch | No change |
| New session | Reset to 2 |

#### Flags

```
/work -n auto          # Adaptive (default)
/work -n 3             # Fixed at 3
/work -n 1             # Sequential
```

#### Tracking

```sql
session_metrics (
  session_id TEXT,
  batches_completed INT,
  last_batch_size INT,
  last_batch_outcome TEXT,  -- completed | interrupted | failed
  created_at TIMESTAMP
)
```

## Solution 7: Headless Session Chaining

### Problem

When context fills, work stops. Manual restart loses momentum.

### Solution

Auto-spawn new session to continue work queue.

#### Flow

```
Session 1 (headless)
├── Execute work queue
├── Context filling...
├── Save WIP to ohno
├── Exit gracefully
└── Trigger: spawn Session 2

Session 2 (headless)
├── get_session_context() → resume from WIP
├── Continue work queue
└── ...until queue empty
```

#### Session Exit Hook

```bash
# hooks/actions/session-chain.sh
queue_status=$(ohno get-ready-count)
if [ "$queue_status" -gt 0 ]; then
    CHAIN_COUNT=$((CHAIN_COUNT + 1))
    if [ "$CHAIN_COUNT" -lt "$MAX_CHAINS" ]; then
        claude --prompt="/work --continue" --headless
    fi
fi
```

#### Configuration

```json
{
  "headless": {
    "max_chains": 10,
    "report": "on_failure",
    "notify": "terminal"
  }
}
```

#### Safety Controls

- `--epic` or `--story` scope required for headless (prevent runaway)
- `--all` flag for explicit "work on everything"
- Max chains limit (default 10)
- Notification on complete/error

#### Chain Reporting

On chain completion, generate report BEFORE memory decay:

```
.ohno/reports/chain-{id}-report.md

# Session Chain Report
- Tasks completed: 18
- Tasks failed: 1 (details preserved, not compacted)
- Decisions made: [extracted before compacting]
- Next steps: [from blocked/failed tasks]
```

## Solution 8: Auto-retry on Test Failures

### Problem

Test failures block tasks, requiring manual intervention.

### Solution

Lightweight fixer agent that attempts automated fixes.

#### Flow

```
Implementer completes
    ↓
Run tests
    ↓
┌─ Pass → proceed to reviewers
│
└─ Fail → spawn yokay-fixer
            ↓
        Parse failure, edit code, re-run
            ↓
        ┌─ Pass → proceed
        └─ Fail → retry (max 3)
                    ↓
                Max retries → mark blocked, continue queue
```

#### New Agent: yokay-fixer

Lightweight agent focused on:
- Reading test failure output
- Making targeted fix
- Re-running tests

Smaller context than full implementer.

#### Configuration

```json
{
  "work": {
    "max_test_retries": 3,
    "auto_fix": true
  }
}
```

#### Task Type Defaults

| Type | Auto-fix |
|------|----------|
| `bug` | Yes |
| `feature` | Yes |
| `spike` | No (failures are data) |
| `chore` | Yes |

## Deferred: Kaizen Integration

**Decision:** Pause kaizen investment until context efficiency is implemented and measured.

**Rationale:** Most review failures may be context-related, not quality-related. Fix infrastructure first, measure failure rates, then decide if kaizen adds value.

**Revisit criteria:**
- Context efficiency improvements deployed
- 2-4 weeks of usage data
- Review failure rate still high despite good context

## Implementation Phases

### Phase 1: Core Context Efficiency

1. WIP tracking (Solution 2) - continuous state saving
2. Response modes (Solution 3) - reduce ohno verbosity
3. Handoffs + memory decay (Solution 1) - subagent result management

### Phase 2: Session Management

4. Adaptive batch sizing (Solution 6)
5. Headless chaining (Solution 7)
6. `/work --continue` flag

### Phase 3: Optimization

7. Hook-triggered work queue (Solution 4)
8. Lazy skill loading (Solution 5)
9. Auto-retry with yokay-fixer (Solution 8)

### Phase 4: Measurement

- Track context usage per session
- Track batch completion rates
- Track session chain lengths
- Compare before/after review failure rates
- Decide on kaizen based on data

## Components Affected

| Component | Changes |
|-----------|---------|
| **ohno MCP** | New tools, new tables, response modes, triggers |
| **bridge.py** | WIP auto-capture hooks, chain spawning, cleanup triggers |
| **Agent definitions** | Update to use handoffs, optional WIP enrichment |
| **/work command** | `--continue`, `-n`/`--parallel`, adaptive sizing |
| **Skills** | Restructure into core + references |
| **New agent** | yokay-fixer for test failure recovery |

## Success Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Tasks per session | ~4 | 8+ |
| Batch completion rate | ~73% | 95%+ |
| Sessions interrupted mid-task | High | Rare (WIP enables resume) |
| Manual restarts needed | Frequent | Automatic via chaining |
| Context at session end | Full | Managed via decay |
