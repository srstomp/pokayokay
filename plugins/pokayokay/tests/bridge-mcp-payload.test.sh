#!/usr/bin/env bash
# Validate bridge.py parses ohno MCP results delivered as JSON-in-content-blocks:
# boundary metadata (story/epic hooks), CLI task-metadata lookup, and
# metacharacter-tolerant env sanitization.

set -euo pipefail

TEST_DIR=$(mktemp -d)
trap 'rm -rf -- "$TEST_DIR"' EXIT

BRIDGE="$(cd "$(dirname "$0")/.." && pwd)/hooks/actions/bridge.py"

echo "Testing bridge MCP payload parsing..."

cd "$TEST_DIR"

# Keep enclosing-session project dirs from leaking in
unset CLAUDE_PROJECT_DIR YOKAY_PROJECT_DIR CODEX_WORKSPACE_DIR YOKAY_WORK_MODE 2>/dev/null || true

# Mock npx: answers ohno-cli `task get` with spike task metadata, logs all
# calls, and succeeds quietly for everything else (compact-handoffs, etc.)
MOCK_BIN="$TEST_DIR/bin"
mkdir -p "$MOCK_BIN"
cat > "$MOCK_BIN/npx" << EOF
#!/usr/bin/env bash
echo "\$@" >> "$TEST_DIR/npx_calls.log"
if [ "\$1" = "@stevestomp/ohno-cli" ] && [ "\$2" = "--json" ] && [ "\$3" = "task" ] && [ "\$4" = "get" ]; then
  echo '{"id":"'"\$5"'","title":"Investigate flux capacitor","task_type":"spike","story_id":"s1","status":"done"}'
  exit 0
fi
exit 0
EOF
chmod +x "$MOCK_BIN/npx"
export PATH="$MOCK_BIN:$PATH"

echo "Test 1: MCP content-block payload triggers post-story hooks"
# Realistic ohno MCP shape: result JSON serialized inside content[0].text.
# Notes intentionally contain shell metacharacters — they must be neutralized,
# not block the post-task hooks.
cat > "$TEST_DIR/payload1.json" << 'EOF'
{"tool_name":"mcp__ohno__update_task_status","tool_input":{"task_id":"T-1","status":"done","notes":"done (verified) -> uses $HOME & `backticks`"},"tool_response":{"content":[{"type":"text","text":"{\"success\":true,\"boundaries\":{\"story_completed\":true,\"story_id\":\"s1\"}}"}]},"hook_event_name":"PostToolUse"}
EOF
OUTPUT=$(python3 "$BRIDGE" < "$TEST_DIR/payload1.json" 2>/dev/null)

if [[ "$OUTPUT" == *"post-story"* ]]; then
  echo "  PASS: post-story hooks ran"
else
  echo "  FAIL: expected post-story hooks for story_completed boundary"
  echo "  Output: $OUTPUT"
  exit 1
fi

if [[ "$OUTPUT" == *"Story s1 completed"* ]]; then
  echo "  PASS: story boundary surfaced with story id"
else
  echo "  FAIL: expected 'Story s1 completed' in context"
  echo "  Output: $OUTPUT"
  exit 1
fi

echo "Test 2: metacharacter notes do not block post-task hooks"
if [[ "$OUTPUT" == *"post-task"* && "$OUTPUT" != *"blocked"* ]]; then
  echo "  PASS: post-task hooks ran despite metacharacters in notes"
else
  echo "  FAIL: post-task hooks should run with metacharacter notes"
  echo "  Output: $OUTPUT"
  exit 1
fi

echo "Test 3: task metadata comes from the ohno CLI lookup"
# update_task_status results carry no task object, so TASK_TITLE/TASK_TYPE
# must come from `ohno-cli --json task get`. The mocked CLI returns a spike,
# which makes the bridge write spike-results.md with the looked-up title.
if grep -q -- "--json task get T-1" "$TEST_DIR/npx_calls.log"; then
  echo "  PASS: bridge looked the task up via ohno CLI"
else
  echo "  FAIL: expected ohno-cli task get call"
  cat "$TEST_DIR/npx_calls.log" 2>/dev/null || echo "  (no npx calls logged)"
  exit 1
fi

if grep -q "Investigate flux capacitor" "$TEST_DIR/memory/spike-results.md" 2>/dev/null; then
  echo "  PASS: spike result captured with CLI-provided title"
else
  echo "  FAIL: expected spike-results.md with looked-up task title"
  ls -la "$TEST_DIR/memory" 2>/dev/null || echo "  (no memory dir)"
  exit 1
fi

echo "Test 4: bare content-block list payload triggers post-epic hooks"
cat > "$TEST_DIR/payload2.json" << 'EOF'
{"tool_name":"mcp__ohno__update_task_status","tool_input":{"task_id":"T-2","status":"done"},"tool_response":[{"type":"text","text":"{\"success\":true,\"boundaries\":{\"epic_completed\":true,\"epic_id\":\"e9\"}}"}],"hook_event_name":"PostToolUse"}
EOF
OUTPUT=$(python3 "$BRIDGE" < "$TEST_DIR/payload2.json" 2>/dev/null)

if [[ "$OUTPUT" == *"post-epic"* && "$OUTPUT" == *"Epic e9 completed"* ]]; then
  echo "  PASS: bare-list content blocks parsed, post-epic hooks ran"
else
  echo "  FAIL: expected post-epic hooks for bare-list payload"
  echo "  Output: $OUTPUT"
  exit 1
fi

echo "Test 5: unwrapped dict response still works (Codex fallback)"
cat > "$TEST_DIR/payload3.json" << 'EOF'
{"tool_name":"mcp__ohno__update_task_status","tool_input":{"task_id":"T-3","status":"done"},"tool_response":{"success":true,"boundaries":{"story_completed":true,"story_id":"s2"}},"hook_event_name":"PostToolUse"}
EOF
OUTPUT=$(python3 "$BRIDGE" < "$TEST_DIR/payload3.json" 2>/dev/null)

if [[ "$OUTPUT" == *"Story s2 completed"* ]]; then
  echo "  PASS: top-level boundaries dict still parsed"
else
  echo "  FAIL: expected story boundary from unwrapped dict response"
  echo "  Output: $OUTPUT"
  exit 1
fi

echo ""
echo "All bridge MCP payload tests passed!"
