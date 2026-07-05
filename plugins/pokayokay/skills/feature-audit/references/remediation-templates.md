# Remediation Task Templates

Pre-built task templates for common gaps identified during feature audits.

## Template Usage

When a gap is identified, use these templates to generate properly-structured remediation tasks, created in ohno via `mcp__ohno__create_task` (CLI equivalent: `npx @stevestomp/ohno-cli create "<title>" -t <type>`). Never write ohno's internal database directly.

One call per gap, using the matching markdown template below as the description source:

```
mcp__ohno__create_task({
  story_id: "[story-id]",
  title: "[Remediation] [F0XX]: Create /[route] page",
  description: "Create the main page for [Feature Name] with data fetching, loading, and error states.",
  task_type: "feature",
  estimate_hours: 6
})
```

| Gap | Task Title | task_type | estimate_hours | Story |
|-----|------------|-----------|----------------|-------|
| No frontend route | Create /[route] page | feature | 6 | [Feature] frontend |
| No navigation link | Add [Feature] to navigation | feature | 1 | [Feature] frontend |
| No API integration | Connect [Feature] UI to backend API | feature | 5 | [Feature] frontend |
| No loading state | Add loading skeleton to [Feature] | feature | 2 | [Feature] polish |
| No error state | Add error handling to [Feature] | feature | 3 | [Feature] polish |
| No empty state | Add empty state to [Feature] | feature | 2 | [Feature] polish |
| No documentation | Write help documentation for [Feature] | chore | 3 | [Feature] docs |
| No mobile support | Make [Feature] mobile-responsive | feature | 6 | [Feature] polish |

Prefix titles with `[Remediation] [FEATURE-ID]:` for traceability (see Task Naming Convention below).

---

## Gap: No Frontend Route

### Diagnosis
- Backend service exists
- No page/route file
- Feature not accessible via URL

### Template: Create Route

**For Next.js (App Router):**
```markdown
### Task: Create [Feature] page

**Type**: Frontend
**Estimate**: 4-8 hours
**Priority**: P0

**Description**:
Create the main page for [Feature] at `/[route]`.

**Acceptance Criteria**:
- [ ] Page exists at `app/[route]/page.tsx`
- [ ] Page renders without errors
- [ ] Page fetches data from backend API
- [ ] Loading state implemented
- [ ] Error state implemented

**Files to Create**:
- `app/[route]/page.tsx`
- `app/[route]/loading.tsx` (optional)
- `app/[route]/error.tsx` (optional)

**Dependencies**:
- Backend API must be deployed
```

**For React Router / TanStack:**
```markdown
### Task: Create [Feature] route

**Type**: Frontend
**Estimate**: 4-8 hours

**Description**:
Add route for [Feature] to the router configuration.

**Acceptance Criteria**:
- [ ] Route added to `src/routes.tsx` or `src/routes/[feature].tsx`
- [ ] Component renders at `/[route]`
- [ ] Route has proper loader (if using data loading)

**Files to Create/Modify**:
- `src/routes/[feature].tsx` or `src/pages/[Feature].tsx`
- `src/routes.tsx` (add route entry)
```

**For React Native / Expo:**
```markdown
### Task: Create [Feature] screen

**Type**: Frontend
**Estimate**: 4-8 hours

**Description**:
Create screen for [Feature] and add to navigation.

**Acceptance Criteria**:
- [ ] Screen exists at `src/screens/[Feature]Screen.tsx`
- [ ] Screen registered in navigator
- [ ] Screen accessible via navigation

**Files to Create/Modify**:
- `src/screens/[Feature]Screen.tsx`
- `src/navigation/MainNavigator.tsx` (add screen)
```

---

## Gap: No Navigation Link

### Diagnosis
- Route exists
- Feature works when URL typed directly
- No link in navigation/menu

### Template: Add Navigation

```markdown
### Task: Add [Feature] to navigation

**Type**: Frontend
**Estimate**: 1-2 hours
**Priority**: P1

**Description**:
Add navigation link to [Feature] in the main navigation/sidebar.

**Acceptance Criteria**:
- [ ] Link appears in [location: sidebar/header/tab bar]
- [ ] Link has appropriate icon
- [ ] Link has correct label
- [ ] Active state works when on page
- [ ] Mobile navigation updated (if applicable)

**Files to Modify**:
- `src/components/Navigation.tsx` or `app/layout.tsx`
- `src/components/Sidebar.tsx` (if separate)
- Mobile nav component (if applicable)

**Design Notes**:
- Icon suggestion: [appropriate icon name]
- Position: After [existing item]
- Group: [navigation group if applicable]
```

