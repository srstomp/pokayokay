#!/bin/bash
# Test for suggest-skills.sh memory-informed routing
set -e

TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

SCRIPT_DIR="$(cd "$(dirname "$0")/../hooks/actions" && pwd)"
SCRIPT="$SCRIPT_DIR/suggest-skills.sh"

echo "Testing suggest-skills.sh memory integration..."

# Setup: create memory files
MEMORY_DIR="$TEST_DIR/memory"
mkdir -p "$MEMORY_DIR"

# Test 1: Suppresses spike when already answered
echo "Test 1: Suppresses spike for previously answered question"
cat > "$MEMORY_DIR/spike-results.md" << 'EOF'
# Spike Results

## Should we use Redis for caching? (2026-02-10)
- **Result**: GO
- **Task**: T-42
- **Finding**: Redis is the right choice for our session caching needs
EOF

export CLAUDE_PROJECT_DIR="$TEST_DIR"
export TASK_TITLE="Investigate whether Redis is suitable for caching"
export TASK_TYPE="spike"
export MEMORY_DIR="$MEMORY_DIR"

OUTPUT=$(bash "$SCRIPT" 2>&1)

if echo "$OUTPUT" | grep -qi "already investigated\|prior spike\|spike-results"; then
  echo "  PASS: References prior spike result"
else
  echo "  FAIL: Should reference prior spike for Redis caching"
  echo "  Output: $OUTPUT"
  exit 1
fi

# Test 2: Boosts skill based on recurring failures
echo "Test 2: Boosts testing-strategy for missing_tests failures"
cat > "$MEMORY_DIR/recurring-failures.md" << 'EOF'
# Recurring Review Failures

## Missing Tests (seen 5x)
**Pattern**: Review failures for missing tests
**Context**: Implementation lacks unit tests for edge cases
**First recorded**: 2026-02-10
EOF

export TASK_TITLE="Add input validation to user form"
export TASK_TYPE="feature"

OUTPUT=$(bash "$SCRIPT" 2>&1)

if echo "$OUTPUT" | grep -qi "testing-strategy\|recurring.*test"; then
  echo "  PASS: Boosted testing-strategy due to recurring failures"
else
  echo "  FAIL: Should boost testing-strategy skill"
  echo "  Output: $OUTPUT"
  exit 1
fi

# Test 3: Mentions relevant graduated rules
echo "Test 3: Mentions graduated rules when they exist"
mkdir -p "$TEST_DIR/.claude/rules/pokayokay"
cat > "$TEST_DIR/.claude/rules/pokayokay/missing-tests.md" << 'EOF'
# Missing Tests Rules

- Always write tests before implementation
EOF

export TASK_TITLE="Implement new API endpoint"
export TASK_TYPE="feature"

OUTPUT=$(bash "$SCRIPT" 2>&1)

if echo "$OUTPUT" | grep -qi "rules\|graduated.*pattern"; then
  echo "  PASS: Mentions graduated rules"
else
  echo "  FAIL: Should mention relevant graduated rules"
  echo "  Output: $OUTPUT"
  exit 1
fi

echo ""
echo "All tests passed!"
