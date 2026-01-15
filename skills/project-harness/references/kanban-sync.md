# Kanban Sync Reference

Complete guide to keeping kanban.html synchronized with tasks.db during development sessions.

## Overview

The kanban board provides visual project tracking, but browsers cannot read SQLite directly. This requires a sync process:

```
tasks.db (SQLite) → Export → JSON → Embed → kanban.html → Browser
```

## Architecture

### Components

| Component | Purpose | Location |
|-----------|---------|----------|
| tasks.db | Source of truth | .claude/tasks.db |
| sync-kanban.py | Export & embed | .claude/scripts/ |
| kanban-template.html | Base HTML | .claude/templates/ |
| kanban.html | Live board | .claude/kanban.html |
| HTTP server | Browser access | localhost:3333 |

### Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    SYNC ARCHITECTURE                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────┐     ┌──────────┐     ┌──────────────┐        │
│  │ tasks.db │ ──► │  sync    │ ──► │ kanban.html  │        │
│  │ (SQLite) │     │  script  │     │ (with data)  │        │
│  └──────────┘     └──────────┘     └──────────────┘        │
│       │                                    │                │
│       │ Triggers:                          │                │
│       │ • Task complete                    │                │
│       │ • Status change                    ▼                │
│       │ • New task added          ┌──────────────┐         │
│       │ • Session start/end       │   Browser    │         │
│       └───────────────────────────│ localhost:   │         │
│                                   │    3333      │         │
│                                   └──────────────┘         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Sync Script

### Full Python Script

Create `.claude/scripts/sync-kanban.py`:

```python
#!/usr/bin/env python3
"""
Kanban Sync Script
Exports tasks.db to JSON and embeds in kanban.html
"""

import sqlite3
import json
import sys
from datetime import datetime
from pathlib import Path

# Paths
CLAUDE_DIR = Path(__file__).parent.parent
DB_PATH = CLAUDE_DIR / "tasks.db"
HTML_PATH = CLAUDE_DIR / "kanban.html"
TEMPLATE_PATH = CLAUDE_DIR / "templates" / "kanban-template.html"

def export_database() -> dict:
    """Export all tables from tasks.db to dict."""
    
    if not DB_PATH.exists():
        print(f"❌ Database not found: {DB_PATH}")
        sys.exit(1)
    
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    
    data = {
        "synced_at": datetime.now().isoformat(),
        "projects": [],
        "epics": [],
        "stories": [],
        "tasks": [],
        "dependencies": [],
    }
    
    # Export each table
    for table in ["projects", "epics", "stories", "tasks", "dependencies"]:
        try:
            cursor = conn.execute(f"SELECT * FROM {table}")
            data[table] = [dict(row) for row in cursor.fetchall()]
        except sqlite3.OperationalError as e:
            print(f"⚠️  Table {table} not found: {e}")
    
    # Add computed stats
    data["stats"] = compute_stats(data)
    
    conn.close()
    return data

def compute_stats(data: dict) -> dict:
    """Compute summary statistics."""
    
    tasks = data["tasks"]
    epics = data["epics"]
    
    total_tasks = len(tasks)
    done_tasks = len([t for t in tasks if t.get("status") == "done"])
    blocked_tasks = len([t for t in tasks if t.get("status") == "blocked"])
    in_progress = len([t for t in tasks if t.get("status") == "in_progress"])
    
    return {
        "total_tasks": total_tasks,
        "done_tasks": done_tasks,
        "blocked_tasks": blocked_tasks,
        "in_progress_tasks": in_progress,
        "todo_tasks": total_tasks - done_tasks - blocked_tasks - in_progress,
        "completion_pct": round(100 * done_tasks / total_tasks, 1) if total_tasks > 0 else 0,
        "total_epics": len(epics),
        "p0_epics": len([e for e in epics if e.get("priority") == "P0"]),
    }

def get_template() -> str:
    """Get HTML template content."""
    
    if TEMPLATE_PATH.exists():
        return TEMPLATE_PATH.read_text()
    elif HTML_PATH.exists():
        return HTML_PATH.read_text()
    else:
        print("❌ No template or existing kanban.html found")
        sys.exit(1)

def embed_data(template: str, data: dict) -> str:
    """Embed JSON data into HTML template."""
    
    json_str = json.dumps(data, default=str, indent=2)
    
    # Replace placeholder
    if "window.KANBAN_DATA = {};" in template:
        return template.replace(
            "window.KANBAN_DATA = {};",
            f"window.KANBAN_DATA = {json_str};"
        )
    elif "window.KANBAN_DATA = " in template:
        # Replace existing data
        import re
        pattern = r"window\.KANBAN_DATA = \{[\s\S]*?\};"
        return re.sub(pattern, f"window.KANBAN_DATA = {json_str};", template)
    else:
        # Inject before </head>
        inject = f"<script>window.KANBAN_DATA = {json_str};</script>\n</head>"
        return template.replace("</head>", inject)

def sync():
    """Main sync function."""
    
    print("🔄 Syncing kanban...")
    
    # Export data
    data = export_database()
    
    # Get template
    template = get_template()
    
    # Embed data
    html = embed_data(template, data)
    
    # Write output
    HTML_PATH.write_text(html)
    
    # Report
    stats = data["stats"]
    print(f"✓ Kanban synced: {stats['done_tasks']}/{stats['total_tasks']} tasks ({stats['completion_pct']}%)")
    
    return data

if __name__ == "__main__":
    sync()
```

