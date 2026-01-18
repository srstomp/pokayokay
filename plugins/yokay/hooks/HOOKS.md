---
name: hooks
description: Automatic action execution at session lifecycle points. Hooks guarantee critical actions (sync, commit, test) run without relying on LLM memory. Integrated with Claude Code native hooks for guaranteed execution.
---

# Hook System

Guaranteed action execution for reliable autonomous sessions.

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
│         ├── post-task  → sync.sh, commit.sh             │
│         ├── post-story → test.sh (if story_completed)   │
│         └── post-epic  → audit (if epic_completed)      │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Why This Matters

Previously, hooks were "soft" - documentation telling the LLM to run them. Now they are "hard" - Claude Code's native hooks guarantee execution regardless of LLM context or memory.

## Quick Reference

| Hook | Trigger | Default Actions |
|------|---------|-----------------|
| pre-session | Session start | verify-clean |
| pre-task | Task start | check-blockers |
| post-task | Task complete | sync, commit |
| post-story | Story complete | test, audit |
| post-epic | Epic complete | full-audit |
| on-error | Error occurs | log, block, recover |
| pre-commit | Before commit | lint, typecheck |
| post-session | Session end | handoff, sync |

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

### Project Override

Create `.yokay/hooks.yaml` to customize:

```yaml
hooks:
  post-task:
    actions:
      - sync
      - commit
      - prisma-generate  # Custom action

  pre-commit:
    enabled: false  # Disable entirely
```

### Adding Custom Actions

Put scripts in `.yokay/hooks/`:

```bash
# .yokay/hooks/prisma-generate.sh
#!/bin/bash
if git diff --name-only | grep -q 'schema.prisma'; then
  npx prisma generate
fi
```

## Mode Behavior

| Hook | supervised | semi-auto | autonomous |
|------|------------|-----------|------------|
| post-task | sync | sync, commit | sync, commit, test |
| post-story | — | test, audit | test, audit |
| post-epic | audit | audit | audit, docs |

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
| PostToolUse | `mcp__ohno__update_task_status` | post-task, post-story (if boundary), post-epic (if boundary) |
| PostToolUse | `mcp__ohno__set_blocker` | on-blocker |
| PreToolUse | `Bash` (git commit) | pre-commit |

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
| `actions/sync.sh` | Syncs ohno kanban state |
| `actions/commit.sh` | Smart git commit |
| `actions/test.sh` | Runs tests (safe, non-blocking) |
| `actions/lint.sh` | Runs linter |
| `actions/recover.sh` | Error recovery |

### Configuration Location

Claude Code hooks are configured in `.claude/settings.local.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "mcp__ohno__update_task_status",
        "hooks": [{
          "type": "command",
          "command": "python3 \"$CLAUDE_PROJECT_DIR/plugins/yokay/hooks/actions/bridge.py\""
        }]
      }
    ]
  }
}
```
