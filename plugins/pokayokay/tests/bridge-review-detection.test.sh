#!/usr/bin/env bash
# Validate bridge.py reads Task (subagent) results from content blocks:
# review FAIL detection fires post-review-fail, PASS skips, and token
# usage is recorded from Claude Code's structured response fields.

set -euo pipefail

TEST_DIR=$(mktemp -d)
trap 'rm -rf -- "$TEST_DIR"' EXIT

BRIDGE="$(cd "$(dirname "$0")/.." && pwd)/hooks/actions/bridge.py"

echo "Testing bridge review-result detection..."

cd "$TEST_DIR"

unset CLAUDE_PROJECT_DIR YOKAY_PROJECT_DIR CODEX_WORKSPACE_DIR 2>/dev/null || true

# Mock npx so nothing shells out to the network
MOCK_BIN="$TEST_DIR/bin"
mkdir -p "$MOCK_BIN"
printf '#!/usr/bin/env bash\nexit 0\n' > "$MOCK_BIN/npx"
chmod +x "$MOCK_BIN/npx"
export PATH="$MOCK_BIN:$PATH"

# Project-root post-review-fail hook (resolved from the project dir by design)
mkdir -p "$TEST_DIR/hooks"
cat > "$TEST_DIR/hooks/post-review-fail.sh" << 'EOF'
#!/usr/bin/env bash
echo '{"action":"SUGGEST","fix_task":{"title":"Fix validation","type":"bug","estimate":2},"message":"from-mock-hook"}'
EOF
chmod +x "$TEST_DIR/hooks/post-review-fail.sh"

export CURRENT_OHNO_TASK_ID="T-9"

echo "Test 1: content-block Spec Review FAIL triggers post-review-fail"
# Claude Code delivers the subagent output in content blocks — there is no
# top-level "result" key on this runtime.
cat > "$TEST_DIR/payload-fail.json" << 'EOF'
{"tool_name":"Task","tool_input":{"subagent_type":"pokayokay:yokay-spec-reviewer","description":"Spec review for T-9"},"tool_response":{"content":[{"type":"text","text":"## Spec Review: FAIL\n\n- AC2 not met: input validation missing on the request body"}],"totalTokens":4321,"totalToolUseCount":7,"totalDurationMs":9000},"hook_event_name":"PostToolUse"}
EOF
OUTPUT=$(python3 "$BRIDGE" < "$TEST_DIR/payload-fail.json" 2>/dev/null)

if [[ "$OUTPUT" == *"post-review-fail"* ]]; then
  echo "  PASS: post-review-fail hook invoked"
else
  echo "  FAIL: expected post-review-fail for content-block FAIL output"
  echo "  Output: $OUTPUT"
  exit 1
fi

if [[ "$OUTPUT" == *"SUGGEST"* ]]; then
  echo "  PASS: kaizen action surfaced from hook output"
else
  echo "  FAIL: expected SUGGEST kaizen action in context"
  echo "  Output: $OUTPUT"
  exit 1
fi

echo "Test 2: failure categorized and tracked for graduation"
TRACKING="$TEST_DIR/.pokayokay/pokayokay-review-failures.json"
if grep -q "missing_validation" "$TRACKING" 2>/dev/null; then
  echo "  PASS: review failure categorized in tracking file"
else
  echo "  FAIL: expected missing_validation in $TRACKING"
  cat "$TRACKING" 2>/dev/null || echo "  (no tracking file)"
  exit 1
fi

echo "Test 3: token usage recorded from structured response fields"
USAGE="$TEST_DIR/.pokayokay/pokayokay-token-usage.json"
if grep -q "4321" "$USAGE" 2>/dev/null; then
  echo "  PASS: totalTokens recorded from structured field"
else
  echo "  FAIL: expected 4321 tokens in $USAGE"
  cat "$USAGE" 2>/dev/null || echo "  (no usage file)"
  exit 1
fi

echo "Test 4: Spec Review PASS is skipped"
cat > "$TEST_DIR/payload-pass.json" << 'EOF'
{"tool_name":"Task","tool_input":{"subagent_type":"pokayokay:yokay-spec-reviewer","description":"Spec review for T-9"},"tool_response":{"content":[{"type":"text","text":"## Spec Review: PASS\n\nAll criteria verified."}]},"hook_event_name":"PostToolUse"}
EOF
OUTPUT=$(python3 "$BRIDGE" < "$TEST_DIR/payload-pass.json" 2>/dev/null)

if [[ "$OUTPUT" != *"post-review-fail"* ]]; then
  echo "  PASS: passing review did not trigger the failure hook"
else
  echo "  FAIL: PASS review must not trigger post-review-fail"
  echo "  Output: $OUTPUT"
  exit 1
fi

echo "Test 5: Codex-style result string still detected"
cat > "$TEST_DIR/payload-codex.json" << 'EOF'
{"tool_name":"Task","tool_input":{"subagent_type":"pokayokay:yokay-quality-reviewer","description":"Quality review for T-9"},"result":{"output":"## Quality Review: FAIL\n\n- No tests were added for the new endpoint"},"hook_event_name":"PostToolUse"}
EOF
OUTPUT=$(python3 "$BRIDGE" < "$TEST_DIR/payload-codex.json" 2>/dev/null)

if [[ "$OUTPUT" == *"post-review-fail"* ]]; then
  echo "  PASS: Codex result alias routed to failure detection"
else
  echo "  FAIL: expected post-review-fail for Codex-shaped payload"
  echo "  Output: $OUTPUT"
  exit 1
fi

echo ""
echo "All bridge review-detection tests passed!"
