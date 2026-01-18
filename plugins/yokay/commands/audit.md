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

**Dimension 1: User Accessibility (L0-L5)** - Default

| Level | Name | Criteria |
|-------|------|----------|
| L0 | Not Started | No implementation found |
| L1 | Backend Only | API exists, no frontend |
| L2 | Frontend Exists | Component exists, not routable |
| L3 | Routable | Has route, not in navigation |
| L4 | Accessible | In navigation, missing polish |
| L5 | Complete | Fully implemented and accessible |

**Dimension 2: Testing Coverage (T0-T4)**

| Level | Name | Criteria |
|-------|------|----------|
| T0 | No Tests | No test files exist |
| T1 | Unit Only | Unit tests present, no integration |
| T2 | Integration | Unit + integration tests |
| T3 | E2E | E2E tests for critical paths |
| T4 | Full Coverage | >80% coverage, all test types |

**Dimension 3: Documentation (D0-D4)**

| Level | Name | Criteria |
|-------|------|----------|
| D0 | Undocumented | No docs or comments |
| D1 | Code Comments | Inline comments only |
| D2 | README | Feature has README section |
| D3 | API Docs | OpenAPI/JSDoc generated |
| D4 | User Docs | End-user documentation exists |

**Dimension 4: Security (S0-S4)**

| Level | Name | Criteria |
|-------|------|----------|
| S0 | Not Assessed | No security review done |
| S1 | Basic | Input validation present |
| S2 | Auth | Authentication/authorization implemented |
| S3 | Audited | Security audit completed |
| S4 | Hardened | All security best practices applied |

**Dimension 5: Observability (O0-O4)**

| Level | Name | Criteria |
|-------|------|----------|
| O0 | None | No logging or monitoring |
| O1 | Basic Logging | console.log or basic logger |
| O2 | Structured | Structured logging with levels |
| O3 | Metrics | Metrics exported (Prometheus, etc.) |
| O4 | Full | Logging, metrics, tracing, alerting |

### 4.1 Dimension Flags

Support dimension-specific audits:
```bash
# Quick audit (accessibility only, default)
/yokay:audit [feature-name]

# Specific dimension
/yokay:audit --dimension testing
/yokay:audit --dimension security
/yokay:audit --dimension observability
/yokay:audit --dimension docs

# Full audit (all dimensions)
/yokay:audit --full
```

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

### Summary (Full Audit)
| Dimension | Average | Lowest Feature |
|-----------|---------|----------------|
| Accessibility | L4 | Settings (L1) |
| Testing | T2 | Dashboard (T0) |
| Documentation | D2 | API (D1) |
| Security | S2 | Settings (S0) |
| Observability | O1 | All (O1) |

### By Feature
| Feature | L | T | D | S | O | Priority Gaps |
|---------|---|---|---|---|---|---------------|
| Auth | L5 | T3 | D3 | S3 | O2 | - |
| Dashboard | L3 | T0 | D2 | S1 | O1 | Testing, Navigation |
| Settings | L1 | T1 | D1 | S0 | O0 | All dimensions |

### Remediation Tasks Created
- task-xxx: Add tests for Dashboard (T0 → T2)
- task-yyy: Security audit for Settings
- task-zzz: Add structured logging to all services
```

### 7.1 Route Remediation Tasks to Skills

When creating remediation tasks, assign appropriate skills:

| Gap Type | Skill | Task Type |
|----------|-------|-----------|
| Testing below T2 | testing-strategy | chore |
| Security below S2 | security-audit | security |
| Observability below O2 | observability | chore |
| Documentation below D2 | documentation | docs |
| Accessibility below L4 | ux-design | chore |

### 8. Sync Kanban
```bash
npx @stevestomp/ohno-cli sync
```

## Related Commands

- `/yokay:work` - Address remediation tasks
- `/yokay:plan` - Re-plan features with major gaps
- `/yokay:review` - Analyze audit patterns over time
