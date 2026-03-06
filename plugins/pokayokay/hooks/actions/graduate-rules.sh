#!/bin/bash
# Graduate recurring failure patterns to .claude/rules/ files
# Called by: bridge.py when failure count >= threshold
# Environment: CLAUDE_PROJECT_DIR, CATEGORY, PATTERN_DESCRIPTION, AFFECTED_PATHS, FAILURE_COUNT
#              AGENT_NAME (optional) - target agent for agent-specific rules
#              ROOT_CAUSE (optional) - vague-criterion|missing-test|shallow-review|missing-edge-case
# Output: Creates/updates .claude/rules/pokayokay/<category>.md (or <agent>-<category>.md)

set -e

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
CATEGORY="${CATEGORY:-}"
PATTERN="${PATTERN_DESCRIPTION:-}"
PATHS="${AFFECTED_PATHS:-}"
COUNT="${FAILURE_COUNT:-0}"
AGENT="${AGENT_NAME:-}"
ROOT_CAUSE="${ROOT_CAUSE:-}"

# Sanitize inputs to prevent path traversal
CATEGORY=$(basename "$CATEGORY" | sed 's/[^a-zA-Z0-9_-]//g')
AGENT=$(echo "$AGENT" | sed 's/[^a-zA-Z0-9_-]//g')
if [ -z "$CATEGORY" ]; then
  exit 0
fi

if [ -z "$PATTERN" ]; then
  exit 0
fi

# Convert category to filename (missing_tests -> missing-tests)
# If agent specified, prefix filename for agent-targeted rules
BASE_CATEGORY=$(echo "$CATEGORY" | tr '_' '-')
if [ -n "$AGENT" ]; then
  FILENAME="${AGENT}-${BASE_CATEGORY}"
else
  FILENAME="$BASE_CATEGORY"
fi

# Ensure rules directory exists
RULES_DIR="$PROJECT_DIR/.claude/rules/pokayokay"
mkdir -p "$RULES_DIR"

RULE_FILE="$RULES_DIR/$FILENAME.md"
DATE=$(date +%Y-%m-%d)

if [ -f "$RULE_FILE" ]; then
  # Append new pattern to existing file
  # Check if this exact pattern already exists
  if grep -qF "$PATTERN" "$RULE_FILE" 2>/dev/null; then
    exit 0
  fi
  echo "" >> "$RULE_FILE"
  ROOT_SUFFIX=""
  [ -n "$ROOT_CAUSE" ] && ROOT_SUFFIX=" [root: $ROOT_CAUSE]"
  [ -n "$AGENT" ] && ROOT_SUFFIX="${ROOT_SUFFIX} [agent: $AGENT]"
  echo "- $PATTERN (seen ${COUNT}x, recorded $DATE)${ROOT_SUFFIX}" >> "$RULE_FILE"
  echo "Graduated pattern to $FILENAME.md"
else
  # Create new rule file
  DISPLAY_NAME=$(echo "$CATEGORY" | tr '_' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')

  if [ -n "$PATHS" ]; then
    {
      echo "---"
      echo "paths:"
      echo "  - \"$PATHS\""
      echo "---"
      echo ""
      echo "# $DISPLAY_NAME Rules"
      echo ""
      echo "Patterns detected from recurring review failures (auto-graduated by pokayokay)."
      echo ""
      ROOT_SUFFIX=""
      [ -n "$ROOT_CAUSE" ] && ROOT_SUFFIX=" [root: $ROOT_CAUSE]"
      [ -n "$AGENT" ] && ROOT_SUFFIX="${ROOT_SUFFIX} [agent: $AGENT]"
      echo "- $PATTERN (seen ${COUNT}x, recorded $DATE)${ROOT_SUFFIX}"
    } > "$RULE_FILE"
  else
    {
      echo "# $DISPLAY_NAME Rules"
      echo ""
      echo "Patterns detected from recurring review failures (auto-graduated by pokayokay)."
      echo ""
      ROOT_SUFFIX=""
      [ -n "$ROOT_CAUSE" ] && ROOT_SUFFIX=" [root: $ROOT_CAUSE]"
      [ -n "$AGENT" ] && ROOT_SUFFIX="${ROOT_SUFFIX} [agent: $AGENT]"
      echo "- $PATTERN (seen ${COUNT}x, recorded $DATE)${ROOT_SUFFIX}"
    } > "$RULE_FILE"
  fi
  echo "Graduated pattern to $FILENAME.md"
fi
