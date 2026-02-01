#!/bin/bash
# Print prominent mini-audit summary after story completion
# Called by: post-story hooks (after mini-audit)
# Environment: STORY_ID, STORY_TITLE, AUDIT_L_LEVEL, AUDIT_T_LEVEL, AUDIT_L_GAP, AUDIT_T_GAP, REMEDIATION_COUNT

set -e

# Print story completion banner
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  STORY COMPLETE: ${STORY_TITLE:-${STORY_ID:-Unknown}}"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Print mini-audit results if available
if [ -n "$AUDIT_L_LEVEL" ] || [ -n "$AUDIT_T_LEVEL" ]; then
  echo "Mini-Audit Results:"
  echo ""

  # Accessibility level
  if [ -n "$AUDIT_L_LEVEL" ]; then
    if [ -n "$AUDIT_L_GAP" ]; then
      echo "   Accessibility: $AUDIT_L_LEVEL ($AUDIT_L_GAP)"
    else
      echo "   Accessibility: $AUDIT_L_LEVEL"
    fi
  fi

  # Testing level
  if [ -n "$AUDIT_T_LEVEL" ]; then
    if [ -n "$AUDIT_T_GAP" ]; then
      echo "   Testing: $AUDIT_T_LEVEL ($AUDIT_T_GAP)"
    else
      echo "   Testing: $AUDIT_T_LEVEL"
    fi
  fi

  echo ""

  # Remediation tasks
  if [ -n "$REMEDIATION_COUNT" ] && [ "$REMEDIATION_COUNT" -gt 0 ]; then
    echo "   $REMEDIATION_COUNT remediation task(s) created"
    echo ""
  fi
else
  echo "   (Mini-audit results not available)"
  echo ""
fi

echo "═══════════════════════════════════════════════════════════"
echo ""