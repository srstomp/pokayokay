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
    "sync": 30,
    "commit": 30,
    "verify-tasks": 15,
    "verify-clean": 10,
    "check-blockers": 10,
    "suggest-skills": 10,
    "detect-spike": 10,
    "capture-knowledge": 15,
    "session-summary": 15,
    "post-review-fail": 30,
}

# Rate limiting configuration
RATE_LIMIT_MAX_EXECUTIONS = 10  # Max executions per hook per minute
RATE_LIMIT_WINDOW_SECONDS = 60

# Track hook executions for rate limiting (in-memory, resets on process restart)
_hook_executions: Dict[str, List[float]] = defaultdict(list)


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


def handle_session_start(input_data: dict) -> dict:
    """Handle SessionStart event - run pre-session hooks."""
    results = []

    # Run pre-session verification
    results.append(run_action("verify-clean"))

    success_count = sum(1 for r in results if r["status"] == "success")
    warning_count = sum(1 for r in results if r["status"] == "warning")

    return {
        "hooks_run": ["pre-session"],
        "results": results,
        "summary": f"{success_count} passed, {warning_count} warnings"
    }


def handle_session_end(input_data: dict) -> dict:
    """Handle SessionEnd event - run post-session hooks."""
    results = []

    # Run post-session hooks
    results.append(run_action("sync"))
    results.append(run_action("session-summary"))

    success_count = sum(1 for r in results if r["status"] == "success")
    warning_count = sum(1 for r in results if r["status"] == "warning")

    return {
        "hooks_run": ["post-session"],
        "results": results,
        "summary": f"{success_count} passed, {warning_count} warnings"
    }


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

    # Run post-story hooks if story completed
    if story_completed:
        hooks_run.append("post-story")
        results.append(run_action("test", env=env))
        # Run audit-gate for story boundary
        story_env = {**env, "BOUNDARY_TYPE": "story"}
        results.append(run_action("audit-gate", env=story_env))

    # Run post-epic hooks if epic completed
    if epic_completed:
        hooks_run.append("post-epic")
        # Run audit-gate for epic boundary
        epic_env = {**env, "BOUNDARY_TYPE": "epic"}
        results.append(run_action("audit-gate", env=epic_env))

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

    # Check for failures that should block
    has_blocking_error = any(r["status"] == "error" for r in results)

    return {
        "hooks_run": ["pre-commit"],
        "results": results,
        "block": has_blocking_error,
        "reason": "lint failed" if has_blocking_error else None
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

    return {
        "hooks_run": ["post-review-fail"],
        "review_type": failure_source,
        "task_id": task_id,
        "kaizen_action": action_data.get("action", "LOGGED"),
        "fix_task": action_data.get("fix_task"),
        "kaizen_message": action_data.get("message"),
        "results": [result],
        "summary": f"Review failed, kaizen action: {action_data.get('action', 'LOGGED')}"
    }


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
        result = handle_review_complete(tool_input, tool_response)

    else:
        result = {"skip": True, "reason": f"unhandled event: {hook_event}/{tool_name}"}

    # Output result
    if result and not result.get("skip"):
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
