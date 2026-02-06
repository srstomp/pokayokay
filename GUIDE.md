# pokayokay Command Guide

This guide explains how pokayokay commands work together to orchestrate AI-assisted development.

## Command Overview

| Command | Purpose | Primary Skill |
|---------|---------|---------------|
| `/pokayokay:plan` | Analyze PRD, create tasks | prd-analyzer |
| `/pokayokay:revise` | Revise existing plan | plan-revision |
| `/pokayokay:work` | Execute work sessions | project-harness |
| `/pokayokay:audit` | Check feature completeness | product-manager |
| `/pokayokay:review` | Analyze session patterns | session-review |
| `/pokayokay:handoff` | Prepare session handoff | session-review |
| `/pokayokay:api` | Design REST/GraphQL APIs | api-design |
| `/pokayokay:arch` | Review architecture | architecture-review |
| `/pokayokay:quick` | Quick task + immediate work | - |
| `/pokayokay:fix` | Bug diagnosis and fix | - |
| `/pokayokay:spike` | Time-boxed investigation | spike |
| `/pokayokay:hotfix` | Production incident response | - |
| `/pokayokay:cicd` | CI/CD pipelines | ci-cd-expert |
| `/pokayokay:db` | Database design | database-design |
| `/pokayokay:test` | Testing strategy | testing-strategy |
| `/pokayokay:research` | Deep research | deep-research |
| `/pokayokay:security` | Security audit | security-audit |
| `/pokayokay:observe` | Observability | observability |
| `/pokayokay:docs` | Documentation | documentation |
| `/pokayokay:sdk` | SDK development | sdk-development |
| `/pokayokay:integrate` | API integration | api-integration |

## Command Relationships

```
                          ┌─────────────────────────────────────┐
                          │              /plan                   │
                          │    (PRD Analysis + Task Creation)    │
                          └──────────────┬──────────────────────┘
                                         │
                                         ▼
                          ┌─────────────────────────────────────┐
                          │             /revise                  │
                          │   (Optional Plan Refinement)         │◄───────┐
                          └──────────────┬──────────────────────┘        │
                                         │                               │
                    ┌────────────────────┼────────────────────┐          │
                    │                    │                    │          │
                    ▼                    ▼                    ▼          │
           ┌───────────────┐    ┌───────────────┐    ┌───────────────┐   │
           │   /api        │    │    /db        │    │    /arch      │   │
           │ (API Design)  │    │  (Database)   │    │ (Architecture)│   │
           └───────┬───────┘    └───────────────┘    └───────────────┘   │
                   │                                                     │
                   └─────────────────┬─────────────────────────────┐     │
                                     │                             │     │
                                     ▼                             │     │
                          ┌─────────────────────────────────────┐  │     │
                          │              /work                   │  │     │
                          │    (Implementation with Skills)      │◄─┘     │
                          └──────────────┬──────────────────────┘        │
                                         │                               │
              ┌──────────────────────────┼──────────────────────────┐    │
              │                          │                          │    │
              ▼                          ▼                          ▼    │
     ┌───────────────┐        ┌───────────────┐        ┌───────────────┐ │
     │    /audit     │        │   /handoff    │        │   /review     │─┘
     │ (Completeness)│        │(Session End)  │        │ (Analysis)    │
     └───────┬───────┘        └───────────────┘        └───────────────┘
             │
             └──────────► Creates remediation tasks ──────► /work
```

## Ad-Hoc Commands

For work that doesn't fit the PRD-to-task flow:

### Quick Tasks
```bash
/pokayokay:quick "add logout button to header"
```
Creates task, starts work immediately, marks done when complete.

### Bug Fixes
```bash
/pokayokay:fix "login fails with special characters"
/pokayokay:fix T045  # Fix existing bug task
```
Structured diagnosis → fix → test workflow.

### Production Incidents
```bash
/pokayokay:hotfix "500 errors on /api/users"
```
Expedited fix with mitigation-first approach, optional postmortem.

### Technical Spikes
```bash
/pokayokay:spike "Can we use Redis for session storage?"
```
Time-boxed investigation with mandatory decision output (GO/NO-GO/PIVOT).

