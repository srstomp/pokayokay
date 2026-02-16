#!/usr/bin/env python3
"""
Bridge script for Claude Code hooks → yokay hooks integration.

Receives PostToolUse hook data from Claude Code, parses boundary metadata
from ohno responses, and triggers appropriate yokay hook actions.

Input: JSON via stdin (Claude Code PostToolUse format)
Output: JSON with additionalContext for Claude
"""

import json
import os
import subprocess
import sys
import time
from collections import defaultdict
from pathlib import Path
from typing import Dict, List, Optional


class DangerousValueError(ValueError):
    """Raised when an environment value contains dangerous shell characters."""
    pass


# Shell metacharacters that could enable command injection
# Note: newlines are already stripped by the non-printable filter
SHELL_METACHARACTERS = frozenset([';', '|', '&', '$', '`', '(', ')', '<', '>'])

# Configurable timeouts per hook (in seconds)
# Default is 30s, with longer timeouts for hooks that may take more time
HOOK_TIMEOUTS: Dict[str, int] = {
    "default": 30,
    "test": 120,        # Tests may take longer
    "audit-gate": 60,   # Audit checks may be extensive
    "lint": 60,         # Linting large codebases
    "check-ref-sizes": 10,  # Reference file size check
    "sync": 30,
    "commit": 30,
    "verify-tasks": 15,
    "verify-clean": 10,
    "check-blockers": 10,
    "suggest-skills": 10,
    "detect-spike": 10,
    "capture-knowledge": 15,
    "session-summary": 15,
    "session-chain": 30,
    "post-review-fail": 30,
    "recover": 30,
    "pre-flight": 30,
    "graduate-rules": 10,
}

# Rate limiting configuration
RATE_LIMIT_MAX_EXECUTIONS = 10  # Max executions per hook per minute
RATE_LIMIT_WINDOW_SECONDS = 60

# Track hook executions for rate limiting (in-memory, resets on process restart)
_hook_executions: Dict[str, List[float]] = defaultdict(list)

# WIP tracking (in-memory, resets on process restart)
_tracked_files: set = set()
_last_wip_update: float = 0
WIP_UPDATE_INTERVAL = 5  # seconds - don't update more than every 5 seconds

# Review failure tracking
REVIEW_FAILURE_THRESHOLD = 3  # Write to memory after this many occurrences
REVIEW_FAILURE_MAX_ENTRIES = 50  # Max entries in recurring-failures.md


def sanitize_env_value(value: str, field_name: str = "unknown") -> str:
    """
    Sanitize environment variable values to prevent command injection.

    Removes non-printable characters and rejects values containing shell
    metacharacters that could enable command injection in shell scripts.

    Args:
        value: The environment variable value to sanitize
        field_name: Name of the field for error messages

    Returns:
        Sanitized string with only safe printable characters

    Raises:
        DangerousValueError: If value contains shell metacharacters
    """
    if not isinstance(value, str):
        return str(value)

    # Remove non-printable characters (except common whitespace)
    sanitized = ''.join(c for c in value if c.isprintable() or c in (' ', '\t'))

    # Check for shell metacharacters
    dangerous_found = [c for c in sanitized if c in SHELL_METACHARACTERS]
    if dangerous_found:
        # Log which characters were found (without exposing full value)
        chars = ', '.join(repr(c) for c in set(dangerous_found))
        raise DangerousValueError(
            f"Field '{field_name}' contains dangerous shell characters: {chars}"
        )

    return sanitized


def get_script_dir() -> Path:
    """Get the directory containing this script."""
    return Path(__file__).parent


def check_rate_limit(hook_name: str) -> Optional[str]:
    """
    Check if a hook has exceeded its rate limit.

    Args:
        hook_name: Name of the hook to check

    Returns:
        None if within limits, error message if rate limited
    """
    now = time.time()
    executions = _hook_executions[hook_name]

    # Remove executions outside the time window
    executions[:] = [t for t in executions if now - t < RATE_LIMIT_WINDOW_SECONDS]

    if len(executions) >= RATE_LIMIT_MAX_EXECUTIONS:
        return f"Rate limited: {hook_name} exceeded {RATE_LIMIT_MAX_EXECUTIONS} executions per minute"

    # Record this execution
    executions.append(now)
    return None


def get_timeout(hook_name: str) -> int:
    """Get the timeout for a specific hook."""
    return HOOK_TIMEOUTS.get(hook_name, HOOK_TIMEOUTS["default"])


def run_action(name: str, args: Optional[List[str]] = None, env: Optional[Dict[str, str]] = None) -> Dict:
    """Run a yokay hook action script."""
    script_path = get_script_dir() / f"{name}.sh"

    if not script_path.exists():
        return {"action": name, "status": "skipped", "reason": "script not found"}

    # Check rate limit before executing
    rate_limit_error = check_rate_limit(name)
    if rate_limit_error:
        return {"action": name, "status": "rate_limited", "reason": rate_limit_error}

    # Get configurable timeout for this hook
    timeout = get_timeout(name)

    try:
        # Merge environment
        run_env = os.environ.copy()
        if env:
            # Sanitize environment variables to prevent command injection
            try:
                sanitized_env = {k: sanitize_env_value(v, field_name=k) for k, v in env.items()}
            except DangerousValueError as e:
                return {"action": name, "status": "blocked", "reason": str(e)}
            run_env.update(sanitized_env)

        # Run the script with configurable timeout
        cmd = [str(script_path)] + (args or [])
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
            env=run_env,
            cwd=os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
        )

        return {
            "action": name,
            "status": "success" if result.returncode == 0 else "warning",
            "output": result.stdout.strip(),
            "error": result.stderr.strip() if result.stderr else None
        }
    except subprocess.TimeoutExpired:
        return {"action": name, "status": "timeout", "reason": f"exceeded {timeout}s"}
    except Exception as e:
        return {"action": name, "status": "error", "reason": "Script execution failed"}


