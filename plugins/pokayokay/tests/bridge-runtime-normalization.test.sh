#!/usr/bin/env bash
# Validate bridge.py accepts Claude-style and Codex-style hook payload aliases.

set -euo pipefail

TEST_DIR=$(mktemp -d)
trap 'rm -rf -- "$TEST_DIR"' EXIT

BRIDGE="$(cd "$(dirname "$0")/.." && pwd)/hooks/actions/bridge.py"

echo "Testing bridge runtime normalization..."

cd "$TEST_DIR"

# Make sure project-dir env vars from an enclosing session don't leak in:
# the bridge must resolve the project dir to this test's cwd/workspace so
# WIP debounce state lands in $TEST_DIR, not the real repo.
unset CLAUDE_PROJECT_DIR YOKAY_PROJECT_DIR CODEX_WORKSPACE_DIR 2>/dev/null || true

# Persisted WIP debounce state — reset between tests that each expect a call
WIP_STATE="$TEST_DIR/.pokayokay/wip-state.json"

MOCK_BIN="$TEST_DIR/bin"
mkdir -p "$MOCK_BIN" "$TEST_DIR/wip_calls"

cat > "$MOCK_BIN/npx" << EOF
#!/usr/bin/env bash
if [ "\$2" = "update-wip" ]; then
  echo "\$4" > "$TEST_DIR/wip_calls/last_call.json"
  exit 0
fi
exit 1
EOF
chmod +x "$MOCK_BIN/npx"

export PATH="$MOCK_BIN:$PATH"
export CURRENT_OHNO_TASK_ID="task-runtime"

assert_last_file() {
  local expected="$1"
  if [[ ! -f "$TEST_DIR/wip_calls/last_call.json" ]]; then
    echo "  FAIL: no WIP update captured"
    exit 1
  fi

  local files
  files=$(cat "$TEST_DIR/wip_calls/last_call.json" | jq -r '.files_modified[]' 2>/dev/null || echo "")
  if [[ "$files" == *"$expected"* ]]; then
    echo "  PASS: captured $expected"
  else
    echo "  FAIL: expected $expected in WIP update"
    echo "  Files: $files"
    exit 1
  fi
}

assert_last_commit_hash() {
  local expected="$1"
  if [[ ! -f "$TEST_DIR/wip_calls/last_call.json" ]]; then
    echo "  FAIL: no WIP update captured"
    exit 1
  fi
  local hash
  hash=$(jq -r '.last_commit // empty' "$TEST_DIR/wip_calls/last_call.json" 2>/dev/null || echo "")
  if [[ "$hash" == "$expected" ]]; then
    echo "  PASS: captured commit $expected"
  else
    echo "  FAIL: expected commit $expected, got '$hash'"
    exit 1
  fi
}

echo "Test 1: Existing Claude-style payload still works"
echo '{"tool_name":"Edit","tool_input":{"file_path":"src/claude.ts"},"tool_response":{},"hook_event_name":"PostToolUse"}' |
  python3 "$BRIDGE" > /dev/null
assert_last_file "src/claude.ts"

echo "Test 2: Codex-style aliases route to the same handler"
rm -f "$TEST_DIR/wip_calls/last_call.json" "$WIP_STATE"
echo '{"runtime":"codex","tool":"edit","input":{"file_path":"src/codex.ts"},"response":{},"event":"PostToolUse"}' |
  python3 "$BRIDGE" > /dev/null
assert_last_file "src/codex.ts"

echo "Test 3: CODEX_WORKSPACE_DIR is accepted as project dir"
rm -f "$TEST_DIR/wip_calls/last_call.json" "$WIP_STATE"
export CODEX_WORKSPACE_DIR="$TEST_DIR"
echo '{"runtime":"codex","tool_name":"write","tool_input":{"file_path":"src/workspace.ts"},"tool_response":{},"hook_event":"PostToolUse"}' |
  python3 "$BRIDGE" > /dev/null
assert_last_file "src/workspace.ts"

echo "Test 4: Codex Bash payload (cmd field) produces a real commit-hash WIP update"
# Codex passes shell commands as tool_input.cmd; the bridge must remap to
# tool_input.command so handle_bash_execution / extract_commit_hash actually
# parse the git output. Without the alias the WIP update would skip silently.
rm -f "$TEST_DIR/wip_calls/last_call.json"
echo '{"runtime":"codex","tool":"exec_command","input":{"cmd":"git commit -m test"},"response":{"output":"[main abc1234] commit message"},"event":"PostToolUse"}' |
  python3 "$BRIDGE" > /dev/null
assert_last_commit_hash "abc1234"

echo "Test 5: Codex Bash payload still routes when tool_name is the canonical Bash"
rm -f "$TEST_DIR/wip_calls/last_call.json"
echo '{"runtime":"codex","tool_name":"Bash","tool_input":{"cmd":"git commit -m hello"},"tool_response":{"output":"[feat def5678] another"},"hook_event_name":"PostToolUse"}' |
  python3 "$BRIDGE" > /dev/null
assert_last_commit_hash "def5678"

echo "Test 6: PermissionRequest safely approves read-only commands"
ALLOW_OUTPUT=$(echo '{"runtime":"codex","hook_event_name":"PermissionRequest","tool_name":"Bash","tool_input":{"command":"git status --short"}}' |
  python3 "$BRIDGE")
