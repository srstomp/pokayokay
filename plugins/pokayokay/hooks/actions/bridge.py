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
import re
import shlex
import subprocess
import sys
import time
from pathlib import Path
from typing import Dict, List, Optional


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
    "curate-memory": 15,
    "story-integration": 120,
}

# WIP tracking debounce interval. The bridge runs as a fresh process per hook
# event, so debounce state is persisted to .pokayokay/wip-state.json (see
# load_wip_state / save_wip_state) rather than kept in module globals.
WIP_UPDATE_INTERVAL = 5  # seconds - don't update more than every 5 seconds

# Action script exit-code contract (documented in HOOKS.md):
#   0                        -> "success"
#   2                        -> "error"   (blocking: handle_pre_commit denies the tool call)
#   any other nonzero (incl. 1) -> "warning" (advisory, surfaced but never blocks)
# Script *execution* failures (unspawnable script, etc.) map to "warning" so a
# chmod-broken hook script cannot accidentally block every commit.

# Review failure tracking
REVIEW_FAILURE_THRESHOLD = 3  # Write to memory after this many occurrences
REVIEW_FAILURE_MAX_ENTRIES = 50  # Max entries in recurring-failures.md


def sanitize_env_value(value: str, field_name: str = "unknown") -> str:
    """
    Sanitize environment variable values passed to hook action scripts.

    Removes non-printable characters and neutralizes shell metacharacters by
    replacing them with spaces (matching the FAILURE_DETAILS handling in
    handle_review_complete). Values are passed via subprocess ``env=`` and
    never interpolated into a shell command line by the bridge, so this is
    defense-in-depth for scripts that mishandle quoting. Neutralizing instead
    of rejecting matters: free-text fields like TASK_NOTES routinely contain
    parentheses/backticks/``$``, and rejecting them would silently disable
    every post-task hook, including auto-commit.

    Args:
        value: The environment variable value to sanitize
        field_name: Name of the field (kept for call-site readability)

    Returns:
        Sanitized string with metacharacters replaced by spaces
    """
    if not isinstance(value, str):
        value = str(value)

    # Remove non-printable characters (except common whitespace)
    sanitized = ''.join(c for c in value if c.isprintable() or c in (' ', '\t'))

    # Neutralize shell metacharacters with spaces instead of rejecting
    return ''.join(' ' if c in SHELL_METACHARACTERS else c for c in sanitized)


def get_script_dir() -> Path:
    """Get the directory containing this script."""
    return Path(__file__).parent


def get_project_dir() -> str:
    """Get the active project directory across supported runtimes."""
    return (
        os.environ.get("YOKAY_PROJECT_DIR")
        or os.environ.get("CODEX_WORKSPACE_DIR")
        or os.environ.get("CLAUDE_PROJECT_DIR")
        or os.getcwd()
    )


def normalize_tool_name(tool_name: str) -> str:
    """Normalize runtime-specific tool aliases to the bridge's canonical names."""
    aliases = {
        "bash": "Bash",
        "shell": "Bash",
        "exec": "Bash",
        "exec_command": "Bash",
        "edit": "Edit",
        "apply_patch": "Edit",
        "write": "Write",
        "skill": "Skill",
        "task": "Task",
        "agent": "Task",
        "spawn_agent": "Task",
        "mcp__ohno__update_task_status": "mcp__ohno__update_task_status",
        "ohno.update_task_status": "mcp__ohno__update_task_status",
        "update_task_status": "mcp__ohno__update_task_status",
        "mcp__ohno__set_blocker": "mcp__ohno__set_blocker",
        "ohno.set_blocker": "mcp__ohno__set_blocker",
        "set_blocker": "mcp__ohno__set_blocker",
    }

    if tool_name in ("Bash", "Edit", "Write", "Skill", "Task"):
        return tool_name

    lowered = str(tool_name).strip().lower()

    # Plugin-scoped MCP servers get prefixed tool names (e.g.
    # mcp__plugin_pokayokay_ohno__update_task_status when ohno is bundled via
    # the plugin's .mcp.json). Canonicalize any server-name variant by suffix.
    # The double-underscore separator keeps the Codex dot alias
    # (ohno.update_task_status) on the alias-dict path below.
    if lowered.endswith("ohno__update_task_status"):
        return "mcp__ohno__update_task_status"
    if lowered.endswith("ohno__set_blocker"):
        return "mcp__ohno__set_blocker"

    return aliases.get(lowered, tool_name)


