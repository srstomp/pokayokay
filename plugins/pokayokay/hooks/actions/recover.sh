#!/bin/bash
# Attempt to recover from errors
# Called by: on-error hooks

echo "Attempting recovery..."

# Check git state
if ! git diff --quiet; then
  echo "Stashing uncommitted changes..."
  git stash push -m "yokay-recovery-$(date +%s)"
  echo "✓ Changes stashed"
fi

# Check for broken builds
if [ -f "package.json" ]; then
  if bun run build 2>/dev/null; then
    echo "✓ Build passes"
  else
    echo "⚠️ Build still failing after recovery"
    echo "Manual intervention may be needed"
  fi
fi

echo "Recovery attempt complete"
