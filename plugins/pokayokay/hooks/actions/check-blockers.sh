#!/bin/bash
# Check for blockers before starting a task
# Called by: pre-task hooks
# Environment: TASK_ID

set -e

echo "Checking blockers for task ${TASK_ID:-unknown}..."

# Try to get blocked tasks via CLI if available.
# --no-install avoids a slow on-demand package download blowing the hook
# timeout. The if-guard separates the CLI's exit status from the head
# truncation (and keeps set -e from aborting), so a failed CLI call reports
# "unavailable" instead of a false "No blocked tasks".
if command -v npx &> /dev/null; then
  if BLOCKED=$(npx --no-install @stevestomp/ohno-cli tasks --status blocked 2>/dev/null); then
    BLOCKED=$(printf '%s\n' "$BLOCKED" | head -5)
    if [ -n "$BLOCKED" ]; then
      echo "WARNING: There are blocked tasks:"
      echo "$BLOCKED"
    else
      echo "No blocked tasks"
    fi
  else
    echo "Blocker check unavailable (ohno CLI not installed or errored)"
  fi
else
  echo "ohno CLI not available, skipping blocker check"
fi