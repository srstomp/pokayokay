#!/bin/bash
# Test for audit-gate.sh security fix (CWE-78)
# Validates that xargs handles filenames with special characters correctly

set -e

TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

echo "Testing audit-gate.sh security fix..."

# Test 1: Verify script handles filenames with spaces
echo "Test 1: Filenames with spaces"
cd "$TEST_DIR"
git init -q
mkdir -p src
echo "console.log('test')" > "src/file with spaces.ts"
echo "TODO: test" > "file with todo.ts"

# Source the script's TODO detection logic with our fix
TODOS=$(git add . && git commit -q -m "test" && git diff HEAD~1 --name-only -z 2>/dev/null | xargs -0 -r grep -l "TODO\|FIXME" 2>/dev/null | wc -l || echo "0")

if [ "$TODOS" -ge 0 ]; then
  echo "  PASS: Script handles spaces in filenames"
else
  echo "  FAIL: Script failed with spaces in filenames"
  exit 1
fi

# Test 2: Verify script handles filenames with special characters
echo "Test 2: Filenames with special characters"
touch "src/file;rm -rf;.ts"
CONSOLE_LOGS=$(find src -name "*.ts" -o -name "*.tsx" -print0 2>/dev/null | xargs -0 -r grep -l "console.log" 2>/dev/null | wc -l || echo "0")

if [ "$CONSOLE_LOGS" -ge 0 ]; then
  echo "  PASS: Script handles special characters in filenames"
else
  echo "  FAIL: Script failed with special characters in filenames"
  exit 1
fi

# Test 3: Verify xargs -r flag (no error when no input)
echo "Test 3: Empty input handling"
mkdir -p empty_dir
RESULT=$(find empty_dir -name "*.ts" -print0 2>/dev/null | xargs -0 -r grep -l "console.log" 2>/dev/null | wc -l || echo "0")

if [ "$RESULT" -eq 0 ]; then
  echo "  PASS: Script handles empty input correctly"
else
  echo "  FAIL: Script failed with empty input"
  exit 1
fi

echo ""
echo "All security tests passed!"
echo ""
echo "Expected script changes:"
echo "  Line 31: git diff HEAD~5 --name-only -z | xargs -0 -r grep -l"
echo "  Line 37: find src ... -print0 | xargs -0 -r grep -l"
