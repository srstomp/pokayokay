#!/usr/bin/env bash
# Validate _detect_stale_session end-to-end: SessionStart with stale chain
# state plus in_progress tasks (mocked ohno-cli) must trigger recovery, and
# the bridge must call the real ohno-cli command surface
# (`--json tasks --status in_progress`, object-shaped output).

set -euo pipefail

TEST_DIR=$(mktemp -d)
trap 'rm -rf -- "$TEST_DIR"' EXIT

BRIDGE="$(cd "$(dirname "$0")/.." && pwd)/hooks/actions/bridge.py"

echo "Testing bridge crash detection..."

cd "$TEST_DIR"

unset CLAUDE_PROJECT_DIR YOKAY_PROJECT_DIR CODEX_WORKSPACE_DIR YOKAY_WORK_MODE 2>/dev/null || true

# Mock npx: answers the tasks listing with the real ohno-cli 0.20.0 JSON shape
# ({"tasks": [...], "total_count": N} — an object, not a bare list).
MOCK_BIN="$TEST_DIR/bin"
mkdir -p "$MOCK_BIN"
cat > "$MOCK_BIN/npx" << EOF
#!/usr/bin/env bash
echo "\$@" >> "$TEST_DIR/npx_calls.log"
if [ "\$1" = "@stevestomp/ohno-cli" ] && [ "\$2" = "--json" ] && [ "\$3" = "tasks" ]; then
  echo '{"tasks":[{"id":"T-42","title":"stuck task","status":"in_progress"}],"total_count":1}'
  exit 0
fi
exit 0
EOF
chmod +x "$MOCK_BIN/npx"
export PATH="$MOCK_BIN:$PATH"

echo "Test 1: stale chain state + in_progress tasks trigger recovery"
mkdir -p "$TEST_DIR/.pokayokay"
cat > "$TEST_DIR/.pokayokay/pokayokay-chain-state.json" << 'EOF'
{"chain_id": "chain-1", "chain_index": 2, "scope_type": "epic", "scope_id": "e1", "tasks_completed": 3}
EOF

OUTPUT=$(echo '{"hook_event_name":"SessionStart","source":"startup"}' | python3 "$BRIDGE" 2>/dev/null)

if [[ "$OUTPUT" == *"recover"* ]]; then
  echo "  PASS: recover action attempted for crashed chain"
else
  echo "  FAIL: expected recover action in SessionStart results"
  echo "  Output: $OUTPUT"
  exit 1
fi

echo "Test 2: detection uses the real ohno-cli command surface"
if grep -q -- "--json tasks --status in_progress" "$TEST_DIR/npx_calls.log"; then
  echo "  PASS: bridge called ohno-cli --json tasks --status in_progress"
else
  echo "  FAIL: expected valid ohno-cli tasks invocation"
  cat "$TEST_DIR/npx_calls.log" 2>/dev/null || echo "  (no npx calls logged)"
  exit 1
fi

echo "Test 3: no chain state means no recovery attempt"
rm -f "$TEST_DIR/.pokayokay/pokayokay-chain-state.json" "$TEST_DIR/npx_calls.log"
OUTPUT=$(echo '{"hook_event_name":"SessionStart","source":"startup"}' | python3 "$BRIDGE" 2>/dev/null)

if [[ "$OUTPUT" != *"recover"* ]]; then
  echo "  PASS: no recovery without chain state"
else
  echo "  FAIL: recovery must not fire without stale chain state"
  echo "  Output: $OUTPUT"
  exit 1
fi

echo ""
echo "All bridge crash-detection tests passed!"
