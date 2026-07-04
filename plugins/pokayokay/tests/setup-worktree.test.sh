#!/usr/bin/env bash
# Validate setup-worktree.sh task routing:
# - feature/bug/spike (and unknown types) get isolated worktrees,
#   chore/docs run in-place
# - FORCE_INPLACE / FORCE_WORKTREE override the type defaults
# - story tasks reuse the existing story worktree
# - base branch is resolved from the repo (current branch when origin/HEAD
#   is absent), never a hardcoded "main"
# - an existing branch without a worktree degrades to in-place

set -euo pipefail

TEST_DIR=$(mktemp -d)
trap 'rm -rf -- "$TEST_DIR"' EXIT

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/hooks/actions/setup-worktree.sh"
[ -f "$SCRIPT" ] || { echo "script not found: $SCRIPT"; exit 1; }

echo "Testing setup-worktree.sh..."

if bash -n "$SCRIPT"; then
  echo "  PASS: script parses (bash -n)"
else
  echo "  FAIL: bash -n reports a syntax error"
  exit 1
fi

# Sandbox HOME so the memory-symlink step can never touch the real ~/.claude
export HOME="$TEST_DIR/home"
mkdir -p "$HOME"

# Repo on a branch deliberately NOT named "main" (regression: the base-branch
# fallback used to hardcode main), with no origin remote so the
# origin/HEAD -> current-branch fallback chain is exercised.
REPO_DIR="$TEST_DIR/repo"
mkdir -p "$REPO_DIR"
cd "$REPO_DIR"
git init -q
git symbolic-ref HEAD refs/heads/trunk
git config user.email "test@example.com"
git config user.name "Test"
echo "hello" > file.txt
echo ".worktrees/" > .gitignore
git add file.txt .gitignore
git commit -qm "init"

run_script() {
  TASK_ID="$1" TASK_TYPE="$2" TASK_TITLE="$3" STORY_ID="${4:-}" \
    FORCE_WORKTREE="${5:-}" FORCE_INPLACE="${6:-}" bash "$SCRIPT"
}

echo "Test 1: chore and docs tasks run in-place"
for t in chore docs; do
  OUTPUT=$(run_script "t-$t" "$t" "Update something")
  if [[ "$OUTPUT" == *"MODE=in-place"* ]] && [[ "$OUTPUT" == *"REASON=$t task"* ]]; then
    echo "  PASS: $t task routed in-place"
  else
    echo "  FAIL: expected MODE=in-place with REASON=$t task"
    echo "$OUTPUT"
    exit 1
  fi
done

echo "Test 2: feature task gets a worktree with repo-derived base branch"
OUTPUT=$(run_script t3 feature "Add Login Page")
if [[ "$OUTPUT" == *"MODE=worktree"* ]] \
  && [[ "$OUTPUT" == *"WORKTREE_PATH=.worktrees/task-t3-add-login-page"* ]] \
  && [[ "$OUTPUT" == *"WORKTREE_CREATED=true"* ]] \
  && [ -d ".worktrees/task-t3-add-login-page" ]; then
  echo "  PASS: worktree created at .worktrees/task-t3-add-login-page"
else
  echo "  FAIL: expected a created worktree for the feature task"
  echo "$OUTPUT"
  exit 1
fi
if [[ "$OUTPUT" == *"BASE_BRANCH=trunk"* ]]; then
  echo "  PASS: base branch resolved to current branch (trunk), not hardcoded main"
else
  echo "  FAIL: expected BASE_BRANCH=trunk"
  echo "$OUTPUT"
  exit 1
fi

echo "Test 3: bug, spike, and unknown types default to worktree"
for t in bug spike experiment; do
  OUTPUT=$(run_script "t-$t" "$t" "Some $t work")
  if [[ "$OUTPUT" == *"MODE=worktree"* ]] && [[ "$OUTPUT" == *"WORKTREE_CREATED=true"* ]]; then
    echo "  PASS: $t task routed to worktree"
  else
    echo "  FAIL: expected MODE=worktree for $t task"
    echo "$OUTPUT"
    exit 1
  fi
done

echo "Test 4: FORCE_INPLACE overrides a worktree type"
OUTPUT=$(run_script t4 feature "Forced inline" "" "" "true")
if [[ "$OUTPUT" == *"MODE=in-place"* ]] && [[ "$OUTPUT" == *"REASON=--in-place flag"* ]]; then
  echo "  PASS: FORCE_INPLACE=true forces in-place"
else
  echo "  FAIL: expected MODE=in-place with REASON=--in-place flag"
  echo "$OUTPUT"
  exit 1
fi

echo "Test 5: FORCE_WORKTREE overrides an in-place type"
OUTPUT=$(run_script t5 chore "Forced worktree" "" "true" "")
if [[ "$OUTPUT" == *"MODE=worktree"* ]] && [[ "$OUTPUT" == *"WORKTREE_CREATED=true"* ]]; then
  echo "  PASS: FORCE_WORKTREE=true forces a worktree for a chore task"
else
  echo "  FAIL: expected MODE=worktree for forced chore task"
  echo "$OUTPUT"
  exit 1
fi

echo "Test 6: story tasks reuse the story worktree"
OUTPUT=$(run_script t6a feature "First story task" s9)
if [[ "$OUTPUT" == *"WORKTREE_PATH=.worktrees/story-s9-first-story-task"* ]] \
  && [[ "$OUTPUT" == *"WORKTREE_CREATED=true"* ]]; then
  echo "  PASS: first story task created story-s9 worktree"
else
  echo "  FAIL: expected a story-s9 worktree to be created"
  echo "$OUTPUT"
  exit 1
fi
OUTPUT=$(run_script t6b feature "Second story task" s9)
if [[ "$OUTPUT" == *"MODE=worktree"* ]] \
  && [[ "$OUTPUT" == *"WORKTREE_REUSED=true"* ]] \
  && [[ "$OUTPUT" == *"story-s9-first-story-task"* ]]; then
  echo "  PASS: second story task reused the same worktree"
else
  echo "  FAIL: expected WORKTREE_REUSED=true pointing at the story-s9 worktree"
  echo "$OUTPUT"
  exit 1
fi

echo "Test 7: existing branch without a worktree degrades to in-place"
git branch task-t7-fix-thing
OUTPUT=$(run_script t7 feature "Fix Thing")
if [[ "$OUTPUT" == *"MODE=in-place"* ]] && [[ "$OUTPUT" == *"already exists"* ]]; then
  echo "  PASS: pre-existing branch reported, no duplicate worktree attempted"
else
  echo "  FAIL: expected MODE=in-place with an 'already exists' reason"
  echo "$OUTPUT"
  exit 1
fi

echo ""
echo "All setup-worktree tests passed!"
