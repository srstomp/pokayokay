---
name: project-harness
description: Orchestrates long-running AI development sessions with human checkpoint control. Reads project state from `.claude/` folder, manages progress tracking, routes work to appropriate skills, and implements supervised/semi-auto/autonomous modes. Use this skill when starting work sessions, resuming interrupted work, or managing multi-session projects.
---

# Project Harness

Orchestrate AI-assisted development with configurable human control.

## Core Concept

This skill bridges the gap between fully manual Claude Code sessions and runaway autonomous agents. It provides structured handoffs between sessions while giving you control over when to intervene.

```
┌─────────────────────────────────────────────────────────────┐
│                    SESSION START                            │
│                          │                                  │
│                          ▼                                  │
│              ┌──────────────────────┐                       │
│              │ Read .claude/ state  │                       │
│              └──────────┬───────────┘                       │
│                          │                                  │
│              ┌──────────────────────┐                       │
│              │ Start kanban server  │◄── Browser access     │
│              └──────────┬───────────┘                       │
│                          │                                  │
│              ┌──────────────────────┐                       │
│              │ Pick next feature    │                       │
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
│              │ Update progress      │                       │
│              │ Sync kanban          │◄── Auto-refresh       │
│              │ Git commit           │                       │
│              └──────────────────────┘                       │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### 1. Initialize Project Harness

If `.claude/` doesn't exist or needs initialization:

```bash
mkdir -p .claude/sessions .claude/checkpoints
```

Then create `.claude/config.yaml`:

```yaml
mode: supervised  # supervised | semi-auto | autonomous
project_name: "My Project"

checkpoints:
  task_complete: pause      # pause | review | notify | skip
  story_complete: pause
  epic_complete: pause
  error_encountered: pause
  
kanban:
  auto_sync: true           # Sync after every task.db change
  serve_locally: true       # Start local server for browser access
  port: 3333                # Port for kanban server
  
git:
  commit_per_task: true
  commit_message_prefix: "[claude]"
  
skills:
  auto_route: true  # Use skill_hint from features.json
```

### 2. Start Session

At the beginning of every session:

```
1. Read .claude/config.yaml       → Understand mode
2. Read .claude/progress.md       → What happened before
3. Read .claude/features.json     → What needs doing
4. Start kanban server            → Browser access at localhost:3333
5. Run basic verification         → Is project in good state?
6. Pick next task                 → Based on priority + deps
7. Announce plan                  → Tell human what you'll do
```

### 3. Work Loop

```
WHILE features remain:
  1. Select next feature (P0 first, respect dependencies)
  2. Route to appropriate skill (via skill_hint)
  3. Complete ONE task
  4. Git commit with descriptive message
  5. SYNC KANBAN                    ← Automatic after every change
  6. Update .claude/progress.md
  7. CHECKPOINT based on mode
  8. IF checkpoint == PAUSE: Stop and wait
     ELSE: Continue to next task
```

---

## Kanban Live View

### Why Live Kanban?

The kanban.html file is your visual dashboard during development. It should always reflect the current state of tasks.db — not stale data from when prd-analyzer first ran.

### How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                    KANBAN SYNC FLOW                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  tasks.db ──► Export JSON ──► Embed in HTML ──► Browser     │
│      │                             │               │        │
│      │                             ▼               │        │
│   (SQLite)                   kanban.html          │        │
│      │                             │               │        │
│      └──────── On change ──────────┘               │        │
│                                                    │        │
│                    localhost:3333 ◄────────────────┘        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Starting the Kanban Server

At session start, launch a simple HTTP server:

```bash
# Start server in background
cd .claude && python3 -m http.server 3333 &
KANBAN_PID=$!
echo $KANBAN_PID > .kanban.pid

# Now accessible at:
# http://localhost:3333/kanban.html
```

Or using Node:
```bash
cd .claude && npx serve -p 3333 &
```

**Tell the user:**
```markdown
## 📊 Kanban Board Live

**URL**: http://localhost:3333/kanban.html
**Auto-refresh**: Enabled (syncs after every task)

