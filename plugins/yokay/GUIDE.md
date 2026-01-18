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

The `/work` command routes to skills based on task type:

| Task Type | Skill |
|-----------|-------|
| API endpoints | api-design |
| UI components | aesthetic-ui-designer |
| User flows | ux-design |
| Database work | database-design |
| CI/CD | ci-cd-expert |
| Testing | testing-strategy |
| Security | security-audit |
| Monitoring | observability |
| Investigation | spike |
| Research | deep-research |

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
