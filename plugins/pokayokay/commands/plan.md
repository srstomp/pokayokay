---
description: Analyze PRD and create implementation plan with task breakdown
argument-hint: [--headless] [--review] <prd-path>
skill: prd-analyzer
---

# PRD Analysis Workflow

Analyze the PRD at `$ARGUMENTS` and create a structured implementation plan.

## Argument Parsing

Parse `$ARGUMENTS` to extract:
1. **Mode**: `--headless` (autonomous, no prompts) or `--review` (review existing plan) or default (interactive)
2. **PRD Path**: Remaining argument after flags

Example arguments:
- `docs/prd.md` → mode=interactive, path=docs/prd.md
- `--headless docs/prd.md` → mode=headless, path=docs/prd.md
- `--review` → mode=review, path=none (loads from ohno)

### Mode Routing

- If `--review`: skip to "## Plan Review Session" section below
- If `--headless`: run Steps 1-7 with all prompts auto-decided (see Headless Behavior below)
- Otherwise: run Steps 1-7 interactively (current behavior)

## Headless Behavior

When `--headless` is active, suppress ALL user-facing prompts and auto-decide:

### Decision Logging

Every auto-decision MUST be logged via ohno:

```
mcp__ohno__add_task_activity:
  task_id: <relevant_task_or_epic_id>
  type: "decision"
  description: "CATEGORY: rationale"
```

Categories: SPIKE, DESIGN, SPLIT, MERGE, DEPENDENCY, PRIORITY, SCOPE

Examples:
- `"SPIKE: Created spike for Redis session storage — PRD says 'fast sessions' but doesn't specify technology"`
- `"DESIGN: Added 3 design-first tasks — PRD mentions wireframes, user flows, responsive layout (2+ UI/UX categories detected)"`
- `"DEPENDENCY: Made payment integration depend on auth spike — need session approach first"`

Cross-cutting decisions (SPLIT, SCOPE, MERGE) go on the epic. Task-specific decisions go on the task.

### Auto-Decisions

| Interactive Prompt | Headless Auto-Decision | Decision Category |
|-------------------|----------------------|-------------------|
| Design plugin: "Create design tasks now?" | Yes (create design tasks + dependencies) | DESIGN |
| Design plugin: "Continue without design plugin?" | Yes (continue without) | — (no decision needed) |
| Spike opportunity detected | Create the spike task | SPIKE |
| Feature split into multiple stories | Split and log rationale | SPLIT |
| Non-obvious dependency added | Add dependency and log | DEPENDENCY |
| Priority differs from PRD ordering | Assign and log rationale | PRIORITY |
| PRD item excluded as out-of-scope | Exclude and log rationale | SCOPE |

### Post-Completion Summary

After Step 7 (Sync and Report), display:

```
Planning complete: [N] epics, [N] stories, [N] tasks
[N] notable decisions to review

Review now? (or run `/plan --review` later)
```

If user says yes, proceed to "## Plan Review Session" below.
If user says no or doesn't respond, end the session.

## Steps

### 1. Check Design Plugin Availability

Before analyzing the PRD, check if the design plugin is installed to enable design-first workflows for UI/UX heavy features.

```python
def is_design_plugin_available():
    """Check if design plugin commands are available"""
    design_commands = ['/design:ux', '/design:ui', '/design:persona', '/design:a11y', '/design:marketing']
    return any(has_command(cmd) for cmd in design_commands)

# Store result for later use
design_plugin_available = is_design_plugin_available()
```

This check is non-blocking - it only detects availability. The result will be used later during task creation to:
- Route design-related tasks to `/design:*` commands when available
- Suggest design plugin installation for UI/UX heavy features when not available
- Enable design-first workflows that create design artifacts before implementation

### 2. Read the PRD
Read and understand the document at the provided path. Extract:
- Project name and description
- Core features and requirements
- Technical constraints
- Success criteria

### 3. Initialize ohno (if needed)
```bash
npx @stevestomp/ohno-cli init
```

### 4. Create Hierarchical Structure

Use the ohno MCP tools to create a proper epic → story → task hierarchy:

#### 4.1 Create Epics (Major Features)
For each major feature area, create an epic with priority:
```
mcp__ohno__create_epic:
  title: "User Authentication"
  description: "Complete auth system with login, registration, password reset"
  priority: "P0"  # P0=critical, P1=high, P2=medium, P3=low
```