## Typical Workflow

### 1. Planning Phase
```bash
/pokayokay:plan path/to/prd.md
```
- Analyzes PRD and creates tasks in ohno
- Tags tasks with recommended skills
- Creates `.claude/PROJECT.md` for context

### 1b. Revision Phase (Optional)
```bash
/pokayokay:revise              # If you want to refine the plan
/pokayokay:revise --direct     # If you know exactly what to change
```
- Review and adjust tasks before starting work
- See impact of changes before applying them
- Useful after feedback or requirements change

### 2. Work Phase
```bash
/pokayokay:work supervised   # Pause after every task
/pokayokay:work semi-auto    # Pause at story boundaries
/pokayokay:work auto         # Pause at epic boundaries
```
- Routes to appropriate skills based on task type
- Handles spike tasks with time-boxing
- Creates incremental git commits

### 3. Quality Phase
```bash
/pokayokay:audit            # Check accessibility (L0-L5)
/pokayokay:audit --full     # Check all dimensions
```
- Multi-dimensional auditing:
  - Accessibility (L0-L5)
  - Testing (T0-T4)
  - Documentation (D0-D4)
  - Security (S0-S4)
  - Observability (O0-O4)

### 4. Session Management
```bash
/pokayokay:handoff          # End session, save context
/pokayokay:review           # Analyze patterns and improvements
```

## Skill Routing

The `/work` command routes to skills based on task type, or use direct commands:

| Task Type | Skill | Direct Command |
|-----------|-------|----------------|
| API endpoints | api-design | `/pokayokay:api` |
| Database work | database-design | `/pokayokay:db` |
| CI/CD | ci-cd-expert | `/pokayokay:cicd` |
| Testing | testing-strategy | `/pokayokay:test` |
| Security | security-audit | `/pokayokay:security` |
| Monitoring | observability | `/pokayokay:observe` |
| Investigation | spike | `/pokayokay:spike` |
| Research | deep-research | `/pokayokay:research` |
| Documentation | documentation | `/pokayokay:docs` |
| SDK/Packages | sdk-development | `/pokayokay:sdk` |
| API integration | api-integration | `/pokayokay:integrate` |

## Keyword Detection

Tasks are automatically routed based on keywords:

| Keywords | Skill |
|----------|-------|
| database, schema, migration | database-design |
| test, coverage, e2e, playwright | testing-strategy |
| deploy, pipeline, ci/cd | ci-cd-expert |
| security, auth, encryption | security-audit |
| logging, monitoring, metrics | observability |
| spike, investigate, feasibility | spike |
| research, evaluate, compare | deep-research |

## Spike Protocol

For high-uncertainty work:

1. **Time-box**: 2-4 hours default, max 1 day
2. **Checkpoints**: 50% progress review
3. **Decision required**: GO / NO-GO / PIVOT / MORE-INFO
4. **Output**: `.claude/spikes/[name].md`

## Integration with ohno

All commands integrate with the ohno MCP server:
- `create_task` - Create tasks
- `get_next_task` - Get prioritized work
- `update_task_status` - Track progress
- `add_task_activity` - Log work
- `get_session_context` - Resume sessions

View the kanban:
```bash
npx @stevestomp/ohno-cli serve
```

## Sub-Agents

Sub-agents provide **isolated execution** for verbose operations. They run in separate context windows, keeping the main conversation clean while enforcing constraints like read-only access.

### Available Agents

| Agent | Model | Mode | Purpose |
|-------|-------|------|---------|
| `yokay-auditor` | Sonnet | Read-only | L0-L5 completeness scanning |
| `yokay-brainstormer` | Sonnet | Read-only | Refine ambiguous tasks into clear requirements |
| `yokay-browser-verifier` | Sonnet | Read-only | Browser verification for UI changes |
| `yokay-explorer` | Haiku | Read-only | Fast codebase exploration |
| `yokay-fixer` | Sonnet | Can write | Auto-retry on test failures with targeted fixes |
| `yokay-implementer` | Sonnet | Can write | TDD implementation with fresh context |
| `yokay-quality-reviewer` | Haiku | Read-only | Code quality, tests, and conventions review |
| `yokay-reviewer` | Sonnet | Read-only | Code review and analysis |
| `yokay-security-scanner` | Sonnet | Read-only | OWASP vulnerability scanning |
| `yokay-spec-reviewer` | Haiku | Read-only | Verify implementation matches spec |
| `yokay-spike-runner` | Sonnet | Can write | Time-boxed investigations |
| `yokay-test-runner` | Haiku | Standard | Test execution with concise output |

