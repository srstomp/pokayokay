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

### Infrastructure-First Ordering

Certain tasks must complete before implementation begins:

| Infrastructure Task | When Required | Blocks |
|-------------------|---------------|--------|
| Test setup | No existing test framework detected | All feature/bug tasks |
| Database schema | PRD includes data models | API and frontend tasks |
| Auth setup | PRD includes protected routes | Protected feature tasks |

The planner MUST check for these and create them as the first tasks with appropriate dependencies.

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

### Task Types

| Type | Examples | Skills |
|------|----------|--------|
| **Frontend** | Components, pages, styles | React, CSS, TypeScript |
| **Backend** | API endpoints, services | Node, Python, databases |
| **Database** | Schema, migrations, queries | SQL, ORM |
| **Design** | Mockups, prototypes | Figma, design systems |
| **DevOps** | CI/CD, infrastructure | Docker, AWS, Terraform |
| **QA** | Test cases, automation | Jest, Cypress, Playwright |
| **Documentation** | Docs, comments, README | Technical writing |

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

**Decomposition strategy:**
1. List all sub-components
2. Identify dependencies between them
3. Create task for each implementable unit
4. Link dependencies

**Example:**
```
Original: "Implement user authentication"

Decomposed:
- TASK-001: Create user database schema (2h)
- TASK-002: Create User model and validation (3h)
- TASK-003: Implement password hashing service (2h)
- TASK-004: Create registration API endpoint (4h)
- TASK-005: Create login API endpoint (4h)
- TASK-006: Implement JWT token service (3h)
- TASK-007: Create auth middleware (2h)
- TASK-008: Build registration form component (4h)
- TASK-009: Build login form component (3h)
- TASK-010: Implement auth context/state (3h)
- TASK-011: Add protected route wrapper (2h)
- TASK-012: Write auth integration tests (4h)
```

### Task Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
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

### Dependency Matrix

| Task | Blocked By | Blocks |
|------|------------|--------|
| TASK-001: DB Schema | — | TASK-002, TASK-004 |
| TASK-002: User Model | TASK-001 | TASK-004, TASK-005 |
| TASK-004: Register API | TASK-001, TASK-002 | TASK-008 |
| TASK-008: Register Form | TASK-004 | — |

### Critical Path Analysis

The critical path is the longest chain of dependencies:

```
DB Schema (2h) → User Model (3h) → Register API (4h) → Register Form (4h)
                                                       Total: 13h minimum
```

**Actions:**
- Can't parallelize critical path
- Allocate best resources to critical path
- Monitor for blockers

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

---

## Output Example

### Complete Breakdown

```markdown
# Implementation Plan: User Authentication

## Epic: Authentication System (EPIC-001)

**Priority**: P0
**Duration**: 2 weeks
**Stories**: 3
**Tasks**: 15

### Story 1: User Registration (STORY-001)

**As a** new user
**I want to** create an account with email and password
**So that** I can access the application

**Acceptance Criteria**:
- [ ] User can enter email and password
- [ ] Email is validated for format and uniqueness
- [ ] Password meets security requirements (8+ chars)
- [ ] User receives verification email
- [ ] Account is created after email verification

**Estimate**: 3 days
**Tasks**: 6

#### Tasks

| ID | Task | Type | Hours | Blocked By |
|----|------|------|-------|------------|
| T-001 | Create users table schema | Backend | 2 | — |
| T-002 | Create User model with validation | Backend | 3 | T-001 |
| T-003 | Implement password hashing | Backend | 2 | — |
| T-004 | Create registration endpoint | Backend | 4 | T-001, T-002, T-003 |
| T-005 | Build registration form | Frontend | 4 | — |
| T-006 | Integrate form with API | Frontend | 3 | T-004, T-005 |

**Critical Path**: T-001 → T-002 → T-004 → T-006 (12h)

### Story 2: User Login (STORY-002)
[Similar breakdown...]

### Story 3: Password Reset (STORY-003)
[Similar breakdown...]

---

## Dependency Graph

```
T-001 (Schema) ──┬──> T-002 (Model) ──┬──> T-004 (Register API) ──> T-006 (Integration)
                 │                     │
T-003 (Hashing) ─┴─────────────────────┘
                                            T-005 (Form) ──────────────────┘
```

## Timeline

| Week | Tasks | Deliverable |
|------|-------|-------------|
| Week 1 | T-001 through T-006 | Registration working |
| Week 2 | T-007 through T-015 | Login + Reset working |

## Risks

| Risk | Mitigation |
|------|------------|
| Email service delays | Use transactional email provider |
| Password policy changes | Make configurable |
```
