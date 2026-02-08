# Cleanup Strategies

## Cleanup Criteria

Worktrees are candidates for cleanup when any of these conditions apply:

| Criteria | Detection | Priority |
|----------|-----------|----------|
| **Merged** | Branch merged to default branch | High — safe to remove |
| **Stale** | No commits in 7+ days AND task done/blocked | Medium — check first |
| **Orphaned** | Task no longer exists in ohno | High — definitely remove |
| **Failed** | Task status is `failed` or discarded | Medium — check for useful work |

### Detection Commands

```bash
# Find merged branches
git branch --merged $(git symbolic-ref refs/remotes/origin/HEAD) | grep -v main

# Check last commit date per worktree
for wt in .worktrees/*/; do
  branch=$(git -C "$wt" rev-parse --abbrev-ref HEAD)
  date=$(git log -1 --format=%ci "$branch" 2>/dev/null || echo "unknown")
  echo "$wt → $branch → $date"
done

# List all worktrees with status
git worktree list --porcelain
```

### Cross-Reference with ohno

For each worktree, extract the task/story ID from the branch name and check status:

```
Branch: story-12-user-auth  → story_id: 12  → ohno: get_story(12)
Branch: task-51-email       → task_id: 51   → ohno: get_task(51)
```

If ohno returns not found, the worktree is orphaned.

## Scheduled Cleanup

Run cleanup periodically to prevent disk bloat:

- **After each work session**: `/pokayokay:worktrees cleanup`
- **Weekly**: Check for stale worktrees during session start
- **Before parallel runs**: Clean up to free disk space

The `post-session` hook can trigger automatic cleanup suggestions when stale worktrees are detected.

## Disk Management

### Monitoring Usage

```bash
# Total worktree disk usage
du -sh .worktrees/

# Per-worktree breakdown
du -sh .worktrees/*/
```

### Reducing Disk Usage

1. **Remove stale worktrees** — biggest savings
2. **Clean up memory symlinks** — worktrees get a symlink at `~/.claude/projects/<worktree-path>/memory` pointing to the main repo memory. Remove these when removing the worktree.
3. **Shared node_modules** — worktrees each install their own dependencies
4. **Git sparse checkout** — for large repos, worktrees can use sparse checkout to only include relevant directories

### Warning Thresholds

| Disk Usage | Action |
|------------|--------|
| < 500 MB | Normal |
| 500 MB – 1 GB | Suggest cleanup |
| > 1 GB | Warn and list largest worktrees |
