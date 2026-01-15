#!/usr/bin/env python3
"""
Kanban Sync Script
Exports tasks.db to JSON and embeds in kanban.html

Usage:
    python3 sync-kanban.py              # Sync once
    python3 sync-kanban.py --watch      # Watch for changes
    python3 sync-kanban.py --serve      # Start server + sync
"""

import sqlite3
import json
import sys
import os
from datetime import datetime
from pathlib import Path

# Determine paths relative to script location
SCRIPT_DIR = Path(__file__).parent
CLAUDE_DIR = SCRIPT_DIR.parent
DB_PATH = CLAUDE_DIR / "tasks.db"
HTML_PATH = CLAUDE_DIR / "kanban.html"
TEMPLATE_PATH = CLAUDE_DIR / "templates" / "kanban-template.html"
PID_PATH = CLAUDE_DIR / ".kanban.pid"

def export_database() -> dict:
    """Export all tables from tasks.db to dict."""
    
    if not DB_PATH.exists():
        print(f"❌ Database not found: {DB_PATH}")
        return None
    
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    
    data = {
        "synced_at": datetime.now().isoformat(),
        "db_path": str(DB_PATH),
        "projects": [],
        "epics": [],
        "stories": [],
        "tasks": [],
        "dependencies": [],
    }
    
    # Export each table
    tables = ["projects", "epics", "stories", "tasks", "dependencies"]
    for table in tables:
        try:
            cursor = conn.execute(f"SELECT * FROM {table}")
            data[table] = [dict(row) for row in cursor.fetchall()]
        except sqlite3.OperationalError:
            # Table might not exist yet
            pass
    
    # Add computed stats
    data["stats"] = compute_stats(data)
    
    conn.close()
    return data

def compute_stats(data: dict) -> dict:
    """Compute summary statistics."""
    
    tasks = data.get("tasks", [])
    stories = data.get("stories", [])
    epics = data.get("epics", [])
    
    total_tasks = len(tasks)
    done_tasks = len([t for t in tasks if t.get("status") == "done"])
    blocked_tasks = len([t for t in tasks if t.get("status") == "blocked"])
    in_progress = len([t for t in tasks if t.get("status") == "in_progress"])
    review_tasks = len([t for t in tasks if t.get("status") == "review"])
    todo_tasks = total_tasks - done_tasks - blocked_tasks - in_progress - review_tasks
    
    total_stories = len(stories)
    done_stories = len([s for s in stories if s.get("status") == "done"])
    
    return {
        "total_tasks": total_tasks,
        "done_tasks": done_tasks,
        "blocked_tasks": blocked_tasks,
        "in_progress_tasks": in_progress,
        "review_tasks": review_tasks,
        "todo_tasks": todo_tasks,
        "completion_pct": round(100 * done_tasks / total_tasks, 1) if total_tasks > 0 else 0,
        "total_stories": total_stories,
        "done_stories": done_stories,
        "story_pct": round(100 * done_stories / total_stories, 1) if total_stories > 0 else 0,
        "total_epics": len(epics),
        "p0_epics": len([e for e in epics if e.get("priority") == "P0"]),
        "p1_epics": len([e for e in epics if e.get("priority") == "P1"]),
        "p2_epics": len([e for e in epics if e.get("priority") == "P2"]),
    }

def get_template() -> str:
    """Get HTML template content."""
    
    if TEMPLATE_PATH.exists():
        return TEMPLATE_PATH.read_text()
    elif HTML_PATH.exists():
        return HTML_PATH.read_text()
    else:
        # Return minimal template
        return get_default_template()

def get_default_template() -> str:
    """Return default kanban template if none exists."""
    return '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kanban Board</title>
    <script>window.KANBAN_DATA = {};</script>
</head>
<body>
    <div id="app">Loading...</div>
    <script>
        // Kanban will be initialized with KANBAN_DATA
        console.log('Kanban data:', window.KANBAN_DATA);
    </script>
