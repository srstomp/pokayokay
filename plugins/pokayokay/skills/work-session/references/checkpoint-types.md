# Checkpoint Types Reference

Checkpoints are decision points where the coordinator can pause for human input, flag for review, notify, or continue silently.

## Checkpoint Events

| Event | Trigger | Default |
|-------|---------|---------|
| `task_complete` | After each task finishes | pause |
| `story_complete` | After all tasks in story done | pause |
| `epic_complete` | After all stories in epic done | pause |
| `error_encountered` | Build/test failure | pause |
| `ambiguity_found` | Requirements unclear | pause |
| `scope_change` | New work discovered | pause |
| `dependency_resolved` | Blocker removed | notify |
| `session_limit` | Max tasks/time reached | pause |

## Checkpoint Behaviors

| Behavior | Action | Human Required |
|----------|--------|----------------|
| `pause` | Stop completely, wait for input | Yes |
| `review` | Flag for review, continue | No (later) |
| `notify` | Log message, continue | No |
| `skip` | Silent continue | No |

## Mode Presets

| Event | supervised | semi-auto | auto | unattended |
|-------|-----------|-----------|------|------------|
| task_complete | pause | notify | skip | skip |
| story_complete | pause | pause | notify | skip |
| epic_complete | pause | pause | pause | skip |
| error_encountered | pause | pause | pause | pause |
| ambiguity_found | pause | pause | review | skip |
| scope_change | pause | review | review | skip |

## PAUSE Options

When pausing, present these options:
1. **Continue** — proceed with proposed next step
2. **Modify** — change approach or provide guidance
3. **Switch** — work on something different
4. **Review** — wait while human inspects the work
5. **End** — stop session

## Best Practices

### Checkpoint Frequency

| Project Phase | Recommended Mode |
|---------------|------------------|
| First epic | supervised |
| Established patterns | semi-auto |
| Routine implementation | auto |
| Critical features | supervised |
| Bug fixes | semi-auto |
| Documentation | auto |

### When to Use Each Behavior

- **pause**: Learning new codebase, critical business logic, security-sensitive code, first time doing something
- **review**: Routine implementation, following established patterns, batch review later
- **notify**: Very routine tasks, high confidence, clear acceptance criteria
- **skip**: Extremely routine (formatting, simple refactors), human unavailable

### Avoiding Checkpoint Fatigue

- Start supervised, graduate to semi-auto once patterns established
- Batch similar tasks: "Complete all P0 frontend tasks, then pause"
- Use notify + review later (check periodically)
