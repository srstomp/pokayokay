#!/usr/bin/env bash
# Validate the ~/.claude/projects key encoding against Claude Code's real
# on-disk format: EVERY non-alphanumeric char becomes "-" and the leading
# dash is kept (e.g. /Users/x/proj/.worktrees/wt -> -Users-x-proj--worktrees-wt).
# Covers bridge.py:_get_memory_dir, suggest-skills.sh auto-detection, and the
# setup-worktree.sh memory symlink.

set -euo pipefail

TEST_DIR=$(mktemp -d)
trap 'rm -rf -- "$TEST_DIR"' EXIT

ACTIONS_DIR="$(cd "$(dirname "$0")/.." && pwd)/hooks/actions"
BRIDGE="$ACTIONS_DIR/bridge.py"

echo "Testing memory project-key encoding..."

# Sandbox HOME so we never touch the real ~/.claude
export HOME="$TEST_DIR/home"
mkdir -p "$HOME"
unset MEMORY_DIR CLAUDE_PROJECT_DIR YOKAY_PROJECT_DIR CODEX_WORKSPACE_DIR 2>/dev/null || true

# Project path with dots and underscores to exercise the full encoding
PROJECT_DIR="$TEST_DIR/my.projects/app_v2"
mkdir -p "$PROJECT_DIR"

# Compute the expected key with an independent implementation
encode_key() {
  python3 -c "import re,sys; print(re.sub(r'[^A-Za-z0-9]', '-', sys.argv[1]))" "$1"
}
PROJECT_KEY=$(encode_key "$PROJECT_DIR")

case "$PROJECT_KEY" in
  -*) : ;;
  *) echo "FAIL: expected key to keep the leading dash, got $PROJECT_KEY"; exit 1 ;;
esac

MAIN_MEMORY="$HOME/.claude/projects/$PROJECT_KEY/memory"
mkdir -p "$MAIN_MEMORY"

echo "Test 1: bridge.py _get_memory_dir resolves the real-format key"
FOUND=$(YOKAY_PROJECT_DIR="$PROJECT_DIR" python3 -c "
import importlib.util
spec = importlib.util.spec_from_file_location('bridge', '$BRIDGE')
bridge = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bridge)
print(bridge._get_memory_dir() or '')
")
if [ "$FOUND" = "$MAIN_MEMORY" ]; then
  echo "  PASS: _get_memory_dir found $PROJECT_KEY"
else
  echo "  FAIL: expected $MAIN_MEMORY, got '$FOUND'"
  exit 1
fi

echo "Test 2: suggest-skills.sh auto-detects the memory dir (encoding + boost)"
cat > "$MAIN_MEMORY/recurring-failures.md" << 'EOF'
# Recurring Review Failures

## Missing Tests (seen 4x)
**Pattern**: Review failures for missing tests
EOF

OUTPUT=$(CLAUDE_PROJECT_DIR="$PROJECT_DIR" TASK_TITLE="Add settings page" TASK_TYPE="feature" \
  bash "$ACTIONS_DIR/suggest-skills.sh" 2>&1)

if echo "$OUTPUT" | grep -qi "recurring 'missing tests' failures"; then
  echo "  PASS: memory-informed routing fired via auto-detected dir"
else
  echo "  FAIL: expected recurring-failures boost from auto-detected memory dir"
  echo "  Output: $OUTPUT"
  exit 1
fi

echo "Test 3: phantom skills are filtered against the plugin skills dir"
FAKE_PLUGIN="$TEST_DIR/fake-plugin"
mkdir -p "$FAKE_PLUGIN/skills/observability"
OUTPUT=$(CLAUDE_PLUGIN_ROOT="$FAKE_PLUGIN" CLAUDE_PROJECT_DIR="$TEST_DIR/nowhere" \
  TASK_TITLE="Fix oauth token logging" TASK_TYPE="bug" \
  bash "$ACTIONS_DIR/suggest-skills.sh" 2>&1)

if echo "$OUTPUT" | grep -q "observability" && ! echo "$OUTPUT" | grep -q "security-audit"; then
  echo "  PASS: existing skill suggested, missing skill filtered out"
else
  echo "  FAIL: expected observability suggested and security-audit filtered"
  echo "  Output: $OUTPUT"
  exit 1
fi

echo "Test 4: setup-worktree.sh symlinks worktree memory with the real key format"
REPO="$TEST_DIR/repo.with_dots"
mkdir -p "$REPO"
cd "$REPO"
git init -q
git config user.email "test@example.com"
git config user.name "Memory Key Test"
echo "seed" > seed.txt
git add seed.txt
git commit -qm "seed"

REPO_KEY=$(encode_key "$REPO")
REPO_MEMORY="$HOME/.claude/projects/$REPO_KEY/memory"
mkdir -p "$REPO_MEMORY"

TASK_ID="t1" TASK_TYPE="feature" TASK_TITLE="Add auth flow" STORY_ID="" \
  FORCE_WORKTREE="" FORCE_INPLACE="" bash "$ACTIONS_DIR/setup-worktree.sh" > "$TEST_DIR/wt-out.txt"

if ! grep -q "MODE=worktree" "$TEST_DIR/wt-out.txt"; then
  echo "  FAIL: worktree was not created"
  cat "$TEST_DIR/wt-out.txt"
  exit 1
fi

WORKTREE_PATH=$(grep '^WORKTREE_PATH=' "$TEST_DIR/wt-out.txt" | cut -d= -f2)
WORKTREE_ABS="$(cd "$REPO/$WORKTREE_PATH" && pwd)"
WORKTREE_KEY=$(encode_key "$WORKTREE_ABS")

# .worktrees dot must become "-" (double dash), key keeps leading dash
case "$WORKTREE_KEY" in
  *"--worktrees-"*) : ;;
  *) echo "  FAIL: expected '--worktrees-' in key, got $WORKTREE_KEY"; exit 1 ;;
esac

WORKTREE_MEMORY="$HOME/.claude/projects/$WORKTREE_KEY/memory"
if [ -L "$WORKTREE_MEMORY" ] && [ "$(readlink "$WORKTREE_MEMORY")" = "$REPO_MEMORY" ]; then
  echo "  PASS: worktree memory symlink created at the real-format key"
else
  echo "  FAIL: expected symlink $WORKTREE_MEMORY -> $REPO_MEMORY"
  ls "$HOME/.claude/projects/" 2>/dev/null || true
  exit 1
fi

echo ""
echo "All memory key encoding tests passed!"
