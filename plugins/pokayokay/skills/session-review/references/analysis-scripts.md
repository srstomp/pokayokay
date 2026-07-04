# Analysis Scripts Reference

Scripts and queries for extracting session review data.

## Git Analysis

### Basic Commit Statistics

```bash
#!/bin/bash
# git-stats.sh - Basic git statistics for session review

# Date range (modify as needed)
SINCE="${1:-1 week ago}"
UNTIL="${2:-now}"

echo "=== Git Statistics ($SINCE to $UNTIL) ==="
echo

# Total commits
TOTAL=$(git log --oneline --since="$SINCE" --until="$UNTIL" | wc -l)
echo "Total commits: $TOTAL"

# Commits by type (based on conventional commits)
echo
echo "Commits by type:"
git log --oneline --since="$SINCE" --until="$UNTIL" | \
    grep -oE "^[a-f0-9]+ (feat|fix|refactor|test|docs|style|chore)" | \
    cut -d' ' -f2 | sort | uniq -c | sort -rn

# Reverts
REVERTS=$(git log --oneline --since="$SINCE" --until="$UNTIL" --grep="[Rr]evert" | wc -l)
echo
echo "Reverts: $REVERTS ($(echo "scale=1; $REVERTS * 100 / $TOTAL" | bc)%)"

# Fix commits
FIXES=$(git log --oneline --since="$SINCE" --until="$UNTIL" --grep="^fix" | wc -l)
echo "Fix commits: $FIXES ($(echo "scale=1; $FIXES * 100 / $TOTAL" | bc)%)"

# Average commit size
echo
echo "Commit size distribution:"
git log --shortstat --since="$SINCE" --until="$UNTIL" --format="" | \
    awk '/files? changed/ {
        commits++
        files += $1
        if ($4 ~ /insertion/) ins += $4
        if ($4 ~ /deletion/) del += $4
        if ($6 ~ /deletion/) del += $6
    }
    END {
        if (commits > 0) {
            print "  Avg files/commit: " files/commits
            print "  Avg insertions/commit: " ins/commits
            print "  Avg deletions/commit: " del/commits
        }
    }'

# Claude commits specifically
echo
echo "Claude commits:"
git log --oneline --since="$SINCE" --until="$UNTIL" --grep="\[claude\]" | wc -l
```

### Commit Timeline

```bash
#!/bin/bash
# commit-timeline.sh - Show commit activity over time

SINCE="${1:-1 week ago}"

echo "=== Commit Timeline ==="
git log --format="%ai %s" --since="$SINCE" | \
    awk '{
        date = $1
        hour = substr($2, 1, 2)
        dates[date]++
        hours[hour]++
    }
    END {
        print "\nBy Date:"
        for (d in dates) print "  " d ": " dates[d]
        print "\nBy Hour:"
        for (h in hours) print "  " h ":00 - " hours[h]
    }' | sort
```

### File Churn Analysis

```bash
#!/bin/bash
# file-churn.sh - Find most frequently changed files

SINCE="${1:-1 week ago}"

echo "=== Most Changed Files ==="
git log --name-only --format="" --since="$SINCE" | \
    sort | uniq -c | sort -rn | head -20
```

## Task Analysis (ohno)

Task state lives in ohno (`.ohno/`) — query it via the CLI's global `--json` flag or MCP tools; never read ohno's internal database directly.

### Task Completion Metrics

```bash
#!/bin/bash
# task-metrics.sh - Completion stats from ohno

npx @stevestomp/ohno-cli tasks --json | node -e '
const tasks = JSON.parse(require("fs").readFileSync(0, "utf8"));

// Overall completion stats
const count = s => tasks.filter(t => t.status === s).length;
console.log("=== Overall ===");
console.log(`Total: ${tasks.length}`);
console.log(`Done: ${count("done")}, In progress: ${count("in_progress")}, Blocked: ${count("blocked")}`);
console.log(`Completion: ${(100 * count("done") / (tasks.length || 1)).toFixed(1)}%`);

// Completion by task type
console.log("\n=== By Task Type ===");
const byType = {};
for (const t of tasks) {
  const g = (byType[t.task_type] ||= { total: 0, done: 0 });
  g.total++;
  if (t.status === "done") g.done++;
}
for (const [type, g] of Object.entries(byType)) {
  console.log(`${type}: ${g.done}/${g.total} (${(100 * g.done / g.total).toFixed(1)}%)`);
}'
```

### Blocked Task Analysis

