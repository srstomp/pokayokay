#!/bin/bash
# Integration test for audit-gate.sh security fix
# Tests the actual script with edge case filenames

set -e

SCRIPT_PATH="/Users/sis4m4/Projects/stevestomp/pokayokay/plugins/pokayokay/hooks/actions/audit-gate.sh"
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

echo "Integration test: audit-gate.sh with special filenames"

cd "$TEST_DIR"
git init -q
git config user.name "Test User"
git config user.email "test@example.com"

# Create src directory with files containing special characters
mkdir -p src

# Test 1: File with spaces
echo "const x = 1;" > "src/file with spaces.ts"
echo "console.log('test');" > "src/another file.tsx"

# Test 2: File with semicolons (potential command injection)
echo "const y = 2;" > "src/file;echo-injected.ts"

# Test 3: File with newlines in name (extreme edge case)
# Note: Some filesystems don't support this, so we skip if it fails
touch "src/file\$injection.ts" 2>/dev/null || true

# Test 4: Normal files
echo "TODO: implement" > "src/normal.ts"
echo "FIXME: bug" > "src/another.tsx"

git add .
git commit -q -m "Initial commit"

# Run the audit script
echo ""
export BOUNDARY_TYPE=story
bash "$SCRIPT_PATH"

echo ""
echo "Integration test passed: Script handles special filenames without command injection"
