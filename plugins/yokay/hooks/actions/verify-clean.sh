#!/bin/bash
# Verify working directory is clean
# Called by: pre-session hooks

set -e

echo "Checking working directory..."

if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  echo "WARNING: Uncommitted changes detected"
  git status --short
  echo ""
  echo "Consider committing or stashing before starting a new session."
  exit 0  # Warning, not error
else
  echo "Working directory clean"
fi