def normalize_hook_input(input_data: dict) -> dict:
    """Normalize Claude/Codex hook payload aliases to one internal shape."""
    normalized = dict(input_data)
    raw_tool = (
        input_data.get("tool_name")
        or input_data.get("tool")
        or input_data.get("toolName")
        or ""
    )
    normalized["tool_name"] = normalize_tool_name(raw_tool)
    normalized["tool_input"] = (
        input_data.get("tool_input")
        or input_data.get("input")
        or input_data.get("arguments")
        or {}
    )
    normalized["tool_response"] = (
        input_data.get("tool_response")
        or input_data.get("response")
        or input_data.get("result")
        or {}
    )
    normalized["hook_event_name"] = (
        input_data.get("hook_event_name")
        or input_data.get("hook_event")
        or input_data.get("event")
        or input_data.get("eventName")
        or ""
    )
    normalized["runtime"] = input_data.get("runtime") or input_data.get("source") or "claude"

    # Codex passes shell commands as ``tool_input.cmd``; the rest of the
    # bridge (handle_pre_commit, handle_bash_execution, parse_error) expects
    # ``tool_input.command``. Mirror inner field aliases so Codex shell calls
    # exercise the same code paths as Claude Code Bash calls.
    tool_input = normalized.get("tool_input")
    if isinstance(tool_input, dict) and normalized["tool_name"] == "Bash":
        if "command" not in tool_input:
            for alias in ("cmd", "shell_command", "command_line"):
                if alias in tool_input:
                    tool_input["command"] = tool_input[alias]
                    break

    return normalized


def get_bash_command(tool_input: dict) -> str:
    """Extract the shell command from runtime-specific tool input shapes."""
    if not isinstance(tool_input, dict):
        return ""
    return str(
        tool_input.get("command")
        or tool_input.get("cmd")
        or tool_input.get("shell_command")
        or tool_input.get("command_line")
        or ""
    ).strip()


def is_dangerous_command(command: str) -> bool:
    """Return true for commands pokayokay should never auto-approve."""
    lowered = f" {command.lower()} "
    dangerous_fragments = (
        " rm -rf ",
        " git reset --hard ",
        " git checkout -- ",
        " git clean -fd",
        " git push ",
        " gh pr merge ",
        " gh pr close ",
        " npm publish",
        " npx wrangler deploy",
        " pulumi up",
        " cdk deploy",
    )
    return any(fragment in lowered for fragment in dangerous_fragments)


def has_shell_control_operator(command: str) -> bool:
    """Return true when a command contains shell composition or redirection."""
    shell_controls = (";", "&&", "||", "|", "<", ">", "`", "$(", "\n", "\r")
    return any(control in command for control in shell_controls)


def tokenize_shell_command(command: str) -> List[str]:
    """Tokenize a simple command, returning an empty list if it is not simple."""
    try:
        return shlex.split(command)
    except ValueError:
        return []


def is_safe_relative_token(token: str) -> bool:
    """Return true when a token cannot reference paths outside the workspace."""
    normalized_token = token.replace("\\", "/")
    has_windows_drive_prefix = (
        len(token) >= 2
        and token[0].isalpha()
        and token[1] == ":"
    )
    return not (
        normalized_token.startswith("/")
        or token.startswith("\\")
        or token.startswith("~")
        or has_windows_drive_prefix
        or normalized_token == ".."
        or normalized_token.startswith("../")
        or "/../" in normalized_token
        or normalized_token.endswith("/..")
    )


def all_tokens_workspace_safe(tokens: List[str]) -> bool:
    """Conservatively reject tokens that look like out-of-workspace paths."""
    return all(is_safe_relative_token(token) for token in tokens)


def has_windows_path_escape(command: str) -> bool:
    """Return true when the raw command contains Windows path escape forms."""
    normalized_command = command.replace("\\", "/")
    return (
        "..\\" in command
        or "\\\\" in command
        or "/../" in normalized_command
        or " ../" in normalized_command
        or normalized_command.endswith("/..")
    )


def is_readonly_or_pokayokay_command(command: str) -> bool:
    """Return true for low-risk commands the pokayokay hook can approve."""
    if has_shell_control_operator(command) or has_windows_path_escape(command):
        return False

    tokens = tokenize_shell_command(command)
    if not tokens:
        return False

    if command.endswith("/hooks/actions/bridge.py") and len(tokens) == 1:
        return True

    executable = tokens[0]
    args = tokens[1:]

    if executable == "pwd":
        return len(tokens) == 1

    if executable == "git" and args:
        safe_git_subcommands = {"status", "diff", "log", "branch", "rev-parse"}
        return args[0] in safe_git_subcommands and all_tokens_workspace_safe(args[1:])

    if executable in {"rg", "ls"}:
        return all_tokens_workspace_safe(args)

    if executable == "sed" and args[:1] == ["-n"]:
        return len(args) >= 2 and all_tokens_workspace_safe(args[1:])

    if executable == "cat" and args:
        return all(
            token.startswith("plugins/pokayokay/") and is_safe_relative_token(token)
            for token in args
        )

    if executable in {"bash", "node"} and len(args) == 1:
        return args[0].startswith("plugins/pokayokay/tests/") and is_safe_relative_token(args[0])

    if executable == "npx" and len(args) >= 1:
        return args[0] == "@stevestomp/ohno-cli" and all_tokens_workspace_safe(args[1:])

    return False


