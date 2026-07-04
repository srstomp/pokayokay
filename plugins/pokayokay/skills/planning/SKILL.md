---
name: planning
argument-hint: "[path-to-prd]"
description: Use when analyzing PRD documents, concept briefs, or feature specs to create implementation plans, breaking work into epics/stories/tasks with dependencies and estimates, or generating PROJECT.md and kanban tracking.
disable-model-invocation: true
---

# PRD Analyzer & Implementation Planner

Transform product requirements into actionable implementation plans with visual kanban tracking.

## When NOT to Use

- **Revising an existing plan** — Use `plan-revision` for modifying task hierarchies or scope changes
- **Starting implementation** — Use `work-session` to begin executing tasks from a plan
- **Quick one-off tasks** — Use `/quick` for tasks that don't need epic/story/task hierarchy
- **Investigating feasibility** — Use `spike` for time-boxed technical investigation before committing to a plan

## Key Principles

- Plan state lives in ohno (`.ohno/`, epics → stories → tasks managed via MCP tools/CLI); `.claude/PROJECT.md` holds the project overview
- Break work into epic → story → task hierarchy (tasks ≤ 8h each)
- Assign skills to features based on type (api-design, database-design, etc.)
- Flag ambiguities before planning — don't assume unclear requirements

## Quick Start Checklist

1. Read the full PRD/brief document
2. Extract goals, features, constraints, and dependencies
3. Classify priorities (P0-P3) and flag ambiguities
4. Break features into epics → stories → tasks with estimates
5. Create the epic/story/task hierarchy in ohno via MCP tools and write `.claude/PROJECT.md`
6. Identify first skill to run and hand off

## Skill Assignment

| Feature Type | Primary Skill | Secondary Skills |
|--------------|---------------|------------------|
| REST/GraphQL APIs | api-design | testing-strategy |
| Database schemas | database-design | — |
| SDK/library | sdk-development | — |
| Auth/Security | api-design | — |
| Testing infrastructure | testing-strategy | — |
| AWS/Cloud provisioning | cloud-infrastructure | — |
| Serverless/Lambda | cloud-infrastructure | api-design |
| Container deployment | cloud-infrastructure | ci-cd |

## References

| Reference | Description |
|-----------|-------------|
| [prd-analysis.md](references/prd-analysis.md) | Deep dive on document analysis |
| [task-breakdown.md](references/task-breakdown.md) | Detailed breakdown methodology |
| [kanban-setup.md](references/kanban-setup.md) | Legacy pre-ohno kanban generation (reference only — plan state lives in ohno) |
| [skill-routing.md](references/skill-routing.md) | Skill assignment logic |
| [project-md-template.md](references/project-md-template.md) | PROJECT.md template and format |
| [database-schema.md](references/database-schema.md) | ohno internal SQLite schema (reference only — manage via MCP tools/CLI, never write the DB directly) |
| [features-json.md](references/features-json.md) | Legacy pre-ohno features.json format (reference only) |
| [anti-patterns.md](references/anti-patterns.md) | Analysis, breakdown, and output anti-patterns |
| [design-integration.md](references/design-integration.md) | Design plugin detection, UI/UX workflows, design-first routing |
| [kanban-template.html](references/kanban-template.html) | HTML template for interactive kanban board |

## Runtime Notes

- **Claude Code**: dispatch yokay-planner via the Task tool with `subagent_type: "pokayokay:yokay-planner"`.
- **Codex**: there is no subagent dispatch. Execute the agent's role inline — read the corresponding `agents/yokay-<name>.md` and follow its Behavioral Defaults, Critical Rules, and Output Contract directly in the current session.
