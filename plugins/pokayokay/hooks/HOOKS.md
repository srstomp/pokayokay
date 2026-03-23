---
name: hooks
description: Automatic action execution at session lifecycle points. Hooks guarantee critical actions (sync, commit, test) run without relying on LLM memory. Integrated with Claude Code native hooks for guaranteed execution.
---

# Hook System

Guaranteed action execution for reliable automated sessions.

## Architecture

Yokay hooks are now **guaranteed** to execute via Claude Code's native hook system:

```
┌─────────────────────────────────────────────────────────┐
│                    Claude Code                           │
│                                                          │
│  PostToolUse(mcp__ohno__update_task_status)             │
│         │                                                │
│         ▼                                                │
│  ┌─────────────────────────────────────┐                │
│  │         bridge.py                    │                │
│  │  - Parses boundary metadata          │                │
│  │  - Detects story/epic completion     │                │
│  │  - Triggers appropriate hooks        │                │
│  └─────────────────────────────────────┘                │
│         │                                                │
│         ├── post-task  → sync, commit, detect-spike,    │
│         │                 capture-knowledge              │
│         ├── post-story → test, story-integration,       │
│         │                 audit-gate (if story_completed)│
│         └── post-epic  → audit-gate (if epic_completed) │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Why This Matters

Previously, hooks were "soft" - documentation telling the LLM to run them. Now they are "hard" - Claude Code's native hooks guarantee execution regardless of LLM context or memory.

## Quick Reference

| Hook | Trigger | Default Actions |
|------|---------|-----------------|
| pre-session | Session start | verify-clean, pre-flight (unattended), recover (if crashed) |
| pre-task | Task start | check-blockers, suggest-skills, setup-worktree |
| post-task | Task complete | sync, commit, detect-spike, capture-knowledge |
| post-story | Story complete | test, story-integration, audit-gate |
| post-epic | Epic complete | audit-gate |
| on-blocker | Task blocked | notification |
| pre-commit | Before commit | lint, check-ref-sizes |
| post-session | Session end | sync, session-summary, curate-memory, session-chain |
| post-command | After audit commands | verify-tasks |
| post-review | Review FAIL | graduate-rules (failure tracking) |
| file-change | Edit/Write | WIP tracking |
| bash-complete | Bash execution | WIP tracking (tests, commits, errors) |

## Execution

Hooks execute automatically. Do not call manually.

### In Work Loop

```
# The work loop with hooks (simplified)
[pre-session hooks]

WHILE tasks remain:
  [pre-task hooks]

  # Do the work
  get_next_task()
  start_task()
  route_to_skill()
  implement()

  [post-task hooks]  <- sync + commit happen here

  checkpoint()

[post-session hooks]
```

### Hook Output Format

When hooks execute, log them:

```markdown
## Hooks: post-task

| Action | Status | Duration |
|--------|--------|----------|
| sync | ✓ | 0.3s |
| commit | ✓ | 0.5s |

All hooks passed.
```

If a hook fails:

```markdown
## Hooks: post-task

| Action | Status | Duration |
|--------|--------|----------|
| sync | ✓ | 0.3s |
| commit | ⚠️ nothing to commit | 0.1s |

Continuing despite warnings.
```

## Configuration

Hook behavior is controlled by `bridge.py` and the `defaults.yaml` reference. Custom hook actions can be added as shell scripts in `hooks/actions/`.

## Mode Behavior

| Hook | supervised | semi-auto | auto |
|------|------------|-----------|------------|
| post-task | sync | sync, commit | sync, commit, test |
| post-story | — | test, audit | test, audit |
| post-epic | audit | audit | audit, docs |

## Intelligent Hooks

Beyond lifecycle automation, hooks now provide intelligent guidance:

### Worktree Setup (pre-task)
Automatically creates git worktrees for task isolation based on task type:

| Task Type | Default Behavior |
|-----------|------------------|
| `feature`, `bug`, `spike` | Creates worktree in `.worktrees/` |
| `chore`, `docs` | Works in-place (no worktree) |
| Unknown | Creates worktree (safer default) |

**Override flags** (set via environment):
- `YOKAY_FORCE_WORKTREE=true` - Always create worktree
- `YOKAY_FORCE_INPLACE=true` - Never create worktree

**Story worktree reuse**: If a task belongs to a story and a worktree already exists for that story, it will be reused instead of creating a new one.

### Skill Suggestions (pre-task)
Analyzes task title/description to suggest relevant skills beyond the primary routed skill. Detects keywords related to performance, security, accessibility, observability, and testing.

### Spike Detection (post-task)
Monitors task completion notes for uncertainty signals ("not sure", "need to investigate", etc.). When detected, suggests converting to a spike for structured investigation.

### Knowledge Capture (post-task)
For spike and research task types, reminds about expected output files and suggests documentation when GO decisions are made.

### Quality Gates (post-story, post-epic)
Checks quality thresholds at story/epic boundaries:
- Looks for test files (T level)
- Counts TODO/FIXME comments
- Checks for console.log statements (O level)

Outputs warnings when thresholds not met, suggests `/pokayokay:audit` for full assessment.

## Post-Command Hooks

Post-command hooks verify that audit commands created expected tasks. They fire after specific commands complete.

### Configured Commands

| Command | Prefix | Trigger |
|---------|--------|---------|
| `/pokayokay:security` | `Security:` | Always |
| `/pokayokay:test --audit` | `Test:` | With `--audit` flag |
| `/pokayokay:observe --audit` | `Observability:` | With `--audit` flag |
| `/pokayokay:arch --audit` | `Arch:` | With `--audit` flag |

### How It Works

1. Command runs (e.g., `/pokayokay:security auth`)
2. Command creates tasks for findings via ohno MCP `create_task`
3. After command completes, `post-command` hook fires
4. `verify-tasks.sh` checks if tasks with expected prefix exist
5. Warns if no tasks found (may indicate missed task creation)

### Example Output

```markdown
## Hooks: post-command

