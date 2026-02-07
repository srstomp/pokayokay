# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

pokayokay is a Claude Code plugin that orchestrates AI-assisted development sessions. It integrates with ohno (task management via MCP) to provide structured workflows with configurable human oversight.

## Development Commands

```bash
# Local development - load plugin from directory
claude --plugin-dir ./pokayokay

# Validate plugin manifest
claude plugin validate plugins/pokayokay

# Run CLI setup wizard locally
node cli/bin/cli.js

# Run specific shell tests
bash plugins/pokayokay/tests/<test-name>.test.sh

# Run all shell tests
for test in plugins/pokayokay/tests/*.test.sh; do bash "$test"; done
```

## Architecture

### Plugin Structure (`plugins/pokayokay/`)

```
plugins/pokayokay/
├── commands/      # Slash command definitions (markdown files)
├── skills/        # Domain knowledge and workflows (subdirs with SKILL.md + references/)
├── agents/        # Subagent definitions for Task tool dispatch
│   └── templates/ # Prompt templates for agent dispatch
└── hooks/
    └── actions/   # Shell scripts + bridge.py for hook execution
```

### Hook System Flow

The plugin uses Claude Code native hooks with `bridge.py` as the central router:

```
Claude Code Hook Event
        │
        ▼
    bridge.py  ──→ Routes to appropriate hook action
        │
        ├── SessionStart  → verify-clean.sh
        ├── update_task_status(done) → sync.sh, commit.sh, detect-spike.sh
        │   └── if story_completed → test.sh, audit-gate.sh
        │   └── if epic_completed → audit-gate.sh
        ├── update_task_status(in_progress) → check-blockers.sh, setup-worktree.sh
        ├── set_blocker → notification
        ├── Task (reviewer agents) → post-review-fail hook (kaizen integration)
        └── SessionEnd → sync, session-summary, session-chain
```

Hook configuration is in `.claude/settings.local.json` under the `hooks` key.

### Subagent Architecture

The `/work` command uses a coordinator pattern that dispatches specialized agents:

1. **yokay-brainstormer** - Refines ambiguous tasks before implementation
2. **yokay-browser-verifier** - Verifies UI changes in a real browser
3. **yokay-explorer** - Fast codebase search (Haiku model, read-only)
4. **yokay-fixer** - Auto-retry on test failures with targeted fixes
5. **yokay-implementer** - Executes tasks with fresh context (TDD)
6. **yokay-planner** - PRD analysis and structured plan generation
7. **yokay-reviewer** - Code review and analysis (read-only)
8. **yokay-security-scanner** - OWASP vulnerability scanning (read-only)
9. **yokay-task-reviewer** - Spec compliance + code quality review
10. **yokay-spike-runner** - Time-boxed technical investigations
11. **yokay-test-runner** - Test execution with concise output
12. **yokay-auditor** - L0-L5 completeness scanning (read-only)

Agents are dispatched via the Task tool with `subagent_type` matching the agent filename (without .md).

### CLI (`cli/`)

Setup wizard for installing the plugin, configuring ohno MCP, and optional kaizen integration. Published as `pokayokay` on npm.

## Key Integration Points

### ohno MCP Server

Task management is handled via ohno MCP tools (prefixed `mcp__ohno__`):
- `create_task`, `get_task`, `update_task_status`, `get_next_task`
- `create_story`, `create_epic` for hierarchy
- `add_task_activity` for logging
- `get_session_context` for session continuity

ohno returns **boundary metadata** when tasks complete, indicating if a story or epic was also completed. This triggers appropriate post-boundary hooks.

### Worktree Management

Tasks automatically get isolated git worktrees based on type:
- `feature`, `bug`, `spike` → worktree in `.worktrees/`
- `chore`, `docs` → work in-place

Story tasks reuse the same worktree for related changes.

## File Conventions

- **Commands** (`commands/*.md`): Frontmatter with `description`, `argument-hint`, optional `skill` reference
- **Skills** (`skills/<name>/SKILL.md`): Main skill file with `references/` subdirectory for detailed guides
- **Agents** (`agents/*.md`): Agent definitions loaded by Task tool's `subagent_type`
- **Hook Actions** (`hooks/actions/*.sh`): Shell scripts executed by bridge.py

## Testing

Shell-based integration tests in `plugins/pokayokay/tests/`:
- Tests are standalone bash scripts that verify hook behavior
- Exit code 0 = pass, non-zero = fail
- Tests mock ohno data via environment variables