def handle_permission_request(tool_name: str, tool_input: dict) -> dict:
    """
    Handle Codex PermissionRequest events.

    The bridge only auto-decides commands that are clearly low-risk or clearly
    dangerous. Everything else falls through to Codex's normal approval prompt.
    """
    if tool_name != "Bash":
        return {"skip": True, "reason": "no automatic decision for non-Bash approval"}

    command = get_bash_command(tool_input)
    if not command:
        return {"skip": True, "reason": "no command in approval request"}

    if is_dangerous_command(command):
        return {
            "permission_decision": "deny",
            "reason": "Blocked by pokayokay policy: destructive or deployment command requires explicit human handling.",
        }

    if is_readonly_or_pokayokay_command(command):
        return {
            "permission_decision": "allow",
            "reason": "Approved by pokayokay policy: read-only, test, or task-tracking command.",
        }

    return {"skip": True, "reason": "approval left to runtime"}


def status_from_returncode(returncode: int) -> str:
    """Map an action script's exit code to a result status per the contract.

    0 = success, 2 = error (blocking), everything else = warning (advisory).
    Only exactly 2 blocks so unexpected codes (126/127, signals) stay advisory.
    """
    if returncode == 0:
        return "success"
    if returncode == 2:
        return "error"
    return "warning"


def get_timeout(hook_name: str) -> int:
    """Get the timeout for a specific hook."""
    return HOOK_TIMEOUTS.get(hook_name, HOOK_TIMEOUTS["default"])


def run_action(
    name: str,
    args: Optional[List[str]] = None,
    env: Optional[Dict[str, str]] = None,
    cwd: Optional[str] = None,
) -> Dict:
    """Run a yokay hook action script.

    ``cwd`` overrides the working directory (defaults to the project dir);
    story-boundary actions pass the story worktree so tests run against the
    tree that actually contains the story's changes.
    """
    script_path = get_script_dir() / f"{name}.sh"

    if not script_path.exists():
        return {"action": name, "status": "skipped", "reason": "script not found"}

    # Get configurable timeout for this hook
    timeout = get_timeout(name)

    try:
        # Merge environment
        run_env = os.environ.copy()
        if env:
            # Sanitize environment variables (neutralizes shell metacharacters)
            sanitized_env = {k: sanitize_env_value(v, field_name=k) for k, v in env.items()}
            run_env.update(sanitized_env)

        # Run the script with configurable timeout
        cmd = [str(script_path)] + (args or [])
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
            env=run_env,
            cwd=cwd or get_project_dir()
        )

        return {
            "action": name,
            "status": status_from_returncode(result.returncode),
            "output": result.stdout.strip(),
            "error": result.stderr.strip() if result.stderr else None
        }
    except subprocess.TimeoutExpired:
        return {"action": name, "status": "timeout", "reason": f"exceeded {timeout}s"}
    except Exception:
        # Execution failure is advisory, not "error": a broken script must
        # not block every commit under the exit-code contract.
        return {"action": name, "status": "warning", "reason": "Script execution failed"}