| Action | Status | Output |
|--------|--------|--------|
| verify-tasks | ✓ | Verified: 3 task(s) created with prefix 'Security:' |

**Summary:** 1 passed, 0 warnings
```

If no tasks were created:

```markdown
## Hooks: post-command

| Action | Status | Output |
|--------|--------|--------|
| verify-tasks | ⚠️ | Warning: No tasks with prefix 'Security:' found |

**Summary:** 0 passed, 1 warnings

Action: If findings were discovered, ensure tasks were created using ohno MCP create_task.
```

## Error Handling

Hooks are **fail-safe**:
- Failures log warnings
- Session continues
- Critical failures (can't sync) pause for human

## Anti-Patterns

| Don't | Do |
|-------|-----|
| Call hooks manually | Let them execute automatically |
| Skip hooks to save time | Trust the system |
| Ignore hook warnings | Review before continuing |

## Claude Code Integration

The yokay hook system integrates with Claude Code's native hooks via `bridge.py`:

### Configured Hooks

| Claude Code Event | Matcher | yokay Hooks Triggered |
|-------------------|---------|----------------------|
| SessionStart | — | pre-session (verify-clean, pre-flight, recover) |
| SessionEnd | — | post-session (sync, session-summary, curate-memory, session-chain) |
| PostToolUse | `mcp__ohno__update_task_status` (done) | post-task, post-story (if boundary), post-epic (if boundary) |
| PostToolUse | `mcp__ohno__update_task_status` (in_progress) | pre-task (check-blockers, suggest-skills, setup-worktree) |
| PostToolUse | `mcp__ohno__set_blocker` | on-blocker |
| PostToolUse | `Task` (reviewers) | token tracking, post-review-fail + graduate-rules (on FAIL) |
| PostToolUse | `Skill` (audit commands) | post-command (verify-tasks) |
| PostToolUse | `Edit` / `Write` | WIP tracking (files modified) |
| PostToolUse | `Bash` | WIP tracking (test results, commits, errors) |
| PreToolUse | `Bash` (git commit/add) | pre-commit (lint, check-ref-sizes) |

### Boundary Metadata

When ohno's `update_task_status` marks a task as `done`, it returns boundary metadata:

```json
{
  "success": true,
  "boundaries": {
    "story_completed": true,
    "epic_completed": false,
    "story_id": "S-45",
    "epic_id": "E-12"
  }
}
```

The bridge script uses this to determine which hooks to run:
- **post-task**: Always runs on task completion
- **post-story**: Runs when `story_completed: true`
- **post-epic**: Runs when `epic_completed: true`

### Files

| File | Purpose |
|------|---------|
| `actions/bridge.py` | Parses Claude Code hook input, routes to yokay hooks |
| `actions/verify-clean.sh` | Checks for uncommitted changes (pre-session) |
| `actions/pre-flight.sh` | Pre-flight validation for unattended mode (pre-session) |
| `actions/recover.sh` | Crash recovery for stale sessions (pre-session) |
| `actions/check-blockers.sh` | Checks for blocked tasks (pre-task) |
| `actions/suggest-skills.sh` | Suggests relevant skills based on task content (pre-task) |
| `actions/setup-worktree.sh` | Creates git worktree for task isolation (pre-task) |
| `actions/sync.sh` | Syncs ohno kanban state |
| `actions/commit.sh` | Smart git commit |
| `actions/detect-spike.sh` | Detects uncertainty signals, suggests spike conversion (post-task) |
| `actions/capture-knowledge.sh` | Auto-suggests docs for spike/research tasks (post-task) |
| `actions/test.sh` | Runs tests (safe, non-blocking) |
| `actions/story-integration.sh` | Story-level integration checks (post-story) |
| `actions/audit-gate.sh` | Checks quality thresholds at boundaries (post-story, post-epic) |
| `actions/verify-tasks.sh` | Verifies audit commands created tasks (post-command) |
| `actions/lint.sh` | Runs linter (pre-commit) |
| `actions/check-ref-sizes.sh` | Blocks commits with >500-line reference files (pre-commit) |
| `actions/session-summary.sh` | Prints session summary with token costs (post-session) |
| `actions/curate-memory.sh` | Enforces MEMORY.md section budgets (post-session) |
| `actions/session-chain.sh` | Handles headless session chaining (post-session) |
| `actions/graduate-rules.sh` | Promotes recurring failures to .claude/rules/ (post-review) |

### Configuration

Hooks are registered through the pokayokay plugin system and routed by `bridge.py`. The plugin registers hook handlers for PostToolUse, PreToolUse, SessionStart, and SessionEnd events.

## Related Commands

- `/pokayokay:hooks` - View and manage hook configuration
- `/pokayokay:work` - Main work loop using hooks
- `/pokayokay:audit` - Full quality assessment (triggered by hooks at boundaries)
