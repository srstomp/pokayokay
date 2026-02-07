# Hook Integration

Hooks execute automatically at lifecycle points. Do not call manually.

## Work Loop with Hooks

```
[pre-session hooks]  <- Verify clean state

WHILE tasks remain:
  [pre-task hooks]   <- Check blockers

  1. Get next task (ohno next)
  2. Start task (ohno start <id>)
  3. WORKTREE DECISION         <- Smart defaults or flags
  4. Setup worktree (if needed) <- Create branch, install deps
  5. Extract task context
  6. Dispatch subagent          <- Fresh context per task
  7. Process subagent result

  [post-task hooks]  <- GUARANTEED: sync, commit

  8. WORKTREE COMPLETION        <- Merge/PR/Keep (if worktree)
  9. CHECKPOINT based on mode

[post-session hooks] <- Final sync, summary
```

## Hook Execution Output

When hooks run, you'll see:

```markdown
## Hooks: post-task

| Action | Status | Time |
|--------|--------|------|
| sync | ✓ | 0.3s |
| commit | ✓ | 0.5s |

Continuing...
```

## Mode-Specific Behavior

| Mode | post-task hooks |
|------|-----------------|
| supervised | sync only |
| semi-auto | sync, commit |
| auto | sync, commit, quick-test |

## Hook Failures

Hooks are fail-safe:
- Warnings don't stop the session
- Critical failures pause for human input
- All results logged for review

See `hooks/HOOKS.md` for configuration.

## During Work

For each task:

```markdown
## Task: [task-id] Create grid component

### Plan
- Create responsive grid using CSS Grid
- Support 1-4 column layouts
- Add to component library

### Implementation
[Work happens here]

### Verification
- [ ] Component renders
- [ ] Responsive breakpoints work
- [ ] Exported from index

### Post-Task
Hooks handle: sync, commit (mode-dependent)
Checkpoint triggers based on mode
```

## Ending a Session

```markdown
## Session End Checklist

1. [ ] Session notes logged via ohno
2. [ ] No broken code left
3. [ ] Clear summary of what was done
4. [ ] Clear next steps documented

*Note: post-session hooks handle final sync and summary automatically.*
```
