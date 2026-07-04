#!/usr/bin/env bash
# Validate bridge.py parses the reviewer verdict contract:
# - terminal "VERDICT: PASS|FAIL|BLOCKED" line wins over substrings like
#   "Result: PASS" in evidence rows
# - BLOCKED is a non-verdict for kaizen (skip, never post-review-fail)
# - missing VERDICT line falls back to the anchored review heading
# - neither signal -> visible unparseable warning (fail closed), not "{}"

set -euo pipefail

TEST_DIR=$(mktemp -d)
trap 'rm -rf -- "$TEST_DIR"' EXIT

BRIDGE="$(cd "$(dirname "$0")/.." && pwd)/hooks/actions/bridge.py"

echo "Testing bridge review verdict parsing..."

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
echo '{"action":"LOGGED","message":"from-mock-hook"}'
EOF
chmod +x "$TEST_DIR/hooks/post-review-fail.sh"

export CURRENT_OHNO_TASK_ID="T-9"

TRACKING="$TEST_DIR/.pokayokay/pokayokay-review-failures.json"

echo "Test 1: terminal VERDICT: PASS is classified PASS (no failure hook)"
cat > "$TEST_DIR/payload-pass.json" << 'EOF'
{"tool_name":"Task","tool_input":{"subagent_type":"pokayokay:yokay-quality-reviewer","description":"Quality review for T-9"},"tool_response":{"content":[{"type":"text","text":"## Quality Review: PASS\n\n**Task**: T-9\n\nCode is well-structured and tested.\n\nVERDICT: PASS"}]},"hook_event_name":"PostToolUse"}
EOF
OUTPUT=$(python3 "$BRIDGE" < "$TEST_DIR/payload-pass.json" 2>/dev/null)

if [[ "$OUTPUT" == "{}" ]]; then
  echo "  PASS: passing review skipped silently"
else
  echo "  FAIL: expected {} for VERDICT: PASS"
  echo "  Output: $OUTPUT"
  exit 1
fi

echo "Test 2: VERDICT: BLOCKED skips kaizen FAIL routing entirely"
cat > "$TEST_DIR/payload-blocked.json" << 'EOF'
{"tool_name":"Task","tool_input":{"subagent_type":"pokayokay:yokay-quality-reviewer","description":"Quality review for T-9"},"tool_response":{"content":[{"type":"text","text":"## Quality Review: BLOCKED\n\n**Condition**: (b) no acceptance criteria in the dispatch prompt\n**Evidence**: The Acceptance Criteria section contains the literal placeholder\n**Needed from coordinator**: Fill ACCEPTANCE_CRITERIA and re-dispatch\n\nVERDICT: BLOCKED"}]},"hook_event_name":"PostToolUse"}
EOF
OUTPUT=$(python3 "$BRIDGE" < "$TEST_DIR/payload-blocked.json" 2>/dev/null)

if [[ "$OUTPUT" == "{}" ]] && [[ "$OUTPUT" != *"post-review-fail"* ]]; then
  echo "  PASS: BLOCKED treated as non-verdict skip"
else
  echo "  FAIL: BLOCKED must not route to post-review-fail"
  echo "  Output: $OUTPUT"
  exit 1
fi

if [[ ! -f "$TRACKING" ]]; then
  echo "  PASS: BLOCKED did not write failure tracking"
else
  echo "  FAIL: BLOCKED must not be tracked as a review failure"
  cat "$TRACKING"
  exit 1
fi

echo "Test 3: FAIL report containing 'Result: PASS' evidence is classified FAIL"
cat > "$TEST_DIR/payload-adversarial-fail.json" << 'EOF'
{"tool_name":"Task","tool_input":{"subagent_type":"pokayokay:yokay-quality-reviewer","description":"Quality review for T-9"},"tool_response":{"content":[{"type":"text","text":"## Quality Review: FAIL\n\n**Task**: T-9\n\n### Verification Evidence\n\n- Command(s): npm test\n- Result: PASS, exit 0 (lint), but coverage checks were skipped\n\n### Issues\n\n| Issue | Severity | Detail |\n|-------|----------|--------|\n| Missing tests for MUST criterion | Major | src/api.ts:10 |\n\n### Required Fixes\n1. Add missing validation tests\n\nVERDICT: FAIL"}]},"hook_event_name":"PostToolUse"}
EOF
OUTPUT=$(python3 "$BRIDGE" < "$TEST_DIR/payload-adversarial-fail.json" 2>/dev/null)

