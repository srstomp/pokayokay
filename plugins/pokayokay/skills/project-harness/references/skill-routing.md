# Skill Routing Reference

Complete mapping of task types, keywords, and work patterns to appropriate skills.

## Routing Priority

Check these in order:

1. **Explicit skill hint** — Task or story may specify a skill in metadata
2. **Task type mapping** — Use `task_type` field from ohno
3. **Keyword analysis** — Parse title/description for domain-specific terms
4. **No match** — Use Claude's general capabilities

## By Task Type

| task_type | Primary Skill | Secondary Skills |
|-----------|---------------|------------------|
| feature | *(use keywords)* | testing-strategy |
| bug | error-handling | testing-strategy |
| spike | spike | deep-research |
| chore | *(use keywords)* | — |
| docs | documentation | — |
| test | testing-strategy | testing-strategy |
| security | security-audit | — |
| performance | performance-optimization | — |
| backend | api-design | api-integration, error-handling |
| database | database-design | — |
| devops | ci-cd-expert | — |
| qa | testing-strategy | testing-strategy |

## By Keywords in Title/Description

| Keywords | Suggested Skill |
|----------|-----------------|
| "API", "endpoint", "REST", "GraphQL", "route" | api-design |
| "integrate", "third-party", "external API", "client", "SDK consume" | api-integration |
| "test", "testing", "spec", "coverage", "TDD" | testing-strategy |
| "API test", "contract test", "integration test", "mock" | testing-strategy |
| "refactor", "architecture", "structure", "module", "boundary" | architecture-review |
| "SDK", "library", "package", "npm publish", "extract" | sdk-development |
| "Figma", "plugin", "design tool" | figma-plugin |
| "security", "audit", "vulnerability", "CVE", "OWASP", "injection" | security-audit |
| "performance", "slow", "optimize", "bundle", "cache", "latency" | performance-optimization |
| "database", "schema", "migration", "query", "index" | database-design |
| "error", "exception", "error handling", "retry", "fallback" | error-handling |
| "logging", "metrics", "tracing", "monitoring", "alerting" | observability |
| "CI", "CD", "pipeline", "deploy", "GitHub Actions", "workflow" | ci-cd-expert |
| "README", "docs", "ADR", "documentation", "user guide" | documentation |
| "PRD", "requirements", "feature spec", "implementation plan" | prd-analyzer |
| "completeness", "gap analysis", "feature audit" | product-manager |
| "worktree", "branch", "isolation" | worktrees |
| "session", "retrospective", "review session" | session-review |

## Multi-Skill Workflows

Some tasks benefit from multiple skills in sequence:

### New API Feature
```
1. api-design         → Design endpoints, schemas
2. api-integration    → If consuming external APIs
3. error-handling     → Error responses and recovery
4. testing-strategy        → Test suite
```

### Security Review
```
1. security-audit     → Scan and classify findings
2. error-handling     → Fix error-related vulnerabilities
3. testing-strategy        → Security regression tests
```

### New Project/Epic Setup
```
1. prd-analyzer       → Create implementation plan
2. architecture-review → Verify structure
3. testing-strategy   → Plan test approach
```

## Skill Invocation Protocol

### 1. Load Skill SKILL.md

Read the skill's SKILL.md to get:
- Key principles and quick start checklist
- Reference table listing available detailed guides

### 2. Load References On-Demand

SKILL.md files are intentionally concise (~50 lines). When you need deeper guidance:
- Read specific reference files from the skill's `references/` directory
- Only load what's needed for the current task
- The reference table in SKILL.md describes what each file contains

### 3. Execute Within Skill Context

Follow the skill's prescribed workflow until task complete.

## When No Skill Matches

1. Check if task is well-defined (vague tasks may need breakdown)
2. Use Claude's general capabilities
3. Ask human for guidance if uncertain
