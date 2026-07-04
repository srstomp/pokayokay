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

warn_no_tasks() {
    # No tasks found - this is a warning, not an error
    echo "Warning: No tasks with prefix '$TASK_PREFIX' found after running $SKILL_NAME"
    echo ""
    echo "Expected: Audit commands should create tasks for findings."
    echo "Action: If findings were discovered, ensure tasks were created using ohno MCP create_task."
    echo ""
    echo "If no issues were found, this warning can be ignored."
    exit 0  # Exit 0 (warning) not 1 (error) - don't block the session
}

OHNO_DB=".ohno/tasks.db"

# Preferred check: query SQLite directly for tasks created in the last
# 5 minutes (the CLI's output carries no created_at field, so a recency
# window is only possible against the database).
if command -v sqlite3 > /dev/null 2>&1 && [ -f "$OHNO_DB" ] && [ -n "$TASK_PREFIX" ]; then
    # Escape single quotes for SQL and LIKE wildcards (% _) for the pattern.
    # datetime(created_at) normalizes ohno's ISO-8601 'T'/'Z' timestamps so
    # they compare correctly against datetime('now', ...) (both UTC).
    ESCAPED_PREFIX=$(printf '%s' "$TASK_PREFIX" | sed -e "s/'/''/g" -e 's/[%_]/\\&/g')
    MATCH_COUNT=$(sqlite3 "$OHNO_DB" \
        "SELECT COUNT(*) FROM tasks WHERE title LIKE '${ESCAPED_PREFIX}%' ESCAPE '\' AND datetime(created_at) >= datetime('now','-5 minutes') AND status != 'archived';" \
        2>/dev/null || echo "")

    if [ -n "$MATCH_COUNT" ]; then
        if [ "$MATCH_COUNT" -gt 0 ] 2>/dev/null; then
            echo "Verified: $MATCH_COUNT task(s) created with prefix '$TASK_PREFIX' in the last 5 minutes"
            exit 0
        else
            warn_no_tasks
        fi
    fi
    # Query failed (schema mismatch, locked DB, ...) - fall through to CLI
fi

# Fallback: recency-blind check via the CLI. This only verifies that tasks
# with the expected prefix exist at all - it cannot tell fresh tasks from
# stale ones, since the CLI output has no created_at field.
RECENT_TASKS=$(npx @stevestomp/ohno-cli tasks --limit 10 2>/dev/null || echo "")

# Check if any tasks with the expected prefix exist
# Use grep -F for fixed-string matching to prevent regex injection
if echo "$RECENT_TASKS" | grep -qF "$TASK_PREFIX"; then
    # Count matching tasks
    MATCH_COUNT=$(echo "$RECENT_TASKS" | grep -cF "$TASK_PREFIX" || echo "0")
    echo "Verified: $MATCH_COUNT task(s) found with prefix '$TASK_PREFIX' (recency unknown - sqlite3 unavailable)"
    exit 0
else
    warn_no_tasks
fi
