---
name: project-harness
description: Orchestrates long-running AI development sessions with human checkpoint control. Uses ohno for task management, manages progress tracking, routes work to appropriate skills, and implements supervised/semi-auto/autonomous modes. Use this skill when starting work sessions, resuming interrupted work, or managing multi-session projects.
---

# Project Harness

Orchestrate AI-assisted development with configurable human control.

## Core Concept

This skill bridges the gap between fully manual Claude Code sessions and runaway autonomous agents. It provides structured handoffs between sessions while giving you control over when to intervene.

**Integrated with [ohno](https://github.com/srstomp/ohno)** for task management via MCP.

```
┌─────────────────────────────────────────────────────────────┐
│                    SESSION START                            │
│                          │                                  │
│                          ▼                                  │
│              ┌──────────────────────┐                       │
│              │ ohno: get_session_   │                       │
│              │       context()      │                       │
│              └──────────┬───────────┘                       │
│                          │                                  │
│              ┌──────────────────────┐                       │
│              │ ohno serve           │◄── Browser access     │
│              └──────────┬───────────┘                       │
│                          │                                  │
│              ┌──────────────────────┐                       │
│              │ ohno: get_next_task()│                       │
│              └──────────┬───────────┘                       │
│                          │                                  │
│              ┌──────────────────────┐                       │
│              │ Route to skill       │                       │
│              └──────────┬───────────┘                       │
│                          │                                  │
│              ┌──────────────────────┐                       │
│              │ CHECKPOINT (by mode) │◄── Human decision     │
│              └──────────┬───────────┘                       │
│                          │                                  │
│              ┌──────────────────────┐                       │
│              │ ohno: done + sync    │                       │
│              │ Git commit           │                       │
│              └──────────────────────┘                       │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### 1. Initialize ohno

```bash
npx @stevestomp/ohno-cli init
```

### 2. Create Project Context (optional)

Create `.claude/PROJECT.md` for shared project context:

```markdown
# Project Name

## Overview
Brief description of the project.

## Tech Stack
- Framework: Next.js 14
- Database: PostgreSQL
- Styling: Tailwind CSS

## Conventions
- Use TypeScript strict mode
- Follow existing patterns in codebase
```

### 3. Start Session

Use ohno MCP tools or CLI:

```bash
# Get context from previous sessions
npx @stevestomp/ohno-cli context

# See all tasks
npx @stevestomp/ohno-cli tasks

# Get recommended next task
npx @stevestomp/ohno-cli next

# Start kanban board
npx @stevestomp/ohno-cli serve
```

---

## Operating Modes

### SUPERVISED Mode (Default)

Human reviews after every task. Maximum control, slower pace.

**Checkpoint behavior:**
- Task complete → PAUSE
- Story complete → PAUSE
- Epic complete → PAUSE

**Use when**: Starting new projects, unfamiliar domains, critical code.

### SEMI-AUTO Mode

Human reviews at story/epic boundaries. Good balance.

**Checkpoint behavior:**
- Task complete → Log and continue
- Story complete → PAUSE
- Epic complete → PAUSE

**Use when**: Established patterns, routine implementation.

### AUTONOMOUS Mode

Human reviews at epic boundaries only. Maximum speed.

**Checkpoint behavior:**
- Task complete → Skip
- Story complete → Log and continue
- Epic complete → PAUSE

**Use when**: Well-defined specs, trusted patterns, time pressure.

---

## Session Protocol

### Starting a Session

```markdown
## Session Start Checklist

1. [ ] Get session context: `ohno context` or MCP get_session_context()
2. [ ] Read .claude/PROJECT.md if exists
3. [ ] Check task list: `ohno tasks`
4. [ ] Start kanban: `ohno serve`
5. [ ] Check git status - clean working directory?
6. [ ] Get next task: `ohno next`
7. [ ] Announce plan - tell human what you'll do
```

**Using ohno MCP:**
```
1. get_session_context() → Understand previous session
2. get_tasks() → See all work
3. get_next_task() → Pick what to do
```

### Work Loop

```
WHILE tasks remain:
  1. Get next task (ohno next)
  2. Start task (ohno start <id>)
  3. Route to appropriate skill if needed
  4. Complete ONE task
  5. Git commit with descriptive message
  6. Mark done (ohno done <id> --notes "...")
  7. Sync kanban (ohno sync)
  8. CHECKPOINT based on mode
  9. IF checkpoint == PAUSE: Stop and wait
     ELSE: Continue to next task
```

### During Work

For each task:

```markdown
## Task: [task-id] Create grid component

### Plan
- Create responsive grid using CSS Grid
- Support 1-4 column layouts
- Add to component library

### Implementation
[Work happens here]

### Verification
- [ ] Component renders
- [ ] Responsive breakpoints work
- [ ] Exported from index

### Post-Task
1. Git commit: `feat(dashboard): add responsive grid component`
2. Mark done: `ohno done <task-id> --notes "Created GridLayout component"`
3. Sync kanban: `ohno sync`
4. Checkpoint (based on mode)
```

### Ending a Session

```markdown
## Session End Checklist

1. [ ] All changes committed
2. [ ] Current task marked done or in-progress
3. [ ] Kanban synced: `ohno sync`
4. [ ] Session notes logged via ohno
5. [ ] No broken code left
6. [ ] Clear summary of what was done
7. [ ] Clear next steps documented
```

---

## Checkpoint Protocol

### PAUSE Checkpoint

Agent stops completely and waits for human input.

```markdown
## CHECKPOINT: Task Complete

**Completed**: task-abc123 - Create grid component
**Status**: Awaiting your review
**Kanban**: http://localhost:3456 (run `ohno serve`)

### What I Did
- Created `GridLayout.tsx` component
- Added responsive breakpoints (sm, md, lg, xl)
- Exported from components/index.ts

### What I'd Do Next
- task-def456: Create dashboard header

### Your Options
1. **Continue** - Proceed to next task
2. **Modify** - Change approach before continuing
3. **Pause** - Stop session here
4. **Switch** - Work on different task

Waiting for your decision...
```

### REVIEW Checkpoint

Agent continues but flags work for later review.

```markdown
## REVIEW FLAG: Story Complete

**Completed**: Dashboard Layout (3 tasks)
**Continuing to**: Dashboard Widgets
**Kanban**: Synced ✓

Flagged for review.
```

### NOTIFY Checkpoint

Agent logs and continues without stopping.

```markdown
## ✓ Task Complete: task-abc123 - Create grid component
Kanban synced → Continuing to next task...
```

---

## Skill Routing

Based on task type, load relevant skill for domain knowledge:

| Task Type | Skill |
|-----------|-------|
| API design | api-design |
| API tests | api-testing |
| UI components | aesthetic-ui-designer |
| User flows | ux-design |
| User research | persona-creation |
| Accessibility | accessibility-auditor |
| Architecture | architecture-review |
| SDK/package | sdk-development |
| Marketing | marketing-website |

### Skill Invocation

When routing to a skill:

```markdown
## Invoking Skill: api-design

**Context**: Feature - API Endpoints
**Task**: task-xyz - Design user endpoints

Reading skill documentation...
[Skill takes over for this task]
```

---

## ohno Integration

### MCP Tools Available

**Query Tools:**
- `get_session_context()` - Previous session notes, blockers, in-progress tasks
- `get_project_status()` - Overall project statistics
- `get_tasks()` - List all tasks
- `get_task(id)` - Get specific task details
- `get_next_task()` - Recommended next task
- `get_blocked_tasks()` - Tasks with blockers

**Update Tools:**
- `start_task(id)` - Mark task in-progress
- `complete_task(id, notes)` - Mark task done
- `log_activity(message)` - Log session activity
- `set_blocker(id, reason)` - Block a task
- `resolve_blocker(id)` - Unblock a task

### CLI Commands

```bash
# Session management
ohno context              # Get session context
ohno status               # Project statistics

# Task management
ohno tasks                # List all tasks
ohno next                 # Get recommended next task
ohno start <id>           # Start working on task
ohno done <id> --notes    # Complete task with notes
ohno block <id> <reason>  # Set blocker
ohno unblock <id>         # Resolve blocker

# Kanban
ohno serve                # Start kanban server
ohno sync                 # Sync kanban HTML
```

---

## Error Recovery

### Build Failures

```markdown
## ⚠️ Build Failed

**Error**: TypeScript compilation error in Dashboard.tsx
**Line 47**: Property 'user' does not exist on type '{}'

### Recovery Plan
1. Check recent changes (git diff)
2. Identify breaking change
3. Fix type error
4. Verify build passes
5. Block task if needed: `ohno block <id> "Build failure"`
6. Continue or escalate

Proceeding with recovery...
```

### Blocked Tasks

```bash
# Block a task
ohno block task-abc123 "Waiting for API spec"

# View blocked tasks
ohno tasks --status blocked

# Resolve blocker
ohno unblock task-abc123
```

---

## Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Skipping verification | Start on broken code | Always verify first |
| No git commits | Can't recover from errors | Commit every task |
| No kanban sync | Stale visual state | Run `ohno sync` after changes |
| Giant tasks | Lose progress on failure | Keep tasks ≤8 hours |
| Ignoring checkpoints | Lose human control | Respect mode settings |
| No session context | Next session confused | Use `ohno context` |
| Autonomous on new project | Bad patterns amplified | Start supervised |

---

## References

- [references/session-protocol.md](references/session-protocol.md) — Detailed session management
- [references/checkpoint-types.md](references/checkpoint-types.md) — Checkpoint configuration
- [references/skill-routing.md](references/skill-routing.md) — Skill selection logic