def _detect_stale_session() -> Optional[dict]:
    """Detect if a previous session crashed by checking for stale chain state.

    A session is considered crashed if:
    1. Chain state file exists (session was chaining)
    2. There are in_progress tasks in ohno (not cleaned up)
    3. No active Claude process is running this chain

    Returns dict with stale_tasks and chain_id if crash detected, None otherwise.
    """
    chain_state = load_chain_state()
    if not chain_state.get("chain_id"):
        return None

    # Check for in_progress tasks via ohno-cli
    try:
        result = subprocess.run(
            ["npx", "@stevestomp/ohno-cli", "list", "--status", "in_progress", "--format", "json"],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0 and result.stdout.strip():
            import json as json_mod
            tasks = json_mod.loads(result.stdout)
            if isinstance(tasks, list) and len(tasks) > 0:
                task_ids = [t.get("id", "") for t in tasks if t.get("id")]
                if task_ids:
                    return {
                        "stale_tasks": task_ids,
                        "chain_id": chain_state.get("chain_id", ""),
                    }
    except (subprocess.TimeoutExpired, json.JSONDecodeError, Exception):
        pass

    return None


def handle_session_start(input_data: dict) -> dict:
    """Handle SessionStart event - run pre-session hooks and crash recovery."""
    results = []

    # Reset token usage tracking for this session
    reset_token_usage()

    # Run pre-session verification
    results.append(run_action("verify-clean"))

    # Run pre-flight validation for unattended mode
    work_mode = os.environ.get("YOKAY_WORK_MODE", "")
    if work_mode == "unattended":
        preflight_result = run_action("pre-flight", env={"WORK_MODE": work_mode})
        results.append(preflight_result)

    # Detect and recover from crashed sessions
    stale = _detect_stale_session()
    if stale:
        recovery_env = {
            "STALE_TASKS": ",".join(stale["stale_tasks"]),
            "CHAIN_ID": stale.get("chain_id", ""),
        }
        recovery_result = run_action("recover", env=recovery_env)
        results.append(recovery_result)

    success_count = sum(1 for r in results if r["status"] == "success")
    warning_count = sum(1 for r in results if r["status"] == "warning")

    return {
        "hooks_run": ["pre-session"],
        "results": results,
        "summary": f"{success_count} passed, {warning_count} warnings"
    }


def load_pokayokay_config() -> dict:
    """Load pokayokay configuration from .claude/pokayokay.json."""
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
    config_path = Path(project_dir) / ".claude" / "pokayokay.json"

    if not config_path.exists():
        return {}

    try:
        with open(config_path) as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError):
        return {}


# ==========================================================================
# Chain State File Functions
# ==========================================================================

CHAIN_STATE_FILENAME = "pokayokay-chain-state.json"


def _chain_state_path() -> Path:
    """Get path to the chain state file."""
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
    return Path(project_dir) / ".claude" / CHAIN_STATE_FILENAME


def load_chain_state() -> dict:
    """Load chain state from .claude/pokayokay-chain-state.json.

    Returns:
        Chain state dict with keys: chain_id, chain_index, scope_type,
        scope_id, tasks_completed. Empty dict if no state file exists.
    """
    state_path = _chain_state_path()
    if not state_path.exists():
        return {}

    try:
        with open(state_path) as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError):
        return {}


def save_chain_state(state: dict) -> None:
    """Save chain state to .claude/pokayokay-chain-state.json.

    Uses atomic write (temp file + rename) to prevent corruption.
    """
    state_path = _chain_state_path()
    state_path.parent.mkdir(parents=True, exist_ok=True)

    tmp_path = state_path.with_suffix(".tmp")
    try:
        with open(tmp_path, "w") as f:
            json.dump(state, f, indent=2)
            f.write("\n")
        tmp_path.rename(state_path)
    except OSError:
        # Best-effort - don't crash hooks on write failure
        if tmp_path.exists():
            tmp_path.unlink()


def delete_chain_state() -> None:
    """Remove the chain state file (chain is done)."""
    state_path = _chain_state_path()
    try:
        if state_path.exists():
            state_path.unlink()
    except OSError:
        pass  # Best-effort cleanup


# ==========================================================================
# Token Usage Tracking
# ==========================================================================

TOKEN_USAGE_FILENAME = "pokayokay-token-usage.json"


def _token_usage_path() -> Path:
    """Get path to the token usage file."""
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
    return Path(project_dir) / ".claude" / TOKEN_USAGE_FILENAME


def load_token_usage() -> dict:
    """Load token usage data for the current session."""
    usage_path = _token_usage_path()
    if not usage_path.exists():
        return {"agents": [], "total_tokens": 0, "total_agents": 0}
    try:
        with open(usage_path) as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError):
        return {"agents": [], "total_tokens": 0, "total_agents": 0}


def save_token_usage(usage: dict) -> None:
    """Save token usage data."""
    usage_path = _token_usage_path()
    usage_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        with open(usage_path, "w") as f:
            json.dump(usage, f, indent=2)
    except OSError:
        pass  # Best-effort


def reset_token_usage() -> None:
    """Reset token usage file at session start."""
    usage_path = _token_usage_path()
    try:
        if usage_path.exists():
            usage_path.unlink()
    except OSError:
        pass


def record_agent_tokens(agent_type: str, description: str, tool_response: dict) -> None:
    """Record token usage from a completed Task (subagent) tool call."""
    # Extract usage from tool_response
    # Claude Code includes usage data in task-notification messages
    result_text = str(tool_response.get("result", ""))

    # Parse total_tokens from the response if available
    total_tokens = 0
    tool_uses = 0
    duration_ms = 0

    # The tool_response for Task contains usage info
    if "total_tokens" in result_text:
        import re
        token_match = re.search(r'total_tokens["\s:]+(\d+)', result_text)
        if token_match:
            total_tokens = int(token_match.group(1))
        tool_match = re.search(r'tool_uses["\s:]+(\d+)', result_text)
        if tool_match:
            tool_uses = int(tool_match.group(1))
        duration_match = re.search(r'duration_ms["\s:]+(\d+)', result_text)
        if duration_match:
            duration_ms = int(duration_match.group(1))

    usage = load_token_usage()
    usage["agents"].append({
        "type": agent_type,
        "description": description[:80],
        "total_tokens": total_tokens,
        "tool_uses": tool_uses,
        "duration_ms": duration_ms,
    })
    usage["total_tokens"] = sum(a["total_tokens"] for a in usage["agents"])
    usage["total_agents"] = len(usage["agents"])
    save_token_usage(usage)


