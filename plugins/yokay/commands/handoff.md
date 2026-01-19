---
description: Prepare session handoff for next session or agent
skill: session-review
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

### 4.1 Skill Usage Summary

Document which skills were used and their outcomes:

```markdown
## Skills Used This Session

| Skill | Tasks | Notes |
|-------|-------|-------|
| api-design | T001, T003 | Designed user endpoints |
| testing-strategy | T002 | Set up Playwright E2E |
| spike | T005 | GO decision on D1 |

### Skills Recommended But Not Used
- security-audit (auth changes were made)
- observability (new API endpoints lack logging)
```

### 4.2 Ad-Hoc Work Tracking

Document work done outside planned tasks:

```markdown
## Ad-Hoc Work

| Type | Description | Time | Task Created? |
|------|-------------|------|---------------|
| Bug fix | Fixed login redirect | 20 min | Yes (T045) |
| Refactor | Extracted auth util | 15 min | No |
| Research | Looked up Prisma syntax | 10 min | No |
```

If significant ad-hoc work (> 30 min total):
1. Create tasks retroactively for tracking
2. Note patterns for future planning
3. Suggest `/pokayokay:review` for pattern analysis

### 4.3 Incomplete Investigation Status

Track spikes and research that span sessions:

```markdown
## Ongoing Investigations

### Spikes (must complete within time-box)
| Spike | Time Used | Time Remaining | Status |
|-------|-----------|----------------|--------|
| Redis caching | 1.5h | 1.5h | Resume next session |

### Deep Research (multi-session)
| Research | Day | Phase | Next Step |
|----------|-----|-------|-----------|
| Auth providers | 2 of 3 | Analysis | Create comparison matrix |
```

**IMPORTANT**: Incomplete spikes should be resumed and completed next session. Do not leave spikes unfinished for > 1 day.

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

## Related Commands

- `/pokayokay:work` - Resume work next session
- `/pokayokay:review` - Analyze completed sessions
- `/pokayokay:plan` - Adjust plan based on findings
- `/pokayokay:audit` - Check feature completeness
