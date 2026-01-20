#!/bin/bash
# Smart git commit with conventional message
# Called by: post-task hooks

set -e

# Check if there are changes to commit
if git diff --cached --quiet && git diff --quiet; then
  echo "✓ Nothing to commit"
  exit 0
fi

# Stage all changes
git add -A

# Build commit message
TASK_TYPE="${TASK_TYPE:-feat}"
TASK_TITLE="${TASK_TITLE:-update}"
TASK_ID="${TASK_ID:-}"

# Map task types to conventional commit types
case "$TASK_TYPE" in
  feature) TYPE="feat" ;;
  bug)     TYPE="fix" ;;
  chore)   TYPE="chore" ;;
  test)    TYPE="test" ;;
  spike)   TYPE="research" ;;
  *)       TYPE="$TASK_TYPE" ;;
esac

# Extract scope from title (first word in parentheses or before colon)
SCOPE=""
if [[ "$TASK_TITLE" =~ ^([a-zA-Z]+): ]]; then
  SCOPE="${BASH_REMATCH[1]}"
fi

# Build message
if [ -n "$SCOPE" ]; then
  MESSAGE="${TYPE}(${SCOPE}): ${TASK_TITLE}"
else
  MESSAGE="${TYPE}: ${TASK_TITLE}"
fi

# Add task ID if available
if [ -n "$TASK_ID" ]; then
  MESSAGE="${MESSAGE}

Task: ${TASK_ID}"
fi

# Commit
git commit -m "$MESSAGE"

echo "✓ Committed: $MESSAGE"