def _write_chain_learnings(chain_state: dict, tasks_completed_count: int) -> None:
    """Write chain progress to memory at session end."""
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())

    # Find memory directory (Claude project memory or project-local)
    project_key = project_dir.replace("/", "-").lstrip("-")
    claude_memory = Path.home() / ".claude" / "projects" / project_key / "memory"
    target_dir = claude_memory if claude_memory.exists() else Path(project_dir) / "memory"
    target_dir.mkdir(parents=True, exist_ok=True)

    learnings_file = target_dir / "chain-learnings.md"
    date_str = time.strftime("%Y-%m-%d %H:%M")
    chain_id = chain_state.get("chain_id", "unknown")
    chain_index = chain_state.get("chain_index", 0)
    scope = chain_state.get("scope_type", "unknown")
    scope_id = chain_state.get("scope_id", "")

    entry = f"\n## Session {chain_index} of {chain_id} ({date_str})\n"
    entry += f"- Scope: {scope}"
    if scope_id:
        entry += f" ({scope_id})"
    entry += "\n"
    entry += f"- Tasks completed this session: {tasks_completed_count}\n"

    try:
        existing = ""
        if learnings_file.exists():
            existing = learnings_file.read_text()

        if not existing.strip():
            existing = "# Chain Learnings\n\nSession-level progress from chained work sessions.\n"

        # Cap at 100 entries — rotate oldest
        entry_count = existing.count("\n## Session ")
        if entry_count >= 100:
            lines = existing.split("\n")
            # Find first "## Session" after header and remove that block
            start = None
            end = None
            for i, line in enumerate(lines):
                if line.startswith("## Session ") and start is None and i > 2:
                    start = i
                elif line.startswith("## Session ") and start is not None:
                    end = i
                    break
            if start is not None:
                if end is None:
                    end = len(lines)
                lines = lines[:start] + lines[end:]
                existing = "\n".join(lines)

        existing += entry
        learnings_file.write_text(existing)
    except OSError:
        pass


def _write_spike_result(task_id: str, task_title: str, task_notes: str) -> None:
    """Write spike GO/NO-GO result to memory."""
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())

    project_key = project_dir.replace("/", "-").lstrip("-")
    claude_memory = Path.home() / ".claude" / "projects" / project_key / "memory"
    target_dir = claude_memory if claude_memory.exists() else Path(project_dir) / "memory"
    target_dir.mkdir(parents=True, exist_ok=True)

    spike_file = target_dir / "spike-results.md"
    date_str = time.strftime("%Y-%m-%d")

    # Determine result from notes
    notes_lower = (task_notes or "").lower()
    if "no-go" in notes_lower or "no go" in notes_lower:
        result = "NO-GO"
    elif "pivot" in notes_lower:
        result = "PIVOT"
    elif "more-info" in notes_lower or "more info" in notes_lower:
        result = "MORE-INFO"
    else:
        result = "GO"

    entry = f"\n## {task_title} ({date_str})\n"
    entry += f"- **Result**: {result}\n"
    entry += f"- **Task**: {task_id}\n"
    finding = (task_notes or "No notes")[:200]
    entry += f"- **Finding**: {finding}\n"

    try:
        existing = ""
        if spike_file.exists():
            existing = spike_file.read_text()

        if not existing.strip():
            existing = "# Spike Results\n\nGO/NO-GO decisions from time-boxed investigations. Prevents future sessions from re-investigating closed questions.\n"

        existing += entry
        spike_file.write_text(existing)
    except OSError:
        pass


def handle_session_end(input_data: dict) -> dict:
    """Handle SessionEnd event - run post-session hooks and session chaining."""
    results = []

    # Run post-session hooks
    results.append(run_action("sync"))
    results.append(run_action("session-summary"))

    # Check for session chaining via state file
    chain_state = load_chain_state()
    chain_id = chain_state.get("chain_id", "")
    chain_result = None

    # Write chain learnings to memory before chaining
    if chain_id:
        _write_chain_learnings(chain_state, chain_state.get("tasks_completed", 0))

    if chain_id:
        # We're in a chain - check if we should continue
        config = load_pokayokay_config()
        headless_config = config.get("headless", {})

        chain_env = {
            "CHAIN_ID": chain_id,
            "CHAIN_INDEX": str(chain_state.get("chain_index", 0)),
            "MAX_CHAINS": str(headless_config.get("max_chains", 10)),
            "SCOPE_TYPE": chain_state.get("scope_type", ""),
            "SCOPE_ID": chain_state.get("scope_id", ""),
            "TASKS_COMPLETED": str(chain_state.get("tasks_completed", 0)),
            "CHAIN_AUDITED": str(chain_state.get("audit_passed", False)).lower(),
            "REPORT_MODE": headless_config.get("report", "on_complete"),
            "NOTIFY_MODE": headless_config.get("notify", "terminal"),
        }

        chain_result = run_action("session-chain", env=chain_env)
        results.append(chain_result)

        # Parse chain result to check if chain is ending
        if chain_result and chain_result.get("output"):
            try:
                chain_data = json.loads(chain_result["output"])
                chain_action = chain_data.get("action", "")
                if chain_action == "continue":
                    # Update state file for next session
                    # Preserve all coordinator state fields (adaptive_n, failed_tasks, etc.)
                    chain_state["chain_index"] = chain_state.get("chain_index", 0) + 1
                    save_chain_state(chain_state)
                elif chain_action == "audit_pending":
                    # Don't end the chain - signal coordinator to run audit
                    chain_state["audit_pending"] = True
                    save_chain_state(chain_state)
                elif chain_action in ("complete", "limit_reached"):
                    # Chain is done - clean up state file
                    delete_chain_state()
            except json.JSONDecodeError:
                pass

    success_count = sum(1 for r in results if r["status"] == "success")
    warning_count = sum(1 for r in results if r["status"] == "warning")

    response = {
        "hooks_run": ["post-session"],
        "results": results,
        "summary": f"{success_count} passed, {warning_count} warnings"
    }

    # Include chain info if available
    if chain_result and chain_result.get("output"):
        try:
            chain_data = json.loads(chain_result["output"])
            response["chain"] = chain_data
        except json.JSONDecodeError:
            pass

    return response


