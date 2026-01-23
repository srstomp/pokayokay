#!/bin/bash
# Test for commit.sh security fix (CWE-732)
# Validates that sensitive files are not accidentally staged

set -e

TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

echo "Testing commit.sh sensitive file detection..."

# Setup test git repo
cd "$TEST_DIR"
git init -q
git config user.email "test@example.com"
git config user.name "Test User"

# Create an initial commit
echo "initial" > initial.txt
git add initial.txt
git commit -q -m "initial commit"

# Test 1: Reject .env files
echo "Test 1: Detect .env file"
echo "normal change" > normal.txt
echo "SECRET_KEY=abc123" > .env
git add normal.txt

export TASK_TYPE="feature"
export TASK_TITLE="test: Add feature"
export TASK_ID="task-001"

COMMIT_SCRIPT="/Users/sis4m4/Projects/stevestomp/pokayokay/plugins/pokayokay/hooks/actions/commit.sh"

if bash "$COMMIT_SCRIPT" 2>&1 | grep -q "Sensitive files detected"; then
  echo "  PASS: .env file detected and blocked"
else
  echo "  FAIL: .env file was not blocked"
  exit 1
fi

# Verify no commit was made
COMMIT_COUNT=$(git rev-list --count HEAD)
if [ "$COMMIT_COUNT" -eq 1 ]; then
  echo "  PASS: No commit was created"
else
  echo "  FAIL: Commit was created despite sensitive files"
  exit 1
fi

# Test 2: Reject credentials files
echo "Test 2: Detect credentials file"
rm .env
git restore --staged normal.txt
echo "normal change" > normal.txt
echo "password=secret" > credentials.json
git add normal.txt

if bash "$COMMIT_SCRIPT" 2>&1 | grep -q "Sensitive files detected"; then
  echo "  PASS: credentials file detected and blocked"
else
  echo "  FAIL: credentials file was not blocked"
  exit 1
fi

# Test 3: Reject secrets files
echo "Test 3: Detect secrets file"
rm credentials.json
git restore --staged normal.txt
echo "normal change" > normal.txt
echo "api_key=xyz" > secrets.yml
git add normal.txt

if bash "$COMMIT_SCRIPT" 2>&1 | grep -q "Sensitive files detected"; then
  echo "  PASS: secrets file detected and blocked"
else
  echo "  FAIL: secrets file was not blocked"
  exit 1
fi

# Test 4: Reject id_rsa files
echo "Test 4: Detect id_rsa file"
rm secrets.yml
git restore --staged normal.txt
echo "normal change" > normal.txt
echo "-----BEGIN RSA PRIVATE KEY-----" > id_rsa
git add normal.txt

if bash "$COMMIT_SCRIPT" 2>&1 | grep -q "Sensitive files detected"; then
  echo "  PASS: id_rsa file detected and blocked"
else
  echo "  FAIL: id_rsa file was not blocked"
  exit 1
fi

# Test 5: Allow normal files (untracked)
echo "Test 5: Allow normal untracked files"
rm id_rsa
git restore --staged normal.txt
echo "safe content" > safe.txt
git add normal.txt

if bash "$COMMIT_SCRIPT" 2>&1; then
  echo "  PASS: Normal files allowed with untracked files present"
  # Verify commit was created
  COMMIT_COUNT=$(git rev-list --count HEAD)
  if [ "$COMMIT_COUNT" -eq 2 ]; then
    echo "  PASS: Commit was created successfully"
  else
    echo "  FAIL: Commit count unexpected: $COMMIT_COUNT"
    exit 1
  fi
else
  echo "  FAIL: Normal files were blocked"
  exit 1
fi

# Test 6: Only stage tracked files (git add -u behavior)
echo "Test 6: Only tracked files are staged"
echo "modified content" > normal.txt
echo "new file" > newfile.txt

# The script should only stage normal.txt (tracked), not newfile.txt (untracked)
if bash "$COMMIT_SCRIPT" 2>&1; then
  # Check that newfile.txt was NOT committed
  if git ls-tree -r HEAD --name-only | grep -q "newfile.txt"; then
    echo "  FAIL: Untracked file was staged and committed"
    exit 1
  else
    echo "  PASS: Untracked file was not staged"
  fi

  # Check that normal.txt WAS committed
  if git ls-tree -r HEAD --name-only | grep -q "normal.txt"; then
    echo "  PASS: Tracked file was staged and committed"
  else
    echo "  FAIL: Tracked file was not committed"
    exit 1
  fi
else
  echo "  FAIL: Commit failed unexpectedly"
  exit 1
fi

echo ""
echo "All sensitive file detection tests passed!"
echo ""
echo "Expected script changes:"
echo "  - Check for sensitive file patterns before staging"
echo "  - Use 'git add -u' instead of 'git add -A'"
echo "  - Exit with error if sensitive files detected"
echo "  - Patterns: .env, credentials, secrets, id_rsa"
