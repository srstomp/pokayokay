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

echo "Test 3b: git -C <path> commit is gated"
C_OPT_OUTPUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"git -C . commit -m wip"},"hook_event_name":"PreToolUse"}' |
  python3 "$BRIDGE")
assert_deny "$C_OPT_OUTPUT"
echo "  PASS: -C option-with-argument form denied"

echo "Test 3c: env-prefixed git commit is gated"
ENV_OUTPUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"GIT_AUTHOR_NAME=bot git commit -m wip"},"hook_event_name":"PreToolUse"}' |
  python3 "$BRIDGE")
assert_deny "$ENV_OUTPUT"
echo "  PASS: env-prefixed commit denied"

echo "Test 4: quoted 'git commit' text does not trigger the gate"
SKIP_OUTPUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"echo \"git commit example\""},"hook_event_name":"PreToolUse"}' |
  python3 "$BRIDGE")
assert_skip "$SKIP_OUTPUT"
echo "  PASS: quoted mention skipped"

echo "Test 5: unstaged violation still blocks via the add-all fallback"
# `git add -A && git commit` fires the hook before staging — the check must
# scan working-tree changes (including untracked files) when the command is
# about to stage everything.
git rm -q --cached "$REF_DIR/big-ref.md"
FALLBACK_OUTPUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"git add -A && git commit -m \"all\""},"hook_event_name":"PreToolUse"}' |
  python3 "$BRIDGE")
assert_deny "$FALLBACK_OUTPUT"
echo "  PASS: untracked oversized reference blocked pre-staging"

echo "Test 5b: plain git commit is NOT blocked by an untracked oversized ref"
# The oversized file is still untracked in the working tree, but the commit
# being intercepted stages only an unrelated file — the check must not
# deadlock the commit on a WIP draft it doesn't include.
echo "unrelated content" > src.txt
git add src.txt
PLAIN_OUTPUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"unrelated\""},"hook_event_name":"PreToolUse"}' |
  python3 "$BRIDGE")
assert_not_blocked "$PLAIN_OUTPUT"
echo "  PASS: unrelated commit not blocked by working-tree draft"

echo "Test 5c: git add of the oversized ref by explicit path is blocked"
NAMED_OUTPUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"git add plugins/pokayokay/skills/demo/references/big-ref.md && git commit -m \"ref\""},"hook_event_name":"PreToolUse"}' |
  python3 "$BRIDGE")
assert_deny "$NAMED_OUTPUT"
echo "  PASS: explicitly-added oversized reference blocked pre-staging"
git rm -q --cached src.txt
rm -f src.txt

echo "Test 5d: git add of a parent directory catches the contained ref"
# `git add skills/demo && git commit` stages everything beneath the dir; the
# pre-staging check must match the contained ref via its parent directory.
DIR_OUTPUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"git add plugins/pokayokay/skills/demo && git commit -m \"dir\""},"hook_event_name":"PreToolUse"}' |
  python3 "$BRIDGE")
assert_deny "$DIR_OUTPUT"
echo "  PASS: directory add gates the contained oversized reference"

echo "Test 5e: sibling directory with shared prefix does not false-block"
SIBLING_OUTPUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"git add plugins/pokayokay/skills/demo-other && git commit -m \"sib\""},"hook_event_name":"PreToolUse"}' |
  python3 "$BRIDGE")
assert_not_blocked "$SIBLING_OUTPUT"
echo "  PASS: demo-other add does not match the demo/ probe"

echo "Test 5f: adding a different file under references/ does not false-block"
OTHERFILE_OUTPUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"git add plugins/pokayokay/skills/demo/references/other.md && git commit -m \"other\""},"hook_event_name":"PreToolUse"}' |
  python3 "$BRIDGE")
assert_not_blocked "$OTHERFILE_OUTPUT"
echo "  PASS: sibling file add does not gate the unrelated oversized ref"

echo "Test 5g: trailing-slash directory add still gates the contained ref"
SLASH_OUTPUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"git add plugins/pokayokay/skills/demo/ && git commit -m \"dirslash\""},"hook_event_name":"PreToolUse"}' |
  python3 "$BRIDGE")
assert_deny "$SLASH_OUTPUT"
echo "  PASS: trailing-slash directory add gates the contained oversized reference"

echo "Test 5h: glob pathspec selecting the oversized ref is blocked"
GLOB_OUTPUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"git add plugins/pokayokay/skills/demo/references/*.md && git commit -m \"glob\""},"hook_event_name":"PreToolUse"}' |
  python3 "$BRIDGE")
assert_deny "$GLOB_OUTPUT"
echo "  PASS: glob pathspec matching the oversized reference is gated"

echo "Test 5i: dot-relative directory add gates the contained ref"
DOT_OUTPUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"git add ./plugins/pokayokay/skills/demo && git commit -m \"dot\""},"hook_event_name":"PreToolUse"}' |
  python3 "$BRIDGE")
assert_deny "$DOT_OUTPUT"
echo "  PASS: ./-prefixed pathspec gates the contained oversized reference"

echo "Test 5j: space-free shell separator still bounds the pathspec (dir add)"
NOSPACE_DIR_OUTPUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"git add plugins/pokayokay/skills/demo&&git commit -m ref"},"hook_event_name":"PreToolUse"}' |
  python3 "$BRIDGE")
assert_deny "$NOSPACE_DIR_OUTPUT"
echo "  PASS: && without surrounding spaces still gates the directory add"

echo "Test 5k: space-free separator does not swallow the commit word into the path"
# `git add <file>;git commit` — the ; must terminate the pathspec so the ref
# is still matched by exact path, not merged with the trailing command.
NOSPACE_FILE_OUTPUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"git add plugins/pokayokay/skills/demo/references/big-ref.md;git commit -m ref"},"hook_event_name":"PreToolUse"}' |
  python3 "$BRIDGE")
assert_deny "$NOSPACE_FILE_OUTPUT"
echo "  PASS: ;-separated file add is gated"

echo "Test 5l: glob under a sibling directory does not false-block"
SIBLING_GLOB_OUTPUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"git add plugins/pokayokay/skills/demo-other/*.md && git commit -m \"sibglob\""},"hook_event_name":"PreToolUse"}' |
  python3 "$BRIDGE")
assert_not_blocked "$SIBLING_GLOB_OUTPUT"
echo "  PASS: glob under demo-other does not match the demo/ reference"

echo "Test 5m: commit message mentioning a ref path does not false-block an unrelated add"
# bridge.py neutralizes && -> spaces, so the pathspec region cannot rely on
# separators. The message must NOT be scanned as a pathspec: `git add src.txt`
# is unrelated to the oversized ref merely named in the commit message.
echo "unrelated" > src.txt
git add src.txt
MSG_OUTPUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"git add src.txt && git commit -m \"fix plugins/pokayokay/skills/demo/references/big-ref.md\""},"hook_event_name":"PreToolUse"}' |
  python3 "$BRIDGE")
assert_not_blocked "$MSG_OUTPUT"
echo "  PASS: ref path in the commit message does not gate an unrelated add"
git rm -q --cached src.txt
rm -f src.txt

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
