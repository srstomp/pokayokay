#!/usr/bin/env bash
# Validate session-summary.sh SessionEnd reporting:
# - COMMIT_COUNT is a single clean number (regression for the "0\n0"
#   two-line count that corrupted the session file)
# - commits from the last hour are counted and listed
# - agent token usage is read from the bridge-managed state file
# - uncommitted changes produce a warning
# - the .ohno/sessions chain-report file is written with clean formatting

set -euo pipefail

TEST_DIR=$(mktemp -d)
trap 'rm -rf -- "$TEST_DIR"' EXIT

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/hooks/actions/session-summary.sh"
[ -f "$SCRIPT" ] || { echo "script not found: $SCRIPT"; exit 1; }

echo "Testing session-summary.sh..."

if bash -n "$SCRIPT"; then
  echo "  PASS: script parses (bash -n)"
else
  echo "  FAIL: bash -n reports a syntax error"
  exit 1
fi

cd "$TEST_DIR"
git init -q
git config user.email "test@example.com"
git config user.name "Test"
echo "hello" > file.txt
git add file.txt
GIT_AUTHOR_DATE="2020-01-01T00:00:00Z" GIT_COMMITTER_DATE="2020-01-01T00:00:00Z" \
  git commit -qm "old commit"
mkdir -p .ohno

session_file() {
  ls "$TEST_DIR/.ohno/sessions/"*.txt 2>/dev/null | head -1
}

echo "Test 1: zero recent commits -> clean 'Commits: 0' line"
rm -rf .ohno/sessions
OUTPUT=$(bash "$SCRIPT")
if [[ "$OUTPUT" == *"SESSION COMPLETE"* ]] && [[ "$OUTPUT" != *"Recent commits"* ]]; then
  echo "  PASS: summary printed without a recent-commits section"
else
  echo "  FAIL: expected SESSION COMPLETE without recent commits"
  echo "$OUTPUT"
  exit 1
fi
FILE=$(session_file)
if [ -n "$FILE" ] && [ "$(sed -n '2p' "$FILE")" = "Commits: 0" ] \
  && [ "$(wc -l < "$FILE" | tr -d ' ')" = "2" ]; then
  echo "  PASS: session file is exactly 'Time:' + 'Commits: 0' (no stray count lines)"
else
  echo "  FAIL: expected a 2-line session file with 'Commits: 0' on line 2"
  cat "$FILE" 2>/dev/null || echo "  (no session file)"
  exit 1
fi

echo "Test 2: fresh commits are counted and listed"
rm -rf .ohno/sessions
echo "change one" >> file.txt
git commit -qam "first fresh commit"
echo "change two" >> file.txt
git commit -qam "second fresh commit"
OUTPUT=$(bash "$SCRIPT")
if [[ "$OUTPUT" == *"Recent commits (2):"* ]] && [[ "$OUTPUT" == *"second fresh commit"* ]]; then
  echo "  PASS: two fresh commits counted and listed"
else
  echo "  FAIL: expected 'Recent commits (2):' in output"
  echo "$OUTPUT"
  exit 1
fi
FILE=$(session_file)
if [ -n "$FILE" ] && [ "$(sed -n '2p' "$FILE")" = "Commits: 2" ]; then
  echo "  PASS: session file records Commits: 2 on a single line"
else
  echo "  FAIL: expected 'Commits: 2' on line 2 of the session file"
  cat "$FILE" 2>/dev/null || echo "  (no session file)"
  exit 1
fi

echo "Test 3: token usage and uncommitted changes are reported"
rm -rf .ohno/sessions
mkdir -p .pokayokay
cat > .pokayokay/pokayokay-token-usage.json << 'EOF'
{
  "total_agents": 2,
  "total_tokens": 1234,
  "agents": [
    {"type": "yokay-implementer", "total_tokens": 1000, "duration_ms": 5000},
    {"type": "yokay-test-runner", "total_tokens": 234, "duration_ms": 2000}
  ]
}
EOF
echo "dirty" >> file.txt
OUTPUT=$(bash "$SCRIPT")
if [[ "$OUTPUT" == *"Subagent usage (2 agents, 1234 total tokens)"* ]] \
  && [[ "$OUTPUT" == *"yokay-implementer"* ]]; then
  echo "  PASS: agent token usage read from .pokayokay state file"
else
  echo "  FAIL: expected subagent usage section for 2 agents / 1234 tokens"
  echo "$OUTPUT"
  exit 1
fi
if [[ "$OUTPUT" == *"WARNING: Uncommitted changes remain"* ]]; then
  echo "  PASS: uncommitted changes produce a warning"
else
  echo "  FAIL: expected an uncommitted-changes warning"
  echo "$OUTPUT"
  exit 1
fi
FILE=$(session_file)
if [ -n "$FILE" ] && grep -q "^Agents: 2 (1234 tokens)$" "$FILE" \
  && grep -q "^Uncommitted:$" "$FILE"; then
  echo "  PASS: session file carries agent totals and uncommitted section"
else
  echo "  FAIL: expected agent totals and Uncommitted section in the session file"
  cat "$FILE" 2>/dev/null || echo "  (no session file)"
  exit 1
fi

echo ""
echo "All session-summary tests passed!"