```bash
# Tasks currently blocked, with reasons
npx @stevestomp/ohno-cli tasks --json | node -e '
const tasks = JSON.parse(require("fs").readFileSync(0, "utf8"));
for (const t of tasks.filter(t => t.status === "blocked")) {
  console.log(`${t.id}: ${t.title} — ${t.blocked_reason || "no reason recorded"}`);
}'
```

In an MCP session, `mcp__ohno__get_project_status` and `mcp__ohno__get_blocked_tasks` return the same data without shell scripting, and `mcp__ohno__get_task_dependencies` shows which tasks blocked others.

## Session Log Analysis

### Python Session Parser

```python
#!/usr/bin/env python3
"""
session_analyzer.py - Parse and analyze session logs from .claude/sessions/
"""

import re
import json
from pathlib import Path
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from typing import Optional

@dataclass
class TaskEvent:
    task_id: str
    title: str
    started: Optional[datetime] = None
    completed: Optional[datetime] = None
    status: str = "unknown"

@dataclass 
class CheckpointEvent:
    event_type: str
    timestamp: datetime
    action_taken: str
    context: str = ""

@dataclass
class Session:
    id: str
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    tasks: list[TaskEvent] = field(default_factory=list)
    checkpoints: list[CheckpointEvent] = field(default_factory=list)
    errors: list[str] = field(default_factory=list)
    commits: list[str] = field(default_factory=list)

def parse_session_log(log_path: Path) -> Session:
    """Parse a single session log file."""
    content = log_path.read_text()
    session_id = log_path.stem
    
    session = Session(id=session_id)
    
    # Extract timestamps
    time_pattern = r'(\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2})'
    times = re.findall(time_pattern, content)
    if times:
        session.start_time = datetime.fromisoformat(times[0].replace(' ', 'T'))
        session.end_time = datetime.fromisoformat(times[-1].replace(' ', 'T'))
    
    # Extract task events
    task_pattern = r'Task (?:start|complete).*?([T]\d+).*?[-–]\s*(.+?)(?:\n|$)'
    for match in re.finditer(task_pattern, content, re.IGNORECASE):
        task_id, title = match.groups()
        session.tasks.append(TaskEvent(task_id=task_id, title=title.strip()))
    
    # Extract checkpoints
    checkpoint_pattern = r'CHECKPOINT:\s*(\w+).*?(?:Action|Decision):\s*(\w+)'
    for match in re.finditer(checkpoint_pattern, content, re.IGNORECASE):
        event_type, action = match.groups()
        session.checkpoints.append(CheckpointEvent(
            event_type=event_type,
            timestamp=session.start_time,  # Approximate
            action_taken=action
        ))
    
    # Extract errors
    error_pattern = r'(?:Error|Failed|Exception):\s*(.+?)(?:\n|$)'
    session.errors = re.findall(error_pattern, content, re.IGNORECASE)
    
    # Extract commits
    commit_pattern = r'(?:Commit|commit):\s*([a-f0-9]{7,40})'
    session.commits = re.findall(commit_pattern, content)
    
    return session

def analyze_sessions(sessions_dir: Path) -> dict:
    """Analyze all sessions in directory."""
    sessions = []
    for log_file in sorted(sessions_dir.glob("*.md")):
        sessions.append(parse_session_log(log_file))
    
    # Compute metrics
    total_tasks = sum(len(s.tasks) for s in sessions)
    total_errors = sum(len(s.errors) for s in sessions)
    total_checkpoints = sum(len(s.checkpoints) for s in sessions)
    
    # Time analysis
    total_duration = timedelta()
    for s in sessions:
        if s.start_time and s.end_time:
            total_duration += s.end_time - s.start_time
    
    # Checkpoint analysis
    checkpoint_actions = {}
    for s in sessions:
        for cp in s.checkpoints:
            key = f"{cp.event_type}:{cp.action_taken}"
            checkpoint_actions[key] = checkpoint_actions.get(key, 0) + 1
    
    return {
        'session_count': len(sessions),
        'total_tasks': total_tasks,
        'total_errors': total_errors,
        'total_checkpoints': total_checkpoints,
        'total_duration_hours': total_duration.total_seconds() / 3600,
        'avg_tasks_per_session': total_tasks / len(sessions) if sessions else 0,
        'checkpoint_actions': checkpoint_actions,
        'sessions': sessions
    }

def detect_patterns(analysis: dict) -> list[dict]:
    """Detect good and bad patterns from analysis."""
    patterns = []
    
    # Check error rate
    if analysis['session_count'] > 0:
        error_rate = analysis['total_errors'] / analysis['session_count']
        if error_rate > 2:
            patterns.append({
                'type': 'bad',
                'name': 'High Error Rate',
                'description': f"Average {error_rate:.1f} errors per session",
                'severity': 'warning'
            })
        elif error_rate < 0.5:
            patterns.append({
                'type': 'good',
                'name': 'Low Error Rate',
                'description': f"Average {error_rate:.1f} errors per session",
                'severity': 'positive'
            })
    
    # Check task completion consistency
    task_counts = [len(s.tasks) for s in analysis['sessions']]
    if task_counts:
        variance = max(task_counts) - min(task_counts)
        if variance <= 2:
            patterns.append({
                'type': 'good',
                'name': 'Consistent Productivity',
                'description': f"Task count varies by only {variance} across sessions",
                'severity': 'positive'
            })
    
    return patterns

if __name__ == "__main__":
    import sys
    
    sessions_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".claude/sessions")
    
    if not sessions_dir.exists():
        print(f"Sessions directory not found: {sessions_dir}")
        sys.exit(1)
    
    analysis = analyze_sessions(sessions_dir)
    patterns = detect_patterns(analysis)
    
    print(json.dumps({
        'analysis': {k: v for k, v in analysis.items() if k != 'sessions'},
        'patterns': patterns
    }, indent=2, default=str))
```

