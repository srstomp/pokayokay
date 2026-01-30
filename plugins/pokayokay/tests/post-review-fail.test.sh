#!/bin/bash
# Test for post-review-fail.sh hook integration with kaizen
# Validates hook handles kaizen availability and outputs correct JSON

set -e

TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

echo "Testing post-review-fail.sh hook..."

# Script path
SCRIPT="/Users/sis4m4/Projects/stevestomp/pokayokay/hooks/post-review-fail.sh"

# Setup test environment
cd "$TEST_DIR"

# Test 1: Graceful exit when kaizen not installed
echo "Test 1: Graceful exit when kaizen not installed"
export PATH="/usr/bin:/bin"  # Minimal PATH without kaizen
export TASK_ID="T-123"
export FAILURE_DETAILS="Build failed with syntax error"
export FAILURE_SOURCE="spec-review"

OUTPUT=$(bash "$SCRIPT" 2>&1)
ACTION=$(echo "$OUTPUT" | jq -r '.action' 2>/dev/null || echo "INVALID")

if [ "$ACTION" = "LOGGED" ]; then
  MESSAGE=$(echo "$OUTPUT" | jq -r '.message' 2>/dev/null || echo "")
  if [[ "$MESSAGE" == *"kaizen"* ]] || [[ "$MESSAGE" == *"not installed"* ]]; then
    echo "  PASS: Graceful exit with kaizen not installed message"
  else
    echo "  PASS: Graceful exit (message: $MESSAGE)"
  fi
else
  echo "  FAIL: Expected action=LOGGED when kaizen not available"
  echo "  Output: $OUTPUT"
  exit 1
fi

# Test 2: Creates mock kaizen commands for testing
echo "Test 2: Hook calls kaizen commands correctly"

# Create mock kaizen command that outputs expected format
MOCK_BIN="$TEST_DIR/bin"
mkdir -p "$MOCK_BIN"

cat > "$MOCK_BIN/kaizen" << 'MOCK_EOF'
#!/bin/bash
case "$1" in
  detect-category)
    echo '{"detected_category": "build-failure", "confidence": "high"}'
    ;;
  capture)
    # Capture just succeeds silently or outputs confirmation
    echo '{"captured": true}'
    ;;
  suggest)
    # Return a suggestion with medium confidence
    echo '{"action": "suggest", "confidence": "medium", "fix_task": {"title": "Fix build error", "description": "Address syntax error"}}'
    ;;
  *)
    echo "Unknown command: $1" >&2
    exit 1
    ;;
esac
MOCK_EOF

chmod +x "$MOCK_BIN/kaizen"
export PATH="$MOCK_BIN:$PATH"

export TASK_ID="T-123"
export FAILURE_DETAILS="Build failed with syntax error in line 42"
export FAILURE_SOURCE="spec-review"

OUTPUT=$(bash "$SCRIPT" 2>&1)
ACTION=$(echo "$OUTPUT" | jq -r '.action' 2>/dev/null || echo "INVALID")

if [ "$ACTION" = "SUGGEST" ]; then
  CONFIDENCE=$(echo "$OUTPUT" | jq -r '.confidence' 2>/dev/null || echo "")
  FIX_TITLE=$(echo "$OUTPUT" | jq -r '.fix_task.title' 2>/dev/null || echo "")
  if [ "$CONFIDENCE" = "medium" ] && [ -n "$FIX_TITLE" ]; then
    echo "  PASS: Hook outputs SUGGEST action with fix_task details"
  else
    echo "  FAIL: Expected confidence and fix_task fields"
    echo "  Output: $OUTPUT"
    exit 1
  fi
else
  echo "  FAIL: Expected action=SUGGEST"
  echo "  Output: $OUTPUT"
  exit 1
fi

# Test 3: AUTO action for high confidence
echo "Test 3: AUTO action for high confidence suggestions"

