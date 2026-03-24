# Task Breakdown Methodology

Detailed guidance for breaking requirements into epics, stories, and tasks.

## Hierarchy Overview

```
Epic (1-4 weeks)
├── Story (1-5 days)
│   ├── Task (1-8 hours)
│   ├── Task
│   └── Task
├── Story
│   └── Tasks...
└── Story
    └── Tasks...
```

### Level Definitions

| Level | Scope | Duration | Owner | Deliverable |
|-------|-------|----------|-------|-------------|
| **Epic** | Feature area | 1-4 weeks | Product | Working capability |
| **Story** | User capability | 1-5 days | Team | Shippable increment |
| **Task** | Implementation | 1-8 hours | Individual | Code/design complete |

### Vertical Slice Ordering

Tasks are vertical slices — each delivers one working feature end-to-end. Shared infrastructure that multiple slices need comes first:

| Infrastructure Task | When Required | Blocks |
|-------------------|---------------|--------|
| Test setup | No existing test framework detected | All feature/bug tasks |
| Shared DB schema | Multiple features need the same tables | Feature slices using those tables |
| Auth middleware | Multiple features need authentication | Protected feature slices |

The planner MUST check for shared infrastructure and create it as the first tasks. Feature-specific schema, API, and UI are part of each feature's vertical slice, NOT separate tasks.

---

## Epic Definition

### What Makes a Good Epic

- **User-focused**: Delivers recognizable value
- **Bounded**: Clear start and end
- **Independent**: Minimal dependencies on other epics
- **Estimable**: Team can roughly size it
- **Decomposable**: Can break into stories

### Epic Template

```markdown
## Epic: [Name]

**ID**: EPIC-001
**Priority**: P0/P1/P2

### Goal
[One sentence: What user outcome does this enable?]

### Scope
**Includes**:
- [Feature/capability 1]
- [Feature/capability 2]

**Excludes**:
- [Explicitly out of scope]

### Success Criteria
- [ ] [Measurable outcome 1]
- [ ] [Measurable outcome 2]

### Dependencies
- **Blocked by**: [Other epics/external]
- **Blocks**: [What this enables]

### Estimate
- **Stories**: [Count]
- **Duration**: [X weeks]
- **Complexity**: Low/Medium/High

### Notes
[Technical considerations, risks, assumptions]
```

### Epic Sizing

| Size | Duration | Stories | Characteristics |
|------|----------|---------|-----------------|
| Small | 1 week | 2-3 | Single feature, isolated |
| Medium | 2 weeks | 4-6 | Feature set, some integration |
| Large | 3-4 weeks | 7-10 | Major capability, consider splitting |
| Too Large | 4+ weeks | 10+ | Must split into multiple epics |

### Epic Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Epic = Sprint | Misunderstands purpose | Epic is scope, not time |
| Horizontal epics | "All backend work" | Vertical: user-facing slices |
| Epic has no stories | Can't estimate | Break down further |
| Epics overlap | Double-counting work | Clear boundaries |

---

## Story Definition

### What Makes a Good Story

**INVEST Criteria:**
- **I**ndependent: Can be developed separately
- **N**egotiable: Details can be discussed
- **V**aluable: Delivers user value
- **E**stimable: Team can size it
- **S**mall: Fits in a sprint/iteration
- **T**estable: Clear acceptance criteria

### Story Template (ohno MCP format)

When creating stories via `mcp__ohno__create_story`, the description provides context for all tasks within the story.

```
mcp__ohno__create_story:
  title: "Email/Password Registration"
  epic_id: "<epic_id>"
  description: |
    Users can create accounts using email and password.

    Acceptance Criteria:
    - Given a valid email and password (8+ chars), when user submits registration form, then account is created and verification email is sent
    - Given an existing email, when user submits, then error "Email already registered" is shown
    - Given an invalid email format, when user submits, then validation error is shown before submission

    Edge Cases:
    - Concurrent registration with same email
    - Password with unicode characters

    Out of Scope:
    - Social auth (separate story)
    - Email verification flow (separate story)
```

**Required description sections:**
1. 1-2 sentence summary of the user capability
2. Acceptance criteria in Given/When/Then format (3-5 minimum)
3. Edge cases (2-3 items)
4. Out-of-scope items (prevents scope creep)

### Story Template (detailed planning)

For internal planning documents (not ohno), use the expanded format:

```markdown
### Story: [Name]

**Epic**: EPIC-001
**Priority**: P0/P1/P2

**As a** [user type]
**I want to** [action/capability]
**So that** [benefit/outcome]

**Acceptance Criteria**:
- Given [context], when [action], then [outcome]
- Given [context], when [action], then [outcome]

**Edge Cases**: [2-3 items]
**Out of Scope**: [What's NOT in this story]
**Estimate**: [X days], [N tasks]
```

