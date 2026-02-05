# ohno Integration

## MCP Tools Available

**Query Tools:**
- `get_session_context()` - Previous session notes, blockers, in-progress tasks
- `get_project_status()` - Overall project statistics
- `get_tasks()` - List all tasks
- `get_task(id)` - Get specific task details
- `get_next_task()` - Recommended next task
- `get_blocked_tasks()` - Tasks with blockers

**Update Tools:**
- `start_task(id)` - Mark task in-progress
- `complete_task(id, notes)` - Mark task done
- `log_activity(message)` - Log session activity
- `set_blocker(id, reason)` - Block a task
- `resolve_blocker(id)` - Unblock a task

## CLI Commands

```bash
# Session management
ohno context              # Get session context
ohno status               # Project statistics

# Task management
ohno tasks                # List all tasks
ohno next                 # Get recommended next task
ohno start <id>           # Start working on task
ohno done <id> --notes    # Complete task with notes
ohno block <id> <reason>  # Set blocker
ohno unblock <id>         # Resolve blocker

# Kanban
ohno serve                # Start kanban server
ohno sync                 # Sync kanban HTML
```
