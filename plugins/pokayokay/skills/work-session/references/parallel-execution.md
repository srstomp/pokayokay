# Parallel Execution

When running with `--parallel N`, multiple implementers run simultaneously.

## Benefits

| Benefit | Description |
|---------|-------------|
| Throughput | N independent tasks process in ~1x time instead of Nx |
| Resource utilization | Better use of available API capacity |
| Faster feedback | Complete more work per session |

## Tradeoffs

| Tradeoff | Mitigation |
|----------|------------|
| Git conflicts | Auto-rebase, manual fallback |
| No shared learning | Agents already isolated in sequential mode |
| Higher token usage | N concurrent contexts |

## Recommended Settings

| Scenario | Parallel Count |
|----------|----------------|
| Default (safe) | 1 (sequential) |
| Independent tasks | 2-3 |
| Large backlog | 3-4 |
| Maximum | 5 |

## Dependency Handling

The ohno `blockedBy` graph is the safety mechanism:
- Tasks with unmet dependencies are not dispatched
- If Task B depends on Task A, B waits for A to complete
- No additional conflict detection - trust the dependency graph

## Work Loop with Hooks (Parallel)

```
[pre-session hooks]  <- Verify clean state

WHILE tasks remain:
  [pre-task hooks]   <- Check blockers (per task)

  1. Get up to N tasks (ohno)
  2. Filter by dependencies
  3. WORKTREE DECISION (per task) <- Smart defaults or flags
  4. Setup worktrees (if needed)  <- May reuse story worktrees
  5. Dispatch N subagents         <- PARALLEL: single message, N Task tools
  6. Wait for results
  7. Process each result:
     - Reviews (sequential per task)
     - Commit (may conflict)

  [post-task hooks]  <- Per completed task

  8. WORKTREE COMPLETION          <- Per task, based on context
  9. CHECKPOINT based on mode

[post-session hooks] <- Final sync, summary
```
