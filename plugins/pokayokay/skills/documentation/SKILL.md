---
name: documentation
description: Use when creating READMEs, API docs, ADRs, or user guides. Provides templates and patterns for each documentation type. Dispatched by /work for docs-type tasks.
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
---

# Documentation

Create clear, maintainable technical documentation that serves your audience.

## Key Principles

- **Documentation as code** — docs live with code, version with code, review with code
- **Audience-first writing** — write for who's reading, not what you know
- **Maintainability over completeness** — inaccurate docs are worse than no docs
- **Link to source of truth** — don't duplicate information across docs

## Quick Start Checklist

1. Identify documentation type (README, API docs, ADR, user guide)
2. Determine audience (all users, developers, team, contributors)
3. Follow type-specific template from references
4. Include working examples (test them!)
5. Link to related documentation

## Documentation Types

| Type | When to Use | Audience |
|------|-------------|----------|
| README | Project entry point | All users |
| API Docs | Endpoint reference | Developers |
| ADR | Major decisions | Team/future devs |
| User Guide | Task completion | End users |

## When NOT to Use

- **Inline code comments** — Just add comments directly; this skill is for standalone documentation artifacts
- **API design** — Use `api-design` for designing APIs; this skill documents existing APIs

## References

| Reference | Description |
|-----------|-------------|
| [readme-guide.md](references/readme-guide.md) | README templates, section patterns, badges |
| [api-docs.md](references/api-docs.md) | API documentation patterns, OpenAPI integration |
| [adr-guide.md](references/adr-guide.md) | Architecture Decision Record format and workflow |
| [diagrams.md](references/diagrams.md) | Mermaid diagram patterns for common scenarios |
| [readme-template.md](references/readme-template.md) | Template for project README files |
| [adr-template.md](references/adr-template.md) | Template for Architecture Decision Records |
