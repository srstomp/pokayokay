#!/bin/bash
# Check that reference files in skills/ don't exceed 500 lines
# Called by: pre-commit hooks (via bridge.py handle_pre_commit)

MAX_LINES=500
SKILLS_DIR="plugins/pokayokay/skills"
VIOLATIONS=""
COUNT=0

# Check staged .md files in skills/*/references/
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep "^${SKILLS_DIR}/.*/references/.*\.md$" || true)

if [ -z "$STAGED_FILES" ]; then
  echo "✓ No reference files staged"
  exit 0
fi

for file in $STAGED_FILES; do
  if [ -f "$file" ]; then
    LINES=$(wc -l < "$file")
    if [ "$LINES" -gt "$MAX_LINES" ]; then
      VIOLATIONS="${VIOLATIONS}\n  ${file} (${LINES} lines)"
      COUNT=$((COUNT + 1))
    fi
  fi
done

if [ "$COUNT" -gt 0 ]; then
  echo "ERROR: ${COUNT} reference file(s) exceed ${MAX_LINES}-line limit:${VIOLATIONS}"
  echo ""
  echo "Split oversized files into focused sub-topics and update the skill's SKILL.md reference table."
  exit 1
fi

echo "✓ All ${STAGED_FILES_COUNT:-staged} reference files under ${MAX_LINES} lines"
