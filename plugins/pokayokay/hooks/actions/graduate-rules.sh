#!/bin/bash
# Graduate recurring failure patterns to .claude/rules/ files
# Called by: bridge.py when failure count >= threshold
# Environment: CLAUDE_PROJECT_DIR, CATEGORY, PATTERN_DESCRIPTION, AFFECTED_PATHS, FAILURE_COUNT
# Output: Creates/updates .claude/rules/pokayokay/<category>.md

set -e

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
CATEGORY="${CATEGORY:-}"
PATTERN="${PATTERN_DESCRIPTION:-}"
PATHS="${AFFECTED_PATHS:-}"
COUNT="${FAILURE_COUNT:-0}"

if [ -z "$CATEGORY" ] || [ -z "$PATTERN" ]; then
  exit 0
fi

# Convert category to filename (missing_tests -> missing-tests)
FILENAME=$(echo "$CATEGORY" | tr '_' '-')

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
  echo "- $PATTERN (seen ${COUNT}x, recorded $DATE)" >> "$RULE_FILE"
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
      echo "- $PATTERN (seen ${COUNT}x, recorded $DATE)"
    } > "$RULE_FILE"
  else
    {
      echo "# $DISPLAY_NAME Rules"
      echo ""
      echo "Patterns detected from recurring review failures (auto-graduated by pokayokay)."
      echo ""
      echo "- $PATTERN (seen ${COUNT}x, recorded $DATE)"
    } > "$RULE_FILE"
  fi
fi