def handle_task_start(tool_input: dict, tool_response: dict) -> dict:
    """Handle task status change to in_progress - run pre-task hooks."""
    task_id = tool_input.get("task_id", "unknown")

    # Extract task metadata from response if available
    task_data = tool_response.get("task", {})
    task_title = task_data.get("title", tool_input.get("title", ""))
    task_type = task_data.get("task_type", task_data.get("type", tool_input.get("type", "feature")))
    story_id = task_data.get("story_id", "")

    # Get worktree flags from environment (set by /work command)
    force_worktree = os.environ.get("YOKAY_FORCE_WORKTREE", "false")
    force_inplace = os.environ.get("YOKAY_FORCE_INPLACE", "false")

    env = {
        "TASK_ID": task_id,
        "TASK_TITLE": task_title,
        "TASK_TYPE": task_type,
        "STORY_ID": story_id,
        "FORCE_WORKTREE": force_worktree,
        "FORCE_INPLACE": force_inplace,
    }

    results = []
    results.append(run_action("check-blockers", env=env))
    results.append(run_action("suggest-skills", env=env))
    results.append(run_action("setup-worktree", env=env))

    # Parse worktree result for context
    worktree_info = {}
    worktree_result = next((r for r in results if r["action"] == "setup-worktree"), None)
    if worktree_result and worktree_result.get("status") == "success" and worktree_result.get("output"):
        for line in worktree_result["output"].split("\n"):
            if "=" in line:
                key, value = line.split("=", 1)
                worktree_info[key.strip()] = value.strip()

    success_count = sum(1 for r in results if r["status"] == "success")
    warning_count = sum(1 for r in results if r["status"] == "warning")

    return {
        "hooks_run": ["pre-task"],
        "task_id": task_id,
        "worktree": worktree_info,
        "results": results,
        "summary": f"{success_count} passed, {warning_count} warnings"
    }


def handle_task_complete(tool_input: dict, tool_response: dict) -> dict:
    """Handle mcp__ohno__update_task_status PostToolUse event for task completion."""
    results = []
    hooks_run = []

    task_id = tool_input.get("task_id", "unknown")

    # Extract task metadata from response if available
    task_data = tool_response.get("task", {})
    task_title = task_data.get("title", tool_input.get("title", ""))
    task_type = task_data.get("type", tool_input.get("type", ""))
    task_notes = tool_input.get("notes", "")

    # Extract boundary metadata
    boundaries = tool_response.get("boundaries", {})
    story_completed = boundaries.get("story_completed", False)
    epic_completed = boundaries.get("epic_completed", False)
    story_id = boundaries.get("story_id")
    epic_id = boundaries.get("epic_id")

    # Build environment for scripts
    env = {
        "TASK_ID": task_id,
        "TASK_TITLE": task_title,
        "TASK_TYPE": task_type,
        "TASK_NOTES": task_notes,
        "STORY_ID": story_id or "",
        "EPIC_ID": epic_id or "",
        "STORY_COMPLETED": str(story_completed).lower(),
        "EPIC_COMPLETED": str(epic_completed).lower(),
    }

    # Always run post-task hooks
    hooks_run.append("post-task")
    results.append(run_action("sync", env=env))
    results.append(run_action("commit", env=env))
    results.append(run_action("detect-spike", env=env))
    results.append(run_action("capture-knowledge", env=env))

    # Write spike results to memory
    if task_type == "spike":
        _write_spike_result(task_id, task_title, task_notes)

    # Run post-story hooks if story completed
    if story_completed:
        hooks_run.append("post-story")
        results.append(run_action("test", env=env))
        # Run audit-gate for story boundary
        story_env = {**env, "BOUNDARY_TYPE": "story"}
        results.append(run_action("audit-gate", env=story_env))

        # Compact story handoffs (memory decay)
        if story_id:
            try:
                subprocess.run(
                    ["npx", "@stevestomp/ohno-cli", "compact-handoffs", story_id],
                    capture_output=True,
                    timeout=15,
                    check=False
                )
            except Exception:
                pass  # Best-effort

    # Run post-epic hooks if epic completed
    if epic_completed:
        hooks_run.append("post-epic")
        # Run audit-gate for epic boundary
        epic_env = {**env, "BOUNDARY_TYPE": "epic"}
        results.append(run_action("audit-gate", env=epic_env))

        # Delete epic handoffs (memory decay)
        if epic_id:
            try:
                subprocess.run(
                    ["npx", "@stevestomp/ohno-cli", "delete-handoffs", epic_id],
                    capture_output=True,
                    timeout=15,
                    check=False
                )
            except Exception:
                pass  # Best-effort

    # Update chain state: increment tasks_completed
    chain_state = load_chain_state()
    if chain_state.get("chain_id"):
        chain_state["tasks_completed"] = chain_state.get("tasks_completed", 0) + 1
        save_chain_state(chain_state)

    # Build summary
    success_count = sum(1 for r in results if r["status"] == "success")
    warning_count = sum(1 for r in results if r["status"] == "warning")

    return {
        "hooks_run": hooks_run,
        "boundaries": {
            "story_completed": story_completed,
            "epic_completed": epic_completed,
            "story_id": story_id,
            "epic_id": epic_id,
        },
        "results": results,
        "summary": f"{success_count} passed, {warning_count} warnings"
    }


def handle_set_blocker(tool_input: dict, tool_response: dict) -> dict:
    """Handle mcp__ohno__set_blocker PostToolUse event."""
    task_id = tool_input.get("task_id", "unknown")
    reason = tool_input.get("reason", "")

    env = {
        "TASK_ID": task_id,
        "BLOCKER_REASON": reason,
    }

    # Run on-blocker notification (inline since it's simple)
    print(f"🚧 Blocker on {task_id}: {reason}", file=sys.stderr)

    return {
        "hooks_run": ["on-blocker"],
        "task_id": task_id,
        "blocker_reason": reason,
        "suggestion": "Consider working on a different task while this is blocked."
    }


def handle_pre_commit(tool_input: dict) -> dict:
    """Handle Bash pre-commit check (PreToolUse)."""
    command = tool_input.get("command", "")

    # Check if this is a git commit command
    if "git commit" not in command and "git add" not in command:
        return {"skip": True, "reason": "not a commit command"}

    results = []

    # Run pre-commit hooks
    results.append(run_action("lint"))
    results.append(run_action("check-ref-sizes"))

    # Check for failures that should block
    has_blocking_error = any(r["status"] == "error" for r in results)

    # Build reason from all failing hooks
    failing = [r["action"] for r in results if r["status"] == "error"]
    reason = ", ".join(failing) + " failed" if failing else None

    return {
        "hooks_run": ["pre-commit"],
        "results": results,
        "block": has_blocking_error,
        "reason": reason
    }


# Commands that should auto-create tasks and need verification
AUDIT_COMMANDS = {
    "pokayokay:security": {"prefix": "Security:", "always": True},
    "pokayokay:a11y": {"prefix": "A11y:", "always": True},
    "pokayokay:test": {"prefix": "Test:", "flag": "--audit"},
    "pokayokay:observe": {"prefix": "Observability:", "flag": "--audit"},
    "pokayokay:arch": {"prefix": "Arch:", "flag": "--audit"},
}


