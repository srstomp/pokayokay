# Simulated Response: `/pokayokay:work semi-auto`

This document describes what Claude would do step-by-step when the user runs `/pokayokay:work semi-auto` with a user-management epic loaded in ohno (3 stories, ~9 tasks). The project is a Next.js app at `~/Projects/acme/webapp`.

---

## Phase 1: Argument Parsing

Claude parses `$ARGUMENTS` = `semi-auto`:

- **Mode**: `semi-auto` (matches known mode keyword)
- **Parallel**: `1` (default, no `-n` flag)
- **Scope**: none specified
- **Continue**: false (no `--continue` flag)
- **Worktree flags**: none (smart defaults apply)

No scope validation required (semi-auto does not require scope -- that's only enforced for auto/unattended/`--continue`). No chain state initialization (semi-auto doesn't chain).

---

## Phase 2: Session Initialization

### Step 0: Load Configuration

Claude reads `.claude/pokayokay.json` (if it exists) for headless/work settings. Since semi-auto doesn't chain, headless config is informational only.

### Step 0.5: Load Project Learnings

Claude checks MEMORY.md (already in system prompt) and looks for:

- `memory/recurring-failures.md` -- to include "Known Pitfalls" in implementer prompts
- `memory/spike-results.md` -- to avoid re-investigating closed spikes
- `memory/chain-learnings.md` -- session chain history

### Step 2: Get Session Context

**MCP call**: `mcp__ohno__get_session_context()`

This returns previous session notes, current blockers, and any in-progress tasks. Since this is a fresh session on a newly-loaded epic, the response likely shows no prior session context and no in-progress tasks.

Claude announces:

```
## Session Start

**Mode**: semi-auto
**Parallel**: 1 (sequential)
**Scope**: all (no filter)
**Project**: ~/Projects/acme/webapp

### Semi-Auto Checkpoints
- Task complete: log and continue
- Story complete: PAUSE for review
- Epic complete: PAUSE for review
- Errors/ambiguity: PAUSE
```

### Step 3: No Resume (no `--continue`)

Skipped -- this is a fresh session.

### Step 4: Read Project Context

Claude checks for `~/Projects/acme/webapp/.claude/PROJECT.md` (or `CLAUDE.md`) to understand the Next.js app's tech stack, conventions, and project overview.

### Step 5: Get Next Task

**MCP call**: `mcp__ohno__get_next_task()`

ohno returns the highest-priority unblocked task. For this simulation, let's say it returns:

```json
{
  "id": "task-001",
  "title": "Create user registration API endpoint",
  "description": "Build POST /api/users/register endpoint that accepts email, password, and name. Validate inputs, hash password with bcrypt, store in database, and return JWT token. Must handle duplicate email gracefully.",
  "task_type": "feature",
  "status": "todo",
  "story_id": "story-001",
  "acceptance_criteria": "- POST /api/users/register accepts {email, password, name}\n- Validates email format and password strength (8+ chars)\n- Returns 409 if email exists\n- Hashes password with bcrypt\n- Returns JWT token on success\n- Returns appropriate error messages",
  "dependencies": []
}
```

**MCP call**: `mcp__ohno__get_story("story-001")` -- to get story context.

**MCP call**: `mcp__ohno__get_epics()` or `mcp__ohno__get_epic(epic_id)` -- to understand the broader epic.

Claude presents the work queue:

```
## Work Queue

**Epic**: User Management
**Stories**: 3 (0 complete)
**Tasks**: ~9 (0 complete)

### Story 1: User Registration (story-001)
- task-001: Create user registration API endpoint
- task-002: Build registration form component
- task-003: Add email verification flow

### Story 2: User Authentication (story-002)
- task-004: Create login API endpoint
- task-005: Build login form component
- task-006: Implement session management

### Story 3: User Profile (story-003)
- task-007: Create profile API endpoints
- task-008: Build profile edit page
- task-009: Add avatar upload

Starting with task-001: Create user registration API endpoint
```

---

## Phase 3: Work Loop -- Task 1

### Step 6: Worktree Decision

Task type is `feature` -- smart default is **worktree**.

Claude checks for an existing story worktree:

```bash
git worktree list --porcelain | grep "story-001"
```

None found, so create a new one:

