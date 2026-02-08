#!/bin/bash
# Print session summary and persist to ohno
# Called by: post-session hooks (via bridge.py handle_session_end)

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
SUMMARY=""

# Count recent commits from this session (last hour)
RECENT_COMMITS=$(git log --oneline --since="1 hour ago" 2>/dev/null | head -10 || true)
COMMIT_COUNT=$(echo "$RECENT_COMMITS" | grep -c . 2>/dev/null || echo "0")

# Check for uncommitted changes
UNCOMMITTED=""
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  UNCOMMITTED=$(git status --short 2>/dev/null)
fi

# Read token usage from bridge-managed state file
TOKEN_FILE=".claude/pokayokay-token-usage.json"
AGENT_COUNT=0
TOTAL_TOKENS=0
TOKEN_DETAILS=""
if [ -f "$TOKEN_FILE" ]; then
  AGENT_COUNT=$(python3 -c "import json; d=json.load(open('$TOKEN_FILE')); print(d.get('total_agents',0))" 2>/dev/null || echo "0")
  TOTAL_TOKENS=$(python3 -c "import json; d=json.load(open('$TOKEN_FILE')); print(d.get('total_tokens',0))" 2>/dev/null || echo "0")
  if [ "$AGENT_COUNT" -gt 0 ] 2>/dev/null; then
    TOKEN_DETAILS=$(python3 -c "
import json
d = json.load(open('$TOKEN_FILE'))
for a in d.get('agents', []):
    tokens = a.get('total_tokens', 0)
    t_str = f'{tokens:,}' if tokens else '?'
    dur = a.get('duration_ms', 0)
    dur_str = f'{dur//1000}s' if dur else '?'
    print(f\"  {a.get('type','?'):30s} {t_str:>10s} tokens  {dur_str:>6s}\")
" 2>/dev/null || echo "  (parse error)")
  fi
fi

# Build summary string
SUMMARY="Session ended at ${TIMESTAMP}."
if [ "$COMMIT_COUNT" -gt 0 ] 2>/dev/null; then
  SUMMARY="${SUMMARY} Commits: ${COMMIT_COUNT}."
else
  SUMMARY="${SUMMARY} Commits: 0."
fi
if [ "$AGENT_COUNT" -gt 0 ] 2>/dev/null; then
  SUMMARY="${SUMMARY} Agents: ${AGENT_COUNT} (${TOTAL_TOKENS} tokens)."
fi
if [ -n "$UNCOMMITTED" ]; then
  SUMMARY="${SUMMARY} WARNING: uncommitted changes remain."
fi

# --- Interactive output (stderr, for terminal sessions) ---
echo ""
echo "========================================"
echo "SESSION COMPLETE"
echo "========================================"
echo "Time: ${TIMESTAMP}"

if [ -n "$RECENT_COMMITS" ] && [ "$COMMIT_COUNT" -gt 0 ] 2>/dev/null; then
  echo ""
  echo "Recent commits (${COMMIT_COUNT}):"
  echo "$RECENT_COMMITS"
fi

if [ "$AGENT_COUNT" -gt 0 ] 2>/dev/null; then
  echo ""
  echo "Subagent usage (${AGENT_COUNT} agents, ${TOTAL_TOKENS} total tokens):"
  echo "$TOKEN_DETAILS"
fi

if [ -n "$UNCOMMITTED" ]; then
  echo ""
  echo "WARNING: Uncommitted changes remain:"
  echo "$UNCOMMITTED"
fi

echo "========================================"

# --- Persist to ohno (for headless/chained sessions) ---
OHNO_DB=".ohno/tasks.db"
if [ -f "$OHNO_DB" ]; then
  SESSION_ID="session-$(date +%s)"
  sqlite3 "$OHNO_DB" "INSERT INTO task_activity (id, task_id, activity_type, description, actor, created_at) VALUES ('${SESSION_ID}', 'session', 'note', '$(echo "$SUMMARY" | sed "s/'/''/g")', 'session-summary-hook', '$(date -u +%Y-%m-%dT%H:%M:%S.000Z)');" 2>/dev/null || true
fi

# Also write to sessions directory for chain reports
SESSIONS_DIR=".ohno/sessions"
if [ -d "$(dirname "$SESSIONS_DIR")" ]; then
  mkdir -p "$SESSIONS_DIR"
  SESSION_FILE="${SESSIONS_DIR}/$(date +%Y%m%d-%H%M%S).txt"
  {
    echo "Time: ${TIMESTAMP}"
    echo "Commits: ${COMMIT_COUNT}"
    if [ -n "$RECENT_COMMITS" ] && [ "$COMMIT_COUNT" -gt 0 ] 2>/dev/null; then
      echo ""
      echo "Commits:"
      echo "$RECENT_COMMITS"
    fi
    if [ "$AGENT_COUNT" -gt 0 ] 2>/dev/null; then
      echo ""
      echo "Agents: ${AGENT_COUNT} (${TOTAL_TOKENS} tokens)"
      echo "$TOKEN_DETAILS"
    fi
    if [ -n "$UNCOMMITTED" ]; then
      echo ""
      echo "Uncommitted:"
      echo "$UNCOMMITTED"
    fi
  } > "$SESSION_FILE" 2>/dev/null || true
fi
