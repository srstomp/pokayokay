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

Tag tasks with recommended skills based on their content:

**Design & UX**:
- User flows, wireframes → ux-design
- Visual components, styling → aesthetic-ui-designer
- User research, personas → persona-creation
- Accessibility requirements → accessibility-auditor

**Backend & API**:
- API endpoints, REST/GraphQL → api-design
- Database schema, migrations → database-design
- Architecture decisions → architecture-review
- Third-party integrations → api-integration

**DevOps & Infrastructure**:
- CI/CD pipelines, GitHub Actions → ci-cd-expert
- Logging, monitoring, alerts → observability

**Quality & Security**:
- Test architecture, coverage → testing-strategy
- Security review, authentication → security-audit

**Investigation**:
- Time-boxed technical questions → spike (task_type: spike)
- Multi-day technology evaluation → deep-research (task_type: research)

### 4.1 Keyword Detection

When skill not explicitly specified, detect from task title/description:

| Keywords | Skill |
|----------|-------|
| database, schema, migration, model, prisma | database-design |
| test, coverage, e2e, playwright, cypress, jest | testing-strategy |
| deploy, pipeline, ci/cd, github actions, release | ci-cd-expert |
| security, auth, encryption, vulnerability, owasp | security-audit |
| logging, monitoring, alert, metrics, tracing | observability |
| spike, investigate, feasibility, can we, how hard | spike |
| research, evaluate, compare, vendor, assessment | deep-research |

### 4.2 Detect Spike Opportunities

For features with high uncertainty, create spike tasks:
- "Can we...?" or "Is it possible to...?" questions
- Performance or feasibility unknowns
- Technology selection decisions
- Complex integration assessments

Example:
```bash
npx @stevestomp/ohno-cli create "Spike: Can D1 handle multi-tenant isolation?" -t spike --estimate 3h
```

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

## Related Commands

- `/pokayokay:work` - Start implementation after planning
- `/pokayokay:audit` - Check feature completeness after implementation
- `/pokayokay:review` - Analyze planning patterns over time
