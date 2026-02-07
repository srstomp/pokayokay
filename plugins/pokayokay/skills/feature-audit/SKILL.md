---
name: feature-audit
description: Audits feature completeness by scanning codebases and comparing against PRD requirements. Identifies gaps between backend implementation and user-facing accessibility. Generates remediation tasks and integrates with planning skill output. Supports multiple frameworks including Next.js, React Router, TanStack, React Native, Expo, and more.
---

# Feature Audit

Ensures features are not just implemented but actually user-accessible. Bridges the gap between "code complete" and "user can use it."

## When NOT to Use

- **Analyzing agent/session patterns** — Use `session-review` for retrospectives on how work went
- **Security review** — Use `security-audit` for vulnerability scanning; this skill checks feature completeness, not security
- **Creating the plan** — Use `planning` to break down PRDs into tasks; this skill audits after implementation

## Completeness Levels

| Level | Name | Meaning |
|-------|------|---------|
| 0 | Not Started | No implementation evidence |
| 1 | Backend Only | Service/API exists, no frontend |
| 2 | Frontend Exists | UI components exist, not accessible |
| 3 | Routable | Has route/screen, not in navigation |
| 4 | Accessible | In navigation, users can reach it |
| 5 | Complete | Accessible + documented + tested |

## Quick Start Checklist

1. Discover project framework and structure
2. Load PRD context from `.claude/features.json` and `tasks.db`
3. For each feature: check backend, frontend, route, navigation
4. Assign completeness level (0-5)
5. Generate report and remediation tasks

## Key Principles

- Always verify in codebase — don't trust task status alone
- Check full accessibility chain: backend → frontend → route → navigation → docs
- Generate specific remediation tasks (not generic "add frontend")
- Priority follows feature priority (P0 gap = P0 remediation)

## References

| Reference | Description |
|-----------|-------------|
| [framework-patterns.md](references/framework-patterns.md) | Scanning patterns for each framework |
| [completeness-criteria.md](references/completeness-criteria.md) | Detailed level definitions and checklists |
| [gap-analysis.md](references/gap-analysis.md) | Analysis methodology |
| [remediation-templates.md](references/remediation-templates.md) | Task templates for common gaps |
| [scanning-process.md](references/scanning-process.md) | Backend, frontend, API, navigation scans |
| [anti-patterns.md](references/anti-patterns.md) | Audit and remediation anti-patterns |
