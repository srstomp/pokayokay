#!/bin/bash
# Smart git commit with conventional message
# Called by: post-task hooks

set -e

# Check if there are changes to commit
if git diff --cached --quiet && git diff --quiet; then
  echo "✓ Nothing to commit"
  exit 0
fi

# Check for sensitive files before staging.
# Parse `git status --porcelain -z` null-delimited so paths containing
# spaces or special characters are handled correctly. Rename/copy entries
# (status R*/C*) emit TWO null-terminated fields (XY dest\0orig\0); the
# extra original-path field must be consumed or it gets misparsed as a
# separate entry. The destination path is what gets committed, so that is
# what the sensitive checks run against. --untracked-files=all expands
# untracked directories (otherwise "?? dir/" hides a nested .env).
#
# Sensitive file patterns (case-insensitive for .env variations)
# Pattern matches:
# - .env (exact filename, case-insensitive)
# - credentials or credentials.json (exact)
# - secrets, secrets.json, secrets.yaml, secrets.yml (exact)
# - id_rsa (exact, not id_rsa.pub)
# Uses (^|/) to match start of path or after directory separator
# Uses $ to ensure exact match (no suffixes allowed)
SENSITIVE_FILES=()
SENSITIVE_LINKS=()
while IFS= read -r -d '' entry; do
  [ -n "$entry" ] || continue
  STATUS="${entry:0:2}"
  FILE_PATH="${entry:3}"

  # Rename/copy entries carry a second field (the original path) - consume it
  case "$STATUS" in
    *R*|*C*)
      IFS= read -r -d '' _orig_path || true
      ;;
  esac

  # Only consider added/modified/renamed/copied/untracked entries
  case "${STATUS:0:1}" in
    A|M|R|C|"?"|" ") ;;
    *) continue ;;
  esac

  # Sensitive-pattern match per parsed path (case-insensitive for .env)
  if printf '%s\n' "$FILE_PATH" | grep -qiE '(^|/)\.env$' || \
     printf '%s\n' "$FILE_PATH" | grep -qE '(^|/)credentials(\.json)?$|(^|/)secrets(\.json|\.ya?ml)?$|(^|/)id_rsa$'; then
    SENSITIVE_FILES+=("$FILE_PATH")
  fi

  # Symbolic links pointing at sensitive files
  if [ -L "$FILE_PATH" ]; then
    TARGET=$(readlink -f "$FILE_PATH" 2>/dev/null || readlink "$FILE_PATH")
    if printf '%s\n' "$TARGET" | grep -qiE '\.env$|credentials|secrets|id_rsa$'; then
      SENSITIVE_LINKS+=("$FILE_PATH -> $TARGET")
    fi
  fi
done < <(git status --porcelain -z --untracked-files=all 2>/dev/null)

if [ ${#SENSITIVE_FILES[@]} -gt 0 ]; then
  echo "⚠️ Sensitive files detected. Review before committing."
  printf '%s\n' "${SENSITIVE_FILES[@]}"
  exit 1
fi

if [ ${#SENSITIVE_LINKS[@]} -gt 0 ]; then
  echo "⚠️ Symbolic link to sensitive file detected:"
  printf '%s\n' "${SENSITIVE_LINKS[@]}"
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

# Read message for display (use printf for safety with special characters)
MESSAGE=$(cat "$COMMIT_FILE")
printf '%s\n' "✓ Committed: $MESSAGE"