def _detect_stale_session() -> Optional[dict]:
    """Detect if a previous session crashed by checking for stale chain state.

    A session is considered crashed if:
    1. Chain state file exists (session was chaining)
    2. The state does NOT carry a handoff_pending marker (a clean chained
       SessionEnd sets it; its presence means this start is the expected
       continuation, not a crash)
    3. There are in_progress tasks in ohno (not cleaned up)

    Returns dict with stale_tasks and chain_id if crash detected, None otherwise.
    """
    chain_state = load_chain_state()
    if not chain_state.get("chain_id"):
        return None

    # A clean SessionEnd that chained to a continuation session sets
    # handoff_pending — in_progress tasks are then the deliberate handoff the
    # resume flow relies on, not crash debris. Consume the marker (one-shot)
    # so a genuine crash in THIS session is still detected on the next start.
    # Without this, recovery would stash the handed-off changes and retire
    # the chain state, silently killing the chain after one hop.
    if chain_state.get("handoff_pending"):
        chain_state.pop("handoff_pending", None)
        save_chain_state(chain_state)
        return None

    # Check for in_progress tasks via ohno-cli (global --json flag; output is
    # an object {"tasks": [...], "total_count": N}, not a bare list)
    try:
        result = subprocess.run(
            ["npx", "@stevestomp/ohno-cli", "--json", "tasks", "--status", "in_progress"],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0 and result.stdout.strip():
            import json as json_mod
            data = json_mod.loads(result.stdout)
            tasks = data.get("tasks", []) if isinstance(data, dict) else []
            if tasks:
                task_ids = [
                    t.get("id", "")
                    for t in tasks
                    if isinstance(t, dict) and t.get("id")
                ]
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

    # SessionStart also fires on mid-session compaction and resume. Only a
    # genuinely new session ("startup", "clear", or runtimes that send no
    # source) resets the token-usage ledger — an auto-compact must not wipe
    # the agent token data accumulated so far.
    source = str(input_data.get("source") or "").strip().lower()
    if source not in ("compact", "resume"):
        reset_token_usage()

    # Run pre-session verification
    results.append(run_action("verify-clean"))

    # Run pre-flight validation for unattended mode
    work_mode = os.environ.get("YOKAY_WORK_MODE", "")
    if work_mode == "unattended":
        preflight_result = run_action("pre-flight", env={"WORK_MODE": work_mode})
        results.append(preflight_result)

    # Detect and recover from crashed sessions. Skip on compaction (the
    # session is still alive, its in_progress tasks are not stale) and on
    # resume (`claude --resume` picks the old session back up — its
    # in_progress tasks are about to be worked on, not crash debris).
    stale = None if source in ("compact", "resume") else _detect_stale_session()
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


# ==========================================================================
# Runtime-agnostic state directory resolution
# ==========================================================================
#
# Reads prefer ``.pokayokay/`` and fall back to ``.claude/`` so existing
# Claude Code projects keep working. Writes go to whichever directory holds
# the file already (preserves user choice); when neither exists, writes go
# to ``.pokayokay/`` because it is runtime-agnostic.

PRIMARY_STATE_DIR = ".pokayokay"
LEGACY_STATE_DIR = ".claude"


def _resolve_state_path(filename: str) -> Path:
    """Return the path that should be read/written for a state file.

    Prefers an existing file in ``.pokayokay/``, then ``.claude/``. When
    neither file exists, returns the runtime-agnostic ``.pokayokay/`` path.
    """
    project_dir = Path(get_project_dir())
    primary = project_dir / PRIMARY_STATE_DIR / filename
    legacy = project_dir / LEGACY_STATE_DIR / filename

    if primary.exists():
        return primary
    if legacy.exists():
        return legacy
    return primary


def load_pokayokay_config() -> dict:
    """Load pokayokay configuration.

    Reads ``.pokayokay/config.json`` when present, falling back to
    ``.claude/pokayokay.json`` for legacy Claude Code projects.
    """
    project_dir = Path(get_project_dir())
    primary = project_dir / PRIMARY_STATE_DIR / "config.json"
    legacy = project_dir / LEGACY_STATE_DIR / "pokayokay.json"

    config_path = primary if primary.exists() else legacy
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
    """Get path to the chain state file (prefers .pokayokay/, falls back to .claude/)."""
    return _resolve_state_path(CHAIN_STATE_FILENAME)


def load_chain_state() -> dict:
    """Load chain state from .pokayokay/ or .claude/ (legacy fallback).

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
    """Save chain state to the active state directory.

    Writes to whichever directory already holds the file; otherwise writes
    to the runtime-agnostic ``.pokayokay/`` location.

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
    """Remove the chain state file from both possible locations."""
    project_dir = Path(get_project_dir())
    for candidate in (
        project_dir / PRIMARY_STATE_DIR / CHAIN_STATE_FILENAME,
        project_dir / LEGACY_STATE_DIR / CHAIN_STATE_FILENAME,
    ):
        try:
            if candidate.exists():
                candidate.unlink()
        except OSError:
            pass  # Best-effort cleanup


# ==========================================================================
# Task State File Functions
# ==========================================================================
#
# Environment variables exported by the coordinator never reach hook
# subprocesses (the exact propagation bug already fixed once for chain
# state), so the active task id and the /work --worktree / --in-place
# override flags travel through a state file instead:
#
# - The coordinator MAY pre-write {"force_worktree": ..., "force_inplace": ...}
#   before marking a task in_progress.
# - handle_task_start merges those flags with the task id and persists
#   {task_id, force_worktree, force_inplace}.
# - WIP tracking (Edit/Write/Bash events) and review-failure attribution
#   read task_id from the file (env var kept as a legacy fallback).
# - handle_task_complete clears the file.

TASK_STATE_FILENAME = "pokayokay-task-state.json"


def _task_state_path() -> Path:
    """Get path to the task state file (prefers .pokayokay/, falls back to .claude/)."""
    return _resolve_state_path(TASK_STATE_FILENAME)


def load_task_state() -> dict:
    """Load the active-task state. Returns {} when absent or unreadable."""
    state_path = _task_state_path()
    if not state_path.exists():
        return {}
    try:
        with open(state_path) as f:
            state = json.load(f)
        return state if isinstance(state, dict) else {}
    except (json.JSONDecodeError, OSError):
        return {}


def save_task_state(state: dict) -> None:
    """Save the active-task state (atomic write, best-effort)."""
    state_path = _task_state_path()
    state_path.parent.mkdir(parents=True, exist_ok=True)

    tmp_path = state_path.with_suffix(".tmp")
    try:
        with open(tmp_path, "w") as f:
            json.dump(state, f, indent=2)
            f.write("\n")
        tmp_path.rename(state_path)
    except OSError:
        if tmp_path.exists():
            tmp_path.unlink()


def clear_task_state() -> None:
    """Remove the task state file from both possible locations."""
    project_dir = Path(get_project_dir())
    for candidate in (
        project_dir / PRIMARY_STATE_DIR / TASK_STATE_FILENAME,
        project_dir / LEGACY_STATE_DIR / TASK_STATE_FILENAME,
    ):
        try:
            if candidate.exists():
                candidate.unlink()
        except OSError:
            pass  # Best-effort cleanup


def get_active_task_id() -> str:
    """Return the active task id: task state file first, env fallback.

    The env fallback (CURRENT_OHNO_TASK_ID) only works when the bridge is
    invoked from a shell that exported it (tests, direct runs) — coordinator
    exports never reach hook subprocesses, hence the state file.
    """
    task_id = str(load_task_state().get("task_id") or "").strip()
    if task_id:
        return task_id
    return os.environ.get("CURRENT_OHNO_TASK_ID", "")


def _coerce_flag(value) -> str:
    """Normalize a JSON/env truthy flag to the literal string 'true'/'false'."""
    return "true" if str(value).strip().lower() == "true" else "false"


# ==========================================================================
# Token Usage Tracking
# ==========================================================================

TOKEN_USAGE_FILENAME = "pokayokay-token-usage.json"


def _token_usage_path() -> Path:
    """Get path to the token usage file (prefers .pokayokay/, falls back to .claude/)."""
    return _resolve_state_path(TOKEN_USAGE_FILENAME)


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


def record_agent_tokens(agent_type: str, description: str, tool_response) -> None:
    """Record token usage from a completed Task (subagent) tool call."""
    total_tokens = 0
    tool_uses = 0
    duration_ms = 0

    # Claude Code exposes structured usage fields on the Task tool_response.
    if isinstance(tool_response, dict):
        try:
            total_tokens = int(tool_response.get("totalTokens") or 0)
            tool_uses = int(tool_response.get("totalToolUseCount") or 0)
            duration_ms = int(tool_response.get("totalDurationMs") or 0)
        except (TypeError, ValueError):
            total_tokens = tool_uses = duration_ms = 0

    # Codex fallback: scrape snake_case usage keys from the response text.
    # (The Task output itself arrives in content blocks on Claude Code, not
    # a top-level "result" key — extract_output_text handles both shapes.)
    if not total_tokens:
        result_text = extract_output_text(tool_response)
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


def _get_memory_dir() -> Optional[Path]:
    """Get the auto memory directory for the current project.

    Checks Claude's project memory directory first, falls back to project-local.
    Returns None if neither can be determined.
    """
    project_dir = get_project_dir()
    # Claude Code encodes project keys by replacing EVERY non-alphanumeric
    # character with "-" and keeps the leading dash (verified on disk:
    # ~/.claude/projects/-Users-steve-...; "." and "_" also become "-").
    project_key = re.sub(r"[^A-Za-z0-9]", "-", project_dir)
    claude_memory = Path.home() / ".claude" / "projects" / project_key / "memory"
    if claude_memory.exists():
        return claude_memory
    local_memory = Path(project_dir) / "memory"
    if local_memory.exists():
        return local_memory
    return None


def _write_chain_learnings(chain_state: dict, tasks_completed_count: int) -> None:
    """Write chain progress to memory at session end."""
    target_dir = _get_memory_dir()
    if target_dir is None:
        target_dir = Path(get_project_dir()) / "memory"
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
    target_dir = _get_memory_dir()
    if target_dir is None:
        target_dir = Path(get_project_dir()) / "memory"
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

    # Curate MEMORY.md - enforce section structure and line budgets
    memory_dir = _get_memory_dir()
    if memory_dir:
        results.append(run_action("curate-memory", env={"MEMORY_DIR": str(memory_dir)}))

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
                    # Mark the handoff as clean so the continuation session's
                    # SessionStart doesn't mistake handed-off in_progress
                    # tasks for a crash (see _detect_stale_session).
                    chain_state["handoff_pending"] = True
                    save_chain_state(chain_state)
                elif chain_action == "audit_pending":
                    # Don't end the chain - signal coordinator to run audit
                    chain_state["audit_pending"] = True
                    chain_state["handoff_pending"] = True
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


def parse_mcp_payload(tool_response) -> dict:
    """Parse an MCP tool result into a plain dict.

    ohno's MCP server wraps every tool result as
    ``{"content": [{"type": "text", "text": "<json string>"}]}`` — and some
    runtimes deliver the content-block list directly. Extract the text via
    extract_output_text and json.loads it. Falls back to top-level dict reads
    (the Codex shape, where the result object arrives unwrapped) when there is
    no parseable JSON payload. Never raises; returns {} for unusable input.
    """
    text = extract_output_text(tool_response)
    if text:
        try:
            parsed = json.loads(text)
            if isinstance(parsed, dict):
                return parsed
        except (json.JSONDecodeError, ValueError):
            pass
    return tool_response if isinstance(tool_response, dict) else {}


def _lookup_task(task_id: str) -> dict:
    """Fetch task metadata (title, task_type, story_id) via the ohno CLI.

    ohno's update_task_status result carries no ``task`` object and its input
    schema rejects title/type fields, so the CLI is the only source for the
    TASK_TITLE/TASK_TYPE/STORY_ID env vars passed to hook scripts.
    Best-effort: short timeout, returns {} on any failure.
    """
    if not task_id or task_id == "unknown":
        return {}
    try:
        result = subprocess.run(
            ["npx", "@stevestomp/ohno-cli", "--json", "task", "get", task_id],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0 and result.stdout.strip():
            data = json.loads(result.stdout)
            if isinstance(data, dict):
                return data
    except (subprocess.TimeoutExpired, json.JSONDecodeError, OSError, Exception):
        pass
    return {}


def handle_task_start(tool_input: dict, tool_response: dict) -> dict:
    """Handle task status change to in_progress - run pre-task hooks."""
    task_id = tool_input.get("task_id", "unknown")

    # ohno MCP results arrive as JSON inside content blocks — parse them.
    response_data = parse_mcp_payload(tool_response)

    # Extract task metadata from response if available, otherwise look the
    # task up via the ohno CLI (update_task_status results carry no task
    # object and its input schema rejects title/type, so tool_input
    # fallbacks alone can never populate these).
    task_data = response_data.get("task")
    if not isinstance(task_data, dict) or not task_data:
        task_data = _lookup_task(task_id)
    task_title = task_data.get("title") or tool_input.get("title", "")
    task_type = (
        task_data.get("task_type")
        or task_data.get("type")
        or tool_input.get("type")
        or "feature"
    )
    story_id = task_data.get("story_id") or ""

    # Worktree override flags come from the task state file: the coordinator
    # writes them there before marking the task in_progress, because exported
    # env vars never reach this hook subprocess. The YOKAY_* env vars remain
    # as a legacy fallback for direct invocations.
    task_state = load_task_state()
    force_worktree = _coerce_flag(
        task_state.get("force_worktree", os.environ.get("YOKAY_FORCE_WORKTREE", "false"))
    )
    force_inplace = _coerce_flag(
        task_state.get("force_inplace", os.environ.get("YOKAY_FORCE_INPLACE", "false"))
    )

    # Persist the active task so later per-event bridge processes (WIP
    # tracking, review-failure attribution) can attribute work to it.
    save_task_state({
        "task_id": task_id,
        "force_worktree": force_worktree,
        "force_inplace": force_inplace,
    })

    # Memory-informed skill routing needs the project memory dir; hook
    # subprocesses can't compute it from Claude-internal state, so pass it
    # explicitly (matching the curate-memory dispatch at session end).
    memory_dir = _get_memory_dir()

    env = {
        "TASK_ID": task_id,
        "TASK_TITLE": task_title,
        "TASK_TYPE": task_type,
        "STORY_ID": story_id,
        "FORCE_WORKTREE": force_worktree,
        "FORCE_INPLACE": force_inplace,
        "MEMORY_DIR": str(memory_dir) if memory_dir else "",
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


def _find_story_worktree(story_id: str) -> Optional[str]:
    """Resolve the story worktree path via ``git worktree list --porcelain``.

    setup-worktree.sh names story worktrees ``.worktrees/story-<story_id>-<slug>``.
    Returns the worktree path when one exists on disk, else None (porcelain
    ``worktree <path>`` lines are parsed whole, so paths with spaces work).
    """
    if not story_id:
        return None
    try:
        result = subprocess.run(
            ["git", "worktree", "list", "--porcelain"],
            capture_output=True, text=True, timeout=10,
            cwd=get_project_dir(),
        )
        if result.returncode != 0:
            return None
        marker = f"story-{story_id}-"
        for line in result.stdout.splitlines():
            if line.startswith("worktree "):
                path = line[len("worktree "):].strip()
                if os.path.basename(path).startswith(marker) and os.path.isdir(path):
                    return path
    except (subprocess.TimeoutExpired, OSError):
        pass
    return None


def handle_task_complete(tool_input: dict, tool_response: dict) -> dict:
    """Handle mcp__ohno__update_task_status PostToolUse event for task completion."""
    results = []
    hooks_run = []

    task_id = tool_input.get("task_id", "unknown")

    # ohno MCP results arrive as JSON inside content blocks — parse them.
    response_data = parse_mcp_payload(tool_response)

    # Extract task metadata from response if available, otherwise look the
    # task up via the ohno CLI (update_task_status results are
    # {success, boundaries?} with no task object).
    task_data = response_data.get("task")
    if not isinstance(task_data, dict) or not task_data:
        task_data = _lookup_task(task_id)
    task_title = task_data.get("title") or tool_input.get("title", "")
    task_type = (
        task_data.get("task_type")
        or task_data.get("type")
        or tool_input.get("type")
        or ""
    )
    task_notes = tool_input.get("notes", "")

    # Extract boundary metadata from the parsed MCP payload
    boundaries = response_data.get("boundaries", {})
    if not isinstance(boundaries, dict):
        boundaries = {}
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

    # Update chain state: increment tasks_completed BEFORE the long-running
    # story/epic boundary actions so the count survives if the runtime kills
    # the bridge process partway through a boundary chain.
    chain_state = load_chain_state()
    if chain_state.get("chain_id"):
        chain_state["tasks_completed"] = chain_state.get("tasks_completed", 0) + 1
        save_chain_state(chain_state)

    # Run post-story hooks if story completed
    if story_completed:
        hooks_run.append("post-story")
        # The story's changes live in its worktree (setup-worktree.sh names
        # them .worktrees/story-<story_id>-<slug>), not the main checkout —
        # run the boundary checks there when the worktree exists.
        story_worktree = _find_story_worktree(story_id or "")
        boundary_env = dict(env)
        if story_worktree:
            boundary_env["WORKTREE_DIR"] = story_worktree
        results.append(run_action("test", env=boundary_env, cwd=story_worktree))
        results.append(run_action("story-integration", env=boundary_env, cwd=story_worktree))
        # Run audit-gate for story boundary
        story_env = {**boundary_env, "BOUNDARY_TYPE": "story"}
        results.append(run_action("audit-gate", env=story_env, cwd=story_worktree))

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

    # The task is no longer active — clear the task state file so later
    # Edit/Bash events don't attribute work to a finished task. Skip when a
    # different task has already been started (overlapping task starts).
    current_state = load_task_state()
    if not current_state or current_state.get("task_id") in ("", None, task_id):
        clear_task_state()

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
    import re

    command = tool_input.get("command", "")

    # Match `git commit` / `git add` only when it is an actual command (at the
    # start of the string or after a shell separator/newline/subshell open),
    # not quoted text inside another command. Tolerates flag-style global
    # options (`git --no-pager commit`) but intentionally does not match
    # option-with-argument forms like `git -C dir commit` — a conscious
    # tightening vs the old substring check.
    git_write_pattern = r'(?:^|&&|\|\||;|\||\n|\()\s*git(?:\s+-\S+)*\s+(?:commit|add)\b'
    if not re.search(git_write_pattern, command):
        return {"skip": True, "reason": "not a commit command"}

    results = []

    # Run pre-commit hooks. check-ref-sizes needs the intercepted command to
    # decide whether unstaged files are about to be staged (add-all forms) or
    # irrelevant to the commit (env values are metachar-sanitized in transit).
    results.append(run_action("lint"))
    results.append(run_action("check-ref-sizes", env={"POKAYOKAY_GIT_COMMAND": command}))

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
    """Get path to the review failure tracking file (prefers .pokayokay/, falls back to .claude/)."""
    return _resolve_state_path(FAILURE_TRACKING_FILENAME)


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
    target_dir = _get_memory_dir()
    if target_dir is None:
        target_dir = Path(get_project_dir()) / "memory"
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

    # Get the agent output. On Claude Code the Task tool_response carries the
    # subagent output in content blocks; "result" is the Codex alias already
    # normalized by normalize_hook_input. extract_output_text handles both.
    agent_output = extract_output_text(tool_response)

    # Detect PASS/FAIL
    if ": PASS" in agent_output:
        return {"skip": True, "reason": "review passed"}

    if ": FAIL" not in agent_output:
        return {"skip": True, "reason": "could not determine review result"}

    # Extract failure source
    failure_source = "spec-review" if is_spec_review else "quality-review"

    # Get task ID from the task state file (written by handle_task_start;
    # env var is a legacy fallback for direct invocations)
    task_id = get_active_task_id() or "unknown"

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
    project_dir = get_project_dir()
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
            cwd=get_project_dir()
        )

        return {
            "action": name,
            "status": status_from_returncode(result.returncode),
            "output": result.stdout.strip(),
            "error": result.stderr.strip() if result.stderr else None
        }
    except subprocess.TimeoutExpired:
        return {"action": name, "status": "timeout", "reason": f"exceeded {timeout}s"}
    except Exception:
        # Execution failure is advisory, not "error": a broken script must
        # not block every commit under the exit-code contract.
        return {"action": name, "status": "warning", "reason": "Script execution failed"}


# ==========================================================================
# WIP Auto-capture Functions
# ==========================================================================
#
# The bridge is spawned as a fresh process per hook event, so WIP debounce
# state (last update time + files touched for the active task) is persisted
# to ``.pokayokay/wip-state.json`` instead of module globals.

WIP_STATE_FILENAME = "wip-state.json"


def _wip_state_path() -> Path:
    """Get path to the WIP state file (prefers .pokayokay/, falls back to .claude/)."""
    return _resolve_state_path(WIP_STATE_FILENAME)


def _default_wip_state(task_id: str) -> dict:
    return {"task_id": task_id, "last_update": 0.0, "files": []}


def load_wip_state(task_id: str) -> dict:
    """Load WIP debounce state, resetting it when the active task changes.

    Falls back to a fresh state (per-event behavior) on any JSON/IO error.
    """
    state_path = _wip_state_path()
    if not state_path.exists():
        return _default_wip_state(task_id)

    try:
        with open(state_path) as f:
            state = json.load(f)
        if not isinstance(state, dict) or state.get("task_id") != task_id:
            return _default_wip_state(task_id)
        files = state.get("files")
        state["files"] = (
            [entry for entry in files if isinstance(entry, str)]
            if isinstance(files, list)
            else []
        )
        state["last_update"] = float(state.get("last_update") or 0.0)
        return state
    except (json.JSONDecodeError, OSError, TypeError, ValueError):
        return _default_wip_state(task_id)


def save_wip_state(state: dict) -> None:
    """Save WIP debounce state.

    Uses atomic write (temp file + rename) to prevent corruption. Best-effort:
    hooks never crash on write failure.
    """
    state_path = _wip_state_path()
    state_path.parent.mkdir(parents=True, exist_ok=True)

    tmp_path = state_path.with_suffix(".tmp")
    try:
        with open(tmp_path, "w") as f:
            json.dump(state, f, indent=2)
            f.write("\n")
        tmp_path.rename(state_path)
    except OSError:
        if tmp_path.exists():
            tmp_path.unlink()


def extract_output_text(tool_response) -> str:
    """Extract text output from tool response (handles Claude and Codex formats)."""
    if isinstance(tool_response, str):
        return tool_response
    if isinstance(tool_response, list):
        # Bare list of MCP content blocks: [{"type": "text", "text": "..."}]
        return "\n".join(
            c.get("text", "") for c in tool_response if isinstance(c, dict)
        )
    if isinstance(tool_response, dict):
        # Claude Code shape: {"content": [{"text": "..."}]} or {"content": "..."}
        content = tool_response.get("content")
        if isinstance(content, list) and content:
            joined = "\n".join(c.get("text", "") for c in content if isinstance(c, dict))
            if joined:
                return joined
        if isinstance(content, str) and content:
            return content
        # Codex / fallback shape: {"output": "..."} or {"text": "..."}
        return tool_response.get("output") or tool_response.get("text") or ""
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
    task_id = get_active_task_id()
    if not task_id or task_id == "unknown":
        return {"skip": True, "reason": "no active task"}

    file_path = tool_input.get("file_path", "")
    if not file_path:
        return {"skip": True, "reason": "no file path"}

    # Track this file in the persisted state
    state = load_wip_state(task_id)
    if file_path not in state["files"]:
        state["files"].append(file_path)

    # Debounce WIP updates across bridge invocations
    now = time.time()
    if now - state["last_update"] < WIP_UPDATE_INTERVAL:
        save_wip_state(state)
        return {"skip": True, "reason": "debounced"}

    wip_data = {
        "files_modified": sorted(state["files"]),
        "uncommitted_changes": True
    }

    update_wip(task_id, wip_data)
    state["last_update"] = now
    save_wip_state(state)
    return {"skip": True, "reason": "wip updated silently"}


def handle_bash_execution(tool_input: dict, tool_response: dict) -> dict:
    """Capture test results, git commits, and errors from Bash."""
    task_id = get_active_task_id()
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
            force_update = True  # Always update immediately for commits

    # Detect errors (non-zero exit)
    if exit_code and exit_code != 0 and not is_test_command(command):
        error_info = parse_error(command, output)
        if error_info:
            wip_data["errors"] = [error_info]

    if not wip_data:
        return {"skip": True, "reason": "wip updated silently"}

    state = load_wip_state(task_id)
    now = time.time()
    debounced = not force_update and now - state["last_update"] < WIP_UPDATE_INTERVAL

    if not debounced:
        update_wip(task_id, wip_data)
        state["last_update"] = now

    if force_update:
        # Commit landed - clear tracked files so the next WIP snapshot
        # doesn't resend already-committed files.
        state["files"] = []

    save_wip_state(state)
    return {"skip": True, "reason": "debounced" if debounced else "wip updated silently"}


def main():
    """Main entry point."""
    try:
        # Read hook input from stdin
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(json.dumps({"error": f"Invalid JSON input: {e}"}))
        sys.exit(2)

    input_data = normalize_hook_input(input_data)
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

    elif hook_event == "PermissionRequest":
        result = handle_permission_request(tool_name, tool_input)

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
        if hook_event == "PermissionRequest":
            decision = result.get("permission_decision")
            if decision in ("allow", "deny"):
                output = {
                    "hookSpecificOutput": {
                        "hookEventName": "PermissionRequest",
                        "decision": {
                            "behavior": decision
                        }
                    }
                }
                if decision == "deny":
                    output["hookSpecificOutput"]["decision"]["message"] = result.get(
                        "reason",
                        "Blocked by pokayokay policy.",
                    )
                print(json.dumps(output))
            else:
                print(json.dumps({}))
        if hook_event == "SessionEnd":
            # SessionEnd doesn't support hookSpecificOutput - just output empty
            print(json.dumps({}))
        elif hook_event != "PermissionRequest":
            # Format for Claude Code hook output
            output = {
                "hookSpecificOutput": {
                    "hookEventName": hook_event,
                    "additionalContext": format_context(result)
                }
            }

            # Block if requested (for pre-commit failures)
            if result.get("block"):
                block_reason = result.get("reason", "Hook check failed")
                if hook_event == "PreToolUse":
                    # Current hook API shape: deny via hookSpecificOutput,
                    # merged alongside additionalContext.
                    output["hookSpecificOutput"]["permissionDecision"] = "deny"
                    output["hookSpecificOutput"]["permissionDecisionReason"] = block_reason
                # Top-level decision/reason is the deprecated legacy shape,
                # kept for older runtimes.
                output["decision"] = "block"
                output["reason"] = block_reason

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
