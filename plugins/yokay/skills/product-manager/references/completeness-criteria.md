# Feature Completeness Criteria

Detailed definitions for each completeness level and how to assess them.

## Completeness Levels

### Level 0: Not Started

**Definition**: No implementation evidence exists.

**Indicators**:
- No backend service/API
- No frontend components
- No database schema
- No tests
- No documentation

**Assessment**:
```bash
# Search for any mention of feature
grep -ri "feature_name\|featurename" --include="*.ts" --include="*.tsx" .

# If nothing found → Level 0
```

---

### Level 1: Backend Only

**Definition**: Backend implementation exists, but no frontend.

**Indicators**:
- ✅ Service files exist
- ✅ API endpoints defined
- ✅ Database schema (if needed)
- ❌ No frontend components
- ❌ No routes/pages
- ❌ No navigation links

**Assessment**:
```bash
# Backend exists
ls backend/src/services/*feature*.ts
grep -r "feature" backend/src/handlers/

# Frontend missing
find src app pages -name "*feature*" -type f 2>/dev/null  # Empty
grep -r "feature" --include="*.tsx" src/components/       # Empty
```

**Evidence Template**:
```markdown
### Backend Evidence
- [x] Service: `backend/src/services/analytics-api.ts`
- [x] Handler: `backend/src/handlers/analytics/index.ts`
- [x] Schema: `analytics` table in `schema.prisma`

### Frontend Evidence
- [ ] No components found
- [ ] No route/page found
- [ ] No navigation link found
```

---

### Level 2: Frontend Exists

**Definition**: Frontend components exist but aren't routed/accessible.

**Indicators**:
- ✅ Backend complete
- ✅ Frontend components exist
- ❌ No route/page
- ❌ No navigation link
- ❌ Components not imported anywhere

**Common Causes**:
- Components built but never integrated
- Feature built then de-prioritized
- Work in progress abandoned

**Assessment**:
```bash
# Components exist
find src/components -name "*Analytics*" -type f

# But no route
find app pages src/routes -name "*analytics*" 2>/dev/null  # Empty

# And not imported
grep -r "AnalyticsComponent\|from.*analytics" --include="*.tsx" src/pages/ src/app/  # Empty
```

**Evidence Template**:
```markdown
### Frontend Components
- [x] `src/components/analytics/AnalyticsChart.tsx`
- [x] `src/components/analytics/AnalyticsTable.tsx`

### Integration
- [ ] No page imports these components
- [ ] No route defined
- [ ] Components are orphaned
```

---

### Level 3: Routable

**Definition**: Route exists but not in navigation.

**Indicators**:
- ✅ Backend complete
- ✅ Frontend complete
- ✅ Route/page exists
- ✅ Manually visiting URL works
- ❌ No navigation link
- ❌ Users can't discover it

**Common Causes**:
- Forgot to add to nav
- Intentionally hidden (admin only)
- Waiting for launch

**Assessment**:
```bash
# Route exists
cat app/analytics/page.tsx  # File exists and has content

# Not in navigation
grep -r "/analytics" --include="*.tsx" src/components/nav/ app/layout.tsx  # Empty

# Not linked from anywhere
grep -r 'href="/analytics"\|to="/analytics"' --include="*.tsx" .  # Empty or minimal
```

**Evidence Template**:
```markdown
### Route
- [x] Page: `app/analytics/page.tsx`
- [x] URL `/analytics` works when typed directly

### Navigation
- [ ] Not in main navigation/sidebar
- [ ] Not linked from dashboard
- [ ] Only accessible via direct URL
```

---

### Level 4: Accessible

**Definition**: Feature is in navigation and users can reach it.

**Indicators**:
- ✅ Backend complete
- ✅ Frontend complete
- ✅ Route exists
- ✅ In navigation
- ✅ Users can discover and use it
- ❌ No documentation
- ❌ Missing polish (error states, loading, empty)

**Assessment**:
```bash
# In navigation
grep -r "/analytics" --include="*.tsx" src/components/Navigation.tsx app/layout.tsx
# Found: <Link href="/analytics">Analytics</Link>

# Has content
wc -l app/analytics/page.tsx  # Substantial content

# Missing docs
find docs -name "*analytics*" 2>/dev/null  # Empty
```

**Evidence Template**:
```markdown
### Accessibility
- [x] Route: `/analytics`
- [x] Navigation: In sidebar under "Reports"
- [x] Link text: "Analytics Dashboard"

### Polish
- [ ] No loading skeleton
- [ ] No empty state
- [ ] Error handling basic
- [ ] Not documented
```

