# Yokay Command Guide

This guide explains how yokay commands work together to orchestrate AI-assisted development.

## Command Overview

| Command | Purpose | Primary Skill |
|---------|---------|---------------|
| `/yokay:plan` | Analyze PRD, create tasks | prd-analyzer |
| `/yokay:work` | Execute work sessions | project-harness |
| `/yokay:audit` | Check feature completeness | product-manager |
| `/yokay:review` | Analyze session patterns | session-review |
| `/yokay:handoff` | Prepare session handoff | session-review |
| `/yokay:api` | Design REST/GraphQL APIs | api-design |
| `/yokay:ux` | Design user flows | ux-design |
| `/yokay:ui` | Create visual designs | aesthetic-ui-designer |
| `/yokay:arch` | Review architecture | architecture-review |
| `/yokay:quick` | Quick task + immediate work | - |
| `/yokay:fix` | Bug diagnosis and fix | - |
| `/yokay:spike` | Time-boxed investigation | spike |
| `/yokay:hotfix` | Production incident response | - |
| `/yokay:cicd` | CI/CD pipelines | ci-cd-expert |
| `/yokay:db` | Database design | database-design |
| `/yokay:test` | Testing strategy | testing-strategy |
| `/yokay:research` | Deep research | deep-research |
| `/yokay:security` | Security audit | security-audit |
| `/yokay:observe` | Observability | observability |
| `/yokay:docs` | Documentation | documentation |
| `/yokay:a11y` | Accessibility audit | accessibility-auditor |
| `/yokay:sdk` | SDK development | sdk-development |
| `/yokay:persona` | User personas | persona-creation |
| `/yokay:marketing` | Marketing pages | marketing-website |
| `/yokay:integrate` | API integration | api-integration |

## Command Relationships

```
                          ┌─────────────────────────────────────┐
                          │              /plan                   │
                          │    (PRD Analysis + Task Creation)    │
                          └──────────────┬──────────────────────┘
                                         │
                    ┌────────────────────┼────────────────────┐
                    │                    │                    │
                    ▼                    ▼                    ▼
           ┌───────────────┐    ┌───────────────┐    ┌───────────────┐
           │   /api        │    │    /ux        │    │    /arch      │
           │ (API Design)  │    │  (UX Design)  │    │ (Architecture)│
           └───────┬───────┘    └───────┬───────┘    └───────────────┘
                   │                    │
                   │                    ▼
                   │            ┌───────────────┐
                   │            │     /ui       │
                   │            │(Visual Design)│
                   │            └───────────────┘
                   │
                   └─────────────────┬─────────────────────────────┐
                                     │                             │
                                     ▼                             │
                          ┌─────────────────────────────────────┐  │
                          │              /work                   │  │
                          │    (Implementation with Skills)      │◄─┘
                          └──────────────┬──────────────────────┘
                                         │
              ┌──────────────────────────┼──────────────────────────┐
              │                          │                          │
              ▼                          ▼                          ▼
     ┌───────────────┐        ┌───────────────┐        ┌───────────────┐
     │    /audit     │        │   /handoff    │        │   /review     │
     │ (Completeness)│        │(Session End)  │        │ (Analysis)    │
     └───────┬───────┘        └───────────────┘        └───────────────┘
             │
             └──────────► Creates remediation tasks ──────► /work
```

## Ad-Hoc Commands

For work that doesn't fit the PRD-to-task flow:

### Quick Tasks
```bash
/yokay:quick "add logout button to header"
```
Creates task, starts work immediately, marks done when complete.

### Bug Fixes
```bash
/yokay:fix "login fails with special characters"
/yokay:fix T045  # Fix existing bug task
```
Structured diagnosis → fix → test workflow.

### Production Incidents
```bash
/yokay:hotfix "500 errors on /api/users"
```
Expedited fix with mitigation-first approach, optional postmortem.

### Technical Spikes
```bash
/yokay:spike "Can we use Redis for session storage?"
```
Time-boxed investigation with mandatory decision output (GO/NO-GO/PIVOT).

## Typical Workflow