def handle_skill_complete(tool_input: dict, tool_response: dict) -> dict:
    """Handle Skill tool PostToolUse event for post-command hooks."""
    skill_name = tool_input.get("skill", "")
    skill_args = tool_input.get("args", "")

    # Check if this skill should trigger post-command verification
    config = AUDIT_COMMANDS.get(skill_name)
    if not config:
        return {"skip": True, "reason": f"skill {skill_name} has no post-command hooks"}

    # Check if flag is required but not present
    required_flag = config.get("flag")
    if required_flag and required_flag not in skill_args:
        return {"skip": True, "reason": f"skill {skill_name} requires {required_flag} flag for task verification"}

    prefix = config["prefix"]

    env = {
        "SKILL_NAME": skill_name,
        "SKILL_ARGS": skill_args,
        "TASK_PREFIX": prefix,
    }

    results = []
    results.append(run_action("verify-tasks", env=env))

    success_count = sum(1 for r in results if r["status"] == "success")
    warning_count = sum(1 for r in results if r["status"] == "warning")

    return {
        "hooks_run": ["post-command"],
        "skill": skill_name,
        "results": results,
        "summary": f"{success_count} passed, {warning_count} warnings"
    }


# ==========================================================================
# Review Failure Tracking
# ==========================================================================

FAILURE_TRACKING_FILENAME = "pokayokay-review-failures.json"

FAILURE_CATEGORIES = [
    ("missing_error_handling", ["error handling", "error state", "try/catch", "catch block", "unhandled"]),
    ("missing_tests", ["no test", "missing test", "test coverage", "untested"]),
    ("scope_creep", ["scope creep", "unrequested", "extra work", "not in spec"]),
    ("missing_validation", ["validation", "input validation", "sanitiz"]),
    ("missing_auth", ["auth", "permission", "access control", "rate limit"]),
    ("missing_edge_cases", ["edge case", "boundary", "null", "empty", "undefined"]),
    ("naming_conventions", ["naming", "convention", "inconsistent name"]),
    ("missing_types", ["type", "typing", "type safety", "any type"]),
]

# Map failure categories to likely affected file paths for rule scoping
CATEGORY_PATH_SCOPES: Dict[str, str] = {
    "missing_error_handling": "",  # Project-wide
    "missing_tests": "",  # Project-wide
    "scope_creep": "",  # Project-wide
    "missing_validation": "",  # Project-wide
    "missing_auth": "src/**/*.{ts,py}",
    "missing_edge_cases": "",  # Project-wide
    "naming_conventions": "",  # Project-wide
    "missing_types": "**/*.{ts,tsx}",
}


def _failure_tracking_path() -> Path:
    """Get path to the review failure tracking file."""
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
    return Path(project_dir) / ".claude" / FAILURE_TRACKING_FILENAME


def load_failure_tracking() -> dict:
    """Load review failure tracking data."""
    path = _failure_tracking_path()
    if not path.exists():
        return {"categories": {}}
    try:
        with open(path) as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError):
        return {"categories": {}}


def save_failure_tracking(data: dict) -> None:
    """Save review failure tracking data."""
    path = _failure_tracking_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp_path = path.with_suffix(".tmp")
    try:
        with open(tmp_path, "w") as f:
            json.dump(data, f, indent=2)
            f.write("\n")
        tmp_path.rename(path)
    except OSError:
        if tmp_path.exists():
            tmp_path.unlink()


def categorize_failure(failure_text: str) -> List[str]:
    """Categorize a review failure into known patterns."""
    text_lower = failure_text.lower()
    matched = []
    for category, keywords in FAILURE_CATEGORIES:
        if any(kw in text_lower for kw in keywords):
            matched.append(category)
    return matched if matched else ["uncategorized"]


def write_recurring_failure_to_memory(category: str, count: int, recent_context: str) -> None:
    """Write a recurring failure pattern to memory/recurring-failures.md."""
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
    memory_dir = Path(project_dir) / "memory"

    # Also check Claude's project memory directory
    claude_memory_dir = Path.home() / ".claude" / "projects"
    # Find the right project memory dir by matching project_dir
    project_key = project_dir.replace("/", "-").lstrip("-")
    claude_project_memory = claude_memory_dir / project_key / "memory"

    # Use Claude project memory if it exists, otherwise project-local
    target_dir = claude_project_memory if claude_project_memory.exists() else memory_dir
    target_dir.mkdir(parents=True, exist_ok=True)

    failures_file = target_dir / "recurring-failures.md"

    # Format the category name for display
    display_name = category.replace("_", " ").title()
    date_str = time.strftime("%Y-%m-%d")

    entry = f"\n## {display_name} (seen {count}x)\n"
    entry += f"**Pattern**: Review failures for {display_name.lower()}\n"
    entry += f"**Context**: {recent_context[:200]}\n"
    entry += f"**First recorded**: {date_str}\n"

    try:
        existing = ""
        if failures_file.exists():
            existing = failures_file.read_text()

        # Count existing entries
        entry_count = existing.count("\n## ")

        if entry_count >= REVIEW_FAILURE_MAX_ENTRIES:
            # Rotate: remove oldest entry (first ## block after header)
            lines = existing.split("\n")
            # Find and remove first entry block
            start = None
            end = None
            for i, line in enumerate(lines):
                if line.startswith("## ") and start is None:
                    # Skip header
                    if i == 0:
                        continue
                    start = i
                elif line.startswith("## ") and start is not None:
                    end = i
                    break
            if start is not None:
                if end is None:
                    end = len(lines)
                lines = lines[:start] + lines[end:]
                existing = "\n".join(lines)

        if not existing.strip():
            existing = "# Recurring Review Failures\n\nPatterns detected from repeated review failures. Include relevant entries in implementer prompts as \"Known Pitfalls\".\n"

        # Check if this category already has an entry — update count instead
        category_header = f"## {display_name}"
        if category_header in existing:
            # Update the existing entry's count
            import re
            existing = re.sub(
                rf"(## {re.escape(display_name)}) \(seen \d+x\)",
                rf"\1 (seen {count}x)",
                existing
            )
        else:
            existing += entry

        failures_file.write_text(existing)
    except OSError:
        pass  # Best-effort


def _graduate_rule(category: str, context: str, count: int) -> None:
    """Graduate a recurring failure to a .claude/rules/ file."""
    display_name = category.replace("_", " ").title()
    description = f"Review failures for {display_name.lower()}: {context[:150]}"

    affected_paths = CATEGORY_PATH_SCOPES.get(category, "")

    env = {
        "CATEGORY": category,
        "PATTERN_DESCRIPTION": description,
        "AFFECTED_PATHS": affected_paths,
        "FAILURE_COUNT": str(count),
    }

    run_action("graduate-rules", env=env)


