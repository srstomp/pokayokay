#!/bin/bash
# Check quality thresholds at story/epic boundaries
# Called by: post-story, post-epic hooks
# Environment: STORY_ID, EPIC_ID, BOUNDARY_TYPE (story|epic)
# Output: Warning if quality thresholds not met

set -e

BOUNDARY="${BOUNDARY_TYPE:-story}"

echo "Checking quality gates for ${BOUNDARY}..."

# Define thresholds (L=accessibility, T=testing, D=docs, S=security, O=observability)
# Story boundaries: L3+, T1+, D1+
# Epic boundaries: L4+, T2+, D2+, S2+, O1+

# Check for common quality indicators in the codebase
QUALITY_ISSUES=()

# Check for missing tests (simple heuristic)
if [ -d "src" ]; then
  SRC_FILES=$(find src -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" 2>/dev/null | wc -l || echo "0")
  TEST_FILES=$(find . -name "*.test.*" -o -name "*.spec.*" 2>/dev/null | wc -l || echo "0")

  if [ "$SRC_FILES" -gt 0 ] && [ "$TEST_FILES" -eq 0 ]; then
    QUALITY_ISSUES+=("No test files found (T0)")
  fi
fi

# Check for TODO/FIXME comments in recent changes
TODOS=$(git diff HEAD~5 --name-only -z 2>/dev/null | xargs -0 -r grep -l "TODO\|FIXME" 2>/dev/null | wc -l || echo "0")
if [ "$TODOS" -gt 3 ]; then
  QUALITY_ISSUES+=("$TODOS files with TODO/FIXME in recent changes")
fi

# Check for console.log in production code
CONSOLE_LOGS=$(find src -name "*.ts" -o -name "*.tsx" -print0 2>/dev/null | xargs -0 -r grep -l "console.log" 2>/dev/null | wc -l || echo "0")
if [ "$CONSOLE_LOGS" -gt 5 ]; then
  QUALITY_ISSUES+=("$CONSOLE_LOGS files with console.log (O1)")
fi

# Output results
if [ ${#QUALITY_ISSUES[@]} -gt 0 ]; then
  echo ""
  echo "## Quality Gate Warning"
  echo ""
  echo "The following quality issues were detected at ${BOUNDARY} completion:"
  echo ""
  for issue in "${QUALITY_ISSUES[@]}"; do
    echo "- $issue"
  done
  echo ""
  echo "Consider running \`/pokayokay:audit\` for a full quality assessment."
  echo ""
else
  echo "Quality gates passed"
fi
