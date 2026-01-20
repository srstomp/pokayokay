#!/bin/bash
# Check for blockers before starting a task
# Called by: pre-task hooks
# Environment: TASK_ID

set -e

echo "Checking blockers for task ${TASK_ID:-unknown}..."

# Try to get blocked tasks via CLI if available
if command -v npx &> /dev/null; then
  BLOCKED=$(npx @stevestomp/ohno-cli tasks --status blocked 2>/dev/null | head -5 || true)
  if [ -n "$BLOCKED" ]; then
    echo "WARNING: There are blocked tasks:"
    echo "$BLOCKED"
  else
    echo "No blocked tasks"
  fi
else
  echo "ohno CLI not available, skipping blocker check"
fi