---
description: Analyze completed sessions and identify patterns
skill: session-review
---

# Session Review Workflow

Analyze recent work sessions to identify what went well, what went wrong, and patterns to improve.

## Steps

### 1. Get Session History
Use ohno MCP `get_session_context` or:
```bash
npx @stevestomp/ohno-cli context
```

### 2. Review Completed Tasks
```bash
npx @stevestomp/ohno-cli tasks
```

Check for patterns:
- Tasks that took longer than expected
- Tasks that were blocked
- Tasks completed quickly

### 3. Check Git History
```bash
git log --oneline -20
```

Look for:
- Commit frequency and quality
- Reverts or fixes
- Patterns in commit messages

### 4. Identify What Went Well
- Features completed successfully
- Clean implementations
- Good test coverage
- Smooth handoffs

### 5. Identify What Went Wrong
- Blockers encountered
- Tasks that needed rework
- Missing requirements discovered late
- Context loss between sessions

### 6. Extract Patterns
Document recurring issues:
- Common blockers
- Frequent mistake types
- Areas needing more upfront planning

### 7. Create Improvement Tasks
For systemic issues, create tasks:
```bash
npx @stevestomp/ohno-cli create "Add pre-commit hook for [issue]" -t chore
```

### 8. Report

```markdown
## Session Review

### Completed
- X tasks completed
- Y features shipped

### What Went Well
- [specific wins]

### What Went Wrong
- [specific issues]

### Patterns Identified
- [recurring themes]

### Recommendations
- [actionable improvements]
```

## Usage
Run periodically (e.g., end of day/week) to maintain quality and improve process.
