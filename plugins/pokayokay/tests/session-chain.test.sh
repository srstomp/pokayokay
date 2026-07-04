#!/usr/bin/env bash
# Validate session-chain.sh chaining decisions against the real ohno-cli
# 0.20.0 command surface (mocked): READY_COUNT comes from
# `tasks --status todo --json` total_count (object shape, not a bare list),
# non-numeric CLI output degrades to 0, termination decisions
# (continue / complete / audit_pending / limit_reached) are correct, the
# report enrichment reads handoff_notes from task rows, and the emitted
# continue_command uses `claude -p` (no nonexistent --headless flag).

set -euo pipefail

TEST_DIR=$(mktemp -d)
trap 'rm -rf -- "$TEST_DIR"' EXIT

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/hooks/actions/session-chain.sh"
[ -f "$SCRIPT" ] || { echo "script not found: $SCRIPT"; exit 1; }

echo "Testing session-chain.sh..."

cd "$TEST_DIR"
export CLAUDE_PROJECT_DIR="$TEST_DIR"

# Mock npx: answers `tasks --status <s> --json` from per-status response files
# using the real ohno-cli JSON shape {"tasks":[...],"total_count":N}.
MOCK_BIN="$TEST_DIR/bin"
mkdir -p "$MOCK_BIN"
cat > "$MOCK_BIN/npx" << EOF
#!/usr/bin/env bash
echo "\$@" >> "$TEST_DIR/npx_calls.log"
if [ "\$1" = "@stevestomp/ohno-cli" ] && [ "\$2" = "tasks" ] && [ "\$3" = "--status" ]; then
  cat "$TEST_DIR/mock-\$4.out" 2>/dev/null || echo '{"tasks":[],"total_count":0}'
  exit 0
fi
exit 1
EOF
chmod +x "$MOCK_BIN/npx"
export PATH="$MOCK_BIN:$PATH"

echo '{"tasks":[],"total_count":0}' > "$TEST_DIR/mock-done.out"
echo '{"tasks":[],"total_count":0}' > "$TEST_DIR/mock-blocked.out"

json_field() {
  python3 -c "import json,sys; print(json.load(sys.stdin).get('$1', ''))"
}

echo "Test 1: not in a chain -> skip"
OUTPUT=$(bash "$SCRIPT" 2>/dev/null)
if [ "$(echo "$OUTPUT" | json_field action)" = "skip" ]; then
  echo "  PASS: skips when CHAIN_ID is unset"
else
  echo "  FAIL: expected action=skip"
  echo "$OUTPUT"
  exit 1
fi

echo "Test 2: work remaining -> continue, counted via total_count"
echo '{"tasks":[{"id":"t1"},{"id":"t2"}],"total_count":5}' > "$TEST_DIR/mock-todo.out"
OUTPUT=$(CHAIN_ID="chain-1" CHAIN_INDEX=0 MAX_CHAINS=10 SCOPE_TYPE="epic" SCOPE_ID="epic-99" \
  bash "$SCRIPT" 2>/dev/null)
ACTION=$(echo "$OUTPUT" | json_field action)
REMAINING=$(echo "$OUTPUT" | json_field tasks_remaining)
CONTINUE_CMD=$(echo "$OUTPUT" | json_field continue_command)
if [ "$ACTION" = "continue" ] && [ "$REMAINING" = "5" ]; then
  echo "  PASS: action=continue with tasks_remaining=5 (total_count, not row/key count)"
else
  echo "  FAIL: expected action=continue with tasks_remaining=5, got action=$ACTION remaining=$REMAINING"
  echo "$OUTPUT"
  exit 1
fi
if [[ "$CONTINUE_CMD" == 'claude -p "/work --continue --epic epic-99"' ]]; then
  echo "  PASS: continue_command uses claude -p with scope flag"
else
  echo "  FAIL: expected claude -p continue_command, got: $CONTINUE_CMD"
  exit 1
fi
if grep -q "^@stevestomp/ohno-cli tasks --status todo --json" "$TEST_DIR/npx_calls.log"; then
  echo "  PASS: ready count read via tasks --status todo --json"