### Story Sizing

| Size | Duration | Tasks | Complexity |
|------|----------|-------|------------|
| XS | 0.5 day | 1-2 | Trivial, well-understood |
| S | 1 day | 2-3 | Small scope, clear requirements |
| M | 2-3 days | 4-6 | Standard feature, some complexity |
| L | 4-5 days | 7-10 | Complex, consider splitting |
| XL | 5+ days | 10+ | Too large, must split |

### Story Splitting Patterns

When a story is too large, split using these patterns:

**1. Workflow Steps**
```
Original: "User completes checkout"
Split:
- User adds items to cart
- User enters shipping info
- User enters payment info
- User confirms and submits order
```

**2. Business Rules**
```
Original: "User gets discounts"
Split:
- User gets percentage discount
- User gets fixed amount discount
- User gets free shipping
- User uses promo code
```

**3. Simple/Complex**
```
Original: "User searches products"
Split:
- User searches by keyword (simple)
- User filters by category
- User filters by price range
- User sorts results (complex)
```

**4. Happy Path/Edge Cases**
```
Original: "User resets password"
Split:
- User resets password (happy path)
- Handle expired reset links
- Handle user not found
- Rate limit reset attempts
```

**5. Data Variations**
```
Original: "Admin manages users"
Split:
- Admin views user list
- Admin creates user
- Admin edits user
- Admin deactivates user
```

### Story Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Technical story | "Refactor database" | User-facing value |
| No acceptance criteria | Can't test | Add Given/When/Then |
| Too vague | "Improve performance" | Specific measurable criteria |
| Compound story | AND in description | Split into multiple stories |
| Solution not problem | "Add dropdown" | State the need |

---

## Task Definition

### What Makes a Good Task

- **Implementable**: Can be done by one person
- **Time-bound**: 1-8 hours
- **Specific**: Clear what "done" means
- **Technical**: Implementation-focused

### Task Template (ohno MCP format)

When creating tasks via `mcp__ohno__create_task`, the description field is the implementer agent's primary context. It must be self-contained.

```
mcp__ohno__create_task:
  title: "Create registration API endpoint"
  story_id: "<story_id>"
  task_type: "feature"
  estimate_hours: 4
  description: |
    POST /api/auth/register endpoint accepting {email, password, name}.

    Behavior:
    - Validate email format and uniqueness against users table
    - Hash password with bcrypt (12 rounds)
    - Create user record with status "pending_verification"
    - Return 201 with {id, email} (no password in response)
    - Return 409 if email exists, 422 if validation fails

    Acceptance Criteria:
    - [ ] Endpoint responds to POST /api/auth/register
    - [ ] Returns 201 on success with user object (no password)
    - [ ] Returns 409 for duplicate email
    - [ ] Returns 422 for invalid input with field-level errors
    - [ ] Password is never returned in any response

    Connects To:
    - Depends on: User schema task (creates the table this writes to)
    - Blocks: Registration form task (needs this endpoint)

    Patterns to Follow:
    - Follow existing endpoint patterns in src/routes/
```

**Required description sections:**
1. **Behavior**: What the code does (not just what the feature is)
2. **Input/output contract**: Endpoints, functions, data shapes
3. **Acceptance criteria**: Checkboxes the implementer self-verifies against
4. **Connects To**: Dependencies with brief context
5. **Patterns to Follow**: Where to find conventions in existing code

### Task Types (ohno)

Task types describe the **nature of work**, NOT the layer. Each task is still a vertical slice regardless of type.

| Type | When to Use | Example |
|------|-------------|---------|
| **feature** | New user-facing capability | "Sake list page: DB query + table + route" |
| **bug** | Fix broken behavior | "Fix sake creation returning 500 on duplicate name" |
| **chore** | Infrastructure, setup, config | "Set up test framework and DB migrations" |
| **spike** | Time-boxed investigation | "Spike: Can D1 handle multi-tenant isolation?" |
| **test** | Test-only changes | "Add E2E tests for sake CRUD flow" |

### Task Sizing

| Size | Hours | Description | Example |
|------|-------|-------------|---------|
| XS | 1-2h | Trivial, one-liner | Fix typo, update config |
| S | 2-4h | Simple, well-defined | Add form field, simple API |
| M | 4-8h | Standard complexity | New component, CRUD endpoint |
| L | 8h+ | Complex, split it | — |

**Rule**: If > 8 hours, break down further.

### Breaking Down Large Tasks

**Signal it's too large:**
- "Set up authentication" (many parts)
- "Build dashboard" (multiple components)
- "Implement search" (frontend + backend + optimization)