### 1. Planning Phase
```bash
/yokay:plan path/to/prd.md
```
- Analyzes PRD and creates tasks in ohno
- Tags tasks with recommended skills
- Creates `.claude/PROJECT.md` for context

### 2. Work Phase
```bash
/yokay:work supervised   # Pause after every task
/yokay:work semi-auto    # Pause at story boundaries
/yokay:work autonomous   # Pause at epic boundaries
```
- Routes to appropriate skills based on task type
- Handles spike tasks with time-boxing
- Creates incremental git commits

### 3. Quality Phase
```bash
/yokay:audit            # Check accessibility (L0-L5)
/yokay:audit --full     # Check all dimensions
```
- Multi-dimensional auditing:
  - Accessibility (L0-L5)
  - Testing (T0-T4)
  - Documentation (D0-D4)
  - Security (S0-S4)
  - Observability (O0-O4)

### 4. Session Management
```bash
/yokay:handoff          # End session, save context
/yokay:review           # Analyze patterns and improvements
```

## Skill Routing

The `/work` command routes to skills based on task type, or use direct commands:

| Task Type | Skill | Direct Command |
|-----------|-------|----------------|
| API endpoints | api-design | `/yokay:api` |
| UI components | aesthetic-ui-designer | `/yokay:ui` |
| User flows | ux-design | `/yokay:ux` |
| Database work | database-design | `/yokay:db` |
| CI/CD | ci-cd-expert | `/yokay:cicd` |
| Testing | testing-strategy | `/yokay:test` |
| Security | security-audit | `/yokay:security` |
| Monitoring | observability | `/yokay:observe` |
| Investigation | spike | `/yokay:spike` |
| Research | deep-research | `/yokay:research` |
| Documentation | documentation | `/yokay:docs` |
| Accessibility | accessibility-auditor | `/yokay:a11y` |
| SDK/Packages | sdk-development | `/yokay:sdk` |
| User personas | persona-creation | `/yokay:persona` |
| Marketing pages | marketing-website | `/yokay:marketing` |
| API integration | api-integration | `/yokay:integrate` |

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
| `yokay-explorer` | Haiku | Read-only | Fast codebase exploration |
| `yokay-reviewer` | Sonnet | Read-only | Code review and analysis |
| `yokay-spike-runner` | Sonnet | Can write | Time-boxed investigations |
| `yokay-security-scanner` | Sonnet | Read-only | OWASP vulnerability scanning |
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
| `/yokay:audit` | yokay-auditor | Always (verbose scanning) |
| `/yokay:spike` | yokay-spike-runner | Deep investigations (>1h) |
| `/yokay:security` | yokay-security-scanner | Always (verbose scanning) |
| `/yokay:test` | yokay-test-runner | Running tests (not designing) |

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

## Hook System

Hooks guarantee critical actions execute at session lifecycle points, eliminating reliance on LLM memory:

| Hook | When | Default Actions |
|------|------|-----------------|
| pre-session | Session start | verify-clean |
| pre-task | Task start | check-blockers |
| post-task | Task complete | sync, commit |
| post-story | Story complete | test, audit |
| post-session | Session end | final sync, summary |

### Mode Behavior

- **supervised**: sync only (no auto-commit)
- **semi-auto**: sync, commit
- **autonomous**: sync, commit, quick-test

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

---

## Complete Workflow Example

Here's a full example of using yokay to build a feature:

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
/yokay:plan docs/prd.md
```

Output:
```
Created implementation plan:
- Epic: User Dashboard (4 stories, 12 tasks)
  - Story: Dashboard API (3 tasks) → api-design
  - Story: Dashboard UI (4 tasks) → ux-design, aesthetic-ui-designer
  - Story: Activity Feed (3 tasks) → api-design, aesthetic-ui-designer
  - Story: Quick Actions (2 tasks) → aesthetic-ui-designer