else
  echo "  FAIL: expected 'tasks --status todo --json' invocation"
  cat "$TEST_DIR/npx_calls.log" 2>/dev/null || echo "  (no npx calls logged)"
  exit 1
fi

echo "Test 3: no work + audited -> complete, report enriched from handoff_notes"
echo '{"tasks":[],"total_count":0}' > "$TEST_DIR/mock-todo.out"
echo '{"tasks":[{"id":"t1","title":"First task","handoff_notes":"Implemented the widget"},{"id":"t2","title":"Second task"}],"total_count":2}' > "$TEST_DIR/mock-done.out"
echo '{"tasks":[{"id":"t3","title":"Third task","blocker_reason":"missing creds"}],"total_count":1}' > "$TEST_DIR/mock-blocked.out"
OUTPUT=$(CHAIN_ID="chain-2" CHAIN_INDEX=3 MAX_CHAINS=10 SCOPE_TYPE="all" \
  CHAIN_AUDITED="true" REPORT_MODE="on_complete" TASKS_COMPLETED=7 \
  bash "$SCRIPT" 2>/dev/null)
ACTION=$(echo "$OUTPUT" | json_field action)
REPORT_PATH=$(echo "$OUTPUT" | json_field report_path)
if [ "$ACTION" = "complete" ]; then
  echo "  PASS: action=complete when no work remains and chain is audited"
else
  echo "  FAIL: expected action=complete, got $ACTION"
  echo "$OUTPUT"
  exit 1
fi
if [ -n "$REPORT_PATH" ] && [ -f "$REPORT_PATH" ] \
  && grep -q "Implemented the widget" "$REPORT_PATH" \
  && grep -q "No handoff" "$REPORT_PATH" \
  && grep -q "Blocked: missing creds" "$REPORT_PATH"; then
  echo "  PASS: report enriched with handoff_notes and blocked tasks"
else
  echo "  FAIL: expected report with handoff summaries at $REPORT_PATH"
  cat "$REPORT_PATH" 2>/dev/null || echo "  (no report)"
  exit 1
fi

echo "Test 4: no work + not audited -> audit_pending"
OUTPUT=$(CHAIN_ID="chain-3" CHAIN_INDEX=1 MAX_CHAINS=10 SCOPE_TYPE="all" \
  bash "$SCRIPT" 2>/dev/null)
if [ "$(echo "$OUTPUT" | json_field action)" = "audit_pending" ]; then
  echo "  PASS: action=audit_pending when unaudited"
else
  echo "  FAIL: expected action=audit_pending"
  echo "$OUTPUT"
  exit 1
fi

echo "Test 5: chain limit reached -> limit_reached"
echo '{"tasks":[{"id":"t9"}],"total_count":3}' > "$TEST_DIR/mock-todo.out"
OUTPUT=$(CHAIN_ID="chain-4" CHAIN_INDEX=9 MAX_CHAINS=10 SCOPE_TYPE="all" \
  REPORT_MODE="never" bash "$SCRIPT" 2>/dev/null)
if [ "$(echo "$OUTPUT" | json_field action)" = "limit_reached" ]; then
  echo "  PASS: action=limit_reached at MAX_CHAINS"
else
  echo "  FAIL: expected action=limit_reached"
  echo "$OUTPUT"
  exit 1
fi

echo "Test 6: garbage CLI output degrades to 0 and still emits valid JSON"
echo 'not json at all' > "$TEST_DIR/mock-todo.out"
OUTPUT=$(CHAIN_ID="chain-5" CHAIN_INDEX=0 MAX_CHAINS=10 SCOPE_TYPE="all" \
  bash "$SCRIPT" 2>/dev/null)
ACTION=$(echo "$OUTPUT" | json_field action)
REMAINING=$(echo "$OUTPUT" | json_field tasks_remaining)
if [ "$ACTION" = "audit_pending" ] && [ "$REMAINING" = "0" ]; then
  echo "  PASS: non-numeric READY_COUNT degrades to 0 with parseable JSON output"
else
  echo "  FAIL: expected action=audit_pending with tasks_remaining=0, got action=$ACTION remaining=$REMAINING"
  echo "$OUTPUT"
  exit 1
fi

echo ""
echo "All session-chain tests passed!"
