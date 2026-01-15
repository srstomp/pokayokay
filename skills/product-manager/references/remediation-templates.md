# Remediation Task Templates

Pre-built task templates for common gaps identified during feature audits.

## Template Usage

When a gap is identified, use these templates to generate properly-structured remediation tasks that integrate with tasks.db.

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

### SQL Insert

```sql
INSERT INTO tasks (id, story_id, title, description, task_type, estimate_hours, status)
VALUES (
    'task-[FEATURE]-route',
    'story-[FEATURE]-frontend',
    'Create /[route] page',
    'Create the main page for [Feature Name] with data fetching, loading, and error states.',
    'frontend',
    6,
    'todo'
);
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

### SQL Insert

```sql
INSERT INTO tasks (id, story_id, title, description, task_type, estimate_hours, status)
VALUES (
    'task-[FEATURE]-nav',
    'story-[FEATURE]-frontend',
    'Add [Feature] to navigation',
    'Add navigation link to [Feature Name] in the main sidebar/navigation.',
    'frontend',
    1,
    'todo'
);
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

### SQL Insert

```sql
INSERT INTO tasks (id, story_id, title, description, task_type, estimate_hours, status)
VALUES (
    'task-[FEATURE]-api-integration',
    'story-[FEATURE]-frontend',
    'Connect [Feature] UI to backend API',
    'Create API client and React Query hooks, wire up components to use real data.',
    'frontend',
    5,
    'todo'
);
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

### SQL Insert

```sql
INSERT INTO tasks (id, story_id, title, description, task_type, estimate_hours, status)
VALUES (
    'task-[FEATURE]-loading',
    'story-[FEATURE]-polish',
    'Add loading skeleton to [Feature]',
    'Create skeleton component that matches content layout, show during data fetching.',
    'frontend',
    2,
    'todo'
);
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

### SQL Insert

```sql
INSERT INTO tasks (id, story_id, title, description, task_type, estimate_hours, status)
VALUES (
    'task-[FEATURE]-error',
    'story-[FEATURE]-polish',
    'Add error handling to [Feature]',
    'Create error UI with retry option, handle different error types appropriately.',
    'frontend',
    3,
    'todo'
);
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

### SQL Insert

```sql
INSERT INTO tasks (id, story_id, title, description, task_type, estimate_hours, status)
VALUES (
    'task-[FEATURE]-empty',
    'story-[FEATURE]-polish',
    'Add empty state to [Feature]',
    'Create helpful empty state with explanation and CTA when no data exists.',
    'frontend',
    2,
    'todo'
);
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

### SQL Insert

```sql
INSERT INTO tasks (id, story_id, title, description, task_type, estimate_hours, status)
VALUES (
    'task-[FEATURE]-docs',
    'story-[FEATURE]-docs',
    'Write help documentation for [Feature]',
    'Create help article with purpose, instructions, screenshots, and FAQ.',
    'documentation',
    3,
    'todo'
);
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

### SQL Insert

```sql
INSERT INTO tasks (id, story_id, title, description, task_type, estimate_hours, status)
VALUES (
    'task-[FEATURE]-mobile',
    'story-[FEATURE]-polish',
    'Make [Feature] mobile-responsive',
    'Ensure layout works on mobile, touch targets adequate, all functionality accessible.',
    'frontend',
    6,
    'todo'
);
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

### Tasks:

#### 1. Create [Feature] page structure
- **Type**: Frontend
- **Hours**: 2
- Create page file with layout

#### 2. Build [Feature] list component
- **Type**: Frontend  
- **Hours**: 4
- List/table of items with pagination

#### 3. Build [Feature] detail component
- **Type**: Frontend
- **Hours**: 4
- Detail view / edit form

#### 4. Build [Feature] create/edit form
- **Type**: Frontend
- **Hours**: 4
- Form with validation

#### 5. Create API integration hooks
- **Type**: Frontend
- **Hours**: 4
- React Query hooks for all endpoints

#### 6. Add loading/error/empty states
- **Type**: Frontend
- **Hours**: 3
- Polish states

