#!/bin/bash
# Run tests safely (don't fail if no tests)
# Called by: post-story, auto-mode post-task hooks

# Parse arguments
BAIL=""
RELATED=""
for arg in "$@"; do
  case $arg in
    --bail) BAIL="--bail" ;;
    --related) RELATED="--findRelatedTests" ;;
  esac
done

# Detect test runner
if [ -f "package.json" ]; then
  if grep -q '"test"' package.json; then
    echo "Running tests..."

    # Build command
    CMD="npm test"
    [ -n "$BAIL" ] && CMD="$CMD -- --bail"

    # Run tests, but don't fail the hook on test failure
    if $CMD 2>/dev/null; then
      echo "✓ Tests passed"
    else
      echo "⚠️ Tests failed (continuing)"
    fi
  else
    echo "✓ No test script defined, skipping"
  fi
else
  echo "✓ No package.json, skipping tests"
fi
