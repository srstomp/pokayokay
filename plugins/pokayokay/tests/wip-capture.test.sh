#!/bin/bash
# Test WIP auto-capture from bridge.py
# Validates Edit, Write, and Bash tool PostToolUse hooks capture WIP data,
# and that the debounce state persists across bridge invocations via
# .pokayokay/wip-state.json (the bridge runs as a fresh process per event).

set -e

TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

echo "Testing WIP auto-capture..."

# Script path
BRIDGE="$(cd "$(dirname "$0")/.." && pwd)/hooks/actions/bridge.py"

# Setup test environment
cd "$TEST_DIR"

# Pin the project dir so wip-state.json lands in $TEST_DIR even when this
# test runs inside a session that exports CLAUDE_PROJECT_DIR.
export YOKAY_PROJECT_DIR="$TEST_DIR"
WIP_STATE="$TEST_DIR/.pokayokay/wip-state.json"

# Mock npx command that captures what would be sent to ohno
MOCK_BIN="$TEST_DIR/bin"
mkdir -p "$MOCK_BIN"
mkdir -p "$TEST_DIR/wip_calls"

# Create mock npx that writes to a file in TEST_DIR
cat > "$MOCK_BIN/npx" << EOF
#!/bin/bash
# Capture WIP update calls for testing
if [ "\$2" = "update-wip" ]; then
  TASK_ID="\$3"
  WIP_DATA="\$4"
  echo "\$WIP_DATA" > "$TEST_DIR/wip_calls/last_call.json"
  echo "\$WIP_DATA" >> "$TEST_DIR/wip_calls/count.log"
  exit 0
fi
exit 1
EOF
chmod +x "$MOCK_BIN/npx"

# Add mock to PATH
export PATH="$MOCK_BIN:$PATH"
export CURRENT_OHNO_TASK_ID="test-123"

# Test 1: Edit tool triggers WIP update with file path
echo "Test 1: Edit tool captures file modifications"
echo '{"tool_name":"Edit","tool_input":{"file_path":"src/auth.ts","old_string":"foo","new_string":"bar"},"tool_response":{},"hook_event_name":"PostToolUse"}' | \
  python3 "$BRIDGE" > /dev/null 2>&1

if [ -f "$TEST_DIR/wip_calls/last_call.json" ]; then
  FILES=$(cat "$TEST_DIR/wip_calls/last_call.json" | jq -r '.files_modified[]' 2>/dev/null || echo "")
  UNCOMMITTED=$(cat "$TEST_DIR/wip_calls/last_call.json" | jq -r '.uncommitted_changes' 2>/dev/null || echo "")

  if [[ "$FILES" == *"src/auth.ts"* ]] && [ "$UNCOMMITTED" = "true" ]; then
    echo "  PASS: Edit tool captured file_path and uncommitted_changes"
  else
    echo "  FAIL: Edit tool did not capture expected WIP data"
    echo "  Files: $FILES"
    echo "  Uncommitted: $UNCOMMITTED"
    exit 1
  fi
else
  echo "  FAIL: No WIP update call made"
  exit 1
fi

# Test 2: Write tool triggers WIP update
# Reset the persisted debounce state so this invocation fires immediately.
echo "Test 2: Write tool captures file modifications"
rm -f "$TEST_DIR/wip_calls/last_call.json" "$WIP_STATE"
echo '{"tool_name":"Write","tool_input":{"file_path":"src/db.ts","content":"new content"},"tool_response":{},"hook_event_name":"PostToolUse"}' | \
  python3 "$BRIDGE" > /dev/null 2>&1

if [ -f "$TEST_DIR/wip_calls/last_call.json" ]; then
  FILES=$(cat "$TEST_DIR/wip_calls/last_call.json" | jq -r '.files_modified[]' 2>/dev/null || echo "")

  if [[ "$FILES" == *"src/db.ts"* ]]; then
    echo "  PASS: Write tool captured file_path"
  else
    echo "  FAIL: Write tool did not capture expected WIP data"
    echo "  Files: $FILES"
    exit 1
  fi
else
  echo "  FAIL: No WIP update call made"
  exit 1
fi

# Test 3: Bash test command captures test results
echo "Test 3: Bash test command captures test results"
rm -f "$TEST_DIR/wip_calls/last_call.json" "$WIP_STATE"

echo '{"tool_name":"Bash","tool_input":{"command":"npm test"},"tool_response":{"content":[{"type":"text","text":"12 passing\n1 failing"}],"exit_code":1},"hook_event_name":"PostToolUse"}' | \
  python3 "$BRIDGE" > /dev/null 2>&1

if [ -f "$TEST_DIR/wip_calls/last_call.json" ]; then
  PASSED=$(cat "$TEST_DIR/wip_calls/last_call.json" | jq -r '.test_results.passed' 2>/dev/null || echo "")
  FAILED=$(cat "$TEST_DIR/wip_calls/last_call.json" | jq -r '.test_results.failed' 2>/dev/null || echo "")

  if [ "$PASSED" = "12" ] && [ "$FAILED" = "1" ]; then
    echo "  PASS: Bash test command captured test results"
  else
    echo "  FAIL: Bash test command did not capture expected test results"
    echo "  Passed: $PASSED, Failed: $FAILED"
    exit 1
  fi
else
  echo "  FAIL: No WIP update call made"
  exit 1
fi

