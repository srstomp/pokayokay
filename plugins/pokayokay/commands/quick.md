---
description: Create and immediately start working on a quick task
argument-hint: <task-description>
---

# Quick Task Workflow

Create and immediately work on: `$ARGUMENTS`

**DO NOT dispatch agents. DO NOT read skill references or subagent-dispatch docs. Work inline in this conversation.**

## When to Use

- Bug fixes not in the backlog
- Quick tweaks or improvements
- Support requests
- Small enhancements
- Any work that doesn't warrant full PRD planning

## Steps

### 1. Parse Task Description
From `$ARGUMENTS`, extract:
- **Title**: First sentence or phrase
- **Type**: Infer (bug, feature, chore)
- **Priority**: Default P2 unless urgent language detected

### 2. Create Task (if ohno available)
Use MCP `mcp__ohno__create_task` or:
```bash
npx @stevestomp/ohno-cli create "$TASK_TITLE" -t $TYPE
npx @stevestomp/ohno-cli start <task-id>
```
If ohno is not configured, skip task tracking and just do the work.

### 3. Complexity Check
Before starting, estimate scope. If the work will likely touch **more than 3 files** or require **architectural decisions**, stop and suggest:
> "This looks complex enough for `/fix` (bug) or `/work` (feature). Want to switch?"

If user says continue, proceed inline.

### 4. Work Inline
Do the work directly. Follow this checklist:

- [ ] Write a test first if behavior is changing
- [ ] Implement the change
- [ ] Run tests to verify nothing broke
- [ ] Self-review the diff (`git diff`) — is it minimal and correct?
- [ ] No scope creep — only do what was asked
- [ ] Commit with conventional message

### 5. Complete Task
If ohno task was created:
```bash
npx @stevestomp/ohno-cli done <task-id> --notes "What was done"
```

## Output

```markdown
## Quick Task Done

**Task**: [task-id or "untracked"] - [title]
**Files Changed**: [list]
**Test**: [test added/updated or "no behavior change"]
**Commit**: [hash] [message]
```

## Options

- `--no-start`: Create task but don't start immediately
- `--epic <epic-id>`: Link to specific epic
