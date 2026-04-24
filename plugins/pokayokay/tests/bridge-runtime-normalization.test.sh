#!/usr/bin/env bash
# Validate bridge.py accepts Claude-style and Codex-style hook payload aliases.

set -euo pipefail

TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

BRIDGE="$(cd "$(dirname "$0")/.." && pwd)/hooks/actions/bridge.py"

echo "Testing bridge runtime normalization..."

cd "$TEST_DIR"

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

echo "Test 1: Existing Claude-style payload still works"
echo '{"tool_name":"Edit","tool_input":{"file_path":"src/claude.ts"},"tool_response":{},"hook_event_name":"PostToolUse"}' |
  python3 "$BRIDGE" > /dev/null
assert_last_file "src/claude.ts"

echo "Test 2: Codex-style aliases route to the same handler"
rm -f "$TEST_DIR/wip_calls/last_call.json"
echo '{"runtime":"codex","tool":"edit","input":{"file_path":"src/codex.ts"},"response":{},"event":"PostToolUse"}' |
  python3 "$BRIDGE" > /dev/null
assert_last_file "src/codex.ts"

echo "Test 3: CODEX_WORKSPACE_DIR is accepted as project dir"
rm -f "$TEST_DIR/wip_calls/last_call.json"
export CODEX_WORKSPACE_DIR="$TEST_DIR"
echo '{"runtime":"codex","tool_name":"write","tool_input":{"file_path":"src/workspace.ts"},"tool_response":{},"hook_event":"PostToolUse"}' |
  python3 "$BRIDGE" > /dev/null
assert_last_file "src/workspace.ts"

echo ""
echo "All bridge runtime normalization tests passed!"
