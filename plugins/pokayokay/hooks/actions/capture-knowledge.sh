#!/bin/bash
# Capture knowledge from spikes and research tasks
# Called by: post-task hooks (when TASK_TYPE is spike or research)
# Environment: TASK_ID, TASK_TYPE, TASK_TITLE, TASK_NOTES
# Output: Suggestions for documentation

set -e

TYPE="${TASK_TYPE:-}"
TITLE="${TASK_TITLE:-}"
NOTES="${TASK_NOTES:-}"

# Validate TASK_TYPE against allowlist (CWE-22: Path Traversal Prevention)
# This prevents malicious task types like "../../../tmp/exploit" from writing outside .claude/
case "$TYPE" in
  spike|research)
    # Valid task types - continue processing
    ;;
  "")
    # Empty task type - exit silently (not an error, just nothing to do)
    exit 0
    ;;
  *)
    # Invalid task type - exit with error
    echo "Error: Invalid task type '$TYPE'. Must be 'spike' or 'research'." >&2
    exit 1
    ;;
esac

# Defense-in-depth: Use basename to strip any path components
# This ensures even if validation is somehow bypassed, path traversal is prevented
SAFE_TYPE=$(basename "$TYPE")

echo "Checking knowledge capture for ${SAFE_TYPE}..."

# Create output directory if needed
KNOWLEDGE_DIR=".claude/${SAFE_TYPE}s"
mkdir -p "$KNOWLEDGE_DIR" 2>/dev/null || true

# Check if output file exists
SAFE_TITLE=$(echo "$TITLE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
DATE=$(date +%Y-%m-%d)
OUTPUT_FILE="${KNOWLEDGE_DIR}/${SAFE_TITLE}-${DATE}.md"

if [ -f "$OUTPUT_FILE" ]; then
  echo "Output file exists: $OUTPUT_FILE"
else
  echo ""
  echo "## Knowledge Capture Reminder"
  echo ""
  echo "This ${SAFE_TYPE} should produce documented findings."
  echo ""
  echo "Expected output: \`$OUTPUT_FILE\`"
  echo ""
fi

# Check for GO decision in notes (spike-specific)
if [ "$SAFE_TYPE" = "spike" ]; then
  NOTES_LOWER=$(echo "$NOTES" | tr '[:upper:]' '[:lower:]')

  if echo "$NOTES_LOWER" | grep -q "go"; then
    echo ""
    echo "## GO Decision Detected"
    echo ""
    echo "Since this spike resulted in a GO decision:"
    echo "1. Ensure implementation tasks are created"
    echo "2. Consider adding findings to PROJECT.md"
    echo "3. Link spike output to related stories"
    echo ""
  elif echo "$NOTES_LOWER" | grep -q "no-go"; then
    echo ""
    echo "## NO-GO Decision Detected"
    echo ""
    echo "Document why this approach was rejected to prevent revisiting."
    echo "Add to: \`.claude/decisions/\` or PROJECT.md"
    echo ""
  fi
fi
