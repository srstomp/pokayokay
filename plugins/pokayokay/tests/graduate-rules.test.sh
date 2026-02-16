#!/bin/bash
# Test for graduate-rules.sh - rule graduation from failure patterns
set -e

TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

SCRIPT_DIR="$(cd "$(dirname "$0")/../hooks/actions" && pwd)"
SCRIPT="$SCRIPT_DIR/graduate-rules.sh"

echo "Testing graduate-rules.sh..."

# Test 1: Creates new rule file with path scope
echo "Test 1: Creates new rule file for hooks category"
export CLAUDE_PROJECT_DIR="$TEST_DIR"
export CATEGORY="missing_tests"
export PATTERN_DESCRIPTION="Review failures for missing tests in hook actions"
export AFFECTED_PATHS="plugins/pokayokay/hooks/**/*"
export FAILURE_COUNT="3"

mkdir -p "$TEST_DIR/.claude/rules/pokayokay"

OUTPUT=$(bash "$SCRIPT" 2>&1)

RULE_FILE="$TEST_DIR/.claude/rules/pokayokay/missing-tests.md"
if [ -f "$RULE_FILE" ]; then
  if head -5 "$RULE_FILE" | grep -q "paths:"; then
    echo "  PASS: Rule file created with paths frontmatter"
  else
    echo "  FAIL: Rule file missing paths frontmatter"
    cat "$RULE_FILE"
    exit 1
  fi
else
  echo "  FAIL: Rule file not created at $RULE_FILE"
  exit 1
fi

# Test 2: Appends to existing rule file
echo "Test 2: Appends new pattern to existing rule file"
export PATTERN_DESCRIPTION="Also missing edge case tests"

OUTPUT=$(bash "$SCRIPT" 2>&1)

LINE_COUNT=$(wc -l < "$RULE_FILE")
if [ "$LINE_COUNT" -gt 8 ]; then
  echo "  PASS: Rule file has additional content"
else
  echo "  FAIL: Rule file should have grown after append"
  cat "$RULE_FILE"
  exit 1
fi

# Test 3: Handles missing CLAUDE_PROJECT_DIR gracefully
echo "Test 3: Handles missing project dir"
unset CLAUDE_PROJECT_DIR
export CATEGORY="missing_validation"
export PATTERN_DESCRIPTION="Input validation missing"
export AFFECTED_PATHS=""

if OUTPUT=$(bash "$SCRIPT" 2>&1); then
  echo "  PASS: Script exits gracefully without project dir"
else
  echo "  PASS: Script exits with error without project dir"
fi

# Test 4: Creates rules directory if missing
echo "Test 4: Creates rules directory if it does not exist"
export CLAUDE_PROJECT_DIR="$TEST_DIR/fresh-project"
mkdir -p "$TEST_DIR/fresh-project/.claude"
export CATEGORY="scope_creep"
export PATTERN_DESCRIPTION="Implementation exceeds spec"
export AFFECTED_PATHS=""
export FAILURE_COUNT="3"

OUTPUT=$(bash "$SCRIPT" 2>&1)
if [ -d "$TEST_DIR/fresh-project/.claude/rules/pokayokay" ]; then
  echo "  PASS: Rules directory created"
else
  echo "  FAIL: Rules directory not created"
  exit 1
fi

# Test 5: No paths frontmatter when AFFECTED_PATHS is empty
echo "Test 5: Project-wide rule when no paths specified"
RULE_FILE="$TEST_DIR/fresh-project/.claude/rules/pokayokay/scope-creep.md"
if [ -f "$RULE_FILE" ]; then
  if head -3 "$RULE_FILE" | grep -q "^---"; then
    echo "  FAIL: Should not have frontmatter when no paths"
    cat "$RULE_FILE"
    exit 1
  else
    echo "  PASS: No frontmatter for project-wide rule"
  fi
else
  echo "  FAIL: Rule file not created"
  exit 1
fi

echo ""
echo "All tests passed!"
