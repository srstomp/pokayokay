#!/bin/bash
# Run tests safely (don't fail if no tests)
# Called by: post-story, auto-mode post-task hooks
# Environment: WORKTREE_DIR (optional) - story worktree to run tests in

# Parse arguments
BAIL=""
for arg in "$@"; do
  case $arg in
    --bail) BAIL="--bail" ;;
  esac
done

# Story-boundary runs execute inside the story worktree (bridge.py also sets
# cwd); cd defensively in case the script is invoked with only the env var.
if [ -n "${WORKTREE_DIR:-}" ] && [ -d "$WORKTREE_DIR" ]; then
  cd "$WORKTREE_DIR" || true
fi

# Detect test runner
if [ -f "package.json" ]; then
  if grep -q '"test"' package.json; then
    echo "Running tests..."

    # Build command
    CMD="npm test"
    [ -n "$BAIL" ] && CMD="$CMD -- --bail"

    # Run tests, but don't fail the hook on test failure. Capture stdout AND
    # stderr (runners write failure detail to stderr) while preserving the
    # runner's exit status for the pass/fail decision.
    if OUTPUT=$($CMD 2>&1); then
      echo "✓ Tests passed"
    else
      echo "⚠️ Tests failed (continuing)"
      echo "$OUTPUT" | tail -40
    fi
  else
    echo "✓ No test script defined, skipping"
  fi
else
  echo "✓ No package.json, skipping tests"
fi
