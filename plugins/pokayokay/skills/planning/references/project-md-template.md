# PROJECT.md Generation

The most important output — shared context for all skills.

## Template

```markdown
# Project: [Name]

## Overview
[1-2 sentence description from PRD]

## Status
- **Phase**: Planning | Design | Implementation | Polish | Launch
- **Created**: [Date]
- **Last Updated**: [Date]
- **Overall Progress**: 0/[N] stories complete

## Metrics
| Metric | Count |
|--------|-------|
| Epics | [N] |
| Stories | [N] |
| Estimated Hours | [N] |
| Estimated Days | [N] |

## Tech Stack
- **Frontend**: [Framework]
- **Backend**: [Framework]
- **Database**: [Database]
- **Hosting**: [Platform]

## Feature Overview

| ID | Feature | Priority | Skill | Status |
|----|---------|----------|-------|--------|
| F001 | [Name] | P0 | [skill] | planned |

## Skill Assignments

| Skill | Features | Status |
|-------|----------|--------|
| api-design | F001, F002 | pending |

## Current Gaps
[Updated by feature-audit after audit]

## Next Actions
1. [First recommended action]

## Key Files
- PRD: [path or "uploaded"]
- Tasks DB: `.claude/tasks.db`
- Kanban: `.claude/kanban.html`

## Session Log
| Date | Session | Completed | Notes |
|------|---------|-----------|-------|
```
