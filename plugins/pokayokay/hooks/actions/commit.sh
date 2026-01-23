#!/bin/bash
# Smart git commit with conventional message
# Called by: post-task hooks

set -e

# Check if there are changes to commit
if git diff --cached --quiet && git diff --quiet; then
  echo "✓ Nothing to commit"
  exit 0
fi

# Check for sensitive files before staging
CHANGED_FILES=$(git status --porcelain | grep -E '^[AM? ]' | cut -c 4-)
if echo "$CHANGED_FILES" | grep -qE '\.env|credentials|secrets|id_rsa'; then
  echo "⚠️ Sensitive files detected. Review before committing."
  echo "$CHANGED_FILES" | grep -E '\.env|credentials|secrets|id_rsa'
  exit 1
fi

# Stage only tracked files (prevents accidentally staging new sensitive files)
git add -u

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

# Create temporary file for commit message
COMMIT_FILE=$(mktemp)
trap "rm -f $COMMIT_FILE" EXIT

# Build message in temporary file using heredoc
if [ -n "$SCOPE" ]; then
  if [ -n "$TASK_ID" ]; then
    cat > "$COMMIT_FILE" <<EOF
${TYPE}(${SCOPE}): ${TASK_TITLE}

Task: ${TASK_ID}
EOF
  else
    cat > "$COMMIT_FILE" <<EOF
${TYPE}(${SCOPE}): ${TASK_TITLE}
EOF
  fi
else
  if [ -n "$TASK_ID" ]; then
    cat > "$COMMIT_FILE" <<EOF
${TYPE}: ${TASK_TITLE}

Task: ${TASK_ID}
EOF
  else
    cat > "$COMMIT_FILE" <<EOF
${TYPE}: ${TASK_TITLE}
EOF
  fi
fi

# Commit using file
git commit -F "$COMMIT_FILE"

# Read message for display
MESSAGE=$(cat "$COMMIT_FILE")
echo "✓ Committed: $MESSAGE"
