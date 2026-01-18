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
from pathlib import Path
from typing import Dict, List, Optional


def get_script_dir() -> Path:
    """Get the directory containing this script."""
    return Path(__file__).parent


def run_action(name: str, args: Optional[List[str]] = None, env: Optional[Dict[str, str]] = None) -> Dict:
    """Run a yokay hook action script."""
    script_path = get_script_dir() / f"{name}.sh"

    if not script_path.exists():
        return {"action": name, "status": "skipped", "reason": "script not found"}

    try:
        # Merge environment
        run_env = os.environ.copy()
        if env:
            run_env.update(env)

        # Run the script
        cmd = [str(script_path)] + (args or [])
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=60,
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
        return {"action": name, "status": "timeout", "reason": "exceeded 60s"}
    except Exception as e:
        return {"action": name, "status": "error", "reason": str(e)}


def handle_task_status_update(tool_response: dict) -> dict:
    """Handle mcp__ohno__update_task_status PostToolUse event."""
    results = []
    hooks_run = []

    # Extract boundary metadata
    boundaries = tool_response.get("boundaries", {})
    story_completed = boundaries.get("story_completed", False)
    epic_completed = boundaries.get("epic_completed", False)
    story_id = boundaries.get("story_id")
    epic_id = boundaries.get("epic_id")

    # Build environment for scripts
    env = {
        "STORY_ID": story_id or "",
        "EPIC_ID": epic_id or "",
        "STORY_COMPLETED": str(story_completed).lower(),
        "EPIC_COMPLETED": str(epic_completed).lower(),
    }

    # Always run post-task hooks
    hooks_run.append("post-task")
    results.append(run_action("sync", env=env))
    results.append(run_action("commit", env=env))

    # Run post-story hooks if story completed
    if story_completed:
        hooks_run.append("post-story")
        results.append(run_action("test", env=env))
        # Note: mini-audit would be a yokay command, not a shell script

    # Run post-epic hooks if epic completed
    if epic_completed:
        hooks_run.append("post-epic")
        # Note: full-audit would be a yokay command, not a shell script

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

    # Route to appropriate handler
    if tool_name == "mcp__ohno__update_task_status":
        # Check if status is "done" - only then do we check boundaries
        status = tool_input.get("status", "")
        if status in ("done", "archived"):
            result = handle_task_status_update(tool_response)
        else:
            result = {"skip": True, "reason": f"status is {status}, not done/archived"}

    elif tool_name == "mcp__ohno__set_blocker":
        result = handle_set_blocker(tool_input, tool_response)

    elif tool_name == "Bash" and hook_event == "PreToolUse":
        result = handle_pre_commit(tool_input)

    else:
        result = {"skip": True, "reason": f"unhandled tool: {tool_name}"}

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
            status_icon = {"success": "✓", "warning": "⚠️", "error": "❌", "skipped": "⏭️"}.get(r["status"], "?")
            output = r.get("output", r.get("reason", ""))[:50]
            lines.append(f"| {r['action']} | {status_icon} | {output} |")

    # Summary
    if result.get("summary"):
        lines.append("")
        lines.append(f"**Summary:** {result['summary']}")

    # Blocker info
    if result.get("blocker_reason"):
        lines.append("")
        lines.append(f"**Blocker:** {result['blocker_reason']}")

    if result.get("suggestion"):
        lines.append(f"**Suggestion:** {result['suggestion']}")

    return "\n".join(lines)


if __name__ == "__main__":
    main()