#### 4.2 Create Stories (User-Facing Capabilities)
For each epic, create stories representing user-facing chunks. See Section 4.5 for required description format.
```
mcp__ohno__create_story:
  title: "Email/Password Registration"
  epic_id: "<epic_id from step above>"
  description: "<rich description per Section 4.5>"
```

#### 4.3 Create Tasks (Implementable Units)
For each story, create tasks (1-8 hours each). See Section 4.5 for required description format.
```
mcp__ohno__create_task:
  title: "Create registration form component"
  story_id: "<story_id from step above>"
  task_type: "feature"  # feature, bug, chore, spike, test
  estimate_hours: 4
  description: "<rich description per Section 4.5>"
```

#### 4.4 Add Dependencies
Link tasks that depend on each other:
```
mcp__ohno__add_dependency:
  task_id: "<task that is blocked>"
  depends_on_task_id: "<task that must complete first>"
```

**Important**: Always create in order: epics first, then stories (with epic_id), then tasks (with story_id). This ensures proper relationships.

### 4.5 Task & Story Description Quality

Every story and task MUST include rich descriptions. The implementer agent receives these descriptions as its only context — vague descriptions force it to guess or waste tokens asking questions.

#### Story Description Format

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

Every story description MUST include:
1. 1-2 sentence summary of the user capability
2. Acceptance criteria in Given/When/Then format (3-5 minimum)
3. Edge cases (2-3 items)
4. Out-of-scope items (prevents scope creep)

#### Task Description Format

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

Every task description MUST include:
1. **Behavior**: What the code should _do_, not just what the feature _is_
2. **Input/output contract**: Endpoints, function signatures, data shapes (where applicable)
3. **Acceptance criteria**: 3-5 checkboxes the implementer can self-verify against
4. **Connects To**: Which tasks this depends on and blocks, with brief context
5. **Patterns to Follow**: Where to look for conventions in existing code

#### Anti-Pattern: Vague Descriptions

```
BAD:  title: "Set up authentication"
      description: "Implement auth for the app"

GOOD: title: "Create JWT token service"
      description: |
        Service that generates and validates JWT access tokens.

        Behavior:
        - generateToken(userId): returns signed JWT with 1h expiry
        - validateToken(token): returns userId or throws InvalidTokenError
        - Use RS256 signing with key from AUTH_PRIVATE_KEY env var

        Acceptance Criteria:
        - [ ] generateToken returns valid JWT with userId claim
        - [ ] validateToken rejects expired tokens
        - [ ] validateToken rejects tampered tokens
        - [ ] Tokens include userId and exp claims

        Connects To:
        - Blocks: Login endpoint (needs token generation)
        - Blocks: Auth middleware (needs token validation)
```

### 5. Assign Skill Hints

Tag tasks with recommended skills based on their content:

**Backend & API**:
- API endpoints, REST/GraphQL → api-design
- Database schema, migrations → database-design
- Architecture decisions → architecture-review
- Third-party integrations → api-integration

**DevOps & Infrastructure**:
- CI/CD pipelines, GitHub Actions → ci-cd-expert
- Logging, monitoring, alerts → observability

**Quality & Security**:
- Test architecture, coverage → testing-strategy
- Security review, authentication → security-audit

**Investigation**:
- Time-boxed technical questions → spike (task_type: spike)
- Multi-day technology evaluation → deep-research (task_type: research)

### 5.1 Keyword Detection

When skill not explicitly specified, detect from task title/description. When a skill is detected, incorporate the skill's purpose into the task description so the implementer understands why that skill was assigned.

| Keywords | Skill | Task Type |
|----------|-------|-----------|
| database, schema, migration, model, prisma | database-design | feature |
| test, coverage, e2e, playwright, cypress, jest | testing-strategy | test |
| deploy, pipeline, ci/cd, github actions, release | ci-cd-expert | chore |
| security, auth, encryption, vulnerability, owasp | security-audit | feature |
| logging, monitoring, alert, metrics, tracing | observability | feature |
| spike, investigate, feasibility, can we, how hard | spike | spike |
| research, evaluate, compare, vendor, assessment | deep-research | research |

### 5.2 Detect Spike Opportunities

For features with high uncertainty, create spike tasks:
- "Can we...?" or "Is it possible to...?" questions
- Performance or feasibility unknowns
- Technology selection decisions
- Complex integration assessments

