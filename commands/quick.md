---
description: Create and immediately start working on a quick task
argument-hint: <task-description>
---

# Quick Task Workflow

Create and immediately work on: `$ARGUMENTS`

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

### 2. Check Project Context
If `.claude/PROJECT.md` exists:
- Read current epic/story context
- Link task to current epic if related
- Otherwise create as standalone

### 3. Create Task
```bash
npx @stevestomp/ohno-cli create "$TASK_TITLE" -t $TYPE
```

### 4. Start Task
```bash
npx @stevestomp/ohno-cli start <task-id>
```

### 5. Work on Task
- Route to appropriate skill if task type suggests it:
  - Database work → Load `database-design`
  - API work → Load `api-design`
  - UI work → Load `aesthetic-ui-designer`
  - Testing → Load `testing-strategy`
- Work in supervised mode by default
- Commit incrementally

### 6. Complete Task
```bash
npx @stevestomp/ohno-cli done <task-id> --notes "What was done"
```

## Output

```markdown
## Quick Task Created

**Task**: [task-id] - [title]
**Type**: [bug|feature|chore]
**Linked to**: [epic-id or "standalone"]

Starting work now...
```

## Options

- `--no-start`: Create task but don't start immediately
- `--epic <epic-id>`: Link to specific epic

## Examples

```
/pokayokay:quick Fix the login button alignment
/pokayokay:quick Add loading spinner to dashboard
/pokayokay:quick Update the README with new setup steps
```

## Related Commands

- `/pokayokay:work` - Continue work session after quick task
- `/pokayokay:fix` - Bug-specific workflow with diagnosis
- `/pokayokay:handoff` - End session with context

## Comparison

| Workflow | Use When |
|----------|----------|
| `/pokayokay:quick` | Small ad-hoc work |
| `/pokayokay:fix` | Bug with diagnosis needed |
| `/pokayokay:plan` + `/pokayokay:work` | Planned feature work |
