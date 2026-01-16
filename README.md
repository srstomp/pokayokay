```
                 __                           __
    ____  ____  / /______ _  __  ______  / /______ ___  __
   / __ \/ __ \/ //_/ __ `/ / / / / __ \/ //_/ __ `/ / / /
  / /_/ / /_/ / ,< / /_/ / / /_/ / /_/ / ,< / /_/ / /_/ /
 / .___/\____/_/|_|\__,_/  \__, /\____/_/|_|\__,_/\__, /
/_/                       /____/                 /____/
```

# pokayokay

**AI-assisted development with human control.** Transform PRDs into actionable tasks, orchestrate multi-session development, and ensure features are actually user-accessible.

pokayokay bridges the gap between fully manual Claude Code sessions and runaway autonomous agents. You stay in control while AI handles the heavy lifting.

## Why pokayokay?

- **PRD to Tasks**: Automatically break down product requirements into epics, stories, and tasks
- **Orchestrated Sessions**: Work across multiple sessions without losing context
- **Human Checkpoints**: Choose how much autonomy to give - from task-by-task approval to epic-level oversight
- **Completeness Auditing**: Verify features aren't just "code complete" but actually user-accessible
- **Skill Routing**: Automatically route work to specialized AI skills (API design, UX, UI, etc.)

---

## Installation

```bash
claude plugin marketplace add https://github.com/srstomp/pokayokay
claude plugin install pokayokay
```

### Prerequisites: ohno MCP Server

pokayokay uses [ohno](https://github.com/srstomp/ohno) for task management. Add to your Claude Code settings (`~/.claude/settings.json`):

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

---

## Quick Start

### 1. Initialize your project

```bash
cd your-project
npx @stevestomp/ohno-cli init
```

### 2. Plan from a PRD

```
/pokayokay:plan docs/prd.md
```

This analyzes your PRD and creates:
- Tasks in ohno (epics → stories → tasks)
- `.claude/PROJECT.md` for shared context
- Skill assignments for each feature

### 3. View your kanban board

```bash
npx @stevestomp/ohno-cli serve
# Opens http://localhost:3456
```

### 4. Start working

```
/pokayokay:work supervised
```

Claude will:
1. Get the next task from ohno
2. Route to the appropriate skill
3. Implement the task
4. Pause for your approval (in supervised mode)
5. Repeat until done

### 5. Audit completeness

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

---

## Work Modes

Control how much autonomy Claude has during work sessions:

### Supervised (Default)
```
/pokayokay:work supervised
```
- **Pauses after every task** for your approval
- Best for: Critical features, learning the codebase, new projects
- You see exactly what's happening and approve each step

### Semi-Auto
```
/pokayokay:work semi-auto
```
- **Logs task completion, pauses at story boundaries**
- Best for: Established patterns, trusted implementations
- Review batches of related work together

### Autonomous
```
/pokayokay:work autonomous
```
- **Only pauses at epic boundaries**
- Best for: Well-defined features, bulk implementation
- Maximum speed, minimum interruption

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

```
PRD says: "User can export data to CSV"
Backend:   ✓ /api/export endpoint exists
Frontend:  ✓ ExportButton component exists
Route:     ✗ No page uses ExportButton
Navigation: ✗ No menu item
Result:    L2 - Users can't actually export!
```

The audit catches these gaps and creates remediation tasks.

---

## Skills

pokayokay includes specialized skills that are automatically loaded based on task type:

| Skill | When it's used |
|-------|---------------|
| **prd-analyzer** | Breaking down PRDs into tasks |
| **project-harness** | Orchestrating work sessions |
| **product-manager** | Auditing feature completeness |
| **session-review** | Analyzing work patterns |
| **api-design** | REST/GraphQL endpoint design |
| **ux-design** | User flows and wireframes |
| **aesthetic-ui-designer** | Visual design and components |
| **architecture-review** | Code structure analysis |
| **accessibility-auditor** | WCAG compliance checks |
| **api-integration** | Third-party API consumption |
| **api-testing** | Test patterns and fixtures |
| **sdk-development** | SDK extraction and publishing |
| **marketing-website** | Landing pages and copy |
| **persona-creation** | User research and personas |
| **figma-plugin** | Figma Plugin API |

---

## ohno CLI Reference

Common commands for task management:

```bash
# Initialize ohno in your project
npx @stevestomp/ohno-cli init

# View all tasks
npx @stevestomp/ohno-cli tasks

# Get recommended next task
npx @stevestomp/ohno-cli next

# Start a task
npx @stevestomp/ohno-cli start <task-id>

# Complete a task
npx @stevestomp/ohno-cli done <task-id> --notes "What was done"

# View kanban board
npx @stevestomp/ohno-cli serve

# Get session context (for resuming)
npx @stevestomp/ohno-cli context

# Sync changes
npx @stevestomp/ohno-cli sync
```

---

## Project Structure

```
pokayokay/
├── .claude-plugin/
│   └── marketplace.json    # Marketplace manifest
├── plugins/
│   └── pokayokay/          # Plugin content
│       ├── .claude-plugin/
│       │   └── plugin.json # Plugin manifest
│       ├── .mcp.json       # MCP server config
│       ├── commands/       # Slash commands
│       │   ├── plan.md
│       │   ├── work.md
│       │   ├── audit.md
│       │   └── ...
│       └── skills/         # Skill definitions
│           ├── prd-analyzer/
│           ├── project-harness/
│           ├── product-manager/
│           └── ...
└── README.md
```

---

## Use Cases

### Starting a new project
1. Write a PRD or feature spec
2. `/pokayokay:plan docs/prd.md` to create tasks
3. `/pokayokay:work supervised` to implement with oversight

### Resuming interrupted work
1. Claude automatically reads session context from ohno
2. `/pokayokay:work` continues where you left off
3. All previous decisions and progress are preserved

### Verifying a feature is complete
1. `/pokayokay:audit FeatureName` checks implementation
2. Creates remediation tasks for any gaps
3. Re-audit after fixes to confirm L5

### Bulk implementation
1. Plan thoroughly with `/pokayokay:plan`
2. `/pokayokay:work autonomous` for maximum speed
3. `/pokayokay:audit` to catch any gaps

---

## Development

For local development:

```bash
git clone https://github.com/srstomp/pokayokay.git
claude --plugin-dir ./pokayokay/plugins/pokayokay
```

---

## Dependencies

- [ohno](https://github.com/srstomp/ohno) - Task management via MCP
- Claude Code - AI coding assistant

---

## License

MIT
