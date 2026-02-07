# Parallel Worktrees

When running tasks in parallel (`-n 2+`), each parallel implementer may need its own worktree.

## How Parallel Worktrees Work

```
Coordinator dispatches 3 tasks in parallel:
├── Task 42 (story-12) → .worktrees/story-12-user-auth/   (existing)
├── Task 55 (standalone) → .worktrees/task-55-fix-nav/     (new)
└── Task 60 (story-15) → .worktrees/story-15-billing/     (new)
```

### Rules

1. **Same-story tasks share a worktree** — never run two same-story tasks in parallel (the dependency graph prevents this)
2. **Different-story tasks get separate worktrees** — no conflicts possible
3. **In-place tasks (chore/docs) serialize** — only one in-place task at a time to avoid conflicts on the same branch

### Conflict Prevention

The coordinator checks before dispatching parallel tasks:

```
For each task pair (A, B) in parallel batch:
  IF A.story_id == B.story_id → SERIALIZE (same worktree)
  IF A.in_place AND B.in_place → SERIALIZE (same branch)
  ELSE → SAFE to parallelize
```

## Worktree Setup for Parallel Tasks

Each implementer agent receives its working directory as part of the dispatch context:

```markdown
{WORKING_DIRECTORY}: /path/to/project/.worktrees/task-55-fix-nav
```

The coordinator creates all needed worktrees BEFORE dispatching the parallel batch.

## Completion Handling

When parallel tasks complete:
- Each implementer commits to its own branch
- Coordinator processes results sequentially
- Worktree disposition prompts are batched (not one per task)

## Disk Considerations

Parallel execution multiplies disk usage:
- 3 parallel tasks = up to 3 active worktrees
- Each worktree includes full working copy + dependencies
- Use `cleanup` after parallel batches to free space
