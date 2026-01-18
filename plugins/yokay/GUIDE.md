# Yokay Command Guide

This guide explains how yokay commands work together to orchestrate AI-assisted development.

## Command Overview

| Command | Purpose | Primary Skill |
|---------|---------|---------------|
| `/yokay:plan` | Analyze PRD, create tasks | prd-analyzer |
| `/yokay:work` | Execute work sessions | project-harness |
| `/yokay:audit` | Check feature completeness | product-manager |
| `/yokay:review` | Analyze session patterns | session-review |
| `/yokay:handoff` | Prepare session handoff | session-review |
| `/yokay:api` | Design REST/GraphQL APIs | api-design |
| `/yokay:ux` | Design user flows | ux-design |
| `/yokay:ui` | Create visual designs | aesthetic-ui-designer |
| `/yokay:arch` | Review architecture | architecture-review |
| `/yokay:quick` | Quick task + immediate work | - |
| `/yokay:fix` | Bug diagnosis and fix | - |
| `/yokay:spike` | Time-boxed investigation | spike |
| `/yokay:hotfix` | Production incident response | - |
| `/yokay:cicd` | CI/CD pipelines | ci-cd-expert |
| `/yokay:db` | Database design | database-design |
| `/yokay:test` | Testing strategy | testing-strategy |
| `/yokay:research` | Deep research | deep-research |
| `/yokay:security` | Security audit | security-audit |
| `/yokay:observe` | Observability | observability |
| `/yokay:docs` | Documentation | documentation |
| `/yokay:a11y` | Accessibility audit | accessibility-auditor |
| `/yokay:sdk` | SDK development | sdk-development |
| `/yokay:persona` | User personas | persona-creation |
| `/yokay:marketing` | Marketing pages | marketing-website |
| `/yokay:integrate` | API integration | api-integration |

## Command Relationships

```
                          ┌─────────────────────────────────────┐
                          │              /plan                   │
                          │    (PRD Analysis + Task Creation)    │
                          └──────────────┬──────────────────────┘
                                         │
                    ┌────────────────────┼────────────────────┐
                    │                    │                    │
                    ▼                    ▼                    ▼
           ┌───────────────┐    ┌───────────────┐    ┌───────────────┐
           │   /api        │    │    /ux        │    │    /arch      │
           │ (API Design)  │    │  (UX Design)  │    │ (Architecture)│
           └───────┬───────┘    └───────┬───────┘    └───────────────┘
                   │                    │
                   │                    ▼
                   │            ┌───────────────┐
                   │            │     /ui       │
                   │            │(Visual Design)│
                   │            └───────────────┘
                   │
                   └─────────────────┬─────────────────────────────┐
                                     │                             │
                                     ▼                             │
                          ┌─────────────────────────────────────┐  │
                          │              /work                   │  │
                          │    (Implementation with Skills)      │◄─┘
                          └──────────────┬──────────────────────┘
                                         │
              ┌──────────────────────────┼──────────────────────────┐
              │                          │                          │
              ▼                          ▼                          ▼
     ┌───────────────┐        ┌───────────────┐        ┌───────────────┐
     │    /audit     │        │   /handoff    │        │   /review     │
     │ (Completeness)│        │(Session End)  │        │ (Analysis)    │
     └───────┬───────┘        └───────────────┘        └───────────────┘
             │
             └──────────► Creates remediation tasks ──────► /work
```

## Ad-Hoc Commands

For work that doesn't fit the PRD-to-task flow:

### Quick Tasks
```bash
/yokay:quick "add logout button to header"
```
Creates task, starts work immediately, marks done when complete.

### Bug Fixes
```bash
/yokay:fix "login fails with special characters"
/yokay:fix T045  # Fix existing bug task
```
Structured diagnosis → fix → test workflow.

### Production Incidents
```bash
/yokay:hotfix "500 errors on /api/users"
```
Expedited fix with mitigation-first approach, optional postmortem.

### Technical Spikes
```bash
/yokay:spike "Can we use Redis for session storage?"
```
Time-boxed investigation with mandatory decision output (GO/NO-GO/PIVOT).

## Typical Workflow

### 1. Planning Phase
```bash
/yokay:plan path/to/prd.md
```
- Analyzes PRD and creates tasks in ohno
- Tags tasks with recommended skills
- Creates `.claude/PROJECT.md` for context

### 2. Work Phase
```bash
/yokay:work supervised   # Pause after every task
/yokay:work semi-auto    # Pause at story boundaries
/yokay:work autonomous   # Pause at epic boundaries
```
- Routes to appropriate skills based on task type
- Handles spike tasks with time-boxing
- Creates incremental git commits

### 3. Quality Phase
```bash
/yokay:audit            # Check accessibility (L0-L5)
/yokay:audit --full     # Check all dimensions
```
- Multi-dimensional auditing:
  - Accessibility (L0-L5)
  - Testing (T0-T4)
  - Documentation (D0-D4)
  - Security (S0-S4)
  - Observability (O0-O4)

### 4. Session Management
```bash
/yokay:handoff          # End session, save context
/yokay:review           # Analyze patterns and improvements
```

## Skill Routing

The `/work` command routes to skills based on task type, or use direct commands:

| Task Type | Skill | Direct Command |
|-----------|-------|----------------|
| API endpoints | api-design | `/yokay:api` |
| UI components | aesthetic-ui-designer | `/yokay:ui` |
| User flows | ux-design | `/yokay:ux` |
| Database work | database-design | `/yokay:db` |
| CI/CD | ci-cd-expert | `/yokay:cicd` |
| Testing | testing-strategy | `/yokay:test` |
| Security | security-audit | `/yokay:security` |
| Monitoring | observability | `/yokay:observe` |
| Investigation | spike | `/yokay:spike` |
| Research | deep-research | `/yokay:research` |
| Documentation | documentation | `/yokay:docs` |
| Accessibility | accessibility-auditor | `/yokay:a11y` |
| SDK/Packages | sdk-development | `/yokay:sdk` |
| User personas | persona-creation | `/yokay:persona` |
| Marketing pages | marketing-website | `/yokay:marketing` |
| API integration | api-integration | `/yokay:integrate` |

## Keyword Detection

Tasks are automatically routed based on keywords:

| Keywords | Skill |
|----------|-------|
| database, schema, migration | database-design |
| test, coverage, e2e, playwright | testing-strategy |
| deploy, pipeline, ci/cd | ci-cd-expert |
| security, auth, encryption | security-audit |
| logging, monitoring, metrics | observability |
| spike, investigate, feasibility | spike |
| research, evaluate, compare | deep-research |

## Spike Protocol

For high-uncertainty work:

1. **Time-box**: 2-4 hours default, max 1 day
2. **Checkpoints**: 50% progress review
3. **Decision required**: GO / NO-GO / PIVOT / MORE-INFO
4. **Output**: `.claude/spikes/[name].md`

## Integration with ohno

All commands integrate with the ohno MCP server:
- `create_task` - Create tasks
- `get_next_task` - Get prioritized work
- `update_task_status` - Track progress
- `add_task_activity` - Log work
- `get_session_context` - Resume sessions

View the kanban:
```bash
npx @stevestomp/ohno-cli serve
```
