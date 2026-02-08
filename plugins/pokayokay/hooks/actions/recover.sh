#!/bin/bash
# Recover from crashed sessions
# Called by: bridge.py handle_session_start when stale chain state detected
#
# Environment:
#   STALE_TASKS     - Comma-separated list of in_progress task IDs from stale session
#   CHAIN_ID        - Chain ID of the stale session (if chained)
#
# Actions:
#   1. Stash uncommitted changes with descriptive message
#   2. Update WIP for in_progress tasks via ohno-cli
#   3. Log crash to ohno task_activity
#   4. Output recovery report

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
STALE_TASKS="${STALE_TASKS:-}"
CHAIN_ID="${CHAIN_ID:-}"
RECOVERED=0

echo "Attempting crash recovery..."

# 1. Stash uncommitted changes
if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
  STASH_MSG="yokay-crash-recovery-$(date +%s)"
  if [ -n "$CHAIN_ID" ]; then
    STASH_MSG="yokay-crash-recovery-${CHAIN_ID}-$(date +%s)"
  fi
  git stash push -m "$STASH_MSG" 2>/dev/null && {
    echo "STASHED=true"
    echo "STASH_MSG=${STASH_MSG}"
    RECOVERED=$((RECOVERED + 1))
  } || echo "STASHED=false"
else
  echo "STASHED=false"
fi

# 2. Update WIP for stale in_progress tasks
if [ -n "$STALE_TASKS" ] && command -v npx &>/dev/null; then
  IFS=',' read -ra TASK_ARRAY <<< "$STALE_TASKS"
  for TASK_ID in "${TASK_ARRAY[@]}"; do
    TASK_ID=$(echo "$TASK_ID" | xargs)  # trim whitespace
    [ -z "$TASK_ID" ] && continue

    # Update WIP with crash info
    WIP_JSON="{\"phase\":\"crashed\",\"errors\":[{\"type\":\"session_crash\",\"message\":\"Session crashed, WIP auto-saved\"}]}"
    npx @stevestomp/ohno-cli update-wip "$TASK_ID" "$WIP_JSON" 2>/dev/null || true

    # Log crash to task activity
    npx @stevestomp/ohno-cli add-activity "$TASK_ID" note "Session crashed. WIP saved, uncommitted changes stashed." 2>/dev/null || true

    echo "TASK_RECOVERED=${TASK_ID}"
    RECOVERED=$((RECOVERED + 1))
  done
fi

# 3. Check for stale worktree locks
if [ -d "${PROJECT_DIR}/.worktrees" ]; then
  for lockfile in "${PROJECT_DIR}"/.worktrees/*/locked 2>/dev/null; do
    [ -f "$lockfile" ] || continue
    echo "STALE_LOCK=${lockfile}"
  done
fi

echo "RECOVERED_COUNT=${RECOVERED}"
echo "Recovery complete"
