#!/usr/bin/env bash
# Validate verify-tasks.sh post-command task verification:
# - sqlite path enforces the 5-minute recency window (fresh tasks verify,
#   stale tasks warn) and ignores archived tasks
# - warnings exit 0 (advisory, never block the session)
# - CLI fallback fires when the ohno DB is absent and reports
#   recency-unknown matches

set -euo pipefail

TEST_DIR=$(mktemp -d)
trap 'rm -rf -- "$TEST_DIR"' EXIT

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/hooks/actions/verify-tasks.sh"
[ -f "$SCRIPT" ] || { echo "script not found: $SCRIPT"; exit 1; }

echo "Testing verify-tasks.sh..."

if bash -n "$SCRIPT"; then
  echo "  PASS: script parses (bash -n)"
else
  echo "  FAIL: bash -n reports a syntax error"
  exit 1
fi

cd "$TEST_DIR"

# Mock npx for the CLI fallback path
MOCK_BIN="$TEST_DIR/bin"
mkdir -p "$MOCK_BIN"
cat > "$MOCK_BIN/npx" << EOF
#!/usr/bin/env bash
echo "\$@" >> "$TEST_DIR/npx_calls.log"
cat "$TEST_DIR/mock-tasks.out" 2>/dev/null || true
exit 0
EOF
chmod +x "$MOCK_BIN/npx"
export PATH="$MOCK_BIN:$PATH"

run_script() {
  SKILL_NAME=security TASK_PREFIX="Security:" bash "$SCRIPT"
}

fresh_ts() { date -u +%Y-%m-%dT%H:%M:%S.000Z; }
stale_ts() {
  python3 -c "from datetime import datetime, timedelta, timezone; print((datetime.now(timezone.utc) - timedelta(minutes=10)).strftime('%Y-%m-%dT%H:%M:%S.000Z'))"
}

if command -v sqlite3 > /dev/null 2>&1; then
  mkdir -p .ohno
  sqlite3 .ohno/tasks.db "CREATE TABLE tasks (id TEXT PRIMARY KEY, title TEXT, status TEXT, created_at TEXT);"

  echo "Test 1: fresh task with the expected prefix verifies via sqlite"
  sqlite3 .ohno/tasks.db "INSERT INTO tasks VALUES ('t1', 'Security: fix XSS in login', 'todo', '$(fresh_ts)');"
  RC=0
  OUTPUT=$(run_script) || RC=$?
  if [ "$RC" -eq 0 ] && [[ "$OUTPUT" == *"Verified: 1 task(s) created with prefix 'Security:' in the last 5 minutes"* ]]; then
    echo "  PASS: fresh task counted within the recency window"
  else
    echo "  FAIL: expected sqlite-backed verification, got exit $RC"
    echo "$OUTPUT"
    exit 1
  fi

  echo "Test 2: stale task (outside the 5-minute window) warns"
  sqlite3 .ohno/tasks.db "DELETE FROM tasks;"
  sqlite3 .ohno/tasks.db "INSERT INTO tasks VALUES ('t2', 'Security: old finding', 'todo', '$(stale_ts)');"
  RC=0
  OUTPUT=$(run_script) || RC=$?
  if [ "$RC" -eq 0 ] && [[ "$OUTPUT" == *"Warning: No tasks with prefix 'Security:'"* ]]; then
    echo "  PASS: 10-minute-old task excluded by the recency window (exit 0)"
  else
    echo "  FAIL: expected a no-tasks warning with exit 0, got exit $RC"
    echo "$OUTPUT"
    exit 1
  fi

  echo "Test 3: archived fresh task is ignored"
  sqlite3 .ohno/tasks.db "DELETE FROM tasks;"
  sqlite3 .ohno/tasks.db "INSERT INTO tasks VALUES ('t3', 'Security: archived finding', 'archived', '$(fresh_ts)');"
  RC=0
  OUTPUT=$(run_script) || RC=$?
  if [ "$RC" -eq 0 ] && [[ "$OUTPUT" == *"Warning: No tasks with prefix 'Security:'"* ]]; then
    echo "  PASS: archived task not counted"
  else
    echo "  FAIL: expected a no-tasks warning for archived-only tasks, got exit $RC"
    echo "$OUTPUT"
    exit 1
  fi

  rm -rf .ohno
else
  echo "  SKIP: sqlite3 not available, skipping DB-backed tests"
fi

echo "Test 4: CLI fallback verifies prefix matches when the DB is absent"
echo "[t9] Security: audit headers (todo)" > "$TEST_DIR/mock-tasks.out"
RC=0
OUTPUT=$(run_script) || RC=$?
if [ "$RC" -eq 0 ] && [[ "$OUTPUT" == *"recency unknown"* ]] && [[ "$OUTPUT" == *"prefix 'Security:'"* ]]; then
  echo "  PASS: CLI fallback reports a recency-unknown match"
else
  echo "  FAIL: expected recency-unknown verification via CLI fallback, got exit $RC"
  echo "$OUTPUT"
  exit 1
fi

echo "Test 5: CLI fallback warns when no tasks match"
: > "$TEST_DIR/mock-tasks.out"
RC=0
OUTPUT=$(run_script) || RC=$?
if [ "$RC" -eq 0 ] && [[ "$OUTPUT" == *"Warning: No tasks with prefix 'Security:'"* ]]; then
  echo "  PASS: empty CLI output warns without blocking (exit 0)"
else
  echo "  FAIL: expected a no-tasks warning with exit 0, got exit $RC"
  echo "$OUTPUT"
  exit 1
fi

echo ""
echo "All verify-tasks tests passed!"
