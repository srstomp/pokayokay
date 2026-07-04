#!/usr/bin/env bash
# session-chain.sh - Spawn continuation session when context fills
#
# Environment:
#   CHAIN_ID       - Current chain identifier
#   CHAIN_INDEX    - Current chain session number (0-based)
#   MAX_CHAINS     - Maximum sessions allowed
#   SCOPE_TYPE     - "epic", "story", or "all"
#   SCOPE_ID       - Epic or story ID (empty for "all")
#   TASKS_COMPLETED - Tasks completed this chain
#   CHAIN_AUDITED  - "true" if chain audit already passed
#   REPORT_MODE    - "on_complete", "on_failure", "always", "never"
#   NOTIFY_MODE    - "terminal", "none"
#
# Output: JSON with chain status

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Defaults
CHAIN_INDEX="${CHAIN_INDEX:-0}"
MAX_CHAINS="${MAX_CHAINS:-10}"
SCOPE_TYPE="${SCOPE_TYPE:-}"
REPORT_MODE="${REPORT_MODE:-on_complete}"
NOTIFY_MODE="${NOTIFY_MODE:-terminal}"
TASKS_COMPLETED="${TASKS_COMPLETED:-0}"

# Check if we're in a chain
if [ -z "${CHAIN_ID:-}" ]; then
    echo '{"action": "skip", "reason": "not in a chain"}'
    exit 0
fi

# Check remaining work
# ohno-cli JSON list output is an object {"tasks": [...], "total_count": N}.
# Unscoped chains read total_count (immune to the --limit cap). Scoped chains
# (--epic/--story) count only in-scope rows — an unrelated todo task must not
# keep the chain alive after the scoped work is done; the CLI has no scope
# filter, so filter client-side over a high --limit.
READY_COUNT=0
if command -v npx &>/dev/null; then
    READY_COUNT=$(npx @stevestomp/ohno-cli tasks --status todo --json --limit 1000 2>/dev/null | \
        SCOPE_TYPE="$SCOPE_TYPE" SCOPE_ID="${SCOPE_ID:-}" python3 -c "
import json, os, sys
data = json.load(sys.stdin)
scope_type = os.environ.get('SCOPE_TYPE', '')
scope_id = os.environ.get('SCOPE_ID', '')
if scope_type in ('story', 'epic') and scope_id:
    key = 'story_id' if scope_type == 'story' else 'epic_id'
    print(sum(1 for t in data.get('tasks', []) if t.get(key) == scope_id))
else:
    print(data.get('total_count', 0))
" 2>/dev/null || echo "0")
fi
# Guard against non-numeric output before -eq tests and JSON interpolation
case "$READY_COUNT" in ''|*[!0-9]*) READY_COUNT=0 ;; esac

# Check if we should continue chaining
NEXT_INDEX=$((CHAIN_INDEX + 1))

if [ "$READY_COUNT" -eq 0 ]; then
    if [ "${CHAIN_AUDITED:-false}" = "true" ]; then
        ACTION="complete"
    else
        ACTION="audit_pending"
    fi
elif [ "$NEXT_INDEX" -ge "$MAX_CHAINS" ]; then
    # Hit chain limit
    ACTION="limit_reached"
else
    # More work available, chain to next session
    ACTION="continue"
fi

# Generate report if configured
REPORT_PATH=""
if [ "$ACTION" != "continue" ] && [ "$ACTION" != "audit_pending" ]; then
    # Chain is ending - check if we should report
    SHOULD_REPORT=false
    case "$REPORT_MODE" in
        always) SHOULD_REPORT=true ;;
        on_complete) [ "$ACTION" = "complete" ] && SHOULD_REPORT=true ;;
        on_failure) [ "$ACTION" = "limit_reached" ] && SHOULD_REPORT=true ;;
        never) ;;
    esac

    if [ "$SHOULD_REPORT" = true ]; then
        # Ensure reports directory exists
        REPORTS_DIR="${PROJECT_DIR}/.ohno/reports"
        mkdir -p "$REPORTS_DIR"

        REPORT_PATH="${REPORTS_DIR}/chain-${CHAIN_ID}-report.md"

        # Build scope description
        SCOPE_DESC="all tasks"
        if [ "$SCOPE_TYPE" = "epic" ] && [ -n "${SCOPE_ID:-}" ]; then
            SCOPE_DESC="epic ${SCOPE_ID}"
        elif [ "$SCOPE_TYPE" = "story" ] && [ -n "${SCOPE_ID:-}" ]; then
            SCOPE_DESC="story ${SCOPE_ID}"
        fi

        # Build report header
        cat > "$REPORT_PATH" <<REPORT
