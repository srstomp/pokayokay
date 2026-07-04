#!/usr/bin/env bash
# Validate story-integration.sh (story-boundary integration tests):
# - skips cleanly (exit 0 + skip JSON) when STORY_ID is missing, when
#   WORKTREE_DIR does not exist, when no test runner is detected, and when
#   pyproject.toml declares pytest but pytest is not importable
# - honors WORKTREE_DIR: the runner executes inside the story worktree,
#   not the hook's cwd
# - emits pass JSON on success, fail JSON + exit 1 on test failure

set -euo pipefail

TEST_DIR=$(mktemp -d)
trap 'rm -rf -- "$TEST_DIR"' EXIT

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/hooks/actions/story-integration.sh"
[ -f "$SCRIPT" ] || { echo "script not found: $SCRIPT"; exit 1; }

echo "Testing story-integration.sh..."

if bash -n "$SCRIPT"; then
  echo "  PASS: script parses (bash -n)"
else
  echo "  FAIL: bash -n reports a syntax error"
  exit 1
fi

# Mock npx: logs its physical cwd plus args; exit code controlled by a flag
MOCK_BIN="$TEST_DIR/bin"
mkdir -p "$MOCK_BIN"
cat > "$MOCK_BIN/npx" << EOF
#!/usr/bin/env bash
echo "\$(pwd -P)|\$*" >> "$TEST_DIR/npx_calls.log"
if [ -f "$TEST_DIR/npx-fail" ]; then
  echo "1 test failed"
  exit 1
fi
echo "all tests passed"
exit 0
EOF
chmod +x "$MOCK_BIN/npx"
export PATH="$MOCK_BIN:$PATH"

cd "$TEST_DIR"

echo "Test 1: missing STORY_ID -> skip"
RC=0
OUTPUT=$(STORY_ID="" WORKTREE_DIR="$TEST_DIR" bash "$SCRIPT") || RC=$?
if [ "$RC" -eq 0 ] && [[ "$OUTPUT" == *'"status": "skip"'* ]] && [[ "$OUTPUT" == *"No STORY_ID"* ]]; then
  echo "  PASS: skip JSON when STORY_ID is unset"
else
  echo "  FAIL: expected skip JSON (exit 0), got exit $RC"
  echo "$OUTPUT"
  exit 1
fi

echo "Test 2: missing worktree directory -> skip, not a crash"
RC=0
OUTPUT=$(STORY_ID=s1 WORKTREE_DIR="$TEST_DIR/removed-worktree" bash "$SCRIPT") || RC=$?
if [ "$RC" -eq 0 ] && [[ "$OUTPUT" == *'"status": "skip"'* ]] && [[ "$OUTPUT" == *"Worktree directory not found"* ]]; then
  echo "  PASS: nonexistent WORKTREE_DIR skips instead of dying on cd"
else
  echo "  FAIL: expected skip JSON for missing worktree dir (exit 0), got exit $RC"
  echo "$OUTPUT"
  exit 1
fi

echo "Test 3: no test runner detected -> skip"
mkdir -p "$TEST_DIR/empty-wt"
RC=0
OUTPUT=$(STORY_ID=s1 WORKTREE_DIR="$TEST_DIR/empty-wt" bash "$SCRIPT") || RC=$?
if [ "$RC" -eq 0 ] && [[ "$OUTPUT" == *'"status": "skip"'* ]] && [[ "$OUTPUT" == *"No test runner detected"* ]]; then
  echo "  PASS: skip JSON when no runner config exists"
else
  echo "  FAIL: expected skip JSON for missing runner (exit 0), got exit $RC"
  echo "$OUTPUT"
  exit 1
fi

echo "Test 4: WORKTREE_DIR honored - vitest runs inside the story worktree"
WT="$TEST_DIR/story-wt"
mkdir -p "$WT"
touch "$WT/vitest.config.ts"
RC=0
OUTPUT=$(STORY_ID=s1 WORKTREE_DIR="$WT" bash "$SCRIPT") || RC=$?
if [ "$RC" -eq 0 ] && [[ "$OUTPUT" == *'"status": "pass"'* ]] && [[ "$OUTPUT" == *'"story_id": "s1"'* ]]; then
  echo "  PASS: pass JSON emitted with the story id"
else
  echo "  FAIL: expected pass JSON (exit 0), got exit $RC"
  echo "$OUTPUT"
  exit 1
fi
EXPECTED_PWD="$(cd "$WT" && pwd -P)"
LAST_CALL=$(tail -1 "$TEST_DIR/npx_calls.log")
if [ "$LAST_CALL" = "${EXPECTED_PWD}|vitest run" ]; then
  echo "  PASS: runner executed in the worktree (not the hook cwd)"
else
  echo "  FAIL: expected npx to run 'vitest run' in $EXPECTED_PWD"
  echo "  got: $LAST_CALL"
  exit 1
fi

echo "Test 5: failing suite -> fail JSON + exit 1"
touch "$TEST_DIR/npx-fail"
RC=0
OUTPUT=$(STORY_ID=s1 WORKTREE_DIR="$WT" bash "$SCRIPT") || RC=$?
if [ "$RC" -eq 1 ] && [[ "$OUTPUT" == *'"status": "fail"'* ]] && [[ "$OUTPUT" == *"Integration tests failed"* ]]; then
  echo "  PASS: test failure surfaces as fail JSON with exit 1"
else
  echo "  FAIL: expected fail JSON with exit 1, got exit $RC"
  echo "$OUTPUT"
  exit 1
fi
rm -f "$TEST_DIR/npx-fail"

echo "Test 6: jest config selects the jest runner"
WT_JEST="$TEST_DIR/jest-wt"
mkdir -p "$WT_JEST"
touch "$WT_JEST/jest.config.js"
RC=0
OUTPUT=$(STORY_ID=s2 WORKTREE_DIR="$WT_JEST" bash "$SCRIPT") || RC=$?
LAST_CALL=$(tail -1 "$TEST_DIR/npx_calls.log")
if [ "$RC" -eq 0 ] && [[ "$LAST_CALL" == *"|jest" ]]; then
  echo "  PASS: jest runner selected from jest.config.js"
else
  echo "  FAIL: expected an 'npx jest' invocation, got: $LAST_CALL (exit $RC)"
  echo "$OUTPUT"
  exit 1
fi

echo "Test 7: pyproject.toml with pytest section but pytest missing -> skip"
WT_PY="$TEST_DIR/py-wt"
mkdir -p "$WT_PY"
printf '[tool.pytest.ini_options]\ntestpaths = ["tests"]\n' > "$WT_PY/pyproject.toml"
# Fake python3 that cannot import pytest (exit 1 on any invocation)
FAKE_PY="$TEST_DIR/fakepy"
mkdir -p "$FAKE_PY"
printf '#!/usr/bin/env bash\nexit 1\n' > "$FAKE_PY/python3"
chmod +x "$FAKE_PY/python3"
RC=0
OUTPUT=$(PATH="$FAKE_PY:$PATH" STORY_ID=s3 WORKTREE_DIR="$WT_PY" bash "$SCRIPT") || RC=$?
if [ "$RC" -eq 0 ] && [[ "$OUTPUT" == *'"status": "skip"'* ]] && [[ "$OUTPUT" == *"pytest not installed"* ]]; then
  echo "  PASS: missing pytest skips instead of running a broken command"
else
  echo "  FAIL: expected skip JSON for missing pytest (exit 0), got exit $RC"
  echo "$OUTPUT"
  exit 1
fi

echo ""
echo "All story-integration tests passed!"
