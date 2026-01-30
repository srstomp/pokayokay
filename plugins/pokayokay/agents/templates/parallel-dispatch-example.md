# Parallel Dispatch Example

When dispatching multiple implementers in parallel, use a SINGLE message with multiple Task tool calls.

## Example: Dispatching 3 Tasks

```
<task1>
Task tool (yokay-implementer):
  description: "Implement: Create user authentication"
  prompt: |
    # Task Implementation Assignment

    **Task ID**: task-001
    **Title**: Create user authentication

    [... full template content ...]
</task1>

<task2>
Task tool (yokay-implementer):
  description: "Implement: Add password hashing"
  prompt: |
    # Task Implementation Assignment

    **Task ID**: task-002
    **Title**: Add password hashing

    [... full template content ...]
</task2>

<task3>
Task tool (yokay-implementer):
  description: "Implement: Create login endpoint"
  prompt: |
    # Task Implementation Assignment

    **Task ID**: task-003
    **Title**: Create login endpoint

    [... full template content ...]
</task3>
```

## Key Points

1. **Single message**: All Task tool calls in ONE response
2. **Independent tasks**: Each agent works in isolation
3. **No shared context**: Agents don't know about each other
4. **Results return together**: Wait for all to complete

## Dependency Handling

Before dispatching, verify:
- Task has no `blockedBy` pointing to non-completed tasks
- Task has no `blockedBy` pointing to in-flight tasks

If Task B depends on Task A:
- Task A dispatched first
- Task B waits until Task A completes
- Then Task B can be dispatched
