#!/bin/bash
# Pre-flight validation for unattended mode
# Called by: bridge.py handle_session_start when mode is unattended
#
# Validates environment readiness before starting an overnight run.
# Reports ALL issues upfront rather than failing mid-session.
#
# Environment:
#   WORK_MODE - Current work mode (unattended, auto, etc.)
#
# Output: key=value pairs, exits non-zero if blocking issues found

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
ISSUES=0
WARNINGS=0

# 1. Git working directory clean
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo "ISSUE=git_dirty"
    echo "DETAIL=Working directory has uncommitted changes"
    ISSUES=$((ISSUES + 1))
else
    echo "CHECK=git_clean OK"
fi

# 2. ohno MCP responsive (try CLI as proxy)
if command -v npx &>/dev/null; then
    if npx @stevestomp/ohno-cli list --limit 1 &>/dev/null; then
        echo "CHECK=ohno_responsive OK"
    else
        echo "ISSUE=ohno_unresponsive"
        echo "DETAIL=ohno-cli failed to respond"
        ISSUES=$((ISSUES + 1))
    fi
else
    echo "WARNING=npx_missing"
    echo "DETAIL=npx not found, cannot verify ohno"
    WARNINGS=$((WARNINGS + 1))
fi

# 3. Tasks available
if command -v npx &>/dev/null; then
    READY_COUNT=$(npx @stevestomp/ohno-cli get-ready-count 2>/dev/null || echo "0")
    if [ "$READY_COUNT" -gt 0 ] 2>/dev/null; then
        echo "CHECK=tasks_available OK (${READY_COUNT} ready)"
    else
        echo "ISSUE=no_tasks"
        echo "DETAIL=No tasks available to work on"
        ISSUES=$((ISSUES + 1))
    fi
fi

# 4. Disk space adequate (warn if <1GB free)
if command -v df &>/dev/null; then
    # Get available space in KB for current directory
    AVAIL_KB=$(df -k "$PROJECT_DIR" 2>/dev/null | tail -1 | awk '{print $4}')
    if [ -n "$AVAIL_KB" ] && [ "$AVAIL_KB" -lt 1048576 ] 2>/dev/null; then
        AVAIL_MB=$((AVAIL_KB / 1024))
        echo "WARNING=low_disk"
        echo "DETAIL=Only ${AVAIL_MB}MB free disk space (recommend >1GB)"
        WARNINGS=$((WARNINGS + 1))
    else
        echo "CHECK=disk_space OK"
    fi
fi

# 5. No stale worktree locks
if [ -d "${PROJECT_DIR}/.worktrees" ]; then
    STALE_LOCKS=0
    for lockfile in "${PROJECT_DIR}"/.worktrees/*/locked 2>/dev/null; do
        [ -f "$lockfile" ] || continue
        STALE_LOCKS=$((STALE_LOCKS + 1))
        echo "WARNING=stale_lock"
        echo "DETAIL=Stale worktree lock: ${lockfile}"
    done
    if [ "$STALE_LOCKS" -gt 0 ]; then
        WARNINGS=$((WARNINGS + $STALE_LOCKS))
    else
        echo "CHECK=worktree_locks OK"
    fi
else
    echo "CHECK=worktree_locks OK (no worktrees dir)"
fi

# 6. Chain state file valid (if --continue)
CHAIN_STATE="${PROJECT_DIR}/.claude/pokayokay-chain-state.json"
if [ -f "$CHAIN_STATE" ]; then
    if python3 -c "import json; json.load(open('$CHAIN_STATE'))" 2>/dev/null; then
        echo "CHECK=chain_state OK"
    else
        echo "ISSUE=chain_state_corrupt"
        echo "DETAIL=Chain state file is not valid JSON"
        ISSUES=$((ISSUES + 1))
    fi
fi

# Summary
echo "ISSUES=${ISSUES}"
echo "WARNINGS=${WARNINGS}"

if [ "$ISSUES" -gt 0 ]; then
    echo "PRE_FLIGHT=FAIL"
    exit 1
else
    echo "PRE_FLIGHT=PASS"
    exit 0
fi
