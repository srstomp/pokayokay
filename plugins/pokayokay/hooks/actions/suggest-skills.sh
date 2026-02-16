#!/bin/bash
# Suggest relevant skills based on task content and project memory
# Called by: pre-task hooks
# Environment: TASK_ID, TASK_TITLE, TASK_TYPE, MEMORY_DIR (optional), CLAUDE_PROJECT_DIR
# Output: Skill suggestions and memory context in additionalContext

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

# --- Memory-informed routing ---
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
MEM_DIR="${MEMORY_DIR:-}"
MEMORY_NOTES=()

# Auto-detect memory dir if not set
if [ -z "$MEM_DIR" ]; then
  PROJECT_KEY=$(echo "$PROJECT_DIR" | tr '/' '-' | sed 's/^-//')
  CLAUDE_MEMORY="$HOME/.claude/projects/$PROJECT_KEY/memory"
  if [ -d "$CLAUDE_MEMORY" ]; then
    MEM_DIR="$CLAUDE_MEMORY"
  elif [ -d "$PROJECT_DIR/memory" ]; then
    MEM_DIR="$PROJECT_DIR/memory"
  fi
fi

if [ -n "$MEM_DIR" ] && [ -d "$MEM_DIR" ]; then
  # Check spike results - flag prior investigations
  SPIKE_FILE="$MEM_DIR/spike-results.md"
  if [ -f "$SPIKE_FILE" ] && echo "$TITLE_LOWER" | grep -qE "(investigat|spike|evaluat|should we|feasib)"; then
    for word in $(echo "$TITLE_LOWER" | tr -cs '[:alpha:]' '\n' | sort -u); do
      if [ ${#word} -gt 4 ] && grep -qi "$word" "$SPIKE_FILE" 2>/dev/null; then
        MATCH_LINE=$(grep -i "$word" "$SPIKE_FILE" | head -1)
        MEMORY_NOTES+=("Prior spike found in spike-results.md matching '$word': $MATCH_LINE")
        break
      fi
    done
  fi

  # Check recurring failures - boost relevant skills
  FAILURES_FILE="$MEM_DIR/recurring-failures.md"
  if [ -f "$FAILURES_FILE" ]; then
    if grep -qi "missing.test" "$FAILURES_FILE" 2>/dev/null; then
      SUGGESTIONS+=("testing-strategy")
      MEMORY_NOTES+=("Recurring 'missing tests' failures detected - testing-strategy skill boosted")
    fi
    if grep -qi "missing.error.handling\|error.state" "$FAILURES_FILE" 2>/dev/null; then
      SUGGESTIONS+=("error-handling")
      MEMORY_NOTES+=("Recurring 'error handling' failures detected - error-handling skill boosted")
    fi
    if grep -qi "missing.validation\|input.validation" "$FAILURES_FILE" 2>/dev/null; then
      MEMORY_NOTES+=("Recurring 'missing validation' failures - ensure input validation in implementation")
    fi
  fi
fi

# Check graduated rules
RULES_DIR="$PROJECT_DIR/.claude/rules/pokayokay"
if [ -d "$RULES_DIR" ]; then
  RULE_FILES=$(ls -1 "$RULES_DIR"/*.md 2>/dev/null | xargs -I{} basename {} .md | tr '\n' ', ' | sed 's/,$//')
  if [ -n "$RULE_FILES" ]; then
    MEMORY_NOTES+=("Graduated patterns in .claude/rules/pokayokay/: $RULE_FILES")
  fi
fi

# Deduplicate suggestions
if [ ${#SUGGESTIONS[@]} -gt 0 ]; then
  SUGGESTIONS=($(printf '%s\n' "${SUGGESTIONS[@]}" | sort -u))
fi

# Output suggestions and memory context
if [ ${#SUGGESTIONS[@]} -gt 0 ] || [ ${#MEMORY_NOTES[@]} -gt 0 ]; then
  echo ""
  if [ ${#SUGGESTIONS[@]} -gt 0 ]; then
    echo "## Skill Suggestions"
    echo ""
    echo "Based on task content and project memory, consider loading these additional skills:"
    echo ""
    for skill in "${SUGGESTIONS[@]}"; do
      echo "- \`$skill\`"
    done
  fi
  if [ ${#MEMORY_NOTES[@]} -gt 0 ]; then
    echo ""
    echo "## Memory Context"
    echo ""
    for note in "${MEMORY_NOTES[@]}"; do
      echo "- $note"
    done
  fi
  echo ""
fi