</body>
</html>'''

def embed_data(template: str, data: dict) -> str:
    """Embed JSON data into HTML template."""
    
    json_str = json.dumps(data, default=str, indent=2)
    
    # Try different placeholder patterns
    if "window.KANBAN_DATA = {};" in template:
        return template.replace(
            "window.KANBAN_DATA = {};",
            f"window.KANBAN_DATA = {json_str};"
        )
    elif "window.KANBAN_DATA = " in template:
        # Replace existing data
        import re
        pattern = r"window\.KANBAN_DATA = [\s\S]*?(?=;\s*<\/script>|;\s*$)"
        replacement = f"window.KANBAN_DATA = {json_str}"
        return re.sub(pattern, replacement, template)
    else:
        # Inject before </head>
        inject = f"<script>window.KANBAN_DATA = {json_str};</script>\n</head>"
        return template.replace("</head>", inject)

def sync() -> dict:
    """Main sync function."""
    
    # Export data
    data = export_database()
    if data is None:
        return None
    
    # Get template
    template = get_template()
    
    # Embed data
    html = embed_data(template, data)
    
    # Write output
    HTML_PATH.write_text(html)
    
    return data

def print_status(data: dict):
    """Print sync status."""
    stats = data["stats"]
    print(f"✓ Kanban synced: {stats['done_tasks']}/{stats['total_tasks']} tasks ({stats['completion_pct']}%)")

def start_server(port: int = 3333):
    """Start HTTP server for kanban access."""
    import subprocess
    
    # Check if already running
    if PID_PATH.exists():
        try:
            pid = int(PID_PATH.read_text().strip())
            os.kill(pid, 0)  # Check if process exists
            print(f"📊 Server already running (PID {pid})")
            print(f"   http://localhost:{port}/kanban.html")
            return pid
        except (OSError, ValueError):
            # Process not running, remove stale PID file
            PID_PATH.unlink()
    
    # Start server
    process = subprocess.Popen(
        ["python3", "-m", "http.server", str(port)],
        cwd=str(CLAUDE_DIR),
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    
    # Save PID
    PID_PATH.write_text(str(process.pid))
    
    print(f"📊 Kanban server started (PID {process.pid})")
    print(f"   http://localhost:{port}/kanban.html")
    
    return process.pid

def stop_server():
    """Stop HTTP server."""
    if not PID_PATH.exists():
        print("📊 No server running")
        return
    
    try:
        pid = int(PID_PATH.read_text().strip())
        os.kill(pid, 15)  # SIGTERM
        PID_PATH.unlink()
        print(f"📊 Server stopped (PID {pid})")
    except (OSError, ValueError) as e:
        print(f"⚠️  Could not stop server: {e}")
        if PID_PATH.exists():
            PID_PATH.unlink()

def watch_and_sync(interval: float = 1.0):
    """Watch for database changes and sync."""
    import time
    
    print(f"👀 Watching {DB_PATH} for changes...")
    print("   Press Ctrl+C to stop")
    
    last_mtime = 0
    
    try:
        while True:
            if DB_PATH.exists():
                current_mtime = DB_PATH.stat().st_mtime
                if current_mtime > last_mtime:
                    if last_mtime > 0:  # Skip first sync message
                        print(f"\n🔄 Database changed, syncing...")
                    data = sync()
                    if data:
                        print_status(data)
                    last_mtime = current_mtime
            time.sleep(interval)
    except KeyboardInterrupt:
        print("\n👋 Stopped watching")

def main():
    """CLI entry point."""
    args = sys.argv[1:]
    
    if "--help" in args or "-h" in args:
        print(__doc__)
        return
    
    if "--serve" in args:
        # Start server and sync
        port = 3333
        if "--port" in args:
            idx = args.index("--port")
            port = int(args[idx + 1])
        
        data = sync()
        if data:
            print_status(data)
        start_server(port)
        return
    
    if "--stop" in args:
        stop_server()
        return
    
    if "--watch" in args:
        # Initial sync
        data = sync()
        if data:
            print_status(data)
        # Then watch
        watch_and_sync()
        return
    
    # Default: single sync
    print("🔄 Syncing kanban...")
    data = sync()
    if data:
        print_status(data)

if __name__ == "__main__":
    main()