```bash
BASE=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's|refs/remotes/origin/||')
git worktree add -b story-001-user-registration .worktrees/story-001-user-registration $BASE
```

Then install dependencies in the worktree:

```bash
cd ~/Projects/acme/webapp/.worktrees/story-001-user-registration
# Detect package manager (Next.js likely uses npm/pnpm/bun)
npm install  # or pnpm install, bun install, etc.
```

Claude announces:

```
## Worktree Setup

Creating worktree for story-001: User Registration
  ✓ Branch created: story-001-user-registration
  ✓ Worktree ready at .worktrees/story-001-user-registration
  ✓ Dependencies installed

Working directory: ~/Projects/acme/webapp/.worktrees/story-001-user-registration
```

### Step 7: Start the Task

**MCP call**: `mcp__ohno__update_task_status("task-001", "in_progress")`

### Step 2 (Skill Routing): Route to Skill

Task title contains "API endpoint" -- keyword match to **api-design** skill.

Claude reads `plugins/pokayokay/skills/api-design/SKILL.md` to get key principles and reference table. This content will be included in the implementer's `{RELEVANT_SKILL}` template variable.

### Step 2.5: Design Task Check

`is_design_task(task)` returns false -- no design keywords, task_type is `feature`, not a design type. Skip design routing.

### Step 3 (Brainstorm Gate): Check if Brainstorm Needed

Evaluation:
- `task_type` is `feature` (not bug/chore, so not auto-skipped)
- `description` length > 100 chars (well-specified)
- `acceptance_criteria` is present
- No ambiguous keywords ("investigate", "explore", etc.)

Result: **Skip brainstorm** -- task is well-specified.

### Step 3.5: Pre-Implementation Validation

- Description length: > 50 chars -- OK
- Acceptance criteria: present -- OK
- Dependencies: none -- OK

Result: **Ready for implementation.**

### Step 4: Dispatch Implementer Subagent

Claude assembles context from multiple sources:

1. **Story context**: "User Registration -- Build the user registration flow including API, form, and email verification"
2. **Task context**: description + acceptance criteria
3. **Handoff notes**: none (first task)
4. **Known pitfalls**: Check `memory/recurring-failures.md` for matching patterns (e.g., "Input validation missing" from graduated rules)

Claude fills the implementer prompt template (`agents/templates/implementer-prompt.md`):

| Variable | Value |
|----------|-------|
| `{TASK_ID}` | `task-001` |
| `{TASK_TITLE}` | `Create user registration API endpoint` |
| `{TASK_DESCRIPTION}` | Full description text |
| `{ACCEPTANCE_CRITERIA}` | The 6-bullet criteria list |
| `{CONTEXT}` | Story context + "Known Pitfall: Input validation missing (seen 3x)" |
| `{RELEVANT_SKILL}` | Contents of api-design SKILL.md |
| `{WORKING_DIRECTORY}` | `~/Projects/acme/webapp/.worktrees/story-001-user-registration` |
| `{RESUME_CONTEXT}` | (empty -- fresh task) |

**Dispatch via Task tool**:

```
Task tool:
  subagent_type: "pokayokay:yokay-implementer"
  description: "Implement: Create user registration API endpoint"
  mode: "bypassPermissions"
  prompt: [filled implementer-prompt.md]
```

The implementer agent runs in its own fresh context. It will:
1. Read the codebase to understand existing patterns
2. Write tests first (TDD)
3. Implement the endpoint
4. Self-review
5. Commit with conventional message
6. Report back with implementation summary

### Step 4.5: Auto-Fix Test Failures

After implementer returns, Claude runs the test suite:

```bash
cd ~/Projects/acme/webapp/.worktrees/story-001-user-registration
npm test -- --testPathPattern="register"
```

- **If PASS**: proceed to browser verification check
- **If FAIL**: dispatch `yokay-fixer` with test output (max 3 attempts)

### Step 4.6: Browser Verification Check

Testability checks:
1. Browser tools available? Check for `mcp__plugin_playwright_*` tools -- yes, they're in the environment
2. Server running? Need to check/start Next.js dev server
3. Renderable files changed? This is an API endpoint -- likely no `.tsx`/`.jsx` changes

Result: **Skip browser verification** -- no UI changes detected (API-only task).

### Step 6 (Review): Two-Stage Review

#### Stage 1: Spec Compliance Review