### Agent vs Skill

| Component | Context | Use Case |
|-----------|---------|----------|
| **Skills** | Main conversation | Interactive work, orchestration, needs shared context |
| **Agents** | Isolated | Verbose output, enforced constraints, parallel execution |

### Automatic Delegation

Commands that benefit from isolated execution include delegation instructions:

| Command | Delegates To | When |
|---------|--------------|------|
| `/pokayokay:audit` | yokay-auditor | Always (verbose scanning) |
| `/pokayokay:spike` | yokay-spike-runner | Deep investigations (>1h) |
| `/pokayokay:security` | yokay-security-scanner | Always (verbose scanning) |
| `/pokayokay:test` | yokay-test-runner | Running tests (not designing) |
| `/pokayokay:work` | yokay-brainstormer | Ambiguous tasks (before impl) |
| `/pokayokay:work` | yokay-implementer | Task execution (dispatched) |
| `/pokayokay:work` | yokay-browser-verifier | UI changes (after implementation) |
| `/pokayokay:work` | yokay-fixer | When tests fail after implementation |
| `/pokayokay:work` | yokay-spec-reviewer | After browser verification |
| `/pokayokay:work` | yokay-quality-reviewer | After spec review passes |

### Manual Invocation

You can also invoke agents directly:

```
Use the yokay-explorer agent to understand how authentication works in this codebase.
```

```
Use yokay-auditor to check the completeness of the dashboard feature.
```

### Benefits

1. **Context isolation** - Verbose scan output stays separate
2. **Cost optimization** - Haiku agents are 5-10x cheaper
3. **Enforced constraints** - Read-only agents can't accidentally edit
4. **Parallel execution** - Run multiple investigations simultaneously

### Brainstorm Gate

For ambiguous tasks, `yokay-brainstormer` runs **before** implementation begins:

```
AMBIGUOUS TASK → yokay-brainstormer → CLEAR REQUIREMENTS → Implementation
```

**Triggers:**
- Short or vague task descriptions
- Missing acceptance criteria
- Spike-type investigations
- Features with unclear scope

**Output:**
- Gaps identified in the spec
- Proposed acceptance criteria (Must Have / Should Have / Could Have)
- Technical approach recommendation
- Questions for human if still unclear

This prevents wasted implementation effort from misunderstood requirements.

### Two-Stage Review

After implementation completes, work passes through two sequential reviews:

```
IMPLEMENTATION → yokay-spec-reviewer → yokay-quality-reviewer → COMPLETE
                      ↓ FAIL                  ↓ FAIL
                 Re-implement              Re-implement
```

**Stage 1: Spec Review** (`yokay-spec-reviewer`)
- Verifies all acceptance criteria are met
- Checks for misinterpretations
- Flags scope creep (unrequested features)
- Binary PASS/FAIL verdict

**Stage 2: Quality Review** (`yokay-quality-reviewer`)
- Only runs after spec review passes
- Checks code structure and readability
- Verifies test coverage and quality
- Checks project conventions
- Binary PASS/FAIL verdict

Both reviews must PASS before a task is marked complete. If either fails, the implementer is re-dispatched with specific fix requirements.

**Why two stages?**
- Separates "did we build the right thing?" from "did we build it well?"
- Prevents quality issues from masking spec failures
- Enables focused, actionable feedback

### Browser Verification

For tasks that modify UI-related files, browser verification runs **after implementation and before reviews**:

```
IMPLEMENTATION → browser-verify → yokay-spec-reviewer → yokay-quality-reviewer → COMPLETE
```

**What it checks:**
- Visual elements render correctly
- Interactive features work as expected
- No JavaScript console errors
- Page loads without issues

**When it runs:**

