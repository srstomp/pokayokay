---
description: View and manage hook configuration
argument-hint: [list|history|toggle]
---

# Hook Management

View the yokay hook system. Hooks are registered via the plugin's
`hooks/hooks.json` and routed by `hooks/actions/bridge.py` — all routing and
action lists are code-controlled in bridge.py, not user configuration.

**Action**: `$ARGUMENTS` (default: list)

## Actions

### list (default)
Show all hooks and the actions they run, based on the actual bridge.py routing:

```markdown
## Active Hooks

| Hook | Trigger | Actions |
|------|---------|---------|
| pre-session | Session start | verify-clean, pre-flight (unattended), recover (if crashed) |
| pre-task | Task moved to in_progress | check-blockers, suggest-skills, setup-worktree |
| post-task | Task marked done | sync, commit, detect-spike, capture-knowledge |
| post-story | All tasks in story done | test, story-integration, audit-gate |
| post-epic | All stories in epic done | audit-gate |
| on-blocker | Blocker set on task | notification |
| pre-commit | Before git commit/add | lint (advisory), check-ref-sizes (blocking) |
| post-command | Audit skill completes | verify-tasks |
| post-review | Reviewer reports FAIL | failure tracking, graduate-rules, post-review-fail (if present) |
| post-session | Session ends | sync, session-summary, curate-memory, session-chain |
| file-change | Edit/Write tool use | WIP tracking (files modified) |
| bash-complete | Bash tool use | WIP tracking (tests, commits, errors) |
```

### history
Show recent hook executions. There is no persistent hook log file — hook
results are emitted inline as additional context after each triggering tool
call. To review recent executions, scan the current session transcript for
`## Hooks:` blocks and summarize them:

```markdown
## Recent Hook Executions (this session)

| Hook | Actions | Status |
|------|---------|--------|
| post-task | sync, commit, detect-spike, capture-knowledge | success |
| pre-task | check-blockers, suggest-skills, setup-worktree | success |
| pre-session | verify-clean | warning |
```

Persistent side effects worth checking: `.pokayokay/wip-state.json` (WIP
tracking), `.pokayokay/pokayokay-review-failures.json` (review failure
tracking), `.claude/rules/pokayokay/` (graduated rules).

### toggle
Per-hook enable/disable is **not currently supported**. Hook behavior is
hardcoded in `bridge.py`; there is no `.yokay/hooks.yaml` or other per-project
override file (nothing reads one).

If asked to disable hooks, explain the actual options:
- **Disable everything**: uninstall or disable the pokayokay plugin.
- **Skip a single commit's pre-commit checks**: not supported via config;
  the lint action is advisory-only already, and only `check-ref-sizes`
  (oversized skill reference files) blocks.
- Custom behavior requires editing `bridge.py` / `hooks/actions/` in a fork.

## Hook Reference

### Lifecycle Hooks

| Hook | Trigger | Actions |
|------|---------|---------|
| pre-session | Session start | verify-clean, pre-flight (unattended mode), recover (if crash detected) |
| pre-task | Task moved to in_progress | check-blockers, suggest-skills, setup-worktree |
| post-task | Task marked done | sync, commit, detect-spike, capture-knowledge |
| post-story | Story boundary reached | test, story-integration, audit-gate (run in story worktree) |
| post-epic | Epic boundary reached | audit-gate |
| on-blocker | Blocker set on task | notification |
| pre-commit | Before git commit/add | lint (advisory), check-ref-sizes (blocking) |
| post-command | Audit skill completes | verify-tasks |
| post-review | Reviewer Task reports FAIL | failure tracking, graduate-rules, post-review-fail (if present in project) |
| post-session | Session ends | sync, session-summary, curate-memory, session-chain |
| file-change | Edit/Write tool use | WIP tracking |
| bash-complete | Bash tool use | WIP tracking |

Hooks run identically in every work mode — mode controls pause points (and
the unattended-mode pre-flight check), not which hooks fire.

### Intelligent Hook Actions

| Action | Hook | Purpose |
|--------|------|---------|
| suggest-skills | pre-task | Suggest relevant skills based on task content |
| setup-worktree | pre-task | Create/reuse git worktree based on task type |
| detect-spike | post-task | Detect uncertainty signals, suggest spike conversion |
| capture-knowledge | post-task | Auto-suggest docs for spike/research tasks |
| audit-gate | post-story, post-epic | Check quality thresholds at boundaries |
| check-ref-sizes | pre-commit | Block commits adding >500-line skill reference files |
| curate-memory | post-session | Enforce MEMORY.md section budgets |
| session-chain | post-session | Decide whether a headless chain continues |
| graduate-rules | post-review | Promote recurring review failures to `.claude/rules/` |

## Configuration

Hook behavior is code-controlled in `bridge.py`. There is no per-project hook
override file. Session chaining behavior (max chains, report/notify modes) is
the one configurable area, via `.pokayokay/config.json` (legacy:
`.claude/pokayokay.json`) — see `hooks/HOOKS.md`.

### Environment Variables Passed to Actions

| Variable | Hooks | Description |
|----------|-------|-------------|
| TASK_ID | pre-task, post-task | Current task ID |
| TASK_TITLE | pre-task, post-task | Current task title |
| TASK_TYPE | pre-task, post-task | feature\|bug\|chore\|docs\|spike |
| TASK_NOTES | post-task | Notes from task completion |
| STORY_ID / EPIC_ID | pre-task, post-task | Parent story/epic IDs |
| STORY_COMPLETED / EPIC_COMPLETED | post-task | Boundary flags from ohno |
| BOUNDARY_TYPE | audit-gate | story\|epic |
| WORKTREE_DIR | post-story actions | Story worktree path (when it exists) |
| FORCE_WORKTREE / FORCE_INPLACE | pre-task | Worktree override flags from the task state file |
| MEMORY_DIR | suggest-skills, curate-memory | Project memory directory |

## Troubleshooting

### Hooks Not Firing
1. Verify the pokayokay plugin is installed and enabled (hooks register via the plugin's `hooks/hooks.json`)
2. Verify ohno MCP is connected (task lifecycle hooks key off `mcp__ohno__update_task_status`)
3. Run `echo '{}' | python3 <plugin>/hooks/actions/bridge.py` to check the bridge executes

### Hook Errors
- Hooks are fail-safe by default
- Warnings don't stop the session
- Only exit code 2 from a pre-commit action blocks (check-ref-sizes)
- Hook results appear inline in the session as additional context; there is no separate log file

## Related

- `/pokayokay:work` - Main work loop using hooks
- `hooks/HOOKS.md` - Full hook system documentation
