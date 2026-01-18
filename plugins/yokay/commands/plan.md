---
description: Analyze PRD and create implementation plan with task breakdown
argument-hint: <prd-path>
skill: prd-analyzer
---

# PRD Analysis Workflow

Analyze the PRD at `$ARGUMENTS` and create a structured implementation plan.

## Steps

### 1. Read the PRD
Read and understand the document at the provided path. Extract:
- Project name and description
- Core features and requirements
- Technical constraints
- Success criteria

### 2. Initialize ohno (if needed)
```bash
npx @stevestomp/ohno-cli init
```

### 3. Break Down into Tasks
For each feature identified:
1. Create an epic-level task in ohno
2. Break into stories (user-facing chunks)
3. Break stories into implementable tasks

Use ohno MCP tools:
- `create_task` for each task
- `add_dependency` for task relationships

### 4. Assign Skill Hints
Tag tasks with recommended skills:
- API endpoints → api-design
- User flows → ux-design
- Visual components → aesthetic-ui-designer
- Architecture decisions → architecture-review

### 5. Create Project Context
Create `.claude/PROJECT.md` with:
- Project overview
- Tech stack decisions
- Feature summary with task IDs
- Links to ohno kanban

### 6. Sync and Report
```bash
npx @stevestomp/ohno-cli sync
```

Report to user:
- Total tasks created
- Epic/story breakdown
- Recommended starting point
- Link to kanban board

## Output

After completion:
- Tasks in ohno (view with `npx @stevestomp/ohno-cli tasks`)
- `.claude/PROJECT.md` for session context
- Kanban at `npx @stevestomp/ohno-cli serve`

## Next Step
Use `/pokayokay:work` to start implementation.
