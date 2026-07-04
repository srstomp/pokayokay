#!/usr/bin/env bash
# story-integration.sh — Run integration tests when a story completes
#
# Triggered by bridge.py when update_task_status(done) reports story_completed.
# Runs the project's test suite to verify story-level integration.

set -euo pipefail

STORY_ID="${STORY_ID:-}"
WORKTREE_DIR="${WORKTREE_DIR:-$(pwd)}"

if [ -z "$STORY_ID" ]; then
  echo '{"status": "skip", "reason": "No STORY_ID provided"}'
  exit 0
fi

# WORKTREE_DIR may point at a worktree that was already removed — skip
# instead of dying on cd under set -euo pipefail.
if [ ! -d "$WORKTREE_DIR" ]; then
  echo "{\"status\": \"skip\", \"reason\": \"Worktree directory not found: $WORKTREE_DIR\"}"
  exit 0
fi

cd "$WORKTREE_DIR"

# Detect test runner
if [ -f "vitest.config.ts" ] || [ -f "vitest.config.js" ]; then
  TEST_CMD="npx vitest run"
elif [ -f "jest.config.ts" ] || [ -f "jest.config.js" ]; then
  TEST_CMD="npx jest"
elif [ -f "pytest.ini" ] || { [ -f "pyproject.toml" ] && grep -q '^\[tool\.pytest' pyproject.toml; }; then
  # pyproject.toml alone doesn't imply pytest (may only carry black/ruff/
  # poetry config), and macOS ships python3 with no `python` binary — gate
  # on pytest actually being importable before committing to the runner.
  if command -v python3 >/dev/null 2>&1 && python3 -c 'import pytest' 2>/dev/null; then
    TEST_CMD="python3 -m pytest"
  else
    echo '{"status": "skip", "reason": "pytest not installed"}'
    exit 0
  fi
else
  echo '{"status": "skip", "reason": "No test runner detected"}'
  exit 0
fi

# Run full test suite
echo "Running integration tests for story $STORY_ID..."
if $TEST_CMD 2>&1; then
  echo "{\"status\": \"pass\", \"story_id\": \"$STORY_ID\"}"
else
  echo "{\"status\": \"fail\", \"story_id\": \"$STORY_ID\", \"reason\": \"Integration tests failed\"}"
  exit 1
fi