# Test 4: Git commit captures hash (force update bypasses the debounce)
echo "Test 4: Git commit captures commit hash"
rm -f "$TEST_DIR/wip_calls/last_call.json"
echo '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"fix\""},"tool_response":{"content":[{"type":"text","text":"[main abc1234] fix"}],"exit_code":0},"hook_event_name":"PostToolUse"}' | \
  python3 "$BRIDGE" > /dev/null 2>&1

if [ -f "$TEST_DIR/wip_calls/last_call.json" ]; then
  COMMIT=$(cat "$TEST_DIR/wip_calls/last_call.json" | jq -r '.last_commit' 2>/dev/null || echo "")
  UNCOMMITTED=$(cat "$TEST_DIR/wip_calls/last_call.json" | jq -r '.uncommitted_changes' 2>/dev/null || echo "")

  if [ "$COMMIT" = "abc1234" ] && [ "$UNCOMMITTED" = "false" ]; then
    echo "  PASS: Git commit captured hash and cleared uncommitted_changes"
  else
    echo "  FAIL: Git commit did not capture expected WIP data"
    echo "  Commit: $COMMIT, Uncommitted: $UNCOMMITTED"
    exit 1
  fi
else
  echo "  FAIL: No WIP update call made"
  exit 1
fi

# Test 5: Debounce persists across invocations (fresh process each time)
echo "Test 5: Debounce persists across bridge invocations"
rm -f "$TEST_DIR/wip_calls/last_call.json" "$TEST_DIR/wip_calls/count.log" "$WIP_STATE"
export CURRENT_OHNO_TASK_ID="test-debounce"

echo '{"tool_name":"Edit","tool_input":{"file_path":"src/one.ts"},"tool_response":{},"hook_event_name":"PostToolUse"}' | \
  python3 "$BRIDGE" > /dev/null 2>&1
echo '{"tool_name":"Edit","tool_input":{"file_path":"src/two.ts"},"tool_response":{},"hook_event_name":"PostToolUse"}' | \
  python3 "$BRIDGE" > /dev/null 2>&1

CALL_COUNT=$(wc -l < "$TEST_DIR/wip_calls/count.log" | tr -d ' ')
STATE_FILES=$(jq -r '.files[]' "$WIP_STATE" 2>/dev/null || echo "")

if [ "$CALL_COUNT" = "1" ]; then
  echo "  PASS: second edit within 5s was debounced (1 CLI call)"
else
  echo "  FAIL: expected exactly 1 CLI call, got $CALL_COUNT"
  exit 1
fi

if [[ "$STATE_FILES" == *"src/one.ts"* ]] && [[ "$STATE_FILES" == *"src/two.ts"* ]]; then
  echo "  PASS: state file accumulated both files"
else
  echo "  FAIL: state file missing tracked files"
  echo "  Files: $STATE_FILES"
  exit 1
fi

# Test 6: Changing task id resets the tracked file list
echo "Test 6: Task change resets tracked files"
rm -f "$TEST_DIR/wip_calls/last_call.json"
export CURRENT_OHNO_TASK_ID="test-456"

echo '{"tool_name":"Edit","tool_input":{"file_path":"src/three.ts"},"tool_response":{},"hook_event_name":"PostToolUse"}' | \
  python3 "$BRIDGE" > /dev/null 2>&1

STATE_TASK=$(jq -r '.task_id' "$WIP_STATE" 2>/dev/null || echo "")
STATE_FILES=$(jq -r '.files[]' "$WIP_STATE" 2>/dev/null || echo "")

if [ "$STATE_TASK" = "test-456" ] && [[ "$STATE_FILES" == *"src/three.ts"* ]] && [[ "$STATE_FILES" != *"src/one.ts"* ]]; then
  echo "  PASS: new task id reset the file list"
else
  echo "  FAIL: task change did not reset state"
  echo "  Task: $STATE_TASK, Files: $STATE_FILES"
  exit 1
fi

if [ ! -f "$TEST_DIR/wip_calls/last_call.json" ]; then
  echo "  FAIL: fresh task should update immediately"
  exit 1
fi
echo "  PASS: fresh task updated immediately"

# Test 7: Git commit clears the persisted tracked file list
echo "Test 7: Git commit clears tracked files"
echo '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"done\""},"tool_response":{"content":[{"type":"text","text":"[main def5678] done"}],"exit_code":0},"hook_event_name":"PostToolUse"}' | \
  python3 "$BRIDGE" > /dev/null 2>&1

STATE_FILE_COUNT=$(jq -r '.files | length' "$WIP_STATE" 2>/dev/null || echo "")

if [ "$STATE_FILE_COUNT" = "0" ]; then
  echo "  PASS: commit cleared the tracked file list"
else
  echo "  FAIL: expected empty file list after commit, got $STATE_FILE_COUNT entries"
  exit 1
fi

# Test 8: No WIP update when task_id is unknown
echo "Test 8: No WIP update when task_id is unknown"
rm -f "$TEST_DIR/wip_calls/last_call.json"
export CURRENT_OHNO_TASK_ID="unknown"

echo '{"tool_name":"Edit","tool_input":{"file_path":"src/test.ts"},"tool_response":{},"hook_event_name":"PostToolUse"}' | \
  python3 "$BRIDGE" > /dev/null 2>&1

if [ ! -f "$TEST_DIR/wip_calls/last_call.json" ]; then
  echo "  PASS: No WIP update when task_id is unknown"
else
  echo "  FAIL: WIP update was made when task_id is unknown"
  exit 1
fi

echo ""
echo "All WIP auto-capture tests passed!"
