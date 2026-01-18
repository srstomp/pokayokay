---
description: Start or continue orchestrated work session
argument-hint: [supervised|semi-auto|autonomous]
skill: project-harness
---

# Work Session Workflow

Start or continue a development session with configurable human control.

**Mode**: `$ARGUMENTS` (default: supervised)

## Session Start

### 1. Get Session Context
Use ohno MCP `get_session_context` to understand:
- Previous session notes
- Current blockers
- In-progress tasks

### 2. Read Project Context
If `.claude/PROJECT.md` exists, read it for:
- Project overview
- Tech stack
- Conventions

### 3. Get Next Task
```bash
npx @stevestomp/ohno-cli next
```
Or use ohno MCP `get_next_task`.

### 4. Start the Task
```bash
npx @stevestomp/ohno-cli start <task-id>
```

## Work Loop

For each task:

### 1. Understand the Task
Read task details via ohno MCP `get_task`.

### 2. Route to Skill (if needed)
Based on task type, load relevant skill for domain knowledge:
- API work → Load `api-design` skill
- UI work → Load `aesthetic-ui-designer` skill
- UX decisions → Load `ux-design` skill

### 3. Implement
Do the work. Make incremental git commits.

### 4. Complete Task
```bash
npx @stevestomp/ohno-cli done <task-id> --notes "What was done"
```

### 5. Checkpoint (based on mode)

**Supervised** (default):
- PAUSE after every task
- Ask user: Continue / Modify / Stop / Switch task?

**Semi-auto**:
- Log task completion, continue
- PAUSE at story/epic boundaries
- Ask user for review

**Autonomous**:
- Log and continue
- Only PAUSE at epic boundaries

### 6. Sync Kanban
```bash
npx @stevestomp/ohno-cli sync
```

### 7. Repeat
Get next task and continue until:
- No more tasks
- User requests stop
- Checkpoint triggers pause

## Session End

### 1. Update Session Notes
Use ohno MCP to log:
- What was accomplished
- Any blockers encountered
- Recommended next steps

### 2. Final Sync
```bash
npx @stevestomp/ohno-cli sync
```

### 3. Report to User
- Tasks completed this session
- Current project status
- Next recommended task

## Modes Reference

| Mode | Task Complete | Story Complete | Epic Complete |
|------|--------------|----------------|---------------|
| supervised | PAUSE | PAUSE | PAUSE |
| semi-auto | log | PAUSE | PAUSE |
| autonomous | skip | log | PAUSE |