All three conditions must be true:

| Condition | Check |
|-----------|-------|
| Browser tools available | Playwright MCP or Chrome extension |
| Server running | HTTP server on ports 3000-9999 |
| UI files changed | `.html`, `.css`, `.tsx`, `.jsx`, `.vue`, `.svelte`, or files in `components/`, `views/`, `ui/`, `pages/` |

If any condition fails, verification is silently skipped.

**Advisory behavior:**

Browser verification is advisory, not blocking:
- User can skip with a reason ("tests cover this", "backend-only change", etc.)
- Skip reason is logged in task notes
- Work continues to spec review with warning flag

**Configuration:**

Create `.yokay/browser-verification.yaml` to customize:

```yaml
enabled: true
server:
  preferredPort: 5173  # Vite default
files:
  additionalPaths:
    - src/templates/
  excludePaths:
    - src/email-templates/
```

See `skills/browser-verification/SKILL.md` for full details.

## Hook System

Hooks guarantee critical actions execute at session lifecycle points, eliminating reliance on LLM memory:

| Hook | When | Default Actions |
|------|------|-----------------|
| pre-session | Session start | verify-clean |
| pre-task | Task start | check-blockers |
| post-task | Task complete | sync, commit |
| post-story | Story complete | test, audit |
| post-command | After audit commands | verify-tasks |
| post-session | Session end | final sync, summary |

### Mode Behavior

- **supervised**: sync only (no auto-commit)
- **semi-auto**: sync, commit
- **auto**: sync, commit, quick-test

### Custom Hooks

Create `.yokay/hooks.yaml` in your project to customize:

```yaml
hooks:
  post-task:
    actions:
      - sync
      - commit
      - my-custom-action

  pre-commit:
    enabled: false
```

See `hooks/HOOKS.md` for full documentation.

### Post-Command Hooks (Audit Task Verification)

Audit commands automatically create ohno tasks for findings. Post-command hooks verify this happened:

| Command | Creates Tasks | Verification |
|---------|---------------|--------------|
| `/pokayokay:security` | Always (Critical/High/Medium findings) | Checks for `Security:` prefix |
| `/pokayokay:test --audit` | With `--audit` flag | Checks for `Test:` prefix |
| `/pokayokay:observe --audit` | With `--audit` flag | Checks for `Observability:` prefix |
| `/pokayokay:arch --audit` | With `--audit` flag | Checks for `Arch:` prefix |

If an audit command completes without creating tasks, the hook warns:
```
Warning: No tasks with prefix 'Security:' found after running pokayokay:security
Action: If findings were discovered, ensure tasks were created using ohno MCP create_task.
```

This ensures audit findings become tracked, actionable work items.

## Kaizen Integration

Kaizen is an optional tool that learns from review failures and automatically suggests or creates fix tasks based on pattern confidence.

### What is Kaizen?

When spec-review or quality-review fails, the `post-review-fail.sh` hook can integrate with kaizen to:
- Detect the failure category (missing-tests, scope-creep, wrong-product)
- Capture the failure in a pattern database
- Suggest actions based on confidence from historical data

Over time, kaizen learns which failures are common and can auto-create fix tasks for them.

### Installation

**Required:**
```bash
# Install kaizen CLI
go install github.com/srstomp/kaizen@latest

# Install jq (for JSON parsing)
brew install jq  # macOS
# or: sudo apt-get install jq  # Linux
```

**Optional - Initialize in your project:**
```bash
kaizen init  # Creates .kaizen/ for project-local storage
```

If not initialized, kaizen uses global storage at `~/.config/kaizen/`.

### How It Works

```
Review Fails → post-review-fail.sh → kaizen analyze → Action
                                                        |
                        ┌───────────────────────────────┼──────────────┐
                        ▼                               ▼              ▼
                      AUTO                          SUGGEST        LOGGED
                (auto-create task)            (prompt user)    (just record)
```

The hook is automatically invoked by pokayokay when reviews fail. It sets environment variables (`TASK_ID`, `FAILURE_DETAILS`, `FAILURE_SOURCE`) and kaizen responds with an action.

### Confidence Thresholds