def track_review_failure(failure_text: str, task_id: str) -> List[str]:
    """Track a review failure and write to memory if threshold reached.

    Returns list of categories that hit the threshold (newly written to memory).
    """
    categories = categorize_failure(failure_text)
    tracking = load_failure_tracking()

    newly_recorded = []

    for category in categories:
        cat_data = tracking["categories"].setdefault(category, {"count": 0, "last_context": "", "written": False})
        cat_data["count"] += 1
        cat_data["last_context"] = failure_text[:300]
        cat_data["last_task"] = task_id
        cat_data["last_seen"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

        if cat_data["count"] >= REVIEW_FAILURE_THRESHOLD and not cat_data.get("written"):
            write_recurring_failure_to_memory(category, cat_data["count"], cat_data["last_context"])
            _graduate_rule(category, cat_data["last_context"], cat_data["count"])
            cat_data["written"] = True
            newly_recorded.append(category)

        # Update count even after written (for re-recording at higher thresholds)
        if cat_data.get("written") and cat_data["count"] % REVIEW_FAILURE_THRESHOLD == 0:
            write_recurring_failure_to_memory(category, cat_data["count"], cat_data["last_context"])
            _graduate_rule(category, cat_data["last_context"], cat_data["count"])

    save_failure_tracking(tracking)
    return newly_recorded


def handle_review_complete(tool_input: dict, tool_response: dict) -> dict:
    """Handle Task tool PostToolUse for review agents (spec-reviewer, quality-reviewer).

    Detects review failures and triggers post-review-fail hook for kaizen integration.
    Gracefully handles missing kaizen installation.
    """
    description = tool_input.get("description", "").lower()
    subagent_type = tool_input.get("subagent_type", "")

    # Only handle spec-reviewer and quality-reviewer
    is_spec_review = "spec-review" in subagent_type or "spec review" in description
    is_quality_review = "quality-review" in subagent_type or "quality review" in description

    if not (is_spec_review or is_quality_review):
        return {"skip": True, "reason": "not a review task"}

    # Get the agent output (tool_response contains the agent's result)
    agent_output = str(tool_response.get("result", ""))

    # Detect PASS/FAIL
    if ": PASS" in agent_output:
        return {"skip": True, "reason": "review passed"}

    if ": FAIL" not in agent_output:
        return {"skip": True, "reason": "could not determine review result"}

    # Extract failure source
    failure_source = "spec-review" if is_spec_review else "quality-review"

    # Get task ID from environment (set by coordinator before dispatching reviewers)
    task_id = os.environ.get("CURRENT_OHNO_TASK_ID", "unknown")

    # Truncate failure details to prevent shell issues (2000 chars max)
    # Also remove any shell metacharacters for safety
    failure_details = agent_output[:2000]
    # Replace problematic characters with safe alternatives
    for char in SHELL_METACHARACTERS:
        failure_details = failure_details.replace(char, ' ')

    # Track failure for recurring pattern detection
    newly_recorded = track_review_failure(failure_details, task_id)

    # Call post-review-fail hook (located in project root hooks/ directory)
    # This hook integrates with kaizen if installed, otherwise logs gracefully
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
    hook_path = Path(project_dir) / "hooks" / "post-review-fail.sh"

    if not hook_path.exists():
        return {
            "hooks_run": ["post-review-fail"],
            "review_type": failure_source,
            "task_id": task_id,
            "kaizen_action": "LOGGED",
            "results": [{"action": "post-review-fail", "status": "skipped", "reason": "hook not found"}],
            "summary": f"Review failed, hook not found at {hook_path}"
        }

    env = {
        "TASK_ID": task_id,
        "FAILURE_DETAILS": failure_details,
        "FAILURE_SOURCE": failure_source,
    }

    # Run the hook
    result = run_action_at_path(hook_path, env=env)

    # Parse the hook output for Claude to act on
    hook_output = result.get("output", "{}")
    try:
        action_data = json.loads(hook_output)
    except json.JSONDecodeError:
        action_data = {"action": "LOGGED", "message": "failed to parse hook output"}

    response = {
        "hooks_run": ["post-review-fail"],
        "review_type": failure_source,
        "task_id": task_id,
        "kaizen_action": action_data.get("action", "LOGGED"),
        "fix_task": action_data.get("fix_task"),
        "kaizen_message": action_data.get("message"),
        "results": [result],
        "summary": f"Review failed, kaizen action: {action_data.get('action', 'LOGGED')}"
    }

    if newly_recorded:
        response["recurring_failures_detected"] = newly_recorded

    return response


def run_action_at_path(script_path: Path, env: Optional[Dict[str, str]] = None) -> Dict:
    """Run a hook script at a specific path (not in the actions directory)."""
    name = script_path.stem

    if not script_path.exists():
        return {"action": name, "status": "skipped", "reason": "script not found"}

    # Check rate limit before executing
    rate_limit_error = check_rate_limit(name)
    if rate_limit_error:
        return {"action": name, "status": "rate_limited", "reason": rate_limit_error}

    # Get configurable timeout for this hook
    timeout = get_timeout(name)

    try:
        # Merge environment
        run_env = os.environ.copy()
        if env:
            run_env.update(env)

        # Run the script with configurable timeout
        cmd = [str(script_path)]
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
            env=run_env,
            cwd=os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
        )

        return {
            "action": name,
            "status": "success" if result.returncode == 0 else "warning",
            "output": result.stdout.strip(),
            "error": result.stderr.strip() if result.stderr else None
        }
    except subprocess.TimeoutExpired:
        return {"action": name, "status": "timeout", "reason": f"exceeded {timeout}s"}
    except Exception as e:
        return {"action": name, "status": "error", "reason": "Script execution failed"}


# ==========================================================================
# WIP Auto-capture Functions
# ==========================================================================

def should_update_wip(force: bool = False) -> bool:
    """Check if enough time has passed to update WIP (rate limiting)."""
    global _last_wip_update
    if force:
        return True
    now = time.time()
    if now - _last_wip_update < WIP_UPDATE_INTERVAL:
        return False
    _last_wip_update = now
    return True


def extract_output_text(tool_response) -> str:
    """Extract text output from tool response (handles various formats)."""
    if isinstance(tool_response, str):
        return tool_response
    if isinstance(tool_response, dict):
        content = tool_response.get("content", [])
        if isinstance(content, list):
            return "\n".join(c.get("text", "") for c in content if isinstance(c, dict))
        if isinstance(content, str):
            return content
        # Try direct text field
        return tool_response.get("text", tool_response.get("output", ""))
    return ""