---

## Gap: No API Integration

### Diagnosis
- Backend API exists
- Frontend components exist
- Components don't call the API

### Template: Connect Frontend to API

```markdown
### Task: Connect [Feature] UI to API

**Type**: Frontend
**Estimate**: 4-6 hours
**Priority**: P0

**Description**:
Wire up the [Feature] frontend components to call the backend API.

**Acceptance Criteria**:
- [ ] API client/service created for [Feature]
- [ ] React Query hooks (or equivalent) implemented
- [ ] Components use the hooks to fetch/mutate data
- [ ] Error handling in place
- [ ] Loading states working

**Files to Create/Modify**:
- `src/services/[feature]-api.ts` (API client)
- `src/hooks/use[Feature].ts` (React Query hooks)
- `src/components/[Feature]/*.tsx` (update to use hooks)

**API Endpoints to Connect**:
- GET /api/[feature] → use[Feature]Query
- POST /api/[feature] → useCreate[Feature]Mutation
- PUT /api/[feature]/:id → useUpdate[Feature]Mutation
- DELETE /api/[feature]/:id → useDelete[Feature]Mutation
```

---

## Gap: No Loading State

### Diagnosis
- Feature works
- No visual feedback during data loading
- Jarring user experience

### Template: Add Loading State

```markdown
### Task: Add loading state to [Feature]

**Type**: Frontend
**Estimate**: 2-3 hours
**Priority**: P2

**Description**:
Add skeleton/loading UI to [Feature] for better UX during data fetching.

**Acceptance Criteria**:
- [ ] Skeleton matches layout of actual content
- [ ] Loading appears during initial load
- [ ] Loading appears during refetch (subtle)
- [ ] No layout shift when content loads

**Implementation Options**:
1. Skeleton components (preferred)
2. Spinner overlay
3. Shimmer effect

**Files to Create/Modify**:
- `src/components/[Feature]/[Feature]Skeleton.tsx` (new)
- `src/components/[Feature]/[Feature].tsx` (add loading check)
- OR `app/[route]/loading.tsx` (Next.js)
```

---

## Gap: No Error State

### Diagnosis
- Feature works in happy path
- Errors result in blank screen or crash
- No recovery options for user

### Template: Add Error Handling

```markdown
### Task: Add error handling to [Feature]

**Type**: Frontend
**Estimate**: 2-4 hours
**Priority**: P1

**Description**:
Add proper error UI and recovery options to [Feature].

**Acceptance Criteria**:
- [ ] API errors display user-friendly message
- [ ] Error UI includes retry option
- [ ] Different error types have appropriate messages
- [ ] Errors are logged (for debugging)
- [ ] Partial errors don't break whole page

**Error Types to Handle**:
- Network error (offline)
- Server error (500)
- Not found (404)
- Unauthorized (401)
- Validation error (400)

**Files to Create/Modify**:
- `src/components/[Feature]/[Feature]Error.tsx` (new)
- `src/components/[Feature]/[Feature].tsx` (add error check)
- OR `app/[route]/error.tsx` (Next.js)
```

---

## Gap: No Empty State

### Diagnosis
- Feature works with data
- Empty/no data shows blank screen
- User confused about what to do

### Template: Add Empty State

```markdown
### Task: Add empty state to [Feature]

**Type**: Frontend
**Estimate**: 2-3 hours
**Priority**: P2

**Description**:
Add helpful empty state when [Feature] has no data.

**Acceptance Criteria**:
- [ ] Empty state explains why there's no data
- [ ] Includes illustration or icon (optional)
- [ ] Includes call-to-action to add first item
- [ ] Matches overall design system

**Content Suggestions**:
- Headline: "No [items] yet"
- Description: "Get started by [action]"
- CTA Button: "Create [item]" or "Import [items]"

**Files to Create/Modify**:
- `src/components/[Feature]/[Feature]Empty.tsx` (new)
- `src/components/[Feature]/[Feature]List.tsx` (add empty check)
```

---

## Gap: No Documentation

### Diagnosis
- Feature works
- Users don't know how to use it
- No help article or tooltips

### Template: Add Documentation

```markdown
### Task: Document [Feature]

**Type**: Documentation
**Estimate**: 2-4 hours
**Priority**: P2

**Description**:
Create help documentation for [Feature].

**Acceptance Criteria**:
- [ ] Help article explains feature purpose
- [ ] Step-by-step usage instructions
- [ ] Screenshots of key actions
- [ ] Common questions answered
- [ ] Linked from feature UI (help icon)

**Content Outline**:
1. What is [Feature]?
2. Getting started
3. [Key action 1]
4. [Key action 2]
5. FAQ / Troubleshooting

**Files to Create**:
- `docs/features/[feature].md`
- Update `docs/index.md` with link
```

---

## Gap: No Mobile Support

### Diagnosis
- Feature works on desktop
- Broken or unusable on mobile
- Not responsive

### Template: Add Mobile Support

```markdown
### Task: Make [Feature] mobile-responsive

**Type**: Frontend
**Estimate**: 4-8 hours
**Priority**: P1

**Description**:
Ensure [Feature] works well on mobile devices.

**Acceptance Criteria**:
- [ ] Layout adapts to mobile viewport (< 768px)
- [ ] Touch targets are 44px minimum
- [ ] No horizontal scrolling
- [ ] Text is readable without zooming
- [ ] All functionality accessible on mobile

**Breakpoints to Test**:
- Mobile: 375px (iPhone SE)
- Mobile Large: 428px (iPhone Pro Max)
- Tablet: 768px (iPad)

**Common Fixes**:
- Convert horizontal layouts to vertical stacks
- Hide secondary actions behind menu
- Increase button/link sizes
- Simplify tables to cards

**Files to Modify**:
- `src/components/[Feature]/*.tsx`
- Related CSS/Tailwind classes
```

---

## Gap: Full Frontend Missing

### Diagnosis
- Backend complete
- No frontend at all
- Needs complete UI build

### Template: Build Feature Frontend

```markdown
### Story: [Feature] Frontend Implementation

**Epic**: [Feature Epic ID]
**Priority**: P0/P1
**Estimate**: X days

**Description**:
Build the complete frontend for [Feature], including all screens, components, and API integration.

**Acceptance Criteria**:
- [ ] Main [feature] page accessible at /[route]
- [ ] All CRUD operations functional
- [ ] Loading, error, and empty states
- [ ] Added to navigation
- [ ] Mobile responsive

---

### Tasks (all Type: Frontend):

| # | Task | Hours | Notes |
|---|------|-------|-------|
| 1 | Create [Feature] page structure | 2 | Page file with layout |
| 2 | Build [Feature] list component | 4 | List/table of items with pagination |
| 3 | Build [Feature] detail component | 4 | Detail view / edit form |
| 4 | Build [Feature] create/edit form | 4 | Form with validation |
| 5 | Create API integration hooks | 4 | React Query hooks for all endpoints |
| 6 | Add loading/error/empty states | 3 | Polish states |
| 7 | Add [Feature] to navigation | 1 | Sidebar link |
| 8 | Mobile responsive pass | 4 | Responsive adjustments |
```

### ohno Creation (Story + Tasks)

Create the story first, then one `mcp__ohno__create_task` per task above (with the returned story ID, `task_type: "feature"`, hours as listed):

```
mcp__ohno__create_story({
  epic_id: "[epic-id]",
  title: "[Feature] Frontend Implementation",
  description: "Build complete frontend including pages, components, API integration, and polish."
})
```

Then chain dependencies with the returned task IDs via `mcp__ohno__add_dependency` (task_id depends on depends_on_task_id): page structure blocks list and detail components; list blocks API hooks; hooks block states; states block navigation; navigation blocks the responsive pass.

---

## Batch Remediation

Batch scripts key off the `Audit (...)` lines recorded in epic descriptions (see [gap-analysis.md](gap-analysis.md), "Gap Tracking in ohno").

### All Missing Navigation

```bash
# Find all features audited at L3 (routable but not in nav), create nav tasks
npx @stevestomp/ohno-cli epics --json | node -e '
const epics = JSON.parse(require("fs").readFileSync(0, "utf8"));
for (const e of epics) {
  if (/Audit \([^)]*\): L3/.test(e.description || "")) {
    console.log(`${e.id}\t${e.title}`);
  }
}' | while IFS=$'\t' read -r id title; do
    npx @stevestomp/ohno-cli create "[Remediation] $id: Add $title to navigation" -t feature
done
```

### All Missing Documentation

Same pattern: filter for descriptions matching `/Audit \([^)]*\):.*no_docs/` and create `[Remediation] $id: Write documentation for $title` tasks with `-t chore`.

---

## Task Naming Convention

ohno assigns task and story IDs — don't invent your own. Encode traceability in titles instead:

```
[Remediation] [FEATURE-ID]: [action]

Examples:
- [Remediation] F028: Create /reports page
- [Remediation] F028: Add Reports to navigation
- [Remediation] F028: Write documentation for Reports
```

Group related remediation tasks under a story per feature (e.g. "F028 Frontend Remediation") so `mcp__ohno__get_tasks` output stays scannable.