### Bash Wrapper

For quick command-line use, create `.claude/scripts/sync-kanban.sh`:

```bash
#!/bin/bash
# Quick kanban sync

cd "$(dirname "$0")/.." || exit 1
python3 scripts/sync-kanban.py "$@"
```

### Inline Sync (No Script File)

For environments where you can't create scripts:

```bash
python3 << 'SYNC_SCRIPT'
import sqlite3, json
from datetime import datetime
from pathlib import Path

db = Path(".claude/tasks.db")
html = Path(".claude/kanban.html")

conn = sqlite3.connect(db)
conn.row_factory = sqlite3.Row

data = {
    "synced_at": datetime.now().isoformat(),
    "tasks": [dict(r) for r in conn.execute("SELECT * FROM tasks").fetchall()],
    "stories": [dict(r) for r in conn.execute("SELECT * FROM stories").fetchall()],
    "epics": [dict(r) for r in conn.execute("SELECT * FROM epics").fetchall()],
}
conn.close()

content = html.read_text()
import re
content = re.sub(
    r"window\.KANBAN_DATA = \{[\s\S]*?\};",
    f"window.KANBAN_DATA = {json.dumps(data, default=str)};",
    content
)
html.write_text(content)
print(f"✓ Synced {len(data['tasks'])} tasks")
SYNC_SCRIPT
```

## HTTP Server Options

### Python (Built-in)

```bash
# Start server
cd .claude && python3 -m http.server 3333 &
echo $! > .kanban.pid

# Access at: http://localhost:3333/kanban.html

# Stop server
kill $(cat .claude/.kanban.pid)
rm .claude/.kanban.pid
```

### Node.js (npx serve)

```bash
# Start server
cd .claude && npx serve -p 3333 &
echo $! > .kanban.pid

# Access at: http://localhost:3333/kanban.html
```

### Node.js (http-server)

```bash
# Start server
cd .claude && npx http-server -p 3333 &
echo $! > .kanban.pid
```

### PHP (if available)

```bash
cd .claude && php -S localhost:3333 &
echo $! > .kanban.pid
```

## Auto-Refresh

### Browser-Side Polling

Add to kanban.html for auto-refresh:

```html
<script>
(function() {
  const REFRESH_INTERVAL = 5000; // 5 seconds
  let lastSyncTime = null;
  
  async function checkForUpdates() {
    try {
      // Fetch with cache-busting
      const resp = await fetch(`kanban.html?_=${Date.now()}`);
      const text = await resp.text();
      
      // Extract sync timestamp
      const match = text.match(/"synced_at":\s*"([^"]+)"/);
      if (match) {
        const newSyncTime = match[1];
        if (lastSyncTime && newSyncTime !== lastSyncTime) {
          console.log('Kanban updated, refreshing...');
          location.reload();
        }
        lastSyncTime = newSyncTime;
      }
    } catch (e) {
      console.warn('Update check failed:', e);
    }
  }
  
  // Start polling
  setInterval(checkForUpdates, REFRESH_INTERVAL);
  checkForUpdates(); // Initial check
})();
</script>
```

### Server-Sent Events (Advanced)

For real-time updates without polling:

