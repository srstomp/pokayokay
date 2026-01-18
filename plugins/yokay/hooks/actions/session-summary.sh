#!/bin/bash
# Print session summary
# Called by: post-session hooks

echo ""
echo "========================================"
echo "SESSION COMPLETE"
echo "========================================"
echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"

# Show recent commits from this session (last hour)
RECENT_COMMITS=$(git log --oneline --since="1 hour ago" 2>/dev/null | head -5 || true)
if [ -n "$RECENT_COMMITS" ]; then
  echo ""
  echo "Recent commits:"
  echo "$RECENT_COMMITS"
fi

# Show any uncommitted changes
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  echo ""
  echo "WARNING: Uncommitted changes remain:"
  git status --short
fi

echo "========================================"