**Decomposition strategy — vertical slices:**
1. Identify the user-facing features (registration, login, protected access)
2. For each feature, include ALL layers needed to make it work end-to-end
3. Extract shared infrastructure only if multiple features need it
4. Each task produces working, testable behavior

**Example (vertical slices):**
```
Original: "Implement user authentication"

Decomposed:
- TASK-001: Shared auth infrastructure (4h)
  → User DB schema, password hashing utility, JWT token service
  → Done when: utility functions pass unit tests

- TASK-002: User registration end-to-end (6h)
  → POST /api/auth/register endpoint + validation + DB insert
  → Registration form component + client-side validation
  → Wire form → API → DB → success/error response
  → Done when: user can fill form, submit, see account created

- TASK-003: User login end-to-end (5h)
  → POST /api/auth/login endpoint + credential check + JWT issue
  → Login form component + auth state/context
  → Wire form → API → token storage → redirect
  → Done when: user can log in and see authenticated state

- TASK-004: Protected routes (3h)
  → Auth middleware + protected route wrapper
  → Redirect unauthenticated users to login
  → Done when: visiting /dashboard redirects to /login if not authed
```

**Anti-example (horizontal layers — DO NOT DO THIS):**
```
BAD: 12 tasks split by layer:
- Create user schema → Create model → Hashing service → Register API
  → Login API → JWT service → Auth middleware → Register form
  → Login form → Auth context → Protected routes → Integration tests

Each task produces files that reference things that don't exist yet.
The register form calls an API that hasn't been built. The API
references a model that hasn't been created. Nothing works until
ALL 12 tasks complete.
```

### Task Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Horizontal layers | Tasks produce disconnected files | Vertical slices (UI+API+DB per feature) |
| Vague task | "Work on feature" | Specific deliverable |
| No estimate | Can't plan | Add time estimate |
| Missing type | Can't assign | Add frontend/backend/etc |
| No dependencies | Blocked work | Map blockers |
| Too large | Not implementable | Split to ≤8 hours |

---

## Dependency Management

### Dependency Types

```
A ──blocks──> B     A must complete before B starts
A <──blocked by── B  A is waiting for B
A ──related──> B    A and B should be coordinated
A ──external──> X   A depends on external system/team
```

### Identifying Dependencies

Questions to ask:
1. What must exist before I can start this?
2. What data/API/component does this need?
3. Who else is touching related code?
4. Are there external approvals needed?

### Dependency Matrix (Vertical Slice Example)

| Task | Blocked By | Blocks |
|------|------------|--------|
| TASK-001: Auth infrastructure | — | TASK-002, TASK-003, TASK-004 |
| TASK-002: Registration e2e | TASK-001 | — |
| TASK-003: Login e2e | TASK-001 | TASK-004 |
| TASK-004: Protected routes | TASK-001, TASK-003 | — |

With vertical slices, feature tasks are mostly independent after shared infrastructure. Registration and login can run in parallel.

### Critical Path Analysis

The critical path is the longest chain of dependencies:

```
Auth infrastructure (4h) → Login e2e (5h) → Protected routes (3h)
                                            Total: 12h minimum
```

Registration (6h) runs in parallel with Login, so total wall-clock time is shorter than summing all tasks.

### Breaking Circular Dependencies

If A needs B and B needs A:

1. **Interface first**: Define the contract, implement separately
2. **Split the task**: Find the shared piece, extract it
3. **Mock it**: One side uses mock until real is ready
4. **Redesign**: Sometimes circular dependency signals design problem

---

## Estimation Techniques

### Task Estimation

**Time-based (hours):**
- Concrete and understandable
- Good for short-term planning
- Risk: Anchoring, precision theater

**Size-based (T-shirt/points):**
- Relative sizing
- Good for uncertainty
- Need conversion for timeline

### Estimation Process

1. **Understand scope**: Read requirements, acceptance criteria
2. **Break down mentally**: What sub-steps are needed?
3. **Consider unknowns**: Add buffer for learning, debugging
4. **Compare to past**: Similar tasks took how long?
5. **State confidence**: "4h if straightforward, 8h if complications"

### Estimation Adjustments

| Factor | Adjustment |
|--------|------------|
| New technology | +50-100% |
| Unclear requirements | +30-50% |
| Integration with legacy | +30-50% |
| First time doing this | +50% |
| Complex business logic | +30% |
| High test coverage needed | +20-30% |

### Estimation Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Optimistic only | Always late | Include buffer |
| Padding everything | Inflated timeline | Be realistic |
| Estimate without breakdown | Guessing | Break down first |
| Ignoring dependencies | Blocked time | Map wait time |
| Single-point estimate | False precision | Give range |