```python
# watch-kanban.py - Watch for DB changes
import sqlite3
import time
import json
from pathlib import Path

DB_PATH = ".claude/tasks.db"
last_mtime = 0

while True:
    current_mtime = Path(DB_PATH).stat().st_mtime
    if current_mtime > last_mtime:
        print("Database changed, syncing...")
        # Run sync
        import subprocess
        subprocess.run(["python3", ".claude/scripts/sync-kanban.py"])
        last_mtime = current_mtime
    time.sleep(1)
```

## Sync Triggers

### When to Sync

| Event | Trigger Sync | Reason |
|-------|--------------|--------|
| Session start | ✅ Always | Fresh state for browser |
| Task created | ✅ Always | New card appears |
| Task status changed | ✅ Always | Card moves columns |
| Story completed | ✅ Always | Progress visible |
| Epic completed | ✅ Always | Milestone visible |
| Error/blocked | ✅ Always | Blocked status shown |
| Remediation tasks added | ✅ Always | New work appears |
| Session end | ✅ Always | Final state saved |
| Git commit | ❌ No | No DB change |
| Checkpoint pause | ❌ No | Already synced |
| Config change | ❌ No | No DB change |

### Integration Points

**In project-harness work loop:**

```python
def complete_task(task_id):
    # 1. Update database
    update_task_status(task_id, "done")
    
    # 2. Git commit
    git_commit(f"Complete {task_id}")
    
    # 3. SYNC KANBAN
    sync_kanban()
    
    # 4. Update progress.md
    update_progress()
    
    # 5. Checkpoint
    checkpoint("task_complete")
```

**In product-manager audit:**

```python
def add_remediation_tasks(tasks):
    # 1. Insert tasks into DB
    for task in tasks:
        insert_task(task)
    
    # 2. SYNC KANBAN
    sync_kanban()
    
    # 3. Report
    print(f"Added {len(tasks)} remediation tasks")
    print("📊 Kanban updated: http://localhost:3333/kanban.html")
```

## Troubleshooting

### Kanban Not Updating

**Symptom**: Browser shows old data

**Fixes**:
1. Check sync ran: `ls -la .claude/kanban.html` (check timestamp)
2. Hard refresh browser: Ctrl+Shift+R / Cmd+Shift+R
3. Check server running: `curl http://localhost:3333/kanban.html`
4. Manual sync: `python3 .claude/scripts/sync-kanban.py`

### Server Not Starting

**Symptom**: "Connection refused" in browser

**Fixes**:
1. Check if already running: `lsof -i :3333`
2. Kill stale process: `kill $(cat .claude/.kanban.pid)`
3. Try different port: `python3 -m http.server 3334`
4. Check firewall settings

### Data Mismatch

**Symptom**: Kanban shows different data than tasks.db

**Fixes**:
1. Force re-sync: `python3 .claude/scripts/sync-kanban.py`
2. Verify DB content: `sqlite3 .claude/tasks.db "SELECT COUNT(*) FROM tasks"`
3. Check template has placeholder: `grep "KANBAN_DATA" .claude/kanban.html`

### Permission Errors

**Symptom**: "Permission denied" when syncing

**Fixes**:
1. Check file permissions: `ls -la .claude/`
2. Fix permissions: `chmod 644 .claude/kanban.html`
3. Check script executable: `chmod +x .claude/scripts/sync-kanban.py`

## Performance

### Large Projects

For projects with 500+ tasks:

```python
# Optimize export with pagination
def export_tasks_paginated(conn, page_size=100):
    offset = 0
    tasks = []
    while True:
        cursor = conn.execute(
            "SELECT * FROM tasks LIMIT ? OFFSET ?", 
            (page_size, offset)
        )
        batch = cursor.fetchall()
        if not batch:
            break
        tasks.extend([dict(r) for r in batch])
        offset += page_size
    return tasks
```

### Debouncing Rapid Changes

When many changes happen quickly:

```python
import time

_last_sync = 0
_sync_debounce = 1.0  # seconds

def sync_kanban_debounced():
    global _last_sync
    now = time.time()
    if now - _last_sync < _sync_debounce:
        return  # Skip, too soon
    _last_sync = now
    sync_kanban()
```

## Best Practices

1. **Always sync after DB changes** — Don't rely on manual refresh
2. **Keep server running** — Start at session begin, stop at session end
3. **Use auto-refresh** — Let browser poll for changes
4. **Check sync in checkpoints** — Confirm kanban is current before pausing
5. **Include URL in messages** — Remind user where to look
6. **Log sync operations** — Track when syncs happen for debugging