echo "$ALLOW_OUTPUT" | node -e '
let data = "";
process.stdin.on("data", (chunk) => data += chunk);
process.stdin.on("end", () => {
  const parsed = JSON.parse(data);
  const decision = parsed.hookSpecificOutput && parsed.hookSpecificOutput.decision;
  if (!decision || decision.behavior !== "allow") throw new Error("expected allow decision");
});
'

echo "Test 7: PermissionRequest denies dangerous commands"
DENY_OUTPUT=$(echo '{"runtime":"codex","hook_event_name":"PermissionRequest","tool_name":"Bash","tool_input":{"command":"rm -rf /tmp/pokayokay-danger"}}' |
  python3 "$BRIDGE")
echo "$DENY_OUTPUT" | node -e '
let data = "";
process.stdin.on("data", (chunk) => data += chunk);
process.stdin.on("end", () => {
  const parsed = JSON.parse(data);
  const decision = parsed.hookSpecificOutput && parsed.hookSpecificOutput.decision;
  if (!decision || decision.behavior !== "deny") throw new Error("expected deny decision");
});
'

echo "Test 8: PermissionRequest leaves shell-control commands to runtime"
CONTROL_OUTPUT=$(echo '{"runtime":"codex","hook_event_name":"PermissionRequest","tool_name":"Bash","tool_input":{"command":"git status --short; touch /tmp/pokayokay-danger"}}' |
  python3 "$BRIDGE")
echo "$CONTROL_OUTPUT" | node -e '
let data = "";
process.stdin.on("data", (chunk) => data += chunk);
process.stdin.on("end", () => {
  const parsed = JSON.parse(data);
  if (Object.keys(parsed).length !== 0) throw new Error("expected runtime fallback for shell-control command");
});
'

echo "Test 9: PermissionRequest leaves absolute-path reads to runtime"
ABS_OUTPUT=$(echo '{"runtime":"codex","hook_event_name":"PermissionRequest","tool_name":"Bash","tool_input":{"command":"sed -n 1,20p /etc/passwd"}}' |
  python3 "$BRIDGE")
echo "$ABS_OUTPUT" | node -e '
let data = "";
process.stdin.on("data", (chunk) => data += chunk);
process.stdin.on("end", () => {
  const parsed = JSON.parse(data);
  if (Object.keys(parsed).length !== 0) throw new Error("expected runtime fallback for absolute-path read");
});
'

echo "Test 10: PermissionRequest leaves Windows absolute-path reads to runtime"
WIN_OUTPUT=$(echo '{"runtime":"codex","hook_event_name":"PermissionRequest","tool_name":"Bash","tool_input":{"command":"sed -n 1,20p C:\\Users\\steve\\.ssh\\config"}}' |
  python3 "$BRIDGE")
echo "$WIN_OUTPUT" | node -e '
let data = "";
process.stdin.on("data", (chunk) => data += chunk);
process.stdin.on("end", () => {
  const parsed = JSON.parse(data);
  if (Object.keys(parsed).length !== 0) throw new Error("expected runtime fallback for Windows absolute-path read");
});
'

echo "Test 11: PermissionRequest leaves backslash parent traversal to runtime"
TRAVERSAL_OUTPUT=$(echo '{"runtime":"codex","hook_event_name":"PermissionRequest","tool_name":"Bash","tool_input":{"command":"ls ..\\..\\outside"}}' |
  python3 "$BRIDGE")
echo "$TRAVERSAL_OUTPUT" | node -e '
let data = "";
process.stdin.on("data", (chunk) => data += chunk);
process.stdin.on("end", () => {
  const parsed = JSON.parse(data);
  if (Object.keys(parsed).length !== 0) throw new Error("expected runtime fallback for backslash traversal");
});
'

echo "Test 12: Plugin-scoped ohno update_task_status routes to post-task hooks"
OHNO_DONE_OUTPUT=$(echo '{"tool_name":"mcp__plugin_pokayokay_ohno__update_task_status","tool_input":{"task_id":"T-1","status":"done"},"tool_response":{},"hook_event_name":"PostToolUse"}' |
  python3 "$BRIDGE" 2>/dev/null)
if [[ "$OHNO_DONE_OUTPUT" == *"Hooks executed: post-task"* ]]; then
  echo "  PASS: plugin-scoped update_task_status ran post-task hooks"
else
  echo "  FAIL: expected post-task hooks for plugin-scoped tool name"
  echo "  Output: $OHNO_DONE_OUTPUT"
  exit 1
fi

echo "Test 13: Plugin-scoped ohno set_blocker routes to on-blocker hook"
OHNO_BLOCKER_OUTPUT=$(echo '{"tool_name":"mcp__plugin_pokayokay_ohno__set_blocker","tool_input":{"task_id":"T-1","reason":"stuck on dependency"},"tool_response":{},"hook_event_name":"PostToolUse"}' |
  python3 "$BRIDGE" 2>/dev/null)
if [[ "$OHNO_BLOCKER_OUTPUT" == *"Hooks executed: on-blocker"* ]]; then
  echo "  PASS: plugin-scoped set_blocker ran on-blocker hook"
else
  echo "  FAIL: expected on-blocker hook for plugin-scoped tool name"
  echo "  Output: $OHNO_BLOCKER_OUTPUT"
  exit 1
fi

echo ""
echo "All bridge runtime normalization tests passed!"
