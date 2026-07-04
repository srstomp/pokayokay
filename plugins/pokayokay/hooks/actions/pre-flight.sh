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
    if npx @stevestomp/ohno-cli status &>/dev/null; then
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
# `next --json` returns a task object with an `id` when work is available,
# or {"message":"No tasks available"} when there is none (exit 0 either way).
if command -v npx &>/dev/null; then
    NEXT_ID=$(npx @stevestomp/ohno-cli next --json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('id') or '')" 2>/dev/null || echo "")
    if [ -n "$NEXT_ID" ]; then
        echo "CHECK=tasks_available OK (next: ${NEXT_ID})"
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
    for lockfile in "${PROJECT_DIR}"/.worktrees/*/locked; do
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
# Prefer .pokayokay/, fall back to .claude/ for legacy projects.
CHAIN_STATE_PRIMARY="${PROJECT_DIR}/.pokayokay/pokayokay-chain-state.json"
CHAIN_STATE_LEGACY="${PROJECT_DIR}/.claude/pokayokay-chain-state.json"
if [ -f "$CHAIN_STATE_PRIMARY" ]; then
    CHAIN_STATE="$CHAIN_STATE_PRIMARY"
elif [ -f "$CHAIN_STATE_LEGACY" ]; then
    CHAIN_STATE="$CHAIN_STATE_LEGACY"
else
    CHAIN_STATE=""
fi
if [ -n "$CHAIN_STATE" ]; then
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