#### 7. Add to navigation
- **Type**: Frontend
- **Hours**: 1
- Sidebar link

#### 8. Mobile responsive pass
- **Type**: Frontend
- **Hours**: 4
- Responsive adjustments
```

### SQL Insert (Story + Tasks)

```sql
-- Create story
INSERT INTO stories (id, epic_id, title, description, estimate_days, status)
VALUES (
    'story-[FEATURE]-frontend',
    'epic-[FEATURE]',
    '[Feature] Frontend Implementation',
    'Build complete frontend including pages, components, API integration, and polish.',
    4,
    'todo'
);

-- Create tasks
INSERT INTO tasks (id, story_id, title, task_type, estimate_hours, status) VALUES
    ('task-[F]-f01', 'story-[FEATURE]-frontend', 'Create [Feature] page structure', 'frontend', 2, 'todo'),
    ('task-[F]-f02', 'story-[FEATURE]-frontend', 'Build [Feature] list component', 'frontend', 4, 'todo'),
    ('task-[F]-f03', 'story-[FEATURE]-frontend', 'Build [Feature] detail component', 'frontend', 4, 'todo'),
    ('task-[F]-f04', 'story-[FEATURE]-frontend', 'Build [Feature] create/edit form', 'frontend', 4, 'todo'),
    ('task-[F]-f05', 'story-[FEATURE]-frontend', 'Create API integration hooks', 'frontend', 4, 'todo'),
    ('task-[F]-f06', 'story-[FEATURE]-frontend', 'Add loading/error/empty states', 'frontend', 3, 'todo'),
    ('task-[F]-f07', 'story-[FEATURE]-frontend', 'Add [Feature] to navigation', 'frontend', 1, 'todo'),
    ('task-[F]-f08', 'story-[FEATURE]-frontend', 'Mobile responsive pass', 'frontend', 4, 'todo');

-- Add dependencies
INSERT INTO dependencies (blocker_task_id, blocked_task_id) VALUES
    ('task-[F]-f01', 'task-[F]-f02'),
    ('task-[F]-f01', 'task-[F]-f03'),
    ('task-[F]-f02', 'task-[F]-f05'),
    ('task-[F]-f05', 'task-[F]-f06'),
    ('task-[F]-f06', 'task-[F]-f07'),
    ('task-[F]-f07', 'task-[F]-f08');
```

---

## Batch Remediation

### All Missing Navigation

```sql
-- Find all features missing navigation
SELECT e.id, e.title 
FROM epics e 
WHERE e.audit_level = 3;  -- Routable but not in nav

-- Generate tasks for all
INSERT INTO tasks (id, story_id, title, task_type, estimate_hours, status)
SELECT 
    'task-' || e.id || '-nav',
    'story-' || e.id || '-frontend', 
    'Add ' || e.title || ' to navigation',
    'frontend',
    1,
    'todo'
FROM epics e
WHERE e.audit_level = 3;
```

### All Missing Documentation

```sql
-- Find all features missing docs
SELECT e.id, e.title 
FROM epics e 
WHERE e.audit_gaps LIKE '%no_docs%';

-- Generate doc tasks for all
INSERT INTO tasks (id, story_id, title, task_type, estimate_hours, status)
SELECT 
    'task-' || e.id || '-docs',
    'story-' || e.id || '-docs', 
    'Write documentation for ' || e.title,
    'documentation',
    3,
    'todo'
FROM epics e
WHERE e.audit_gaps LIKE '%no_docs%';
```

---

## Task ID Convention

```
task-[EPIC]-[TYPE][NUMBER]

Examples:
- task-028-f01  → Epic 028, Frontend task 1
- task-028-b01  → Epic 028, Backend task 1
- task-028-d01  → Epic 028, Documentation task 1
- task-028-p01  → Epic 028, Polish task 1

Story IDs:
- story-028-frontend  → Frontend work for epic 028
- story-028-polish    → Polish work for epic 028
- story-028-docs      → Documentation for epic 028
```