Example:
```
mcp__ohno__create_task:
  title: "Spike: Can D1 handle multi-tenant isolation?"
  story_id: "<relevant_story_id>"
  task_type: "spike"
  estimate_hours: 3
```

### 5.3 Design Plugin Integration

For UI/UX heavy features, check design plugin availability and create design-first workflows. See the prd-analyzer skill's [design-integration.md](references/design-integration.md) reference for full detection logic, keyword lists, and workflow details.

### 6. Create Project Context
Create `.claude/PROJECT.md` with:
- Project overview
- Tech stack decisions
- Feature summary with task IDs
- Links to ohno kanban

### 7. Sync and Report
```bash
npx @stevestomp/ohno-cli sync
```

Report to user:
- Total tasks created
- Epic/story breakdown
- Recommended starting point
- Link to kanban board

## Plan Review Session

Entered via `--review` flag or after headless completion when user says "yes" to review prompt.

### Phase 1: Load Plan Data

Fetch current plan state from ohno:

```
epics = mcp__ohno__get_epics(status="active")
```

For each epic, fetch stories and tasks:
```
stories = mcp__ohno__list_stories(epic_id=epic.id)
tasks = mcp__ohno__get_tasks(status="todo", fields="minimal")
```

Fetch notable decisions (activities with type "decision"):
```
For each epic and task, check:
  mcp__ohno__summarize_task_activity(task_id)
  → Filter for type="decision" entries
```

### Phase 2: Overview

Display a summary:

```
Plan: [project name from PROJECT.md or first epic title]
  [N] epics ([list with priorities])
  [N] stories, [N] tasks
  [N] spikes, [N] design tasks
  [N] notable decisions
```

If no notable decisions found, skip to Phase 4.

### Phase 3: Walk Through Notable Decisions

Present each decision one at a time. For each:

```
Decision [i]/[total] [CATEGORY]:
  Context: [what was created/changed]
  Reason: [rationale from the decision description]

  Options:
  1. Keep as-is (recommended)
  2. [Category-specific alternative — see table below]
  3. [Category-specific alternative]
  4. Something else (describe)
```

Category-specific options:

| Category | Option 2 | Option 3 |
|----------|----------|----------|
| SPIKE | Remove spike, make assumption instead | Change spike question |
| DESIGN | Remove design tasks, implement directly | Keep some, remove others |
| SPLIT | Merge back into single story | Different split |
| MERGE | Split back into separate items | Keep merge, adjust scope |
| DEPENDENCY | Remove dependency | Change dependency direction |
| PRIORITY | Change to [higher/lower] priority | Match PRD ordering |
| SCOPE | Include it back in scope | Keep excluded, create future task |

Apply changes immediately via ohno MCP tools:
- Remove task: `mcp__ohno__archive_task(task_id, "Removed during plan review")`
- Change priority: `mcp__ohno__update_epic(epic_id, priority=...)`
- Remove dependency: `mcp__ohno__remove_dependency(task_id, depends_on_task_id)`
- Create task: `mcp__ohno__create_task(...)`
- Update task: `mcp__ohno__update_task(task_id, ...)`

### Phase 4: Open Floor

After all decisions reviewed (or if there were none):

```
All decisions reviewed. Anything else you'd like to adjust?
  1. Done — plan looks good
  2. Show me a specific epic/story in detail
  3. Add/remove/modify tasks
  4. Re-prioritize epics
```

**Option 2**: Ask which epic/story to show. Display full task list with descriptions, estimates, dependencies, and skill hints. Allow inline edits.

**Option 3**: Free-form — user describes what to add/remove/change. Apply via ohno MCP tools.

**Option 4**: Show current epic priorities, let user reorder. Apply via `update_epic`.

**Option 1**: Exit review. Print final counts and link to kanban.

Loop on options 2-4 until user picks option 1.

## Output

After completion:
- Tasks in ohno (view with `npx @stevestomp/ohno-cli tasks`)
- `.claude/PROJECT.md` for session context
- Kanban at `npx @stevestomp/ohno-cli serve`

## Related Commands

- `/pokayokay:work` - Start implementation after planning
- `/pokayokay:audit` - Check feature completeness after implementation
- `/pokayokay:review` - Analyze planning patterns over time