Open in your browser to track progress visually.
```

### Syncing the Kanban

After ANY change to tasks.db, run sync:

```bash
# Sync script (inline or from .claude/scripts/sync-kanban.sh)
python3 << 'EOF'
import sqlite3
import json
from pathlib import Path

db_path = ".claude/tasks.db"
html_path = ".claude/kanban.html"
template_path = ".claude/templates/kanban-template.html"

# Export data from SQLite
conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row

data = {
    "synced_at": __import__('datetime').datetime.now().isoformat(),
    "projects": [dict(r) for r in conn.execute("SELECT * FROM projects").fetchall()],
    "epics": [dict(r) for r in conn.execute("SELECT * FROM epics ORDER BY priority, sort_order").fetchall()],
    "stories": [dict(r) for r in conn.execute("SELECT * FROM stories").fetchall()],
    "tasks": [dict(r) for r in conn.execute("SELECT * FROM tasks").fetchall()],
    "dependencies": [dict(r) for r in conn.execute("SELECT * FROM dependencies").fetchall()],
}
conn.close()

# Read template and embed data
template = Path(template_path).read_text() if Path(template_path).exists() else Path(html_path).read_text()
updated_html = template.replace(
    "window.KANBAN_DATA = {};",
    f"window.KANBAN_DATA = {json.dumps(data, default=str)};"
)