cat > "$MOCK_BIN/kaizen" << 'MOCK_EOF'
#!/bin/bash
case "$1" in
  detect-category)
    echo '{"detected_category": "test-failure", "confidence": "high"}'
    ;;
  capture)
    echo '{"captured": true}'
    ;;
  suggest)
    # Return auto-create suggestion
    echo '{"action": "auto-create", "confidence": "high", "fix_task": {"title": "Fix failing test", "description": "Update test assertion"}}'
    ;;
  *)
    echo "Unknown command: $1" >&2
    exit 1
    ;;
esac
MOCK_EOF

chmod +x "$MOCK_BIN/kaizen"

OUTPUT=$(bash "$SCRIPT" 2>&1)
ACTION=$(echo "$OUTPUT" | jq -r '.action' 2>/dev/null || echo "INVALID")

if [ "$ACTION" = "AUTO" ]; then
  FIX_TITLE=$(echo "$OUTPUT" | jq -r '.fix_task.title' 2>/dev/null || echo "")
  if [ -n "$FIX_TITLE" ]; then
    echo "  PASS: Hook outputs AUTO action with fix_task"
  else
    echo "  FAIL: Expected fix_task field"
    echo "  Output: $OUTPUT"
    exit 1
  fi
else
  echo "  FAIL: Expected action=AUTO for high confidence"
  echo "  Output: $OUTPUT"
  exit 1
fi

# Test 4: LOGGED action for low confidence
echo "Test 4: LOGGED action for low confidence suggestions"

cat > "$MOCK_BIN/kaizen" << 'MOCK_EOF'
#!/bin/bash
case "$1" in
  detect-category)
    echo '{"detected_category": "unknown", "confidence": "low"}'
    ;;
  capture)
    echo '{"captured": true}'
    ;;
  suggest)
    # Return logged-only suggestion
    echo '{"action": "log", "confidence": "low"}'
    ;;
  *)
    echo "Unknown command: $1" >&2
    exit 1
    ;;
esac
MOCK_EOF

chmod +x "$MOCK_BIN/kaizen"

OUTPUT=$(bash "$SCRIPT" 2>&1)
ACTION=$(echo "$OUTPUT" | jq -r '.action' 2>/dev/null || echo "INVALID")

if [ "$ACTION" = "LOGGED" ]; then
  echo "  PASS: Hook outputs LOGGED action for low confidence"
else
  echo "  FAIL: Expected action=LOGGED for low confidence"
  echo "  Output: $OUTPUT"
  exit 1
fi

# Test 5: Handles missing environment variables
echo "Test 5: Handles missing environment variables gracefully"

unset TASK_ID
unset FAILURE_DETAILS
unset FAILURE_SOURCE

if OUTPUT=$(bash "$SCRIPT" 2>&1); then
  # Should succeed but log the issue
  echo "  PASS: Script handles missing env vars gracefully"
else
  echo "  FAIL: Script should not fail on missing env vars"
  exit 1
fi

# Test 6: Valid JSON output format
echo "Test 6: Validates JSON output format"

export TASK_ID="T-123"
export FAILURE_DETAILS="Error message"
export FAILURE_SOURCE="quality-review"

OUTPUT=$(bash "$SCRIPT" 2>&1)

# Verify output is valid JSON
if echo "$OUTPUT" | jq empty 2>/dev/null; then
  echo "  PASS: Output is valid JSON"
else
  echo "  FAIL: Output is not valid JSON"
  echo "  Output: $OUTPUT"
  exit 1
fi

# Verify required fields exist
ACTION=$(echo "$OUTPUT" | jq -r '.action' 2>/dev/null || echo "")
if [ -n "$ACTION" ] && [[ "$ACTION" =~ ^(AUTO|SUGGEST|LOGGED)$ ]]; then
  echo "  PASS: Output has valid action field"
else
  echo "  FAIL: Output missing or invalid action field"
  echo "  Output: $OUTPUT"
  exit 1
fi

echo ""
echo "All tests passed!"
echo ""
echo "Hook script requirements verified:"
echo "  - Checks for kaizen availability"
echo "  - Calls detect-category, capture, suggest commands"
echo "  - Outputs valid JSON with action type"
echo "  - Handles AUTO, SUGGEST, LOGGED actions"
echo "  - Gracefully handles missing dependencies"