---

### Level 5: Complete

**Definition**: Feature is fully complete and production-ready.

**Indicators**:
- ✅ Backend complete
- ✅ Frontend complete
- ✅ Route exists
- ✅ In navigation
- ✅ Error states handled
- ✅ Loading states
- ✅ Empty states
- ✅ Documentation exists
- ✅ Tests pass

**Assessment**:
```bash
# All previous checks pass, plus:

# Has loading state
grep -r "loading\|isLoading\|skeleton" app/analytics/page.tsx

# Has error state
grep -r "error\|Error\|catch" app/analytics/page.tsx

# Has empty state
grep -r "empty\|no.*found\|NoData" app/analytics/page.tsx

# Has documentation
cat docs/features/analytics.md

# Has tests
find . -name "*analytics*.test.tsx" -o -name "*analytics*.spec.tsx"
```

**Evidence Template**:
```markdown
### Complete Checklist
- [x] Backend service
- [x] Frontend components
- [x] Route/page
- [x] Navigation link
- [x] Loading state
- [x] Error handling
- [x] Empty state
- [x] Documentation
- [x] Tests passing
```

---

## Platform-Specific Completeness

### Web Application

| Aspect | Requirements |
|--------|--------------|
| Desktop | Full functionality |
| Tablet | Responsive, touch-friendly |
| Mobile | Responsive or mobile-specific UI |
| Browsers | Chrome, Firefox, Safari, Edge |

**Assessment**:
```bash
# Check for responsive styles
grep -r "@media\|sm:\|md:\|lg:" --include="*.tsx" --include="*.css" app/analytics/

# Check for mobile-specific components
find . -name "*mobile*" -path "*analytics*"
```

### Mobile Application (React Native/Expo)

| Aspect | Requirements |
|--------|--------------|
| iOS | Works on iPhone/iPad |
| Android | Works on Android phones/tablets |
| Offline | Graceful degradation or sync |
| Permissions | Required permissions documented |

**Assessment**:
```bash
# Check for platform-specific code
grep -r "Platform.OS\|Platform.select" --include="*.tsx" src/screens/Analytics*

# Check for offline handling
grep -r "NetInfo\|offline\|isConnected" --include="*.tsx" src/
```

### API/CLI Tool

| Aspect | Requirements |
|--------|--------------|
| Endpoints | All documented |
| Authentication | Properly secured |
| Rate limiting | Implemented |
| Versioning | API version in URL/header |

---

## Evidence Collection Templates

### Backend Evidence

```markdown
## Backend: [Feature Name]

### Services
| File | Status | Notes |
|------|--------|-------|
| `backend/src/services/analytics.ts` | ✅ | Main service |
| `backend/src/services/analytics-export.ts` | ✅ | Export helpers |

### API Endpoints
| Method | Path | Handler | Status |
|--------|------|---------|--------|
| GET | `/api/analytics` | `getAnalytics` | ✅ |
| POST | `/api/analytics/export` | `exportAnalytics` | ✅ |

### Database
| Table/Model | Status | Notes |
|-------------|--------|-------|
| `analytics_events` | ✅ | Main table |
| `analytics_aggregates` | ✅ | Cached aggregates |

### Tests
| File | Passing | Coverage |
|------|---------|----------|
| `analytics.test.ts` | ✅ | 85% |
```

### Frontend Evidence

```markdown
## Frontend: [Feature Name]

### Components
| Component | Location | Status |
|-----------|----------|--------|
| `AnalyticsDashboard` | `src/components/analytics/` | ✅ |
| `AnalyticsChart` | `src/components/analytics/` | ✅ |
| `AnalyticsFilters` | `src/components/analytics/` | ✅ |

### Route
| Path | File | Status |
|------|------|--------|
| `/analytics` | `app/analytics/page.tsx` | ✅ |
| `/analytics/[id]` | `app/analytics/[id]/page.tsx` | ❌ |

### Navigation
| Location | Link Text | Status |
|----------|-----------|--------|
| Sidebar | "Analytics" | ❌ Not present |
| Dashboard | "View Analytics" | ✅ |

### API Integration
| Endpoint | Hook/Function | Status |
|----------|---------------|--------|
| GET /api/analytics | `useAnalytics()` | ✅ |
| POST /api/analytics/export | `useExportAnalytics()` | ❌ Not connected |
```

