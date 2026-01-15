# Gap Analysis Methodology

Systematic approach to identifying and categorizing gaps between PRD requirements and implementation reality.

## Analysis Process

```
┌─────────────────────────────────────────────────────────────────┐
│                      GAP ANALYSIS FLOW                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  PRD Features ──────┐                                          │
│                     ├──► Compare ──► Gaps ──► Prioritize       │
│  Codebase Scan ─────┘                            │              │
│                                                  ▼              │
│                                           Remediation           │
│                                              Tasks              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Gap Categories

### 1. Implementation Gaps

Feature not implemented at all or partially implemented.

| Gap Type | Description | Detection |
|----------|-------------|-----------|
| **Missing Backend** | No service/API | `find backend -name "*feature*"` returns nothing |
| **Missing Frontend** | No UI components | `find src -name "*Feature*"` returns nothing |
| **Partial Backend** | Some endpoints missing | Compare PRD endpoints vs implemented |
| **Partial Frontend** | Some screens missing | Compare PRD screens vs implemented |

### 2. Integration Gaps

Components exist but aren't connected.

| Gap Type | Description | Detection |
|----------|-------------|-----------|
| **No API Integration** | Frontend doesn't call backend | No fetch/axios calls to endpoint |
| **No Route** | Components not routable | No page/route file |
| **No State Management** | Data not flowing | No hooks/context using the service |
| **Broken Links** | Dead routes | Links to non-existent pages |

### 3. Accessibility Gaps

Feature exists but users can't find/use it.

| Gap Type | Description | Detection |
|----------|-------------|-----------|
| **No Navigation** | Not in menu/nav | No link in navigation components |
| **Hidden Route** | Only via direct URL | Route exists, no links to it |
| **No Search Index** | Can't search for it | Not in search index/algolia |
| **No Onboarding** | Users don't know it exists | No tooltips/guides pointing to it |

### 4. Polish Gaps

Feature accessible but not production-ready.

| Gap Type | Description | Detection |
|----------|-------------|-----------|
| **No Loading State** | Jarring experience | No skeleton/spinner |
| **No Error State** | Confusing failures | No error UI |
| **No Empty State** | Blank screen | No "no data" message |
| **No Mobile** | Desktop only | No responsive styles |
| **No Offline** | Breaks without network | No offline handling |

### 5. Documentation Gaps

Feature works but undocumented.

| Gap Type | Description | Detection |
|----------|-------------|-----------|
| **No Help Article** | Users can't learn | `find docs -name "*feature*"` empty |
| **No API Docs** | Devs can't integrate | No OpenAPI/Swagger |
| **No Changelog** | Users don't know it's new | Not in release notes |
| **No Tooltips** | UI not self-explanatory | No inline help |

---

## Gap Detection Scripts

### Master Audit Script

```bash
#!/bin/bash
# audit-feature.sh - Audit a single feature

FEATURE_NAME=$1
FEATURE_ROUTE=$2  # e.g., /analytics

echo "=== Auditing Feature: $FEATURE_NAME ==="
echo ""

# Backend
echo "## Backend"
BACKEND_FILES=$(find backend server api -name "*${FEATURE_NAME,,}*" -type f 2>/dev/null)
if [ -n "$BACKEND_FILES" ]; then
    echo "✅ Found backend files:"
    echo "$BACKEND_FILES" | sed 's/^/   /'
else
    echo "❌ No backend files found"
fi
echo ""

# Frontend Components
echo "## Frontend Components"
FRONTEND_FILES=$(find src app components -name "*${FEATURE_NAME}*" -type f 2>/dev/null)
if [ -n "$FRONTEND_FILES" ]; then
    echo "✅ Found frontend files:"
    echo "$FRONTEND_FILES" | sed 's/^/   /'
else
    echo "❌ No frontend components found"
fi
echo ""

# Routes
echo "## Routes"
if [ -n "$FEATURE_ROUTE" ]; then
    ROUTE_FILES=$(find app pages src/routes src/screens -type f 2>/dev/null | xargs grep -l "$FEATURE_ROUTE" 2>/dev/null)
    if [ -n "$ROUTE_FILES" ]; then
        echo "✅ Route $FEATURE_ROUTE found in:"
        echo "$ROUTE_FILES" | sed 's/^/   /'
    else
        echo "❌ Route $FEATURE_ROUTE not found"
    fi
fi
echo ""

