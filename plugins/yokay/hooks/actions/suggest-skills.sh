#!/bin/bash
# Suggest relevant skills based on task content
# Called by: pre-task hooks
# Environment: TASK_ID, TASK_TITLE, TASK_TYPE
# Output: Skill suggestions in additionalContext

set -e

TITLE="${TASK_TITLE:-}"
TYPE="${TASK_TYPE:-}"

# Skip if no title available
if [ -z "$TITLE" ]; then
  exit 0
fi

TITLE_LOWER=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]')
SUGGESTIONS=()

# Performance-related keywords
if echo "$TITLE_LOWER" | grep -qE "(optimi|slow|latency|cache|memory|bundle|performance|speed)"; then
  SUGGESTIONS+=("performance-optimization")
fi

# Security-related keywords
if echo "$TITLE_LOWER" | grep -qE "(auth|security|permiss|access|encrypt|vulnerab|token|jwt|oauth)"; then
  SUGGESTIONS+=("security-audit")
fi

# Accessibility-related keywords
if echo "$TITLE_LOWER" | grep -qE "(a11y|accessibility|screen.?reader|aria|wcag|keyboard)"; then
  SUGGESTIONS+=("accessibility-auditor")
fi

# Observability-related keywords
if echo "$TITLE_LOWER" | grep -qE "(log|metric|trac|monitor|alert|debug)"; then
  SUGGESTIONS+=("observability")
fi

# Testing-related keywords (beyond testing-strategy already routed)
if echo "$TITLE_LOWER" | grep -qE "(test|spec|coverage|mock|e2e|integration)"; then
  SUGGESTIONS+=("testing-strategy")
fi

# Only output if we have suggestions
if [ ${#SUGGESTIONS[@]} -gt 0 ]; then
  echo ""
  echo "## Skill Suggestions"
  echo ""
  echo "Based on task content, consider loading these additional skills:"
  echo ""
  for skill in "${SUGGESTIONS[@]}"; do
    echo "- \`$skill\`"
  done
  echo ""
fi
