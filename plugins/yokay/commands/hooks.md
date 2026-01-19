---
description: View and manage hook configuration
argument-hint: [list|history|toggle]
---

# Hook Management

View and manage the yokay hook system.

**Action**: `$ARGUMENTS` (default: list)

## Actions

### list (default)
Show all configured hooks and their status.

```markdown
## Active Hooks

| Hook | Enabled | Actions |
|------|---------|---------|
| pre-session | yes | verify-clean |
| pre-task | yes | check-blockers, suggest-skills |
| post-task | yes | sync, commit, detect-spike, capture-knowledge |
| post-story | yes | test, mini-audit, audit-gate |
| post-epic | yes | full-audit, audit-gate |
| on-error | yes | log-error, block-task, recover |
| on-blocker | yes | notify, suggest-next |
| pre-commit | yes | lint |
| post-session | yes | final-sync, summary |

Current mode: supervised
```

### history
Show recent hook execution history.

```markdown
## Recent Hook Executions

| Time | Hook | Actions | Status | Duration |
|------|------|---------|--------|----------|
| 10:45 | post-task | sync, commit | success | 0.8s |
| 10:44 | pre-task | check-blockers, suggest-skills | success | 0.3s |
| 10:30 | pre-session | verify-clean | warning | 0.2s |
```

### toggle
Enable/disable specific hooks for debugging.

```markdown
## Toggle Hooks

To temporarily disable a hook, create/update `.yokay/hooks.yaml`:

```yaml
hooks:
  pre-commit:
    enabled: false  # Disable linting for debugging
  post-task:
    actions:
      - sync
      # Remove commit to skip auto-commits
```

Note: Toggle changes are session-scoped unless saved to config.
```

## Hook Reference

### Lifecycle Hooks

| Hook | Trigger | Default Actions |
|------|---------|-----------------|
| pre-session | Session start | verify-clean |
| pre-task | Task moved to in_progress | check-blockers, suggest-skills |
| post-task | Task marked done | sync, commit, detect-spike, capture-knowledge |
| post-story | All tasks in story done | test, mini-audit, audit-gate |
| post-epic | All stories in epic done | full-audit, audit-gate |
| on-error | Error during task | log-error, block-task, recover |
| on-blocker | Blocker set on task | notify, suggest-next |
| pre-commit | Before git commit | lint |
| post-session | Session ends | final-sync, summary |

### Mode-Specific Behavior

| Hook | Supervised | Semi-Auto | Autonomous |
|------|-----------|-----------|-----------|
| post-task | sync only | sync, commit | sync, commit, quick-test |
| post-story | — | test, audit | test, audit |
| post-epic | audit | audit | audit |

### New Hook Actions (v1.1)

| Action | Hook | Purpose |
|--------|------|---------|
| suggest-skills | pre-task | Suggest relevant skills based on task content |
| detect-spike | post-task | Detect uncertainty signals, suggest spike conversion |
| capture-knowledge | post-task | Auto-suggest docs for spike/research tasks |
| audit-gate | post-story, post-epic | Check quality thresholds at boundaries |

## Configuration

### Project-Level Override

Create `.yokay/hooks.yaml` in your project:

```yaml
hooks:
  post-task:
    actions:
      - sync
      - commit
      - my-custom-action  # Add custom action

  pre-commit:
    enabled: false  # Disable for this project
```

### Available Variables

| Variable | Description |
|----------|-------------|
| TASK_ID | Current task ID |
| TASK_TITLE | Current task title |
| TASK_TYPE | feature\|bug\|chore\|spike\|test\|research |
| TASK_NOTES | Notes from task completion |
| STORY_ID | Current story ID |
| EPIC_ID | Current epic ID |
| BOUNDARY_TYPE | story\|epic (for audit-gate) |
| SESSION_MODE | supervised\|semi-auto\|autonomous |

## Troubleshooting

### Hooks Not Firing
1. Check `.claude/settings.json` for hooks configuration
2. Verify ohno MCP is connected
3. Check bridge.py logs for errors

### Hook Errors
- Hooks are fail-safe by default
- Warnings don't stop the session
- Critical failures pause for human input
- Check `.claude/hooks.log` for details

## Related

- `/pokayokay:work` - Main work loop using hooks
- `hooks/HOOKS.md` - Full hook system documentation
