---
description: Prepare session handoff for next session or agent
---

# Session Handoff Workflow

Summarize current session and prepare context for the next session or agent.

## When to Use
- End of work session
- Before context compaction
- Handing off to different agent/person
- Pausing work for later

## Steps

### 1. Summarize Completed Work
List what was accomplished:
```bash
npx @stevestomp/ohno-cli tasks --status done
```

### 2. Document Current State
For any in-progress task:
```bash
npx @stevestomp/ohno-cli tasks --status in_progress
```

Note:
- What's been done on it
- What remains
- Any decisions made
- Any blockers

### 3. Check for Uncommitted Work
```bash
git status
git diff --stat
```

If uncommitted changes exist:
- Commit with descriptive message, OR
- Document what the changes are for

### 4. Write Handoff Notes
Use ohno MCP to update session notes with:

```markdown
## Session Summary [DATE]

### Completed
- [task-id]: [brief description]

### In Progress
- [task-id]: [what's done, what remains]

### Blockers
- [any blockers encountered]

### Decisions Made
- [any architectural or implementation decisions]

### Next Steps
- [recommended next task]
- [any context the next session needs]
```

### 5. Update ohno
```bash
# If task is partially done, add notes
npx @stevestomp/ohno-cli task <task-id>  # View current state

# Log activity
# (Use ohno MCP log_activity tool)
```

### 6. Sync Final State
```bash
npx @stevestomp/ohno-cli sync
```

### 7. Report to User

```markdown
## Handoff Complete

### Session Summary
- Tasks completed: X
- Tasks in progress: Y
- Blockers: Z

### For Next Session
Run: `/pokayokay:work` to continue

### Recommended Next Task
[task-id]: [description]

### Kanban
`npx @stevestomp/ohno-cli serve`
```

## Automatic Handoff
The `/pokayokay:work` command automatically calls handoff when:
- Session ends normally
- Context is getting full
- User requests pause

## Recovery
Next session can restore context with:
```bash
npx @stevestomp/ohno-cli context
```
Or use ohno MCP `get_session_context`.