Kaizen determines confidence based on how often it has seen similar failures:

| Occurrences | Confidence | Action | pokayokay Behavior |
|-------------|------------|--------|--------------------|
| 5+ times | High | AUTO | Automatically creates fix task in ohno |
| 2-4 times | Medium | SUGGEST | Prompts user to create fix task |
| 0-1 times | Low | LOGGED | Logs failure, no task created |

The more failures captured, the smarter kaizen becomes.

### Configuration

**Storage Location:**
- **Project-local**: `.kaizen/` (recommended for team projects)
- **Global**: `~/.config/kaizen/` (default if not initialized)

**Hook Integration:**
The `hooks/post-review-fail.sh` hook is built into pokayokay and requires no configuration. It automatically checks for kaizen availability.

### Example Workflow

**First time a failure occurs:**
```bash
# Review fails: "No test file found for src/api/users.go"
# → kaizen captures it as "missing-tests" category
# → Returns: {"action": "LOGGED"}
# → pokayokay logs the failure, no fix task created
```

**After 5 similar failures:**
```bash
# Review fails again: "Missing test coverage for API endpoint"
# → kaizen recognizes pattern with high confidence
# → Returns: {"action": "AUTO", "fix_task": {...}}
# → pokayokay auto-creates: "Add tests for task-123"
```

### Full Documentation

