---
description: List, create, cleanup, switch, or remove worktrees
argument-hint: [list|cleanup|switch <id>|remove <id>]
skill: worktrees
---

# Worktrees Management

Manage git worktrees used for task isolation.

**Command**: `$ARGUMENTS` (default: list)

## Subcommands

### List Worktrees (default)

Show all active worktrees with status.

```bash
git worktree list --porcelain
```

Parse and display:

| Worktree | Task | Status | Last Activity |
|----------|------|--------|---------------|
| story-12-user-auth | task 42 | in_progress | 2 commits, 3h ago |
| task-51-email | task 51 | review | 5 commits, 1d ago |
| story-8-billing | task 38 | blocked | stale (7 days) |

Include:
- Total disk usage: `du -sh .worktrees/`
- Count of worktrees

### Cleanup

Remove stale and merged worktrees.

**Criteria for cleanup:**
1. **Merged**: Branch has been merged to default branch
2. **Stale**: No commits in 7+ days AND task is done/blocked
3. **Orphaned**: Associated task no longer exists in ohno

**Flow:**
1. List candidates with reason
2. Prompt for confirmation
3. Remove each worktree and branch
4. Report freed disk space

```bash
# Check if merged
git branch --merged $(git symbolic-ref refs/remotes/origin/HEAD) | grep <branch>

# Check last commit date
git log -1 --format=%ci <branch>

# Remove worktree
git worktree remove .worktrees/<name>

# Delete branch
git branch -d <branch>  # -D if not merged
```

### Switch

Change to a different worktree.

```bash
/pokayokay:worktrees switch story-12
```

1. Find worktree matching pattern
2. If multiple matches, show selection
3. Output: `cd /path/to/.worktrees/story-12-user-auth`

**Note:** Claude Code cannot change the user's shell directory. Output the `cd` command for user to run, or if in an IDE context, use appropriate navigation.

### Remove

Remove a specific worktree.

```bash
/pokayokay:worktrees remove story-12
```

1. Find worktree matching pattern
2. Check for uncommitted changes
3. If changes exist, prompt: "Worktree has uncommitted changes. Remove anyway?"
4. Remove worktree and optionally branch

## Integration with ohno

Cross-reference worktrees with task status:

```javascript
// For each worktree, get task status
const task = await mcp.ohno.get_task(taskId);
const storyId = extractStoryId(worktreeName);
```

Display task status alongside worktree info.

## Output Examples

### List

```
Active worktrees:

  story-12-user-auth       task 42 in_progress   2 commits, modified 3h ago
  task-51-email-verify     task 51 review        5 commits, modified 1d ago
  story-8-billing          task 38 blocked       stale (7 days)

Total: 3 worktrees, 847 MB disk usage
```

### Cleanup

```
Found 2 worktrees to clean:

  story-8-billing     stale (7 days, no commits)
  task-22-old-fix     merged to main

Remove these worktrees? [Y/n]

  ✓ Removed story-8-billing
  ✓ Removed task-22-old-fix

Freed 234 MB disk space.
```

## Error Handling

- **Worktree not found**: List available worktrees
- **Permission denied**: Suggest running with elevated permissions
- **Uncommitted changes**: Warn and require --force or confirmation
- **Branch in use**: Show which worktree is using it