## Progress.md Analysis

### Python Progress Parser

```python
#!/usr/bin/env python3
"""
progress_analyzer.py - Parse and analyze progress.md
"""

import re
from pathlib import Path
from dataclasses import dataclass

@dataclass
class ProgressState:
    active_feature: str = ""
    active_story: str = ""
    active_task: str = ""
    total_tasks: int = 0
    completed_tasks: int = 0
    completion_pct: float = 0.0

def parse_progress(progress_path: Path) -> ProgressState:
    """Parse progress.md to extract current state."""
    content = progress_path.read_text()
    state = ProgressState()
    
    # Extract active items
    active_pattern = r'\*\*Active (\w+)\*\*:\s*(.+?)(?:\n|$)'
    for match in re.finditer(active_pattern, content):
        item_type, value = match.groups()
        if 'feature' in item_type.lower():
            state.active_feature = value.strip()
        elif 'story' in item_type.lower():
            state.active_story = value.strip()
        elif 'task' in item_type.lower():
            state.active_task = value.strip()
    
    # Extract progress stats
    progress_pattern = r'(\d+)/(\d+)\s*tasks?\s*\((\d+)%\)'
    match = re.search(progress_pattern, content)
    if match:
        state.completed_tasks = int(match.group(1))
        state.total_tasks = int(match.group(2))
        state.completion_pct = float(match.group(3))
    
    return state

def compare_progress(before: ProgressState, after: ProgressState) -> dict:
    """Compare two progress states."""
    return {
        'tasks_completed': after.completed_tasks - before.completed_tasks,
        'progress_delta': after.completion_pct - before.completion_pct,
        'feature_changed': before.active_feature != after.active_feature,
        'story_changed': before.active_story != after.active_story
    }
```

## Combined Analysis Script

```bash
#!/bin/bash
# full-analysis.sh - Run all analysis and generate report

PROJECT_DIR="${1:-.}"
CLAUDE_DIR="$PROJECT_DIR/.claude"
OUTPUT_DIR="$CLAUDE_DIR/reviews"

mkdir -p "$OUTPUT_DIR"

REPORT_DATE=$(date +%Y-%m-%d)
REPORT_FILE="$OUTPUT_DIR/$REPORT_DATE.md"

echo "Running session review analysis..."
echo

# Git analysis
echo "## Git Analysis" > "$REPORT_FILE"
echo >> "$REPORT_FILE"
./git-stats.sh "1 week ago" >> "$REPORT_FILE"

# Task analysis (ohno)
if [ -d "$PROJECT_DIR/.ohno" ]; then
    echo >> "$REPORT_FILE"
    echo "## Task Analysis" >> "$REPORT_FILE"
    echo >> "$REPORT_FILE"
    ./task-metrics.sh >> "$REPORT_FILE"
fi

# Session analysis
if [ -d "$CLAUDE_DIR/sessions" ]; then
    echo >> "$REPORT_FILE"
    echo "## Session Analysis" >> "$REPORT_FILE"
    echo >> "$REPORT_FILE"
    python3 session_analyzer.py "$CLAUDE_DIR/sessions" >> "$REPORT_FILE"
fi

echo "Report generated: $REPORT_FILE"
```
