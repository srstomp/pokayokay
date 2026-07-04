#!/usr/bin/env bash
# Validate recover.sh crash recovery end-to-end (mocked ohno-cli):
# - runs to its "Recovery complete" line (regression for the for-loop
#   `2>/dev/null` syntax error that aborted the script with exit 2)
# - stashes uncommitted changes and saves crash WIP via update-wip
#   (no call to the nonexistent add-activity command)
# - reports stale worktree locks
# - retires the chain-state file (renamed *.recovered) so stale-session
#   detection cannot re-fire on the next SessionStart

set -euo pipefail

TEST_DIR=$(mktemp -d)
trap 'rm -rf -- "$TEST_DIR"' EXIT

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/hooks/actions/recover.sh"
[ -f "$SCRIPT" ] || { echo "script not found: $SCRIPT"; exit 1; }

echo "Testing recover.sh..."

# Sanity: the script must parse (regression for the line-60 syntax error)
if bash -n "$SCRIPT"; then
  echo "  PASS: script parses (bash -n)"
else
  echo "  FAIL: bash -n reports a syntax error"
  exit 1
fi

cd "$TEST_DIR"
export CLAUDE_PROJECT_DIR="$TEST_DIR"

# Git repo with an uncommitted change (so the stash step has work to do)
git init -q
git config user.email "test@example.com"
git config user.name "Test"
echo "hello" > file.txt
git add file.txt
git commit -qm "init"
echo "uncommitted change" >> file.txt

# Mock npx: logs every ohno-cli invocation
MOCK_BIN="$TEST_DIR/bin"
mkdir -p "$MOCK_BIN"
cat > "$MOCK_BIN/npx" << EOF
#!/usr/bin/env bash
echo "\$@" >> "$TEST_DIR/npx_calls.log"
exit 0
EOF
chmod +x "$MOCK_BIN/npx"
export PATH="$MOCK_BIN:$PATH"

# Stale worktree lock + stale chain state from the "crashed" session
mkdir -p "$TEST_DIR/.worktrees/task-t1"
touch "$TEST_DIR/.worktrees/task-t1/locked"
mkdir -p "$TEST_DIR/.pokayokay"
echo '{"chain_id":"chain-9","chain_index":1,"tasks_completed":2}' \
  > "$TEST_DIR/.pokayokay/pokayokay-chain-state.json"

echo "Test 1: full recovery run"
RC=0
OUTPUT=$(STALE_TASKS="t1, t2" CHAIN_ID="chain-9" bash "$SCRIPT" 2>&1) || RC=$?
if [ "$RC" -eq 0 ] && [[ "$OUTPUT" == *"Recovery complete"* ]]; then
  echo "  PASS: script ran to 'Recovery complete' (exit 0)"
else
  echo "  FAIL: expected exit 0 with 'Recovery complete', got exit $RC"
  echo "$OUTPUT"
  exit 1
fi
if [[ "$OUTPUT" == *"STASHED=true"* ]] && git diff --quiet && git stash list | grep -q "yokay-crash-recovery-chain-9"; then
  echo "  PASS: uncommitted changes stashed with chain-tagged message"
else
  echo "  FAIL: expected STASHED=true and a yokay-crash-recovery-chain-9 stash"
  echo "$OUTPUT"
  git stash list || true
  exit 1
fi
if [[ "$OUTPUT" == *"TASK_RECOVERED=t1"* ]] && [[ "$OUTPUT" == *"TASK_RECOVERED=t2"* ]] \
  && [[ "$OUTPUT" == *"RECOVERED_COUNT=3"* ]]; then
  echo "  PASS: both stale tasks recovered (stash + 2 tasks = RECOVERED_COUNT=3)"
else
  echo "  FAIL: expected TASK_RECOVERED for t1 and t2 with RECOVERED_COUNT=3"
  echo "$OUTPUT"
  exit 1
fi
if grep -q "^@stevestomp/ohno-cli update-wip t1 " "$TEST_DIR/npx_calls.log" \
  && grep -q "^@stevestomp/ohno-cli update-wip t2 " "$TEST_DIR/npx_calls.log"; then
  echo "  PASS: crash WIP saved via update-wip for both tasks"
else
  echo "  FAIL: expected update-wip calls for t1 and t2"
  cat "$TEST_DIR/npx_calls.log" 2>/dev/null || echo "  (no npx calls logged)"
  exit 1
fi
if ! grep -q "add-activity" "$TEST_DIR/npx_calls.log"; then
  echo "  PASS: no call to nonexistent add-activity command"
else
  echo "  FAIL: recover.sh must not call add-activity (not in ohno-cli 0.20.0)"
  cat "$TEST_DIR/npx_calls.log"
  exit 1
fi
if [[ "$OUTPUT" == *"STALE_LOCK=${TEST_DIR}/.worktrees/task-t1/locked"* ]]; then
  echo "  PASS: stale worktree lock reported"
else
  echo "  FAIL: expected STALE_LOCK for .worktrees/task-t1/locked"
  echo "$OUTPUT"
  exit 1
fi

echo "Test 2: chain state retired so recovery cannot re-fire"
if [ ! -f "$TEST_DIR/.pokayokay/pokayokay-chain-state.json" ] \
  && [ -f "$TEST_DIR/.pokayokay/pokayokay-chain-state.json.recovered" ] \
  && [[ "$OUTPUT" == *"CHAIN_STATE_RETIRED="* ]]; then
  echo "  PASS: chain-state file renamed to .recovered"
else
  echo "  FAIL: expected pokayokay-chain-state.json renamed to .recovered"
  ls -la "$TEST_DIR/.pokayokay" || true
  exit 1
fi

echo "Test 3: legacy .claude chain state is retired too"
mkdir -p "$TEST_DIR/.claude"
echo '{"chain_id":"chain-old"}' > "$TEST_DIR/.claude/pokayokay-chain-state.json"
RC=0
OUTPUT=$(CHAIN_ID="chain-old" bash "$SCRIPT" 2>&1) || RC=$?
if [ "$RC" -eq 0 ] && [ ! -f "$TEST_DIR/.claude/pokayokay-chain-state.json" ] \
  && [ -f "$TEST_DIR/.claude/pokayokay-chain-state.json.recovered" ]; then
  echo "  PASS: legacy chain-state file renamed to .recovered"
else
  echo "  FAIL: expected legacy .claude chain state retired, got exit $RC"
  ls -la "$TEST_DIR/.claude" || true
  exit 1
fi

echo ""
echo "All recover tests passed!"