### User Accessibility Evidence

```markdown
## Accessibility: [Feature Name]

### Discoverability
| Method | Status | Notes |
|--------|--------|-------|
| Main navigation | ❌ | Not in sidebar |
| Search | ❌ | Not indexed |
| Dashboard link | ✅ | "View Analytics" card |
| Documentation | ❌ | No help article |

### UX States
| State | Status | Notes |
|-------|--------|-------|
| Loading | ✅ | Skeleton screen |
| Empty | ❌ | Shows blank |
| Error | ⚠️ | Generic error only |
| Offline | ❌ | Not handled |

### Responsive
| Viewport | Status |
|----------|--------|
| Desktop (1200px+) | ✅ |
| Tablet (768px) | ✅ |
| Mobile (375px) | ⚠️ | Scrolling issues |
```

---

## Completeness Assessment Workflow

### Step 1: Identify Feature Scope

```markdown
## Feature: F028 Analytics API

**From PRD**:
- REST API for coded data
- Tableau connector
- Looker integration docs
- Webhook notifications
- Rate limiting & quotas

**Expected Components**:
- Backend: analytics-api.ts, tableau-connector.ts, webhooks.ts
- Frontend: /analytics page, dashboard widgets, settings UI
- Docs: API reference, integration guides
```

### Step 2: Scan for Evidence

```bash
# Backend
find backend -name "*analytics*" -o -name "*tableau*" -o -name "*webhook*"

# Frontend
find src app -name "*analytics*" -o -name "*Analytics*"

# Routes
grep -r "/analytics" --include="*.tsx" app/ pages/ src/routes/

# Navigation
grep -r "analytics" --include="*.tsx" src/components/nav/ app/layout.tsx

# Docs
find docs -name "*analytics*"
```

### Step 3: Map Evidence to Checklist

```markdown
| Component | Expected | Found | Status |
|-----------|----------|-------|--------|
| analytics-api.ts | ✓ | ✓ | ✅ |
| tableau-connector.ts | ✓ | ✓ | ✅ |
| /analytics route | ✓ | ✗ | ❌ |
| Navigation link | ✓ | ✗ | ❌ |
| API docs | ✓ | ✗ | ❌ |
```

### Step 4: Assign Level

```markdown
## Assessment

**Evidence Summary**:
- Backend: 5/5 components ✅
- Frontend: 0/3 components ❌
- Navigation: Not present ❌
- Documentation: Not present ❌

**Level**: 1 - Backend Only

**Gap Summary**:
- No frontend route
- No navigation link
- No API documentation
- No integration guides
```

### Step 5: Generate Remediation

```markdown
## Remediation Tasks

### High Priority
1. Create `/analytics` page with dashboard
2. Add "Analytics" to main navigation

### Medium Priority
3. Create Tableau integration docs
4. Create Looker integration docs

### Lower Priority
5. Add loading skeleton to dashboard
6. Add empty state for no data
7. Add help article for Analytics
```

---

## Quick Level Assessment

### Decision Tree

```
Feature mentioned in codebase?
├── No → Level 0 (Not Started)
└── Yes
    └── Backend service exists?
        ├── No → Level 0
        └── Yes
            └── Frontend components exist?
                ├── No → Level 1 (Backend Only)
                └── Yes
                    └── Route/page exists?
                        ├── No → Level 2 (Frontend Exists)
                        └── Yes
                            └── In navigation?
                                ├── No → Level 3 (Routable)
                                └── Yes
                                    └── Fully polished?
                                        ├── No → Level 4 (Accessible)
                                        └── Yes → Level 5 (Complete)
```

### Quick Commands

```bash
# Level 0-1: Backend check
ls backend/src/services/*feature* 2>/dev/null && echo "L1+" || echo "L0"

# Level 1-2: Frontend check
find src app -name "*Feature*" -type f 2>/dev/null | grep -q . && echo "L2+" || echo "L1"

# Level 2-3: Route check
find app pages src/routes -name "*feature*" 2>/dev/null | grep -q . && echo "L3+" || echo "L2"

# Level 3-4: Navigation check
grep -r "/feature" src/components/*nav* app/layout.tsx 2>/dev/null | grep -q . && echo "L4+" || echo "L3"

# Level 4-5: Polish check
grep -r "loading\|error\|empty" app/feature/ 2>/dev/null | grep -q . && echo "L5" || echo "L4"
```
