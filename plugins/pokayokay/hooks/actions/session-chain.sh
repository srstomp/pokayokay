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
READY_COUNT=0
if command -v npx &>/dev/null; then
    READY_COUNT=$(npx @stevestomp/ohno-cli get-ready-count 2>/dev/null || echo "0")
fi

# Check if we should continue chaining
NEXT_INDEX=$((CHAIN_INDEX + 1))

if [ "$READY_COUNT" -eq 0 ]; then
    # No more work - chain complete
    ACTION="complete"
elif [ "$NEXT_INDEX" -ge "$MAX_CHAINS" ]; then
    # Hit chain limit
    ACTION="limit_reached"
else
    # More work available, chain to next session
    ACTION="continue"
fi

# Generate report if configured
REPORT_PATH=""
if [ "$ACTION" != "continue" ]; then
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
        if command -v npx &>/dev/null; then
            # Get completed tasks and their handoffs
            DONE_TASKS=$(npx @stevestomp/ohno-cli list --status done --format json 2>/dev/null || echo "[]")
            if [ "$DONE_TASKS" != "[]" ] && [ -n "$DONE_TASKS" ]; then
                echo "" >> "$REPORT_PATH"
                echo "## Completed Tasks" >> "$REPORT_PATH"
                echo "" >> "$REPORT_PATH"

                # Parse task IDs and titles, get handoff for each
                echo "$DONE_TASKS" | python3 -c "
import json, sys, subprocess
try:
    tasks = json.load(sys.stdin)
    if isinstance(tasks, list):
        for t in tasks[:50]:  # Cap at 50
            tid = t.get('id', '')
            title = t.get('title', 'Unknown')
            # Try to get handoff summary
            try:
                result = subprocess.run(
                    ['npx', '@stevestomp/ohno-cli', 'get-handoff', tid, '--format', 'brief'],
                    capture_output=True, text=True, timeout=5
                )
                handoff = result.stdout.strip() if result.returncode == 0 else 'No handoff'
            except Exception:
                handoff = 'No handoff'
            print(f'- **{tid}**: {title} — {handoff}')
except Exception:
    pass
" >> "$REPORT_PATH" 2>/dev/null || true

                # Add failed/blocked tasks
                BLOCKED_TASKS=$(npx @stevestomp/ohno-cli list --status blocked --format json 2>/dev/null || echo "[]")
                if [ "$BLOCKED_TASKS" != "[]" ] && [ -n "$BLOCKED_TASKS" ]; then
                    echo "" >> "$REPORT_PATH"
                    echo "## Blocked Tasks" >> "$REPORT_PATH"
                    echo "" >> "$REPORT_PATH"
                    echo "$BLOCKED_TASKS" | python3 -c "
import json, sys
try:
    tasks = json.load(sys.stdin)
    if isinstance(tasks, list):
        for t in tasks:
            tid = t.get('id', '')
            title = t.get('title', 'Unknown')
            reason = t.get('blocker_reason', t.get('blockers', 'Unknown reason'))
            print(f'- **{tid}**: {title} — Blocked: {reason}')
except Exception:
    pass
" >> "$REPORT_PATH" 2>/dev/null || true
                fi
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
  "continue_command": "claude --headless --prompt=\"/work --continue ${SCOPE_FLAG}\"",
  "scope_flag": "${SCOPE_FLAG}"
}
EOF