**Dispatch via Task tool**:

```
Task tool:
  subagent_type: "pokayokay:yokay-spec-reviewer"
  description: "Spec review: Create user registration API endpoint"
  mode: "bypassPermissions"
  prompt: [filled spec-review-prompt.md with task details, implementation summary, files changed, commit info]
```

The spec reviewer adversarially checks:
- All 6 acceptance criteria met against actual code
- No missing requirements
- No scope creep

**If FAIL**: Re-dispatch implementer with specific spec issues. Skip quality review. (Max 3 review cycles.)

**If PASS**: Proceed to Stage 2.

#### Stage 2: Code Quality Review

**Dispatch via Task tool**:

```
Task tool:
  subagent_type: "pokayokay:yokay-quality-reviewer"
  description: "Quality review: Create user registration API endpoint"
  mode: "bypassPermissions"
  prompt: [filled quality-review-prompt.md with task details, files changed, commit info]
```

The quality reviewer checks code structure, test quality, conventions compliance.

**If FAIL**: Re-dispatch implementer with quality issues.

**If PASS**: Proceed to task completion.

### Step 7: Complete Task

**MCP call**: `mcp__ohno__update_task_status("task-001", "done")` with notes summarizing what was implemented.

**MCP call**: `mcp__ohno__add_task_activity("task-001", "note", "Task review: PASS (spec + quality)")`

ohno returns boundary metadata indicating whether this completion also completed a story or epic.

Post-task hooks fire automatically:
- `sync.sh` -- syncs ohno state
- `commit.sh` -- ensures changes are committed

### Step 8: Checkpoint (Semi-Auto)

**Semi-auto behavior on task_complete**: Log and continue (no pause).

```
✓ task-001 complete (abc1234) | Create user registration API endpoint → Starting task-002
```

Since task-001 is part of story-001 which has more tasks, the worktree is kept. No merge/PR prompt.

---

## Phase 3 (continued): Work Loop -- Task 2

Claude gets the next task:

**MCP call**: `mcp__ohno__get_next_task()`

Returns `task-002: Build registration form component`.

### Worktree Decision

Same story (story-001) -- **reuse existing worktree** at `.worktrees/story-001-user-registration`.

### Start Task

**MCP call**: `mcp__ohno__update_task_status("task-002", "in_progress")`

### Skill Routing

"form component" -- keyword match: likely routes to general frontend (no specialized skill, or possibly testing-strategy as secondary). Claude uses general capabilities.

### Brainstorm Gate

Evaluate task specification quality. If well-specified, skip. If vague, dispatch `yokay-brainstormer`.

### Dispatch Implementer

Same flow as task-001 but with task-002 details, different skill routing, and the working directory is the same worktree.

### Auto-Fix, Browser Verification

- Auto-fix: same flow
- Browser verification: This task changes `.tsx` files -- **browser verification triggers** if Playwright tools are available and a server can be started. Dispatch `yokay-browser-verifier`.

### Review, Complete, Checkpoint

Same two-stage review flow. Log and continue (semi-auto, task boundary).

```
✓ task-002 complete (def5678) | Build registration form component → Starting task-003
```

---

## Phase 3 (continued): Work Loop -- Task 3

Claude gets task-003: `Add email verification flow`.

Same worktree, same flow. After completion:

**MCP call**: `mcp__ohno__update_task_status("task-003", "done")`

ohno boundary metadata indicates: **story-001 is now complete** (3/3 tasks done).

### Checkpoint: Story Boundary (PAUSE)

Semi-auto mode pauses at story boundaries. Claude presents:

```
## CHECKPOINT: Story Complete

**Story**: story-001 - User Registration (3/3 tasks done)
**Tasks completed**: task-001, task-002, task-003
**Time in story**: [elapsed]
**Branch**: story-001-user-registration

### Summary
- Created user registration API endpoint with validation and JWT
- Built registration form with client-side validation
- Added email verification flow with token generation

### Worktree Disposition

Story 001 complete (3/3 tasks done).

  1. Merge to main (Recommended)
  2. Create Pull Request
  3. Keep worktree (continue later)
  4. Discard work

Which option?

### Next Up
Story 002: User Authentication (3 tasks)
- task-004: Create login API endpoint
- task-005: Build login form component
- task-006: Implement session management

### Your Options

1. **Continue** - Merge/PR this story and proceed to Story 002
2. **Review** - I'll wait while you check the code
3. **Modify** - Tell me what to change
4. **Switch** - Work on different story
5. **End** - Stop session here

What would you like to do?
```

