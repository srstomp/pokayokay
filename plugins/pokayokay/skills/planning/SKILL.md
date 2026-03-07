---
name: planning
agents: [yokay-planner]
description: Use when analyzing PRD documents, concept briefs, or feature specs to create implementation plans with epic/story/task breakdowns, dependency mapping, and skill routing via ohno MCP.
disable-model-invocation: true
---

# PRD Analyzer & Implementation Planner

Transform product requirements into actionable implementation plans using ohno for task management.

## Key Principles

- Break work into epic -> story -> task hierarchy (tasks <= 8h each)
- Create tasks in ohno via MCP (create_epic, create_story, create_task)
- Assign skills to features based on type
- Flag ambiguities before planning -- don't assume unclear requirements

## Quick Start Checklist

1. Read the full PRD/brief document
2. Extract goals, features, constraints, and dependencies
3. Classify priorities (P0-P3) and flag ambiguities
4. Break features into epics -> stories -> tasks with estimates
5. Create hierarchy in ohno via MCP tools
6. Identify first skill to run and hand off

## Skill Assignment

| Feature Type | Primary Skill | Secondary Skills |
|--------------|---------------|------------------|
| REST/GraphQL APIs | api-design | testing-strategy |
| Database schemas | database-design | -- |
| SDK/library | sdk-development | -- |
| Auth/Security | api-design | -- |
| AWS/Cloud provisioning | cloud-infrastructure | -- |
| Container deployment | cloud-infrastructure | ci-cd |

## When NOT to Use

- For revising existing plans -- see plan-revision skill
- For time-boxed investigations -- see spike skill
- For deep research before planning -- see deep-research skill

## References

| Reference | Description |
|-----------|-------------|
| [project-md-template.md](references/project-md-template.md) | PROJECT.md template and format |
| [features-json.md](references/features-json.md) | features.json format and integration points |
| [anti-patterns.md](references/anti-patterns.md) | Analysis, breakdown, and output anti-patterns |
| [design-integration.md](references/design-integration.md) | Design plugin detection, UI/UX workflows |
