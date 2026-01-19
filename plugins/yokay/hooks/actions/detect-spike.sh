#!/bin/bash
# Detect high-uncertainty signals in task work
# Called by: post-task hooks
# Environment: TASK_ID, TASK_NOTES
# Output: Suggestion to convert to spike if uncertainty detected

set -e

# Uncertainty signal patterns
UNCERTAINTY_PATTERNS=(
  "not sure"
  "might work"
  "need to investigate"
  "unclear"
  "let me research"
  "I don't know"
  "could try"
  "uncertain"
  "need more info"
  "haven't figured out"
)

NOTES="${TASK_NOTES:-}"

# Skip if no notes available
if [ -z "$NOTES" ]; then
  exit 0
fi

# Check for uncertainty signals
NOTES_LOWER=$(echo "$NOTES" | tr '[:upper:]' '[:lower:]')
FOUND_SIGNAL=""

for pattern in "${UNCERTAINTY_PATTERNS[@]}"; do
  if echo "$NOTES_LOWER" | grep -q "$pattern"; then
    FOUND_SIGNAL="$pattern"
    break
  fi
done

if [ -n "$FOUND_SIGNAL" ]; then
  echo ""
  echo "## Uncertainty Detected"
  echo ""
  echo "Task notes contain uncertainty signals: \"$FOUND_SIGNAL\""
  echo ""
  echo "**Consider**: Convert to spike with \`/pokayokay:spike <question>\`"
  echo "Spikes provide structured time-boxed investigation with mandatory conclusions."
  echo ""
fi
