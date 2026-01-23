#!/bin/bash
# Test for commit.sh security fix (CWE-78)
# Validates that commit messages with special characters cannot execute commands

set -e

TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

echo "Testing commit.sh security fix..."

# Setup test git repo
cd "$TEST_DIR"
git init -q
git config user.email "test@example.com"
git config user.name "Test User"

# Test 1: Verify malicious characters in TASK_TITLE cannot escape
echo "Test 1: Command injection in TASK_TITLE"
echo "test file" > test.txt
git add test.txt

# Create a malicious task title with command injection attempt
MALICIOUS_TITLE='test"; touch /tmp/exploit-proof; echo "injected'
export TASK_TYPE="feature"
export TASK_TITLE="$MALICIOUS_TITLE"
export TASK_ID="task-123"

# Run the commit script (using the fixed version)
COMMIT_SCRIPT="/Users/sis4m4/Projects/stevestomp/pokayokay/plugins/pokayokay/hooks/actions/commit.sh"

# Execute the script
if bash "$COMMIT_SCRIPT" 2>/dev/null; then
  # Verify the exploit file was NOT created
  if [ -f "/tmp/exploit-proof" ]; then
    echo "  FAIL: Command injection vulnerability detected - exploit file created"
    rm -f /tmp/exploit-proof
    exit 1
  else
    echo "  PASS: Command injection prevented - no exploit file created"
  fi

  # Verify commit message contains the malicious string literally
  COMMIT_MSG=$(git log -1 --pretty=%B)
  if [[ "$COMMIT_MSG" == *"$MALICIOUS_TITLE"* ]]; then
    echo "  PASS: Malicious characters treated as literal text"
  else
    echo "  FAIL: Commit message doesn't contain expected text"
    echo "  Expected: $MALICIOUS_TITLE"
    echo "  Got: $COMMIT_MSG"
    exit 1
  fi
else
  echo "  FAIL: Commit script failed to execute"
  exit 1
fi

# Test 2: Verify newlines and special characters are handled correctly
echo "Test 2: Newlines and special characters in TASK_TITLE"
echo "test2" > test2.txt
git add test2.txt

export TASK_TITLE='test$(whoami)$USER`date`'
export TASK_TYPE="fix"
export TASK_ID="task-456"

if bash "$COMMIT_SCRIPT" 2>/dev/null; then
  COMMIT_MSG=$(git log -1 --pretty=%B)
  # Verify command substitution did not execute
  if [[ "$COMMIT_MSG" == *'$(whoami)'* ]] || [[ "$COMMIT_MSG" == *'$USER'* ]]; then
    echo "  PASS: Command substitution prevented"
  else
    echo "  FAIL: Command substitution may have executed"
    echo "  Got: $COMMIT_MSG"
    exit 1
  fi
else
  echo "  FAIL: Commit script failed to execute"
  exit 1
fi

# Test 3: Verify normal titles still work
echo "Test 3: Normal commit message"
echo "test3" > test3.txt
git add test3.txt

export TASK_TITLE="security: Fix command injection vulnerability"
export TASK_TYPE="fix"
export TASK_ID="task-789"

if bash "$COMMIT_SCRIPT" 2>/dev/null; then
  COMMIT_MSG=$(git log -1 --pretty=%B)
  if [[ "$COMMIT_MSG" == *"Fix command injection vulnerability"* ]]; then
    echo "  PASS: Normal commit messages work correctly"
  else
    echo "  FAIL: Normal commit message malformed"
    echo "  Got: $COMMIT_MSG"
    exit 1
  fi
else
  echo "  FAIL: Commit script failed to execute"
  exit 1
fi

# Test 4: Verify commit message format is preserved
echo "Test 4: Commit message format"
echo "test4" > test4.txt
git add test4.txt

export TASK_TITLE="test: Add new feature"
export TASK_TYPE="feature"
export TASK_ID="task-999"

if bash "$COMMIT_SCRIPT" 2>/dev/null; then
  COMMIT_MSG=$(git log -1 --pretty=%B)

  # Check format: TYPE(SCOPE): TITLE\n\nTask: ID
  if [[ "$COMMIT_MSG" =~ ^feat\(test\): ]]; then
    echo "  PASS: Type and scope extracted correctly"
  else
    echo "  FAIL: Type/scope format incorrect"
    echo "  Got: $COMMIT_MSG"
    exit 1
  fi

  if [[ "$COMMIT_MSG" == *"Task: task-999"* ]]; then
    echo "  PASS: Task ID included correctly"
  else
    echo "  FAIL: Task ID not found in commit message"
    echo "  Got: $COMMIT_MSG"
    exit 1
  fi
else
  echo "  FAIL: Commit script failed to execute"
  exit 1
fi

# Test 5: Verify empty scope and task ID are handled
echo "Test 5: Empty scope and task ID"
echo "test5" > test5.txt
git add test5.txt

export TASK_TITLE="Add documentation"
export TASK_TYPE="chore"
unset TASK_ID

if bash "$COMMIT_SCRIPT" 2>/dev/null; then
  COMMIT_MSG=$(git log -1 --pretty=%B)

  if [[ "$COMMIT_MSG" =~ ^chore: ]]; then
    echo "  PASS: Empty scope handled correctly"
  else
    echo "  FAIL: Empty scope not handled"
    echo "  Got: $COMMIT_MSG"
    exit 1
  fi

  if [[ "$COMMIT_MSG" != *"Task:"* ]]; then
    echo "  PASS: Empty task ID handled correctly"
  else
    echo "  FAIL: Task ID should not be in message"
    echo "  Got: $COMMIT_MSG"
    exit 1
  fi
else
  echo "  FAIL: Commit script failed to execute"
  exit 1
fi

echo ""
echo "All security tests passed!"
echo ""
echo "Expected script changes:"
echo "  - Use temporary file for commit message"
echo "  - Use 'git commit -F' instead of 'git commit -m'"
echo "  - Add trap to clean up temporary file"
echo "  - Use heredoc to write message to file"