For detailed configuration, troubleshooting, and advanced usage, see:
- [docs/integrations/kaizen.md](docs/integrations/kaizen.md) - Complete integration guide
- [kaizen GitHub](https://github.com/srstomp/kaizen) - kaizen CLI repository

---

## Complete Workflow Example

Here's a full example of using pokayokay to build a feature:

### Step 1: Create a PRD

Create `docs/prd.md`:

```markdown
# User Dashboard Feature

## Overview
Users need a dashboard to view their activity and stats.

## Requirements
- Display user's recent activity (last 10 items)
- Show key metrics: total posts, followers, engagement rate
- Quick actions: create post, view notifications
- Responsive design for mobile

## Technical Notes
- Use existing auth system
- Data from /api/users/:id/stats endpoint
```

### Step 2: Plan the work

```bash
/pokayokay:plan docs/prd.md
```

Output:
```
Created implementation plan:
- Epic: User Dashboard (4 stories, 12 tasks)
  - Story: Dashboard API (3 tasks) → api-design
  - Story: Dashboard UI (4 tasks) → testing-strategy
  - Story: Activity Feed (3 tasks) → api-design
  - Story: Quick Actions (2 tasks) → testing-strategy

View kanban: npx @stevestomp/ohno-cli serve
```

### Step 3: Work on tasks

```bash
/pokayokay:work supervised
```

Claude picks up the first task:
```
Starting: Create /api/users/:id/stats endpoint
Loading skill: api-design

[Claude implements the endpoint]

Task complete. Options:
1. Continue to next task
2. Review changes first
3. Switch to different task
4. Stop session

Your choice?
```

### Step 4: Continue or pause

Type `1` to continue, or `2` to review. In supervised mode, you approve each task.

### Step 5: Audit when ready

After implementing, verify everything is accessible:

```bash
/pokayokay:audit
```

Output:
```
## Audit Results

| Feature | Level | Status |
|---------|-------|--------|
| Dashboard API | L1 | Backend only - no frontend |
| Dashboard UI | L4 | Missing nav link |
| Activity Feed | L5 | Complete |
| Quick Actions | L5 | Complete |

Remediation tasks created:
- Add Dashboard to navigation menu
- Create Dashboard page component
```

### Step 6: Fix gaps and re-audit

```bash
/pokayokay:work semi-auto
```

Work through remediation tasks, then audit again until all features reach L5.

---

## Detailed Command Reference

### /pokayokay:plan

Analyzes a PRD, concept brief, or feature spec and creates a structured implementation plan.

**What it does:**
1. Reads and parses the document
2. Extracts features, requirements, and constraints
3. Creates epics, stories, and tasks in ohno
4. Assigns skills to features based on type
5. Generates `.claude/PROJECT.md` for shared context

**Flags:**
- `--headless` - Autonomous analysis without prompts. Auto-decides on spikes, design tasks, dependencies, and logs each as a "notable decision" for later review.
- `--review` - Interactive review of existing plan. Walks through notable decisions, lets you adjust tasks, priorities, and dependencies.

**Examples:**
```bash
/pokayokay:plan docs/feature-spec.md               # Interactive (default)
/pokayokay:plan --headless docs/feature-spec.md     # Autonomous analysis
/pokayokay:plan --review                            # Review existing plan
```

### /pokayokay:revise

Revise an existing plan through guided conversation or directed changes, with full impact analysis before execution.

**Modes:**
- **Explore** (default) - Guided discovery when you're unsure what to change
- **Direct** (`--direct`) - Fast path when you know exactly what to change

**What it does:**
1. Loads current plan from ohno
2. Guides you through changes (explore) or parses your intent (direct)
3. Shows impact analysis: ticket diff, risk assessment, dependency graph
4. Executes changes with approval (dry-run first)

**Example:**
```bash
/pokayokay:revise                    # Explore mode - "something feels off"
/pokayokay:revise --direct           # Direct mode - "I want to change X"
```

**Use when:**
- After `/plan` to refine before starting work
- Mid-project when requirements change
- After `/review` to act on retrospective findings

### /pokayokay:work

Starts or continues an orchestrated work session with configurable human control.

**Modes:**
- `supervised` (default) - Pause after every task
- `semi-auto` - Pause at story/epic boundaries
- `auto` - Pause only at epic boundaries

**Flags:**
- `--continue` - Resume an interrupted session, picking up tasks with saved WIP data
- `-n <count>` - Run N tasks in parallel (default: 1)
- `-n auto` - Adaptive parallel sizing (starts at 2, adjusts based on outcomes)
- `--epic <id>` / `--story <id>` / `--all` - Scope which tasks to work on

> **Note:** `-p` is reserved for the Claude CLI `--prompt` flag. Use `-n` for parallel count.
> Headless session chaining is configured in `.claude/pokayokay.json`, not via a flag. See README for details.

**Examples:**
```bash
/pokayokay:work semi-auto             # Standard semi-auto session
/pokayokay:work --continue            # Resume interrupted session
/pokayokay:work semi-auto -n 3        # 3 tasks in parallel
/pokayokay:work semi-auto -n auto     # Adaptive parallel sizing
/pokayokay:work auto --story story-abc123  # Scoped to a story
```

### /pokayokay:audit

Audits feature completeness by scanning the codebase and comparing against requirements.

**What it checks:**
- Backend implementation (APIs, services, models)
- Frontend implementation (components, pages)
- User accessibility (routes, navigation)
- Creates remediation tasks for gaps

**Example:**
```bash
/pokayokay:audit                    # Audit all features
/pokayokay:audit UserDashboard      # Audit specific feature
/pokayokay:audit --dimension testing # Check testing coverage
/pokayokay:audit --full             # All 5 dimensions
```

### /pokayokay:spike

Time-boxed technical investigation with mandatory decision output.

**Example:**
```bash
/pokayokay:spike "Can we use Redis for session storage?"
```

**Outputs:** GO / NO-GO / PIVOT / MORE-INFO decision with evidence.

---

## Completeness Levels (L0-L5)

The audit system uses six levels to track feature accessibility:

| Level | Name | What it means |
|-------|------|---------------|
| **L0** | Not Started | No implementation found |
| **L1** | Backend Only | API/service exists, no frontend |
| **L2** | Frontend Exists | Component exists, not routable |
| **L3** | Routable | Has URL route, not in navigation |
| **L4** | Accessible | In navigation, missing polish |
| **L5** | Complete | Fully implemented and user-accessible |

### Why this matters

A common problem in development:

```
PRD says: "User can export data to CSV"
Backend:   ✓ /api/export endpoint exists
Frontend:  ✓ ExportButton component exists
Route:     ✗ No page uses ExportButton
Navigation: ✗ No menu item
Result:    L2 - Users can't actually export!
```

The audit catches these gaps and creates remediation tasks automatically.

---

## Work Modes Explained

### Supervised (Default)

```bash
/pokayokay:work supervised
```

- **Pauses after every task** for your approval
- Best for: Critical features, learning the codebase, new projects
- You see exactly what's happening and approve each step

### Semi-Auto

```bash
/pokayokay:work semi-auto
```

- **Logs task completion, pauses at story boundaries**
- Best for: Established patterns, trusted implementations
- Review batches of related work together

### Auto

```bash
/pokayokay:work auto
```

- **Only pauses at epic boundaries**
- Best for: Well-defined features, bulk implementation
- Maximum speed, minimum interruption

### Mode Comparison

| Mode | Task Complete | Story Complete | Epic Complete |
|------|--------------|----------------|---------------|
| supervised | PAUSE | PAUSE | PAUSE |
| semi-auto | log | PAUSE | PAUSE |
| auto | log | log | PAUSE |

---

## Use Cases

### Starting a new project
1. Write a PRD or feature spec
2. `/pokayokay:plan docs/prd.md` to create tasks
3. `/pokayokay:revise` to refine if needed
4. `/pokayokay:work supervised` to implement with oversight
5. `/pokayokay:audit` to verify completeness

### Revising a plan mid-project
1. `/pokayokay:revise` to explore what needs to change
2. Review impact analysis (affected tasks, risks)
3. Approve changes or iterate
4. `/pokayokay:work` to continue with updated plan

### Resuming interrupted work
1. Use `/pokayokay:work --continue` to resume with saved WIP data
2. Tasks with in-progress work skip brainstorming and load previous context
3. All previous decisions and progress are preserved

### Headless session chaining
1. Configure chaining in `.claude/pokayokay.json` (see README)
2. Run `/pokayokay:work auto --story story-abc123` with a scope
3. When context fills, session exits gracefully and a new one spawns automatically
4. Chain reports are generated to `.ohno/reports/`
5. Max chain limit (default 10) prevents runaway execution

### Verifying a feature is complete
1. `/pokayokay:audit FeatureName` checks implementation
2. Identifies gaps (L0-L4 features)
3. Creates remediation tasks automatically
4. Re-audit after fixes to confirm L5

### API-first workflow
1. `/pokayokay:api` to design backend APIs
2. `/pokayokay:db` to design database schema
3. `/pokayokay:work` to implement the designs

---

## Tips & Best Practices

### Planning
- **Be specific in PRDs**: The more detail, the better the task breakdown
- **Include technical constraints**: Stack, existing patterns, etc.
- **Define success criteria**: How do you know a feature is done?

### Working
- **Start supervised**: Get comfortable before using auto mode
- **Review at boundaries**: Even in auto mode, review at epic boundaries
- **Use handoff notes**: Document decisions for future sessions

### Auditing
- **Audit early and often**: Don't wait until "done" to audit
- **Fix L1-L2 gaps first**: Backend-only features are common
- **Check navigation**: L3 features are technically done but inaccessible

### Task Management
- **Keep tasks small**: 1-8 hours max per task
- **Use task types**: feature, bug, chore, spike, test
- **Block early**: If something is blocking, mark it

---

## Troubleshooting

### "ohno MCP not available"

Make sure ohno is configured in your MCP settings:
```json
{
  "mcpServers": {
    "ohno": {
      "command": "npx",
      "args": ["@stevestomp/ohno-mcp"]
    }
  }
}
```

### "No tasks found"

Initialize ohno in your project:
```bash
npx @stevestomp/ohno-cli init
```

Then create tasks with `/pokayokay:plan` or manually.

### "Skill not found"

Ensure the plugin is installed:
```bash
claude plugin list
```

If not listed, reinstall:
```bash
claude plugin marketplace add srstomp/pokayokay
claude plugin install pokayokay@srstomp-pokayokay
```

### Session context lost

Check ohno context:
```bash
npx @stevestomp/ohno-cli context
```

If empty, previous session may not have synced. Start fresh with `/pokayokay:plan`.

### Agent not delegating

If commands aren't delegating to agents:
1. Check that `agents/` directory exists
2. Verify agent files have correct YAML frontmatter
3. Try explicit invocation: "Use the yokay-auditor agent to..."