# Write updated HTML
Path(html_path).write_text(updated_html)
print(f"✓ Kanban synced ({len(data['tasks'])} tasks)")
EOF
```

### When to Sync

| Event | Sync? | Reason |
|-------|-------|--------|
| Session start | ✅ | Fresh state |
| Task status change | ✅ | Progress visible |
| Task created | ✅ | New work appears |
| Story/epic complete | ✅ | Milestone visible |
| Error encountered | ✅ | Blocked status shown |
| Session end | ✅ | Final state saved |
| Git commit | ❌ | No DB change |
| Checkpoint pause | ❌ | Already synced |

### Auto-Refresh in Browser

The kanban.html includes auto-refresh to pick up changes:

```html
<!-- Add to kanban.html <head> -->
<script>
  // Check for updates every 5 seconds
  let lastSync = null;
  setInterval(async () => {
    const resp = await fetch('kanban.html?nocache=' + Date.now());
    const text = await resp.text();
    const match = text.match(/synced_at":\s*"([^"]+)"/);
    if (match && match[1] !== lastSync) {
      lastSync = match[1];
      location.reload();
    }
  }, 5000);
</script>
```

---

## Operating Modes

### SUPERVISED Mode (Default)

Human reviews after every task. Maximum control, slower pace.

```yaml
checkpoints:
  task_complete: pause
  story_complete: pause
  epic_complete: pause
```

**Use when**: Starting new projects, unfamiliar domains, critical code.

### SEMI-AUTO Mode

Human reviews at story/epic boundaries. Good balance.

```yaml
checkpoints:
  task_complete: notify    # Log but continue
  story_complete: pause    # Stop for review
  epic_complete: pause
```

**Use when**: Established patterns, routine implementation.

### AUTONOMOUS Mode

Human reviews at epic boundaries only. Maximum speed.

```yaml
checkpoints:
  task_complete: skip
  story_complete: notify
  epic_complete: pause
```

**Use when**: Well-defined specs, trusted patterns, time pressure.

---

## `.claude/` Folder Structure

```
.claude/
├── config.yaml           # Harness configuration
├── features.json         # What to build (from prd-analyzer)
├── tasks.db              # Detailed breakdown (SQLite)
├── progress.md           # Session history (human-readable)
├── kanban.html           # Visual board (auto-synced)
├── .kanban.pid           # Server process ID
├── scripts/
│   └── sync-kanban.py    # Sync script
├── templates/
│   └── kanban-template.html  # Base template
├── sessions/             # Per-session logs
│   ├── 2025-01-10-001.md
│   └── 2025-01-10-002.md
└── checkpoints/          # Human decision records
    └── pending-review.md
```

### config.yaml

```yaml
mode: supervised
project_name: "Authentication System"
created_at: "2025-01-10T12:00:00Z"

checkpoints:
  task_complete: pause
  story_complete: pause  
  epic_complete: pause
  error_encountered: pause
  ambiguity_found: pause

kanban:
  auto_sync: true
  serve_locally: true
  port: 3333
  auto_refresh_seconds: 5

git:
  commit_per_task: true
  commit_message_prefix: "[claude]"
  branch_per_epic: false

skills:
  auto_route: true
  default_skill: null
  
session:
  max_tasks_per_session: 10
  require_verification: true
```

### progress.md

```markdown
# Project Progress

## Current State
- **Active Feature**: F002 - User Dashboard
- **Active Story**: S003 - Dashboard Layout
- **Last Task Completed**: T007 - Create grid component
- **Overall Progress**: 12/47 tasks (25%)
- **Kanban**: http://localhost:3333/kanban.html

## Session History

### Session 2025-01-10-002 (14:30 - 15:45)
- Completed: T005, T006, T007
- Feature F001 marked done
- Started F002
- Checkpoint: Awaiting review of dashboard approach

### Session 2025-01-10-001 (09:00 - 11:30)
- Completed: T001, T002, T003, T004
- Set up project structure
- Implemented auth endpoints
```

---

## Session Protocol

### Starting a Session

```markdown
## Session Start Checklist

1. [ ] Read config.yaml - confirm mode
2. [ ] Read progress.md - understand state
3. [ ] Read features.json - know what's next
4. [ ] Start kanban server - browser access
5. [ ] Sync kanban - ensure current state
6. [ ] Check git status - clean working directory?
7. [ ] Run verification - does app work?
8. [ ] Announce plan - tell human what you'll do
```

### Session Start Script

```bash
#!/bin/bash
# .claude/scripts/start-session.sh

echo "🚀 Starting project harness session..."

# Start kanban server if not running
if [ ! -f .claude/.kanban.pid ] || ! kill -0 $(cat .claude/.kanban.pid) 2>/dev/null; then
    echo "📊 Starting kanban server..."
    cd .claude && python3 -m http.server 3333 > /dev/null 2>&1 &
    echo $! > .kanban.pid
    cd ..
fi

# Initial sync
echo "🔄 Syncing kanban..."
python3 .claude/scripts/sync-kanban.py

echo ""
echo "✅ Session ready!"
echo "📊 Kanban: http://localhost:3333/kanban.html"
echo ""
```

### During Work

For each task:

```markdown
## Task: [T007] Create grid component

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
1. Git commit: `[claude] feat(dashboard): add responsive grid component`
2. Update tasks.db: T007 status → done
3. **Sync kanban** ← Automatic
4. Update progress.md
5. Checkpoint (based on mode)
```

### Ending a Session

```markdown
## Session End Checklist

1. [ ] All changes committed
2. [ ] tasks.db status current
3. [ ] **Kanban synced** (final state)
4. [ ] progress.md updated
5. [ ] No broken code left
6. [ ] Stop kanban server (optional)
7. [ ] Clear summary of what was done
8. [ ] Clear next steps documented
```

### Session End Script

```bash
#!/bin/bash
# .claude/scripts/end-session.sh

echo "🏁 Ending session..."

# Final sync
echo "🔄 Final kanban sync..."
python3 .claude/scripts/sync-kanban.py

# Optionally stop server
read -p "Stop kanban server? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f .claude/.kanban.pid ]; then
        kill $(cat .claude/.kanban.pid) 2>/dev/null
        rm .claude/.kanban.pid
        echo "📊 Kanban server stopped"
    fi
fi

echo "✅ Session ended"
```

---

## Checkpoint Protocol

### PAUSE Checkpoint

Agent stops completely and waits for human input.

```markdown
## 🛑 CHECKPOINT: Task Complete

**Completed**: T007 - Create grid component
**Status**: Awaiting your review
**Kanban**: http://localhost:3333/kanban.html (updated)

### What I Did
- Created `GridLayout.tsx` component
- Added responsive breakpoints (sm, md, lg, xl)
- Exported from components/index.ts

### What I'd Do Next
- T008: Create dashboard header
- Estimated: 2 hours

### Your Options
1. **Continue** - Proceed to T008
2. **Modify** - Change approach before continuing
3. **Pause** - Stop session here
4. **Switch** - Work on different feature

Waiting for your decision...
```

### REVIEW Checkpoint

Agent continues but flags work for later review.

```markdown
## 📋 REVIEW FLAG: Story Complete

**Completed**: S003 - Dashboard Layout (3 tasks)
**Continuing to**: S004 - Dashboard Widgets
**Kanban**: Synced ✓

Flagged for review in `.claude/checkpoints/pending-review.md`
```

### NOTIFY Checkpoint

Agent logs and continues without stopping.

```markdown
## ✓ Task Complete: T007 - Create grid component
Kanban synced → Continuing to T008...
```

---

## Skill Routing

### Automatic Routing

When `auto_route: true`, use `skill_hint` from features.json:

```json
{
  "id": "F003",
  "title": "API Endpoints",
  "skill_hint": "api-design, api-testing"
}
```

Route to suggested skill(s) in order.

### Manual Routing

When `auto_route: false` or no hint:

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

**Context**: Feature F003 - API Endpoints
**Task**: T012 - Design user endpoints

Reading skill documentation...
[Skill takes over for this task]
```

---

## Kanban Sync Integration

### Sync After Database Changes

Any operation that modifies tasks.db should trigger sync:

```python
# After any DB modification
def update_task_status(task_id: str, status: str):
    conn = sqlite3.connect(".claude/tasks.db")
    conn.execute("UPDATE tasks SET status = ? WHERE id = ?", (status, task_id))
    conn.commit()
    conn.close()
    
    # Always sync after DB change
    sync_kanban()

def create_task(task_data: dict):
    conn = sqlite3.connect(".claude/tasks.db")
    # ... insert task ...
    conn.commit()
    conn.close()
    
    # Always sync after DB change
    sync_kanban()
```

### Integration with product-manager

When product-manager adds remediation tasks:

```markdown
## product-manager: Remediation Tasks Added

Added 5 new tasks to tasks.db for frontend gaps.

**Syncing kanban...** ✓

View updated board: http://localhost:3333/kanban.html
```

### Integration with prd-analyzer

When prd-analyzer creates initial structure:

```markdown
## prd-analyzer: Project Initialized

Created:
- .claude/tasks.db (47 tasks)
- .claude/features.json (8 features)
- .claude/kanban.html (synced)

**Starting kanban server...**
📊 http://localhost:3333/kanban.html
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
5. **Sync kanban** (mark task blocked if needed)
6. Continue with task

Proceeding with recovery...
```

### Kanban Server Issues

```markdown
## ⚠️ Kanban Server Not Running

The kanban server appears to be stopped.

**Restarting...**
```bash
cd .claude && python3 -m http.server 3333 &
echo $! > .kanban.pid
```

✓ Server restarted: http://localhost:3333/kanban.html
```

---

## Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Skipping verification | Start on broken code | Always verify first |
| No git commits | Can't recover from errors | Commit every task |
| **No kanban sync** | Stale visual state | Sync after every DB change |
| Giant tasks | Lose progress on failure | Keep tasks ≤8 hours |
| Ignoring checkpoints | Lose human control | Respect mode settings |
| No progress.md update | Next session confused | Update after every task |
| Autonomous on new project | Bad patterns amplified | Start supervised |
| **Manual kanban opens** | Forget to check | Keep browser tab open |

---

## References

- [references/session-protocol.md](references/session-protocol.md) — Detailed session management
- [references/checkpoint-types.md](references/checkpoint-types.md) — Checkpoint configuration
- [references/skill-routing.md](references/skill-routing.md) — Skill selection logic
- [references/kanban-sync.md](references/kanban-sync.md) — Kanban synchronization details
- [templates/config.yaml](templates/config.yaml) — Default configuration
- [templates/progress.md](templates/progress.md) — Progress file template
- [scripts/sync-kanban.py](scripts/sync-kanban.py) — Kanban sync script
