#!/bin/bash
# Start a project-harness session
# Usage: ./start-session.sh [port]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"
PORT="${1:-3333}"

echo "🚀 Starting project harness session..."
echo ""

# Check if .claude directory exists
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "❌ .claude directory not found"
    echo "   Run prd-analyzer first to create project structure"
    exit 1
fi

# Check if tasks.db exists
if [ ! -f "$CLAUDE_DIR/tasks.db" ]; then
    echo "⚠️  No tasks.db found"
    echo "   Run prd-analyzer to create tasks"
fi

# Start kanban server if not running
if [ -f "$CLAUDE_DIR/.kanban.pid" ]; then
    PID=$(cat "$CLAUDE_DIR/.kanban.pid")
    if kill -0 "$PID" 2>/dev/null; then
        echo "📊 Kanban server already running (PID $PID)"
    else
        echo "📊 Starting kanban server..."
        rm -f "$CLAUDE_DIR/.kanban.pid"
        cd "$CLAUDE_DIR" && python3 -m http.server "$PORT" > /dev/null 2>&1 &
        echo $! > "$CLAUDE_DIR/.kanban.pid"
    fi
else
    echo "📊 Starting kanban server..."
    cd "$CLAUDE_DIR" && python3 -m http.server "$PORT" > /dev/null 2>&1 &
    echo $! > "$CLAUDE_DIR/.kanban.pid"
fi

# Initial sync
if [ -f "$CLAUDE_DIR/tasks.db" ]; then
    echo "🔄 Syncing kanban..."
    python3 "$SCRIPT_DIR/sync-kanban.py" 2>/dev/null || echo "   (sync script not found, using inline)"
fi

echo ""
echo "✅ Session ready!"
echo ""
echo "📊 Kanban Board: http://localhost:$PORT/kanban.html"
echo "   Auto-refreshes every 5 seconds"
echo ""
echo "📁 Project files:"
echo "   - Config:   $CLAUDE_DIR/config.yaml"
echo "   - Progress: $CLAUDE_DIR/progress.md"
echo "   - Tasks:    $CLAUDE_DIR/tasks.db"
echo ""
