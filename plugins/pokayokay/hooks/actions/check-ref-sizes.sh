#!/bin/bash
# Check that reference files in skills/ don't exceed 500 lines
# Called by: pre-commit hooks (via bridge.py handle_pre_commit)
#
# Exit-code contract (see HOOKS.md): 0 = success, 1 = warning (advisory),
# 2 = error (blocks the commit). Oversized reference files block.

MAX_LINES=500
SKILLS_DIR="plugins/pokayokay/skills"
REF_PATTERN="^${SKILLS_DIR}/.*/references/.*\.md$"

# Check staged .md files in skills/*/references/
FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep "$REF_PATTERN" || true)
SCOPE="staged"

# The hook fires on PreToolUse for the whole Bash command, so compound
# commands like `git add -A && git commit ...` run this check before anything
# is staged. When no reference files are staged, fall back to scanning
# working-tree changes (modified + untracked) so those commits are gated too.
if [ -z "$FILES" ]; then
  SCOPE="working-tree"
  FILES=$( { git diff --name-only --diff-filter=ACM 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null; } | grep "$REF_PATTERN" | sort -u || true)
fi

if [ -z "$FILES" ]; then
  echo "✓ No reference file changes to check"
  exit 0
fi

VIOLATIONS=""
COUNT=0
CHECKED=0

while IFS= read -r file; do
  [ -f "$file" ] || continue
  CHECKED=$((CHECKED + 1))
  LINES=$(wc -l < "$file")
  if [ "$LINES" -gt "$MAX_LINES" ]; then
    VIOLATIONS="${VIOLATIONS}"$'\n'"  ${file} (${LINES} lines)"
    COUNT=$((COUNT + 1))
  fi
done <<< "$FILES"

if [ "$COUNT" -gt 0 ]; then
  echo "ERROR: ${COUNT} reference file(s) exceed ${MAX_LINES}-line limit:${VIOLATIONS}"
  echo ""
  echo "Split oversized files into focused sub-topics and update the skill's SKILL.md reference table."
  exit 2
fi

echo "✓ All ${CHECKED} ${SCOPE} reference files under ${MAX_LINES} lines"
