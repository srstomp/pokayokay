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

# Test 7: Allow .env.backup (false positive check)
echo "Test 7: Allow .env.backup file"
rm -f newfile.txt
echo "backup" > .env.backup
echo "change 1" > normal.txt
git add normal.txt

if bash "$COMMIT_SCRIPT" 2>&1; then
  echo "  PASS: .env.backup file was allowed"
  COMMIT_COUNT=$(git rev-list --count HEAD)
  if [ "$COMMIT_COUNT" -eq 4 ]; then
    echo "  PASS: Commit was created successfully"
  else
    echo "  FAIL: Commit count unexpected: $COMMIT_COUNT"
    exit 1
  fi
else
  echo "  FAIL: .env.backup was incorrectly blocked"
  exit 1
fi

# Test 8: Allow id_rsa.pub (public key is safe)
echo "Test 8: Allow id_rsa.pub file"
rm -f .env.backup
echo "-----BEGIN PUBLIC KEY-----" > id_rsa.pub
echo "change 2" > normal.txt
git add normal.txt

if bash "$COMMIT_SCRIPT" 2>&1; then
  echo "  PASS: id_rsa.pub file was allowed"
  COMMIT_COUNT=$(git rev-list --count HEAD)
  if [ "$COMMIT_COUNT" -eq 5 ]; then
    echo "  PASS: Commit was created successfully"
  else
    echo "  FAIL: Commit count unexpected: $COMMIT_COUNT"
    exit 1
  fi
else
  echo "  FAIL: id_rsa.pub was incorrectly blocked"
  exit 1
fi

# Test 9: Allow credentials-backup.json (false positive check)
echo "Test 9: Allow credentials-backup.json file"
rm -f id_rsa.pub
echo "backup" > credentials-backup.json
echo "change 3" > normal.txt
git add normal.txt

if bash "$COMMIT_SCRIPT" 2>&1; then
  echo "  PASS: credentials-backup.json file was allowed"
  COMMIT_COUNT=$(git rev-list --count HEAD)
  if [ "$COMMIT_COUNT" -eq 6 ]; then
    echo "  PASS: Commit was created successfully"
  else
    echo "  FAIL: Commit count unexpected: $COMMIT_COUNT"
    exit 1
  fi
else
  echo "  FAIL: credentials-backup.json was incorrectly blocked"
  exit 1
fi

# Test 10: Allow secrets-config.yml (false positive check)
echo "Test 10: Allow secrets-config.yml file"
rm -f credentials-backup.json
echo "config" > secrets-config.yml
echo "change 4" > normal.txt
git add normal.txt

if bash "$COMMIT_SCRIPT" 2>&1; then
  echo "  PASS: secrets-config.yml file was allowed"
  COMMIT_COUNT=$(git rev-list --count HEAD)
  if [ "$COMMIT_COUNT" -eq 7 ]; then
    echo "  PASS: Commit was created successfully"
  else
    echo "  FAIL: Commit count unexpected: $COMMIT_COUNT"
    exit 1
  fi
else
  echo "  FAIL: secrets-config.yml was incorrectly blocked"
  exit 1
fi

# Test 11: Block exact .env file
echo "Test 11: Block exact .env file"
rm -f secrets-config.yml
echo "SECRET=value" > .env
echo "normal change" > normal.txt
git add normal.txt

if bash "$COMMIT_SCRIPT" 2>&1 | grep -q "Sensitive files detected"; then
  echo "  PASS: Exact .env file was blocked"
else
  echo "  FAIL: Exact .env file was not blocked"
  exit 1
fi

# Test 12: Block credentials.json (with extension)
echo "Test 12: Block credentials.json"
rm -f .env
git restore --staged normal.txt
echo "password=secret" > credentials.json
echo "normal change" > normal.txt
git add normal.txt

if bash "$COMMIT_SCRIPT" 2>&1 | grep -q "Sensitive files detected"; then
  echo "  PASS: credentials.json was blocked"
else
  echo "  FAIL: credentials.json was not blocked"
  exit 1
fi

# Test 13: Block exact credentials file (no extension)
echo "Test 13: Block exact credentials file"
rm -f credentials.json
git restore --staged normal.txt
echo "password=secret" > credentials
echo "normal change" > normal.txt
git add normal.txt

if bash "$COMMIT_SCRIPT" 2>&1 | grep -q "Sensitive files detected"; then
  echo "  PASS: Exact credentials file was blocked"
else
  echo "  FAIL: Exact credentials file was not blocked"
  exit 1
fi

# Test 14: Block secrets.yaml
echo "Test 14: Block secrets.yaml"
rm -f credentials
git restore --staged normal.txt
echo "api_key=xyz" > secrets.yaml
echo "normal change" > normal.txt
git add normal.txt

if bash "$COMMIT_SCRIPT" 2>&1 | grep -q "Sensitive files detected"; then
  echo "  PASS: secrets.yaml was blocked"
else
  echo "  FAIL: secrets.yaml was not blocked"
  exit 1
fi

# Test 15: Allow .env.local
echo "Test 15: Allow .env.local file"
rm -f secrets.yaml
git restore --staged normal.txt
echo "LOCAL_VAR=value" > .env.local
echo "change 5" > normal.txt
git add normal.txt

if bash "$COMMIT_SCRIPT" 2>&1; then
  echo "  PASS: .env.local file was allowed"
  COMMIT_COUNT=$(git rev-list --count HEAD)
  if [ "$COMMIT_COUNT" -eq 8 ]; then
    echo "  PASS: Commit was created successfully"
  else
    echo "  FAIL: Commit count unexpected: $COMMIT_COUNT"
    exit 1
  fi
else
  echo "  FAIL: .env.local was incorrectly blocked"
  exit 1
fi

# Test 16: Allow .env.example
echo "Test 16: Allow .env.example file"
rm -f .env.local
echo "EXAMPLE_VAR=value" > .env.example
echo "change 6" > normal.txt
git add normal.txt

if bash "$COMMIT_SCRIPT" 2>&1; then
  echo "  PASS: .env.example file was allowed"
  COMMIT_COUNT=$(git rev-list --count HEAD)
  if [ "$COMMIT_COUNT" -eq 9 ]; then
    echo "  PASS: Commit was created successfully"
  else
    echo "  FAIL: Commit count unexpected: $COMMIT_COUNT"
    exit 1
  fi
else
  echo "  FAIL: .env.example was incorrectly blocked"
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
echo "  - Allow false positives: .env.backup, .env.local, .env.example, id_rsa.pub, credentials-backup.json, secrets-config.yml"
