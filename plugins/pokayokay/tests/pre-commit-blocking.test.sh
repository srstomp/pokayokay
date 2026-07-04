#!/usr/bin/env bash
# Validate the pre-commit gate exit-code contract (0=success, 1=warning
# advisory, 2=error blocking): check-ref-sizes.sh exit 2 denies the commit,
# lint failures stay advisory, and the git commit/add trigger matches real
# commands only (not quoted mentions).

set -euo pipefail

TEST_DIR=$(mktemp -d)
trap 'rm -rf -- "$TEST_DIR"' EXIT

BRIDGE="$(cd "$(dirname "$0")/.." && pwd)/hooks/actions/bridge.py"

echo "Testing pre-commit blocking gate..."

cd "$TEST_DIR"
git init -q
git config user.email "test@example.com"
git config user.name "Pre-Commit Test"

# Pin the project dir so hook actions (git diff --cached, lint) run against
# this temp repo even when the test runs inside a Claude Code session.
export YOKAY_PROJECT_DIR="$TEST_DIR"

assert_deny() {
  echo "$1" | python3 -c '
import json, sys
data = json.load(sys.stdin)
hso = data.get("hookSpecificOutput") or {}
assert hso.get("permissionDecision") == "deny", f"expected permissionDecision deny, got: {data}"
assert data.get("decision") == "block", f"expected legacy decision block, got: {data}"
assert data.get("reason"), "expected a block reason"
'
}

assert_not_blocked() {
  echo "$1" | python3 -c '
import json, sys
data = json.load(sys.stdin)
hso = data.get("hookSpecificOutput") or {}
assert hso.get("permissionDecision") != "deny", f"unexpected deny: {data}"
assert data.get("decision") != "block", f"unexpected block: {data}"
assert "additionalContext" in hso, f"expected pre-commit hooks to run, got: {data}"
'
}

assert_skip() {
  echo "$1" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data == {}, f"expected empty skip output, got: {data}"
'
}

# Stage a 600-line reference file at the exact path check-ref-sizes.sh gates
REF_DIR="plugins/pokayokay/skills/demo/references"
mkdir -p "$REF_DIR"
seq 600 | sed 's/^/reference line /' > "$REF_DIR/big-ref.md"
git add "$REF_DIR/big-ref.md"

echo "Test 1: Oversized staged reference file blocks git commit"
DENY_OUTPUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"add ref\""},"hook_event_name":"PreToolUse"}' |
  python3 "$BRIDGE")
assert_deny "$DENY_OUTPUT"
echo "  PASS: commit denied via permissionDecision + legacy block"

echo "Test 2: git add is gated too"
ADD_OUTPUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"git add plugins"},"hook_event_name":"PreToolUse"}' |
  python3 "$BRIDGE")
assert_deny "$ADD_OUTPUT"
echo "  PASS: git add denied while violation is staged"

echo "Test 3: newline-separated compound command is still gated"
COMPOUND_OUTPUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"cd plugins\ngit commit -m wip"},"hook_event_name":"PreToolUse"}' |
  python3 "$BRIDGE")
assert_deny "$COMPOUND_OUTPUT"
echo "  PASS: compound command denied"

echo "Test 4: quoted 'git commit' text does not trigger the gate"
SKIP_OUTPUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"echo \"git commit example\""},"hook_event_name":"PreToolUse"}' |
  python3 "$BRIDGE")
assert_skip "$SKIP_OUTPUT"
echo "  PASS: quoted mention skipped"

echo "Test 5: unstaged violation still blocks via the working-tree fallback"
# `git add -A && git commit` fires the hook before staging — the check must
# scan working-tree changes (including untracked files) when nothing relevant
# is staged yet.
git rm -q --cached "$REF_DIR/big-ref.md"
FALLBACK_OUTPUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"git add -A && git commit -m \"all\""},"hook_event_name":"PreToolUse"}' |
  python3 "$BRIDGE")
assert_deny "$FALLBACK_OUTPUT"
echo "  PASS: untracked oversized reference blocked pre-staging"

echo "Test 6: advisory failures (lint exit 1) do not block the commit"
# Remove the violation entirely and stage a package.json whose lint fails.
rm -f "$REF_DIR/big-ref.md"
cat > package.json << 'EOF'
{
  "name": "pre-commit-test",
  "scripts": {
    "lint": "exit 1"
  }
}
EOF
git add package.json
WARN_OUTPUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"lint warns\""},"hook_event_name":"PreToolUse"}' |
  python3 "$BRIDGE")
assert_not_blocked "$WARN_OUTPUT"
echo "  PASS: lint failure surfaced as advisory, commit not blocked"

echo ""
echo "All pre-commit blocking tests passed!"
