# pokayokay User Guide

Complete guide to using pokayokay for AI-assisted development with human control.

## Table of Contents

- [Getting Started](#getting-started)
- [Complete Workflow Example](#complete-workflow-example)
- [Commands Reference](#commands-reference)
- [Work Modes](#work-modes)
- [Completeness Levels](#completeness-levels)
- [Skills](#skills)
- [ohno CLI Reference](#ohno-cli-reference)
- [Use Cases](#use-cases)

---

## Getting Started

### 1. Install the plugin

```bash
claude plugin marketplace add https://github.com/srstomp/pokayokay
claude plugin install pokayokay
```

### 2. Configure ohno MCP Server

Add to your Claude Code settings (`~/.claude/settings.json`):

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

### 3. Initialize your project

```bash
cd your-project
npx @stevestomp/ohno-cli init
```

### 4. Plan from a PRD

```
/pokayokay:plan docs/prd.md
```

This analyzes your PRD and creates:
- Tasks in ohno (epics → stories → tasks)
- `.claude/PROJECT.md` for shared context
- Skill assignments for each feature

### 5. View your kanban board

```bash
npx @stevestomp/ohno-cli serve
# Opens http://localhost:3456
```

### 6. Start working

```
/pokayokay:work supervised
```

Claude will:
1. Get the next task from ohno
2. Route to the appropriate skill
3. Implement the task
4. Pause for your approval (in supervised mode)
5. Repeat until done

### 7. Audit completeness

```
/pokayokay:audit
```

Verify features are not just implemented but actually user-accessible.

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

```
/pokayokay:plan docs/prd.md
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

```
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

```
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

```
/pokayokay:work semi-auto
```

Work through remediation tasks, then audit again until all features reach L5.

---

## Commands Reference

| Command | Description | Example |
|---------|-------------|---------|
| `/pokayokay:plan <path>` | Analyze PRD and create tasks | `/pokayokay:plan docs/prd.md` |
| `/pokayokay:work [mode]` | Start/continue work session | `/pokayokay:work semi-auto` |
| `/pokayokay:audit [feature]` | Audit feature completeness | `/pokayokay:audit Dashboard` |
| `/pokayokay:review` | Analyze completed sessions | `/pokayokay:review` |
| `/pokayokay:api <task>` | Design APIs | `/pokayokay:api user stats endpoint` |
| `/pokayokay:ux <task>` | Design user flows | `/pokayokay:ux onboarding flow` |
| `/pokayokay:ui <task>` | Visual design | `/pokayokay:ui dashboard cards` |
| `/pokayokay:arch <task>` | Architecture review | `/pokayokay:arch data layer` |
| `/pokayokay:handoff` | Session handoff protocol | `/pokayokay:handoff` |

### /pokayokay:plan

Analyzes a PRD, concept brief, or feature spec and creates a structured implementation plan.

**What it does:**
1. Reads and parses the document
2. Extracts features, requirements, and constraints
3. Creates epics, stories, and tasks in ohno
4. Assigns skills to features based on type
5. Generates `.claude/PROJECT.md` for shared context

**Example:**
```
/pokayokay:plan docs/feature-spec.md
```

### /pokayokay:work

Starts or continues an orchestrated work session with configurable human control.

**Modes:**
- `supervised` (default) - Pause after every task
- `semi-auto` - Pause at story/epic boundaries
- `autonomous` - Pause only at epic boundaries

**Example:**
```
/pokayokay:work semi-auto
```

### /pokayokay:audit

Audits feature completeness by scanning the codebase and comparing against requirements.

**What it checks:**
- Backend implementation (APIs, services, models)
- Frontend implementation (components, pages)
- User accessibility (routes, navigation)
- Creates remediation tasks for gaps

**Example:**
```
/pokayokay:audit                    # Audit all features
/pokayokay:audit UserDashboard      # Audit specific feature
```

### /pokayokay:review

Analyzes completed work sessions to identify patterns and improvements.

**Example:**
```
/pokayokay:review
```

### /pokayokay:api, /pokayokay:ux, /pokayokay:ui, /pokayokay:arch

Direct access to specialized skills for specific tasks.

**Examples:**
```
/pokayokay:api design the user authentication endpoints
/pokayokay:ux create the onboarding flow
/pokayokay:ui design the settings page
/pokayokay:arch review the data layer architecture
```

### /pokayokay:handoff

Generates session handoff notes for continuity between sessions.

**Example:**
```
/pokayokay:handoff
```

---

## Work Modes

Control how much autonomy Claude has during work sessions.

### Supervised (Default)

```
/pokayokay:work supervised
```

- **Pauses after every task** for your approval
- Best for: Critical features, learning the codebase, new projects
- You see exactly what's happening and approve each step

**When to use:**
- First time using pokayokay
- Working on security-sensitive features
- Learning a new codebase
- When you want maximum control

### Semi-Auto

```
/pokayokay:work semi-auto
```

- **Logs task completion, pauses at story boundaries**
- Best for: Established patterns, trusted implementations
- Review batches of related work together

**When to use:**
- You trust the implementation approach
- Tasks within a story are related
- You want to review logical groupings

### Autonomous

```
/pokayokay:work autonomous
```

- **Only pauses at epic boundaries**
- Best for: Well-defined features, bulk implementation
- Maximum speed, minimum interruption

**When to use:**
- Well-planned, low-risk features
- Bulk implementation of similar components
- Time-sensitive work with clear requirements

### Mode Comparison

| Mode | Task Complete | Story Complete | Epic Complete |
|------|--------------|----------------|---------------|
| supervised | PAUSE | PAUSE | PAUSE |
| semi-auto | log | PAUSE | PAUSE |
| autonomous | log | log | PAUSE |

---

## Completeness Levels

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

### Level Details

**L0 - Not Started**
- No code found for this feature
- Neither backend nor frontend exists

**L1 - Backend Only**
- API endpoints exist
- Database models/migrations exist
- No frontend components

**L2 - Frontend Exists**
- Components are created
- But not connected to a route
- Users can't navigate to them

**L3 - Routable**
- Has a URL route (e.g., `/dashboard`)
- But not in navigation menu
- Users must know the URL

**L4 - Accessible**
- In navigation, users can find it
- Missing polish (loading states, error handling, etc.)

**L5 - Complete**
- Fully implemented
- Accessible via navigation
- Polished and production-ready

---

## Skills

pokayokay includes specialized skills that are automatically loaded based on task type:

### Core Skills

| Skill | Purpose |
|-------|---------|
| **prd-analyzer** | Transforms PRDs into epics, stories, and tasks |
| **project-harness** | Orchestrates work sessions with human checkpoints |
| **product-manager** | Audits feature completeness (L0-L5) |
| **session-review** | Analyzes work patterns across sessions |

### Design Skills

| Skill | Purpose |
|-------|---------|
| **ux-design** | User flows, wireframes, information architecture |
| **aesthetic-ui-designer** | Visual design, typography, color, components |
| **accessibility-auditor** | WCAG 2.2 compliance verification |
| **persona-creation** | User research and persona development |

### Development Skills

| Skill | Purpose |
|-------|---------|
| **api-design** | REST/GraphQL endpoint design, OpenAPI specs |
| **api-integration** | Third-party API consumption with type safety |
| **api-testing** | Test patterns, fixtures, E2E validation |
| **architecture-review** | Code structure, module boundaries, refactoring |
| **sdk-development** | SDK extraction and npm publishing |

### Specialized Skills

| Skill | Purpose |
|-------|---------|
| **marketing-website** | Landing pages, conversion optimization, copy |
| **figma-plugin** | Figma Plugin API for design automation |

### Skill Routing

Skills are automatically assigned based on feature type:

| Feature Type | Primary Skill | Secondary Skills |
|--------------|---------------|------------------|
| User flows, wireframes | `ux-design` | `persona-creation` |
| REST/GraphQL APIs | `api-design` | `api-testing` |
| UI components | `aesthetic-ui-designer` | - |
| Data visualization | `ux-design` | `aesthetic-ui-designer` |
| Authentication/Security | `api-design` | - |
| Mobile screens | `ux-design` | `aesthetic-ui-designer` |
| Third-party integrations | `api-integration` | - |

---

## ohno CLI Reference

Common commands for task management:

### Initialization

```bash
# Initialize ohno in your project
npx @stevestomp/ohno-cli init
```

### Viewing Tasks

```bash
# View all tasks
npx @stevestomp/ohno-cli tasks

# View tasks by status
npx @stevestomp/ohno-cli tasks --status in_progress

# View blocked tasks
npx @stevestomp/ohno-cli blocked
```

### Working on Tasks

```bash
# Get recommended next task
npx @stevestomp/ohno-cli next

# Start a task
npx @stevestomp/ohno-cli start <task-id>

# Complete a task
npx @stevestomp/ohno-cli done <task-id> --notes "What was done"

# Block a task
npx @stevestomp/ohno-cli block <task-id> --reason "Waiting for API"
```

### Kanban Board

```bash
# Start visual kanban board
npx @stevestomp/ohno-cli serve
# Opens http://localhost:3456
```

### Session Management

```bash
# Get session context (for resuming work)
npx @stevestomp/ohno-cli context

# Sync changes
npx @stevestomp/ohno-cli sync
```

### Creating Tasks

```bash
# Create a new task
npx @stevestomp/ohno-cli create "Task title" -t feature

# Task types: feature, bug, chore, spike, test
```

---

## Use Cases

### Starting a new project

1. Write a PRD or feature spec
2. `/pokayokay:plan docs/prd.md` to create tasks
3. `/pokayokay:work supervised` to implement with oversight
4. `/pokayokay:audit` to verify completeness

### Resuming interrupted work

1. Claude automatically reads session context from ohno
2. `/pokayokay:work` continues where you left off
3. All previous decisions and progress are preserved

### Verifying a feature is complete

1. `/pokayokay:audit FeatureName` checks implementation
2. Identifies gaps (L0-L4 features)
3. Creates remediation tasks automatically
4. Re-audit after fixes to confirm L5

### Bulk implementation

1. Plan thoroughly with `/pokayokay:plan`
2. Review the kanban board
3. `/pokayokay:work autonomous` for maximum speed
4. `/pokayokay:audit` to catch any gaps

### Working across multiple sessions

1. First session: `/pokayokay:plan` then `/pokayokay:work`
2. End session naturally or with `/pokayokay:handoff`
3. Next session: `/pokayokay:work` picks up automatically
4. ohno preserves all context and progress

### Design-first workflow

1. `/pokayokay:ux` to design user flows first
2. `/pokayokay:ui` to create visual designs
3. `/pokayokay:api` to design backend APIs
4. `/pokayokay:work` to implement the designs

### Auditing existing projects

Even without a PRD:
1. Initialize ohno: `npx @stevestomp/ohno-cli init`
2. `/pokayokay:audit` scans codebase for features
3. Creates tasks for incomplete features
4. `/pokayokay:work` to address gaps

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

Make sure ohno is configured in `~/.claude/settings.json`:
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
claude plugin install pokayokay
```

### Session context lost

Check ohno context:
```bash
npx @stevestomp/ohno-cli context
```

If empty, previous session may not have synced. Start fresh with `/pokayokay:plan`.
