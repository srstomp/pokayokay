#!/usr/bin/env bash
# Validate the coordinator<->hook task state file (.pokayokay/pokayokay-task-state.json):
# handle_task_start persists {task_id, force_worktree, force_inplace} and
# honors coordinator-pre-written force flags, WIP tracking attributes work via
# the state file (no env var needed), and handle_task_complete clears it.

set -euo pipefail

TEST_DIR=$(mktemp -d)
trap 'rm -rf -- "$TEST_DIR"' EXIT

BRIDGE="$(cd "$(dirname "$0")/.." && pwd)/hooks/actions/bridge.py"

echo "Testing bridge task state file..."

cd "$TEST_DIR"

# Pin the project dir and drop any enclosing-session task id so the state
# file is provably the only channel.
export YOKAY_PROJECT_DIR="$TEST_DIR"
unset CURRENT_OHNO_TASK_ID CLAUDE_PROJECT_DIR CODEX_WORKSPACE_DIR YOKAY_WORK_MODE 2>/dev/null || true

STATE_FILE="$TEST_DIR/.pokayokay/pokayokay-task-state.json"

# Hook actions (setup-worktree, commit) need a real git repo
git init -q
git config user.email "test@example.com"
git config user.name "Task State Test"
echo "seed" > seed.txt
git add seed.txt
git commit -qm "seed"

# Mock npx: task metadata lookups, blocked-task checks, WIP capture
MOCK_BIN="$TEST_DIR/bin"
mkdir -p "$MOCK_BIN" "$TEST_DIR/wip_calls"
cat > "$MOCK_BIN/npx" << EOF
#!/usr/bin/env bash
args="\$*"
echo "\$args" >> "$TEST_DIR/npx_calls.log"
case "\$args" in
  *"task get"*)
    echo '{"id":"task-777","title":"Refactor config loader","task_type":"chore","story_id":"","status":"in_progress"}'
    ;;
  *"update-wip"*)
    # invoked as: npx @stevestomp/ohno-cli update-wip <task_id> <json>
    echo "\$3" > "$TEST_DIR/wip_calls/last_task_id"
    ;;
  *"tasks --status"*)
    echo '{"tasks":[],"total_count":0}'
    ;;
esac
exit 0
EOF
chmod +x "$MOCK_BIN/npx"
export PATH="$MOCK_BIN:$PATH"

echo "Test 1: in_progress transition persists the active task"
echo '{"tool_name":"mcp__ohno__update_task_status","tool_input":{"task_id":"task-777","status":"in_progress"},"tool_response":{"content":[{"type":"text","text":"{\"success\":true}"}]},"hook_event_name":"PostToolUse"}' | \
  python3 "$BRIDGE" > /dev/null

STATE_TASK=$(python3 -c "import json;print(json.load(open('$STATE_FILE')).get('task_id',''))" 2>/dev/null || echo "")
if [ "$STATE_TASK" = "task-777" ]; then
  echo "  PASS: task state file holds task-777"
else
  echo "  FAIL: expected task-777 in state file, got '$STATE_TASK'"
  cat "$STATE_FILE" 2>/dev/null || echo "  (no state file)"
  exit 1
fi

echo "Test 2: WIP tracking reads the task id from the state file (no env var)"
echo '{"tool_name":"Edit","tool_input":{"file_path":"src/config.ts","old_string":"a","new_string":"b"},"tool_response":{},"hook_event_name":"PostToolUse"}' | \
  python3 "$BRIDGE" > /dev/null

if [ "$(cat "$TEST_DIR/wip_calls/last_task_id" 2>/dev/null)" = "task-777" ]; then
  echo "  PASS: WIP update attributed to task-777 via state file"
else
  echo "  FAIL: expected WIP update for task-777"
  cat "$TEST_DIR/wip_calls/last_task_id" 2>/dev/null || echo "  (no WIP call recorded)"
  exit 1
fi

echo "Test 3: task completion clears the state file"
echo '{"tool_name":"mcp__ohno__update_task_status","tool_input":{"task_id":"task-777","status":"done","notes":"done"},"tool_response":{"content":[{"type":"text","text":"{\"success\":true}"}]},"hook_event_name":"PostToolUse"}' | \
  python3 "$BRIDGE" > /dev/null

if [ ! -f "$STATE_FILE" ]; then
  echo "  PASS: state file cleared on completion"
else
  echo "  FAIL: state file should be removed after task completion"
  cat "$STATE_FILE"
  exit 1
fi

echo "Test 4: coordinator-pre-written force_inplace flag reaches setup-worktree"
mkdir -p "$TEST_DIR/.pokayokay"
printf '{"force_worktree": false, "force_inplace": true}\n' > "$STATE_FILE"

OUTPUT=$(echo '{"tool_name":"mcp__ohno__update_task_status","tool_input":{"task_id":"task-888","status":"in_progress"},"tool_response":{"content":[{"type":"text","text":"{\"success\":true}"}]},"hook_event_name":"PostToolUse"}' | \
  python3 "$BRIDGE")

if [[ "$OUTPUT" == *"Working In-Place"* && "$OUTPUT" == *"--in-place flag"* ]]; then
  echo "  PASS: force_inplace honored (MODE=in-place, --in-place reason)"
else
  echo "  FAIL: expected in-place mode from pre-written force flag"
  echo "  Output: $OUTPUT"
  exit 1
fi

STATE_JSON=$(cat "$STATE_FILE")
if [[ "$STATE_JSON" == *'"task_id": "task-888"'* && "$STATE_JSON" == *'"force_inplace": "true"'* ]]; then
  echo "  PASS: flags merged with the new task id in the state file"
else
  echo "  FAIL: expected merged state with task-888 + force_inplace"
  echo "  State: $STATE_JSON"
  exit 1
fi

echo ""
echo "All bridge task state tests passed!"
