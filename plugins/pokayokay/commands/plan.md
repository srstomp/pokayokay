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

### 3. Create Hierarchical Structure

Use the ohno MCP tools to create a proper epic → story → task hierarchy:

#### 3.1 Create Epics (Major Features)
For each major feature area, create an epic with priority:
```
mcp__ohno__create_epic:
  title: "User Authentication"
  description: "Complete auth system with login, registration, password reset"
  priority: "P0"  # P0=critical, P1=high, P2=medium, P3=low
```

#### 3.2 Create Stories (User-Facing Capabilities)
For each epic, create stories representing user-facing chunks:
```
mcp__ohno__create_story:
  title: "Email/Password Registration"
  epic_id: "<epic_id from step above>"
  description: "Users can create accounts with email and password"
```

#### 3.3 Create Tasks (Implementable Units)
For each story, create tasks (1-8 hours each):
```
mcp__ohno__create_task:
  title: "Create registration form component"
  story_id: "<story_id from step above>"
  task_type: "feature"  # feature, bug, chore, spike, test
  estimate_hours: 4
```

#### 3.4 Add Dependencies
Link tasks that depend on each other:
```
mcp__ohno__add_dependency:
  task_id: "<task that is blocked>"
  depends_on_task_id: "<task that must complete first>"
```

**Important**: Always create in order: epics first, then stories (with epic_id), then tasks (with story_id). This ensures proper relationships.

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
```
mcp__ohno__create_task:
  title: "Spike: Can D1 handle multi-tenant isolation?"
  story_id: "<relevant_story_id>"
  task_type: "spike"
  estimate_hours: 3
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
