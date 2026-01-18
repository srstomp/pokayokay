---
description: Audit feature completeness and identify gaps
argument-hint: [feature-name]
skill: product-manager
---

# Feature Audit Workflow

Audit implementation completeness against requirements.

**Feature**: `$ARGUMENTS` (optional - audits all if not specified)

## Steps

### 1. Get Task List
```bash
npx @stevestomp/ohno-cli tasks
```
Or use ohno MCP `get_tasks`.

### 2. Read Project Context
Read `.claude/PROJECT.md` for:
- Expected features
- Success criteria
- Tech stack (to know where to look)

### 3. Scan Codebase
For each feature/task, search for implementation evidence:

**Backend indicators:**
- API routes/endpoints
- Database models/migrations
- Service/controller files

**Frontend indicators:**
- Components/pages
- Route definitions
- Navigation links

### 4. Assign Completeness Levels

| Level | Name | Criteria |
|-------|------|----------|
| L0 | Not Started | No implementation found |
| L1 | Backend Only | API exists, no frontend |
| L2 | Frontend Exists | Component exists, not routable |
| L3 | Routable | Has route, not in navigation |
| L4 | Accessible | In navigation, missing polish |
| L5 | Complete | Fully implemented and accessible |

### 5. Identify Gaps
Document gaps for features below L5:
- Missing routes
- Missing navigation
- Missing error handling
- Missing tests

### 6. Create Remediation Tasks
For each gap, create task in ohno:
```bash
npx @stevestomp/ohno-cli create "Add navigation link for [feature]" -t chore
```

### 7. Report Results

```markdown
## Audit Results

| Feature | Level | Gap |
|---------|-------|-----|
| User Auth | L5 | Complete |
| Dashboard | L3 | Missing nav link |
| Settings | L1 | Backend only |

### Remediation Tasks Created
- task-xxx: Add navigation for Dashboard
- task-yyy: Create Settings UI
```

### 8. Sync Kanban
```bash
npx @stevestomp/ohno-cli sync
```

## Next Steps
- Use `/pokayokay:work` to address remediation tasks
- Re-run `/pokayokay:audit` after fixes