# Session Chain Report

- **Chain ID**: ${CHAIN_ID}
- **Sessions**: ${NEXT_INDEX}
- **Scope**: ${SCOPE_DESC}
- **Tasks completed**: ${TASKS_COMPLETED}
- **Tasks remaining**: ${READY_COUNT}
- **Status**: ${ACTION}
- **Generated**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Chain Outcome

$([ "$ACTION" = "complete" ] && echo "All tasks in scope completed successfully." || echo "Chain limit reached (${MAX_CHAINS} sessions). ${READY_COUNT} tasks remaining.")
REPORT

        # Enrich report with task handoff summaries
        # ohno-cli list output is an object {"tasks": [...], "total_count": N};
        # task rows already carry handoff_notes (no separate handoff command).
        if command -v npx &>/dev/null; then
            # Get completed tasks and their handoffs
            DONE_TASKS=$(npx @stevestomp/ohno-cli tasks --status done --json 2>/dev/null || echo '{"tasks":[]}')
            DONE_LINES=$(echo "$DONE_TASKS" | python3 -c "
import json, sys
try:
    tasks = json.load(sys.stdin).get('tasks', [])
    for t in tasks[:50]:  # Cap at 50
        tid = t.get('id', '')
        title = t.get('title', 'Unknown')
        handoff = (t.get('handoff_notes') or '').strip()
        handoff = handoff.splitlines()[0] if handoff else 'No handoff'
        print(f'- **{tid}**: {title} — {handoff}')
except Exception:
    pass
" 2>/dev/null || true)
            if [ -n "$DONE_LINES" ]; then
                {
                    echo ""
                    echo "## Completed Tasks"
                    echo ""
                    echo "$DONE_LINES"
                } >> "$REPORT_PATH"
            fi

            # Add failed/blocked tasks
            BLOCKED_TASKS=$(npx @stevestomp/ohno-cli tasks --status blocked --json 2>/dev/null || echo '{"tasks":[]}')
            BLOCKED_LINES=$(echo "$BLOCKED_TASKS" | python3 -c "
import json, sys
try:
    tasks = json.load(sys.stdin).get('tasks', [])
    for t in tasks:
        tid = t.get('id', '')
        title = t.get('title', 'Unknown')
        reason = t.get('blocker_reason', t.get('blockers', 'Unknown reason'))
        print(f'- **{tid}**: {title} — Blocked: {reason}')
except Exception:
    pass
" 2>/dev/null || true)
            if [ -n "$BLOCKED_LINES" ]; then
                {
                    echo ""
                    echo "## Blocked Tasks"
                    echo ""
                    echo "$BLOCKED_LINES"
                } >> "$REPORT_PATH"
            fi
        fi
    fi

    # Notify if configured
    if [ "$NOTIFY_MODE" = "terminal" ]; then
        if [ "$ACTION" = "complete" ]; then
            echo "Chain ${CHAIN_ID} complete: ${TASKS_COMPLETED} tasks done" >&2
        else
            echo "Chain ${CHAIN_ID} stopped at limit: ${TASKS_COMPLETED} tasks done, ${READY_COUNT} remaining" >&2
        fi
    fi
fi

# Build scope flag for continuation
SCOPE_FLAG=""
if [ "$SCOPE_TYPE" = "epic" ] && [ -n "${SCOPE_ID:-}" ]; then
    SCOPE_FLAG="--epic ${SCOPE_ID}"
elif [ "$SCOPE_TYPE" = "story" ] && [ -n "${SCOPE_ID:-}" ]; then
    SCOPE_FLAG="--story ${SCOPE_ID}"
elif [ "$SCOPE_TYPE" = "all" ]; then
    SCOPE_FLAG="--all"
fi

# Output result
cat <<EOF
{
  "action": "${ACTION}",
  "chain_id": "${CHAIN_ID}",
  "chain_index": ${NEXT_INDEX},
  "max_chains": ${MAX_CHAINS},
  "tasks_completed": ${TASKS_COMPLETED},
  "tasks_remaining": ${READY_COUNT},
  "report_path": "${REPORT_PATH}",
  "continue_command": "claude -p \"/work --continue ${SCOPE_FLAG}\"",
  "scope_flag": "${SCOPE_FLAG}"
}
EOF