# Navigation
echo "## Navigation"
NAV_LINKS=$(grep -r "$FEATURE_ROUTE" --include="*.tsx" --include="*.jsx" \
    src/components/*nav* src/components/*Nav* src/components/*sidebar* \
    src/components/*Sidebar* app/layout.tsx app/_layout.tsx 2>/dev/null)
if [ -n "$NAV_LINKS" ]; then
    echo "✅ Found in navigation:"
    echo "$NAV_LINKS" | sed 's/^/   /'
else
    echo "❌ Not found in navigation"
fi
echo ""

# Documentation
echo "## Documentation"
DOC_FILES=$(find docs documentation -name "*${FEATURE_NAME,,}*" -type f 2>/dev/null)
if [ -n "$DOC_FILES" ]; then
    echo "✅ Found documentation:"
    echo "$DOC_FILES" | sed 's/^/   /'
else
    echo "❌ No documentation found"
fi
```

### Batch Audit Script

```bash
#!/bin/bash
# audit-all-features.sh - Audit all features from tasks.db

DB_PATH=".claude/tasks.db"

# Get all epics
sqlite3 "$DB_PATH" "SELECT id, title FROM epics ORDER BY id" | while IFS='|' read -r id title; do
    echo "========================================"
    echo "Feature: $id - $title"
    echo "========================================"
    
    # Extract route guess from title
    ROUTE=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
    
    ./audit-feature.sh "$title" "/$ROUTE"
    echo ""
done > audit-results.txt

echo "Audit complete. Results in audit-results.txt"
```

---

## Gap Scoring

### Severity Matrix

| Gap Type | P0 Feature | P1 Feature | P2 Feature |
|----------|------------|------------|------------|
| Missing Backend | Critical | High | Medium |
| Missing Frontend | Critical | High | Medium |
| No Route | Critical | High | Medium |
| No Navigation | High | Medium | Low |
| No Loading State | Medium | Low | Low |
| No Documentation | Medium | Medium | Low |

### Impact Score

Calculate overall feature health:

```
Impact Score = (Implemented Components / Required Components) × 100

Backend Score:   Services implemented / Services required
Frontend Score:  Components implemented / Components required
Route Score:     Routes implemented / Routes required
Nav Score:       Nav links present / Nav links required
Polish Score:    Polish items done / Polish items required

Overall = Average of all scores
```

### Feature Health Classification

| Score | Classification | Action |
|-------|----------------|--------|
| 90-100% | ✅ Complete | Monitor |
| 70-89% | ⚠️ Almost Ready | Polish tasks |
| 50-69% | 🟡 Partial | Integration work |
| 25-49% | 🟠 Incomplete | Major development |
| 0-24% | 🔴 Not Started | Full implementation |

---

## Comparison Methodology

### PRD to Code Mapping

For each feature in PRD:

```markdown
## Feature: Analytics API

### PRD Requirements
1. REST API for coded data
2. Tableau connector
3. Looker integration docs
4. Webhook notifications
5. Rate limiting & quotas

### Code Evidence

| Requirement | Expected File | Found | Status |
|-------------|---------------|-------|--------|
| REST API | analytics-api.ts | ✓ | ✅ |
| Tableau | tableau-connector.ts | ✓ | ✅ |
| Looker docs | docs/looker.md | ✗ | ❌ |
| Webhooks | webhooks.ts | ✓ | ✅ |
| Rate limiting | rate-limiter.ts | ✓ | ✅ |

### Gaps Identified
1. Missing: Looker integration documentation
```

### Cross-Reference Matrix

```
                    │ Backend │ Frontend │ Route │ Nav │ Docs │ Score
────────────────────┼─────────┼──────────┼───────┼─────┼──────┼───────
F001 Survey Studio  │    ✅    │    ✅     │   ✅   │  ✅  │  ✅   │ 100%
F002 RAG Pipeline   │    ✅    │    ✅     │   ✅   │  ✅  │  ❌   │  80%
F003 Chat Interface │    ✅    │    ✅     │   ✅   │  ✅  │  ✅   │ 100%
...
F028 Analytics API  │    ✅    │    ❌     │   ❌   │  ❌  │  ❌   │  20%
F029 Tenant Isolat. │    ✅    │    ❌     │   ❌   │  ❌  │  ❌   │  20%
F030 Distribution   │    ✅    │    ⚠️     │   ⚠️   │  ❌  │  ❌   │  40%
```

---

## Gap Prioritization

### Priority Factors

1. **Feature Priority**: P0 gaps > P1 gaps > P2 gaps
2. **Gap Type**: Missing > Partial > Polish
3. **User Impact**: Blocking > Degraded > Inconvenient
4. **Effort**: Quick wins first for momentum

### Prioritization Matrix

```
                    Low Effort    │    High Effort
                ──────────────────┼──────────────────
High Impact     │   DO FIRST     │   PLAN NEXT
                │   - Add nav    │   - Build UI
                │   - Add route  │   - Full feature
                ──────────────────┼──────────────────
Low Impact      │   DO LATER     │   CONSIDER
                │   - Polish     │   - Nice to have
                │   - Docs       │   - Refactors
```

### Recommended Order

1. **P0 features missing frontend** → Users can't access core functionality
2. **P0 features missing navigation** → Users can't find core functionality
3. **P1 features missing frontend** → Important features inaccessible
4. **All features missing documentation** → Batch together
5. **Polish items** → Batch by type (all loading states, all error states)

---

## Gap Report Template

### Executive Summary

```markdown
# Feature Gap Analysis

**Project**: [Name]
**Date**: [Date]
**Auditor**: Claude

## Summary

| Status | Count | Percentage |
|--------|-------|------------|
| ✅ Complete | 12 | 40% |
| ⚠️ Accessible | 5 | 17% |
| 🟡 Partial | 5 | 17% |
| 🔴 Backend Only | 8 | 26% |

**Critical Finding**: 8 features (26%) have backend implementation but no user-facing UI.

## Top Priority Gaps

1. **F028 Analytics API** - P0 feature, backend only, needs full frontend
2. **F029 Tenant Isolation** - P0 feature, backend only, needs settings UI
3. **F030 Distribution** - P1 feature, partial frontend, needs QR code UI
```

### Detailed Gap List

```markdown
## All Gaps by Priority

### Critical (Block Launch)

| Feature | Gap Type | Description | Effort |
|---------|----------|-------------|--------|
| F028 | No Frontend | Analytics has no dashboard | 3 days |
| F029 | No Frontend | Tenant settings not exposed | 2 days |

### High (Degraded Experience)

| Feature | Gap Type | Description | Effort |
|---------|----------|-------------|--------|
| F030 | Partial UI | QR code generator missing | 4 hours |
| F022 | No Navigation | Codebook not in sidebar | 1 hour |

### Medium (Missing Polish)

| Feature | Gap Type | Description | Effort |
|---------|----------|-------------|--------|
| F011 | No Empty State | Dashboard shows blank | 2 hours |
| F015 | No Loading | Table has no skeleton | 2 hours |

### Low (Documentation)

| Feature | Gap Type | Description | Effort |
|---------|----------|-------------|--------|
| F028 | No API Docs | Endpoints undocumented | 4 hours |
| F025 | No Help | Slack setup not explained | 2 hours |
```

### Remediation Roadmap

```markdown
## Recommended Remediation Order

### Week 1: Critical Gaps
- [ ] F028: Create analytics dashboard
- [ ] F029: Create tenant settings UI
- [ ] F030: Add QR code generation UI

### Week 2: Navigation & Access
- [ ] Add all missing features to navigation
- [ ] Verify all routes accessible

### Week 3: Polish
- [ ] Add loading states to all data pages
- [ ] Add empty states to all lists
- [ ] Add error handling throughout

### Week 4: Documentation
- [ ] API documentation for external integrations
- [ ] Help articles for complex features
- [ ] Onboarding tooltips for new features
```

---

## Continuous Gap Monitoring

### Automation Ideas

```bash
# Add to CI/CD pipeline
npm run audit:features

# Pre-commit hook
./scripts/check-feature-completeness.sh

# Weekly report
0 9 * * 1 ./scripts/gap-report.sh | mail -s "Weekly Gap Report" team@company.com
```

### Gap Tracking in tasks.db

```sql
-- Add audit metadata to epics
ALTER TABLE epics ADD COLUMN audit_level INTEGER DEFAULT 0;
ALTER TABLE epics ADD COLUMN audit_date TEXT;
ALTER TABLE epics ADD COLUMN audit_gaps TEXT;  -- JSON array

-- Update after audit
UPDATE epics 
SET audit_level = 1,
    audit_date = '2026-01-12',
    audit_gaps = '["no_frontend", "no_navigation", "no_docs"]'
WHERE id = 'epic-028';

-- Query gaps
SELECT id, title, audit_level, audit_gaps
FROM epics 
WHERE audit_level < 4
ORDER BY 
    CASE priority 
        WHEN 'P0' THEN 0 
        WHEN 'P1' THEN 1 
        WHEN 'P2' THEN 2 
        ELSE 3 
    END,
    audit_level;
```

### Dashboard Query

```sql
-- Gap summary for dashboard
SELECT 
    audit_level,
    CASE audit_level
        WHEN 0 THEN 'Not Started'
        WHEN 1 THEN 'Backend Only'
        WHEN 2 THEN 'Frontend Exists'
        WHEN 3 THEN 'Routable'
        WHEN 4 THEN 'Accessible'
        WHEN 5 THEN 'Complete'
    END as level_name,
    COUNT(*) as count,
    GROUP_CONCAT(id) as features
FROM epics
GROUP BY audit_level
ORDER BY audit_level;
```