def extract_exit_code(tool_response) -> Optional[int]:
    """Extract exit code from tool response."""
    if isinstance(tool_response, dict):
        return tool_response.get("exit_code", tool_response.get("returncode"))
    return None


def is_test_command(command: str) -> bool:
    """Check if a bash command is running tests."""
    test_patterns = ["npm test", "npx vitest", "npx jest", "pytest", "cargo test", "go test", "npm run test"]
    return any(p in command for p in test_patterns)


def is_git_commit(command: str) -> bool:
    """Check if a bash command is a git commit."""
    return "git commit" in command


def extract_commit_hash(output: str) -> Optional[str]:
    """Extract commit hash from git commit output."""
    # Git commit output: "[branch abc1234] commit message"
    import re
    match = re.search(r'\[[\w/.-]+ ([a-f0-9]{7,})\]', output)
    return match.group(1) if match else None


def parse_test_output(output: str, exit_code: Optional[int]) -> dict:
    """Parse test output into structured results."""
    import re

    result = {"ran": True, "passed": 0, "failed": 0}

    # Try to parse common test output formats
    # vitest/jest: "Tests: X passed, Y failed" or "X passing, Y failing"
    # pytest: "X passed, Y failed"

    passed = re.search(r'(\d+)\s+(?:passing|passed)', output)
    failed = re.search(r'(\d+)\s+(?:failing|failed)', output)

    if passed:
        result["passed"] = int(passed.group(1))
    if failed:
        result["failed"] = int(failed.group(1))

    if result["failed"] > 0:
        # Try to extract first failing test name
        fail_match = re.search(r'(?:FAIL|✗|×)\s+(.+)', output)
        if fail_match:
            result["failing_test"] = fail_match.group(1).strip()[:200]

    return result


def parse_error(command: str, output: str) -> Optional[dict]:
    """Parse error from failed command."""
    if not output.strip():
        return None

    # Truncate to prevent oversized WIP data
    error_msg = output.strip()[:500]
    return {
        "type": "command_error",
        "command": command[:200],
        "message": error_msg
    }


def update_wip(task_id: str, wip_data: dict):
    """Call ohno CLI to update WIP."""
    try:
        json_str = json.dumps(wip_data)
        subprocess.run(
            ["npx", "@stevestomp/ohno-cli", "update-wip", task_id, json_str],
            capture_output=True,
            timeout=10,
            check=False
        )
    except Exception:
        pass  # Silent failure - WIP updates are best-effort


def handle_file_change(tool_name: str, tool_input: dict, tool_response: dict) -> dict:
    """Capture file modifications to WIP."""
    task_id = os.environ.get("CURRENT_OHNO_TASK_ID")
    if not task_id or task_id == "unknown":
        return {"skip": True, "reason": "no active task"}

    file_path = tool_input.get("file_path", "")
    if not file_path:
        return {"skip": True, "reason": "no file path"}

    # Track this file
    _tracked_files.add(file_path)

    # Rate limit WIP updates
    if not should_update_wip():
        return {"skip": True, "reason": "rate limited"}

    wip_data = {
        "files_modified": sorted(list(_tracked_files)),
        "uncommitted_changes": True
    }

    update_wip(task_id, wip_data)
    return {"skip": True, "reason": "wip updated silently"}


def handle_bash_execution(tool_input: dict, tool_response: dict) -> dict:
    """Capture test results, git commits, and errors from Bash."""
    task_id = os.environ.get("CURRENT_OHNO_TASK_ID")
    if not task_id or task_id == "unknown":
        return {"skip": True, "reason": "no active task"}

    command = tool_input.get("command", "")
    output = extract_output_text(tool_response)
    exit_code = extract_exit_code(tool_response)

    wip_data = {}
    force_update = False

    # Detect test commands
    if is_test_command(command):
        wip_data["test_results"] = parse_test_output(output, exit_code)

    # Detect git commit
    if is_git_commit(command):
        commit_hash = extract_commit_hash(output)
        if commit_hash:
            wip_data["last_commit"] = commit_hash
            wip_data["uncommitted_changes"] = False
            # Clear tracked files after commit
            _tracked_files.clear()
            force_update = True  # Always update immediately for commits

    # Detect errors (non-zero exit)
    if exit_code and exit_code != 0 and not is_test_command(command):
        error_info = parse_error(command, output)
        if error_info:
            wip_data["errors"] = [error_info]

    if wip_data and should_update_wip(force=force_update):
        update_wip(task_id, wip_data)

    return {"skip": True, "reason": "wip updated silently"}


def main():
    """Main entry point."""
    try:
        # Read hook input from stdin
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(json.dumps({"error": f"Invalid JSON input: {e}"}))
        sys.exit(2)

    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})
    tool_response = input_data.get("tool_response", {})
    hook_event = input_data.get("hook_event_name", "")

    result = None

    # Route to appropriate handler based on event type
    if hook_event == "SessionStart":
        result = handle_session_start(input_data)

    elif hook_event == "SessionEnd":
        result = handle_session_end(input_data)

    elif tool_name == "mcp__ohno__update_task_status":
        status = tool_input.get("status", "")
        if status in ("done", "archived"):
            # Task completed - run post-task hooks
            result = handle_task_complete(tool_input, tool_response)
        elif status == "in_progress":
            # Task started - run pre-task hooks
            result = handle_task_start(tool_input, tool_response)
        else:
            result = {"skip": True, "reason": f"status is {status}, no hooks for this transition"}

    elif tool_name == "mcp__ohno__set_blocker":
        result = handle_set_blocker(tool_input, tool_response)

    elif tool_name == "Bash" and hook_event == "PreToolUse":
        result = handle_pre_commit(tool_input)

    elif tool_name == "Skill" and hook_event == "PostToolUse":
        result = handle_skill_complete(tool_input, tool_response)

    elif tool_name == "Task" and hook_event == "PostToolUse":
        # Track token usage for all subagent completions
        record_agent_tokens(
            tool_input.get("subagent_type", "unknown"),
            tool_input.get("description", ""),
            tool_response,
        )
        result = handle_review_complete(tool_input, tool_response)

    elif tool_name in ("Edit", "Write") and hook_event == "PostToolUse":
        result = handle_file_change(tool_name, tool_input, tool_response)

    elif tool_name == "Bash" and hook_event == "PostToolUse":
        result = handle_bash_execution(tool_input, tool_response)

    else:
        result = {"skip": True, "reason": f"unhandled event: {hook_event}/{tool_name}"}

    # Output result
    if result and not result.get("skip"):
        if hook_event == "SessionEnd":
            # SessionEnd doesn't support hookSpecificOutput - just output empty
            print(json.dumps({}))
        else:
            # Format for Claude Code hook output
            output = {
                "hookSpecificOutput": {
                    "hookEventName": hook_event,
                    "additionalContext": format_context(result)
                }
            }

            # Block if requested (for pre-commit failures)
            if result.get("block"):
                output["decision"] = "block"
                output["reason"] = result.get("reason", "Hook check failed")

            print(json.dumps(output))
    else:
        # No action needed
        print(json.dumps({}))