if [[ "$OUTPUT" == *"post-review-fail"* ]]; then
  echo "  PASS: terminal VERDICT: FAIL overrode 'Result: PASS' substring"
else
  echo "  FAIL: expected post-review-fail despite 'Result: PASS' evidence line"
  echo "  Output: $OUTPUT"
  exit 1
fi

if [[ -f "$TRACKING" ]]; then
  echo "  PASS: failure tracked for graduation"
else
  echo "  FAIL: expected failure tracking file at $TRACKING"
  exit 1
fi

echo "Test 4: no VERDICT line falls back to the anchored review heading"
cat > "$TEST_DIR/payload-heading-fallback.json" << 'EOF'
{"tool_name":"Task","tool_input":{"subagent_type":"pokayokay:yokay-quality-reviewer","description":"Quality review for T-9"},"tool_response":{"content":[{"type":"text","text":"## Quality Review: FAIL\n\n- Result: PASS, exit 0 for lint\n- No tests were added for the new endpoint"}]},"hook_event_name":"PostToolUse"}
EOF
OUTPUT=$(python3 "$BRIDGE" < "$TEST_DIR/payload-heading-fallback.json" 2>/dev/null)

if [[ "$OUTPUT" == *"post-review-fail"* ]]; then
  echo "  PASS: heading fallback classified FAIL (FAIL precedence over substrings)"
else
  echo "  FAIL: expected post-review-fail via heading fallback"
  echo "  Output: $OUTPUT"
  exit 1
fi

echo "Test 5: unparseable reviewer output fails closed with a visible warning"
cat > "$TEST_DIR/payload-gibberish.json" << 'EOF'
{"tool_name":"Task","tool_input":{"subagent_type":"pokayokay:yokay-quality-reviewer","description":"Quality review for T-9"},"tool_response":{"content":[{"type":"text","text":"The reviewer wandered off and wrote a poem about code quality instead."}]},"hook_event_name":"PostToolUse"}
EOF
OUTPUT=$(python3 "$BRIDGE" < "$TEST_DIR/payload-gibberish.json" 2>/dev/null)

if [[ "$OUTPUT" != "{}" ]] && [[ "$OUTPUT" == *"could not be parsed"* ]]; then
  echo "  PASS: unparseable warning surfaced in additionalContext"
else
  echo "  FAIL: expected visible unparseable warning, not silent skip"
  echo "  Output: $OUTPUT"
  exit 1
fi

if [[ "$OUTPUT" != *"post-review-fail"* ]]; then
  echo "  PASS: unparseable output did not invoke the failure hook directly"
else
  echo "  FAIL: unparseable path must instruct re-dispatch, not run post-review-fail"
  echo "  Output: $OUTPUT"
  exit 1
fi

echo "Test 6: description-only match keeps the silent skip on unparseable output"
cat > "$TEST_DIR/payload-description-only.json" << 'EOF'
{"tool_name":"Task","tool_input":{"subagent_type":"general-purpose","description":"Quality review notes cleanup"},"tool_response":{"content":[{"type":"text","text":"Tidied up the notes file."}]},"hook_event_name":"PostToolUse"}
EOF
OUTPUT=$(python3 "$BRIDGE" < "$TEST_DIR/payload-description-only.json" 2>/dev/null)

if [[ "$OUTPUT" == "{}" ]]; then
  echo "  PASS: non-reviewer Task with review-ish description skipped silently"
else
  echo "  FAIL: expected {} for description-only match"
  echo "  Output: $OUTPUT"
  exit 1
fi

echo ""
echo "All review verdict parsing tests passed!"