---

## Phase 4: User Responds, Session Continues

If user says "1, merge and continue" (or similar):

1. **Merge worktree**:
   ```bash
   cd ~/Projects/acme/webapp
   git checkout main
   git merge --no-ff story-001-user-registration
   git worktree remove .worktrees/story-001-user-registration
   git branch -d story-001-user-registration
   ```

2. **Start Story 002**: Create new worktree `story-002-user-authentication`
3. **Resume work loop** with task-004

The same pattern repeats for Story 002 (3 tasks, log each task completion, PAUSE at story boundary) and Story 003 (3 tasks, log each, PAUSE at story boundary).

When Story 003 completes, ohno indicates **epic complete**. Semi-auto also pauses at epic boundaries:

```
## CHECKPOINT: Epic Complete

**Epic**: User Management
**Stories completed**: 3/3
**Tasks completed**: 9/9

### Summary
- Story 1: User Registration (API, form, email verification)
- Story 2: User Authentication (login, form, sessions)
- Story 3: User Profile (API, edit page, avatar upload)

All user management work is complete.

### Your Options
1. **Continue** - Work on next available epic
2. **Review** - Inspect all changes
3. **End** - Stop session

What would you like to do?
```

---

## Session End

When the user ends the session (or all tasks are exhausted), Claude runs the session end checklist:

```
## Session Complete

**Duration**: [elapsed]
**Mode**: semi-auto
**Tasks completed**: 9
**Stories completed**: 3
**Epic completed**: User Management

### Session End Checklist

1. [x] All changes committed
2. [x] ohno task statuses current
3. [x] No broken code left
4. [x] Clear summary written
5. [x] Next steps documented

Session ended cleanly. Progress saved.
```

Post-session hooks fire:
- `sync.sh` -- final ohno sync
- `session-summary.sh` -- generates summary with token costs
- `curate-memory.sh` -- enforces MEMORY.md budget

---

## Key Behavioral Notes

### What Semi-Auto Mode Does Differently

| Event | Semi-Auto Behavior |
|-------|-------------------|
| Task complete | Log one-liner, continue automatically |
| Story complete | **PAUSE** -- wait for user input |
| Epic complete | **PAUSE** -- wait for user input |
| Error/ambiguity | **PAUSE** -- wait for user input |
| Scope change | Flag for review |

This means the user sees 3 pauses for this epic (one per story boundary) plus a final epic-complete pause, rather than 9 pauses (one per task) in supervised mode.

### Worktree Lifecycle

- Each story gets its own worktree branch
- Tasks within a story share the worktree
- At story completion, user chooses merge/PR/keep/discard
- Chore/docs tasks would work in-place (not applicable here)

### Agent Dispatch Pattern

For each of the 9 tasks, the coordinator dispatches up to 4 agents:

1. `yokay-brainstormer` (conditional -- only if task is underspecified)
2. `yokay-implementer` (always -- does the actual work)
3. `yokay-fixer` (conditional -- only if tests fail after implementation)
4. `yokay-browser-verifier` (conditional -- only if UI files changed and browser tools available)
5. `yokay-spec-reviewer` (always -- adversarial spec compliance)
6. `yokay-quality-reviewer` (always, if spec passes -- code quality check)

Each agent gets fresh context via the Task tool. No context degradation across tasks.

### MCP Tools Used (Summary)

| Tool | When | Purpose |
|------|------|---------|
| `get_session_context()` | Session start | Previous session state |
| `get_next_task()` | Before each task | Pick highest-priority unblocked task |
| `get_task(id)` | Before dispatch | Full task details for template |
| `get_story(id)` | Before dispatch | Story context for implementer |
| `update_task_status(id, "in_progress")` | Task start | Mark task started |
| `update_task_status(id, "done")` | Task complete | Mark task done, triggers boundary metadata |
| `add_task_activity(id, type, msg)` | Throughout | Log brainstorm, review, decisions |
| `get_task_dependencies(id)` | Pre-validation | Verify no unmet blockers |
| `set_blocker(id, reason)` | On failure | Block tasks that can't auto-fix |