def format_context(result: dict) -> str:
    """Format result as human-readable context for Claude."""
    lines = []

    hooks_run = result.get("hooks_run", [])
    if hooks_run:
        lines.append(f"## Hooks executed: {', '.join(hooks_run)}")
        lines.append("")

    # Boundary info
    boundaries = result.get("boundaries", {})
    if boundaries.get("story_completed"):
        lines.append(f"✅ Story {boundaries.get('story_id', 'unknown')} completed!")
    if boundaries.get("epic_completed"):
        lines.append(f"🎉 Epic {boundaries.get('epic_id', 'unknown')} completed!")

    # Results table
    results = result.get("results", [])
    if results:
        lines.append("")
        lines.append("| Action | Status | Output |")
        lines.append("|--------|--------|--------|")
        for r in results:
            status_icon = {
                "success": "✓",
                "warning": "⚠️",
                "error": "❌",
                "skipped": "⏭️",
                "blocked": "🚫",
                "rate_limited": "⏳",
                "timeout": "⏰",
            }.get(r["status"], "?")
            output = r.get("output", r.get("reason", ""))[:50]
            lines.append(f"| {r['action']} | {status_icon} | {output} |")

    # Summary
    if result.get("summary"):
        lines.append("")
        lines.append(f"**Summary:** {result['summary']}")

    # Worktree info
    worktree = result.get("worktree", {})
    if worktree:
        lines.append("")
        mode = worktree.get("MODE", "")
        if mode == "worktree":
            if worktree.get("WORKTREE_CREATED") == "true":
                lines.append("## Worktree Setup")
                lines.append(f"  ✓ Branch created: {worktree.get('WORKTREE_BRANCH', 'unknown')}")
                lines.append(f"  ✓ Path: {worktree.get('WORKTREE_PATH', 'unknown')}")
                lines.append(f"  ✓ Based on: {worktree.get('BASE_BRANCH', 'main')}")
                lines.append("")
                lines.append(f"**IMPORTANT**: Work in `{worktree.get('WORKTREE_PATH')}` for this task.")
            elif worktree.get("WORKTREE_REUSED") == "true":
                lines.append("## Worktree Reused")
                lines.append(f"  ✓ Using existing worktree: {worktree.get('WORKTREE_PATH', 'unknown')}")
                lines.append("")
                lines.append(f"**IMPORTANT**: Work in `{worktree.get('WORKTREE_PATH')}` for this task.")
        elif mode == "in-place":
            reason = worktree.get("REASON", "smart default")
            lines.append("## Working In-Place")
            lines.append(f"  Working directly on current branch ({reason}).")

    # Blocker info
    if result.get("blocker_reason"):
        lines.append("")
        lines.append(f"**Blocker:** {result['blocker_reason']}")

    if result.get("suggestion"):
        lines.append(f"**Suggestion:** {result['suggestion']}")

    # Chain info (for session end with chaining)
    chain = result.get("chain", {})
    if chain:
        lines.append("")
        chain_action = chain.get("action", "")
        if chain_action == "continue":
            lines.append("## Session Chain: Continuing")
            lines.append(f"Chain {chain.get('chain_id', '?')} session {chain.get('chain_index', '?')}/{chain.get('max_chains', '?')}")
            lines.append(f"Tasks completed so far: {chain.get('tasks_completed', 0)}")
            lines.append(f"Tasks remaining: {chain.get('tasks_remaining', 0)}")
            lines.append(f"Next: `{chain.get('continue_command', '')}`")
        elif chain_action == "complete":
            lines.append("## Session Chain: Complete")
            lines.append(f"All tasks in scope completed! ({chain.get('tasks_completed', 0)} total)")
            report = chain.get("report_path", "")
            if report:
                lines.append(f"Report: {report}")
        elif chain_action == "limit_reached":
            lines.append("## Session Chain: Limit Reached")
            lines.append(f"Max chains ({chain.get('max_chains', 10)}) reached.")
            lines.append(f"Completed: {chain.get('tasks_completed', 0)}, Remaining: {chain.get('tasks_remaining', 0)}")
            report = chain.get("report_path", "")
            if report:
                lines.append(f"Report: {report}")

    # Kaizen action info (for review failures)
    kaizen_action = result.get("kaizen_action")
    if kaizen_action:
        lines.append("")
        lines.append("## Kaizen Review Failure Analysis")
        lines.append(f"**Action:** {kaizen_action}")

        if kaizen_action == "AUTO":
            fix_task = result.get("fix_task", {})
            lines.append("")
            lines.append("**Auto-creating fix task:**")
            lines.append(f"- Title: {fix_task.get('title', 'Unknown')}")
            lines.append(f"- Type: {fix_task.get('type', 'bug')}")
            lines.append(f"- Estimate: {fix_task.get('estimate', 2)}h")
            lines.append("")
            lines.append("Create this task in ohno, block the current task, then continue with next task.")

        elif kaizen_action == "SUGGEST":
            fix_task = result.get("fix_task", {})
            lines.append("")
            lines.append("**Suggested fix task (needs confirmation):**")
            lines.append(f"- Title: {fix_task.get('title', 'Unknown')}")
            lines.append(f"- Type: {fix_task.get('type', 'bug')}")
            lines.append(f"- Estimate: {fix_task.get('estimate', 2)}h")
            lines.append("")
            lines.append("Ask user: Create this fix task? (yes/no/customize)")

        elif kaizen_action == "LOGGED":
            message = result.get("kaizen_message", "")
            if message:
                lines.append(f"**Message:** {message}")
            lines.append("")
            lines.append("Failure logged. Continue with re-dispatch behavior (max 3 cycles).")

    return "\n".join(lines)


if __name__ == "__main__":
    main()
