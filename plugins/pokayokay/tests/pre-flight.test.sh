#!/usr/bin/env bash
# Validate pre-flight.sh unattended-mode checks end-to-end:
# - passes on a healthy environment (clean git, responsive ohno, task available)
# - the worktree-lock loop parses and runs (regression for the for-loop
#   `2>/dev/null` syntax error that aborted the script with exit 2)
# - real ohno-cli 0.20.0 command surface is used (`status`, `next --json`)
# - blocking issues (dirty git, no tasks) produce PRE_FLIGHT=FAIL / exit 1

set -euo pipefail

TEST_DIR=$(mktemp -d)
trap 'rm -rf -- "$TEST_DIR"' EXIT

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/hooks/actions/pre-flight.sh"
[ -f "$SCRIPT" ] || { echo "script not found: $SCRIPT"; exit 1; }

echo "Testing pre-flight.sh..."

# Sanity: the script must parse (regression for the line-72 syntax error)
if bash -n "$SCRIPT"; then
  echo "  PASS: script parses (bash -n)"
else
  echo "  FAIL: bash -n reports a syntax error"
  exit 1
fi

# Keep the git repo in a subdirectory so the mock npx shim and response
# files do not show up as untracked files in the git-clean check.
REPO_DIR="$TEST_DIR/repo"
mkdir -p "$REPO_DIR"
cd "$REPO_DIR"
export CLAUDE_PROJECT_DIR="$REPO_DIR"

# Clean git repo
git init -q
git config user.email "test@example.com"
git config user.name "Test"
echo "hello" > file.txt
echo ".worktrees/" > .gitignore
git add file.txt .gitignore
git commit -qm "init"

# Mock npx: emulates ohno-cli 0.20.0 (`status` exists; `next --json` returns
# a task object with an `id`, or {"message":"No tasks available"}).
MOCK_BIN="$TEST_DIR/bin"
mkdir -p "$MOCK_BIN"
cat > "$MOCK_BIN/npx" << EOF
#!/usr/bin/env bash
echo "\$@" >> "$TEST_DIR/npx_calls.log"
if [ "\$1" = "@stevestomp/ohno-cli" ]; then
  case "\$2" in
    status) exit 0 ;;
    next) cat "$TEST_DIR/mock-next.out"; exit 0 ;;
  esac
fi
exit 1
EOF
chmod +x "$MOCK_BIN/npx"
export PATH="$MOCK_BIN:$PATH"

echo '{"id":"task-42","title":"ready task","status":"todo"}' > "$TEST_DIR/mock-next.out"

echo "Test 1: healthy environment passes"
RC=0
OUTPUT=$(bash "$SCRIPT" 2>&1) || RC=$?
if [ "$RC" -eq 0 ] && [[ "$OUTPUT" == *"PRE_FLIGHT=PASS"* ]]; then
  echo "  PASS: PRE_FLIGHT=PASS on healthy environment"
else
  echo "  FAIL: expected PRE_FLIGHT=PASS (exit 0), got exit $RC"
  echo "$OUTPUT"
  exit 1
fi
if [[ "$OUTPUT" == *"CHECK=ohno_responsive OK"* ]] && [[ "$OUTPUT" == *"tasks_available OK"* ]]; then
  echo "  PASS: ohno responsiveness and task availability checks pass"
else
  echo "  FAIL: expected ohno_responsive and tasks_available checks to pass"
  echo "$OUTPUT"
  exit 1
fi
if grep -q "^@stevestomp/ohno-cli status" "$TEST_DIR/npx_calls.log" \
  && grep -q "^@stevestomp/ohno-cli next --json" "$TEST_DIR/npx_calls.log"; then
  echo "  PASS: real ohno-cli command surface used (status, next --json)"
else
  echo "  FAIL: expected 'status' and 'next --json' invocations"
  cat "$TEST_DIR/npx_calls.log" 2>/dev/null || echo "  (no npx calls logged)"
  exit 1
fi

echo "Test 2: stale worktree lock is a warning, not a failure"
mkdir -p "$REPO_DIR/.worktrees/task-abc"
touch "$REPO_DIR/.worktrees/task-abc/locked"
RC=0
OUTPUT=$(bash "$SCRIPT" 2>&1) || RC=$?
if [ "$RC" -eq 0 ] && [[ "$OUTPUT" == *"WARNING=stale_lock"* ]] && [[ "$OUTPUT" == *"PRE_FLIGHT=PASS"* ]]; then
  echo "  PASS: lock reported as warning, pre-flight still passes"
else
  echo "  FAIL: expected WARNING=stale_lock with PRE_FLIGHT=PASS (exit 0), got exit $RC"
  echo "$OUTPUT"
  exit 1
fi
rm -rf "$REPO_DIR/.worktrees"

echo "Test 3: no tasks available fails pre-flight"
echo '{"message":"No tasks available"}' > "$TEST_DIR/mock-next.out"
RC=0
OUTPUT=$(bash "$SCRIPT" 2>&1) || RC=$?
if [ "$RC" -ne 0 ] && [[ "$OUTPUT" == *"ISSUE=no_tasks"* ]] && [[ "$OUTPUT" == *"PRE_FLIGHT=FAIL"* ]]; then
  echo "  PASS: no-tasks environment fails with ISSUE=no_tasks"
else
  echo "  FAIL: expected ISSUE=no_tasks and PRE_FLIGHT=FAIL (non-zero exit), got exit $RC"
  echo "$OUTPUT"
  exit 1
fi
echo '{"id":"task-42","title":"ready task","status":"todo"}' > "$TEST_DIR/mock-next.out"

echo "Test 4: dirty git tree fails pre-flight"
echo "uncommitted" >> file.txt
RC=0
OUTPUT=$(bash "$SCRIPT" 2>&1) || RC=$?
if [ "$RC" -ne 0 ] && [[ "$OUTPUT" == *"ISSUE=git_dirty"* ]] && [[ "$OUTPUT" == *"PRE_FLIGHT=FAIL"* ]]; then
  echo "  PASS: dirty tree fails with ISSUE=git_dirty"
else
  echo "  FAIL: expected ISSUE=git_dirty and PRE_FLIGHT=FAIL (non-zero exit), got exit $RC"
  echo "$OUTPUT"
  exit 1
fi

echo ""
echo "All pre-flight tests passed!"