View kanban: npx @stevestomp/ohno-cli serve
```

### Step 3: Work on tasks

```bash
/yokay:work supervised
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
/yokay:audit
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
/yokay:work semi-auto
```

Work through remediation tasks, then audit again until all features reach L5.

---

## Detailed Command Reference

### /yokay:plan

Analyzes a PRD, concept brief, or feature spec and creates a structured implementation plan.

**What it does:**
1. Reads and parses the document
2. Extracts features, requirements, and constraints
3. Creates epics, stories, and tasks in ohno
4. Assigns skills to features based on type
5. Generates `.claude/PROJECT.md` for shared context

**Example:**
```bash
/yokay:plan docs/feature-spec.md
```

### /yokay:work

Starts or continues an orchestrated work session with configurable human control.

**Modes:**
- `supervised` (default) - Pause after every task
- `semi-auto` - Pause at story/epic boundaries
- `autonomous` - Pause only at epic boundaries

**Example:**
```bash
/yokay:work semi-auto
```

### /yokay:audit

Audits feature completeness by scanning the codebase and comparing against requirements.

**What it checks:**
- Backend implementation (APIs, services, models)
- Frontend implementation (components, pages)
- User accessibility (routes, navigation)
- Creates remediation tasks for gaps

**Example:**
```bash
/yokay:audit                    # Audit all features
/yokay:audit UserDashboard      # Audit specific feature
/yokay:audit --dimension testing # Check testing coverage
/yokay:audit --full             # All 5 dimensions
```

### /yokay:spike

Time-boxed technical investigation with mandatory decision output.

**Example:**
```bash
/yokay:spike "Can we use Redis for session storage?"
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
/yokay:work supervised
```

- **Pauses after every task** for your approval
- Best for: Critical features, learning the codebase, new projects
- You see exactly what's happening and approve each step

### Semi-Auto

```bash
/yokay:work semi-auto
```

- **Logs task completion, pauses at story boundaries**
- Best for: Established patterns, trusted implementations
- Review batches of related work together

### Autonomous

```bash
/yokay:work autonomous
```

- **Only pauses at epic boundaries**
- Best for: Well-defined features, bulk implementation
- Maximum speed, minimum interruption

### Mode Comparison

| Mode | Task Complete | Story Complete | Epic Complete |
|------|--------------|----------------|---------------|
| supervised | PAUSE | PAUSE | PAUSE |
| semi-auto | log | PAUSE | PAUSE |
| autonomous | log | log | PAUSE |

---

## Use Cases

### Starting a new project
1. Write a PRD or feature spec
2. `/yokay:plan docs/prd.md` to create tasks
3. `/yokay:work supervised` to implement with oversight
4. `/yokay:audit` to verify completeness

### Resuming interrupted work
1. Claude automatically reads session context from ohno
2. `/yokay:work` continues where you left off
3. All previous decisions and progress are preserved

### Verifying a feature is complete
1. `/yokay:audit FeatureName` checks implementation
2. Identifies gaps (L0-L4 features)
3. Creates remediation tasks automatically
4. Re-audit after fixes to confirm L5

### Design-first workflow
1. `/yokay:ux` to design user flows first
2. `/yokay:ui` to create visual designs
3. `/yokay:api` to design backend APIs
4. `/yokay:work` to implement the designs

---

## Tips & Best Practices

### Planning
- **Be specific in PRDs**: The more detail, the better the task breakdown
- **Include technical constraints**: Stack, existing patterns, etc.
- **Define success criteria**: How do you know a feature is done?

### Working
- **Start supervised**: Get comfortable before using autonomous mode
- **Review at boundaries**: Even in autonomous mode, review at epic boundaries
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

Then create tasks with `/yokay:plan` or manually.

### "Skill not found"

Ensure the plugin is installed:
```bash
claude plugin list
```

If not listed, reinstall:
```bash
claude plugin add https://github.com/srstomp/pokayokay
```

### Session context lost

Check ohno context:
```bash
npx @stevestomp/ohno-cli context
```

If empty, previous session may not have synced. Start fresh with `/yokay:plan`.

### Agent not delegating

If commands aren't delegating to agents:
1. Check that `plugins/yokay/agents/` directory exists
2. Verify agent files have correct YAML frontmatter
3. Try explicit invocation: "Use the yokay-auditor agent to..."
