#!/bin/bash
# verify-tasks.sh - Verify that audit commands created expected tasks
#
# Environment variables:
#   SKILL_NAME   - Name of the skill that was run
#   SKILL_ARGS   - Arguments passed to the skill
#   TASK_PREFIX  - Expected prefix for created tasks (e.g., "Security:", "A11y:")

set -euo pipefail

SKILL_NAME="${SKILL_NAME:-unknown}"
SKILL_ARGS="${SKILL_ARGS:-}"
TASK_PREFIX="${TASK_PREFIX:-}"

# Get recent tasks from ohno (last 10 created in the last 5 minutes)
# We use the CLI to check for recently created tasks with the expected prefix
RECENT_TASKS=$(npx @stevestomp/ohno-cli tasks --limit 10 2>/dev/null || echo "")

# Check if any tasks with the expected prefix were created
# Use grep -F for fixed-string matching to prevent regex injection
if echo "$RECENT_TASKS" | grep -qF "$TASK_PREFIX"; then
    # Count matching tasks
    MATCH_COUNT=$(echo "$RECENT_TASKS" | grep -cF "$TASK_PREFIX" || echo "0")
    echo "Verified: $MATCH_COUNT task(s) created with prefix '$TASK_PREFIX'"
    exit 0
else
    # No tasks found - this is a warning, not an error
    echo "Warning: No tasks with prefix '$TASK_PREFIX' found after running $SKILL_NAME"
    echo ""
    echo "Expected: Audit commands should create tasks for findings."
    echo "Action: If findings were discovered, ensure tasks were created using ohno MCP create_task."
    echo ""
    echo "If no issues were found, this warning can be ignored."
    exit 0  # Exit 0 (warning) not 1 (error) - don't block the session
fi
