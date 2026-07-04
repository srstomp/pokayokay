# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

pokayokay is a Claude Code plugin that orchestrates AI-assisted development sessions. It integrates with ohno (task management via MCP) to provide structured workflows with configurable human oversight.

## Development Commands

```bash
# Local development - load plugin from directory
claude --plugin-dir ./plugins/pokayokay

# Validate plugin manifest
claude plugin validate plugins/pokayokay

# Run CLI setup wizard locally
node cli/bin/cli.js

# Run specific shell tests
bash plugins/pokayokay/tests/<test-name>.test.sh

# Run the full test suite (shell + node, per-test PASS/FAIL, non-zero exit on failure)
npm test
# or directly:
bash plugins/pokayokay/tests/run-tests.sh
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
        ├── SessionStart  → verify-clean.sh, pre-flight.sh (unattended), recover.sh (if crashed)
        ├── update_task_status(done) → sync.sh, commit.sh, detect-spike.sh, capture-knowledge.sh
        │   └── if story_completed → test.sh, story-integration.sh, audit-gate.sh
        │   └── if epic_completed → audit-gate.sh
        ├── update_task_status(in_progress) → check-blockers.sh, suggest-skills.sh, setup-worktree.sh
        ├── set_blocker → notification
        ├── Task (any agent) → token tracking; reviewers → post-review-fail + graduate-rules.sh
        ├── Skill (post-command) → verify-tasks.sh
        ├── Edit/Write → WIP tracking (files modified)
        ├── Bash (PreToolUse, git commit) → lint.sh, check-ref-sizes.sh
        ├── Bash (PostToolUse) → WIP tracking (test results, commits, errors)
        └── SessionEnd → sync, session-summary, curate-memory.sh, session-chain
```

Hooks are registered through the plugin system and routed by `bridge.py`.

### Subagent Architecture

The `/work`, `/fix`, and `/hotfix` commands use a coordinator pattern that dispatches specialized agents. `/quick` works inline without agents. `/fix` uses a light pipeline (implementer only) by default; `/fix --thorough` engages the full pipeline.

1. **yokay-brainstormer** - Refines ambiguous tasks before implementation
2. **yokay-browser-verifier** - Verifies UI changes in a real browser
3. **yokay-design-reviewer** - Pre-implementation design review; validates approach against codebase patterns and design skills (read-only)
4. **yokay-explorer** - Fast codebase search (Haiku model, read-only)
5. **yokay-fixer** - Auto-retry on test failures with targeted fixes
6. **yokay-implementer** - Executes tasks with AC-first TDD, follows pre-validated approach from design reviewer
7. **yokay-planner** - PRD analysis with structured acceptance criteria (MUST/SHOULD/COULD)
8. **yokay-quality-reviewer** - Code quality review with automated checks (coverage, lint, test-AC mapping) + design compliance post-check
9. **yokay-reviewer** - Code review and analysis (read-only)
10. **yokay-security-scanner** - OWASP vulnerability scanning (read-only)
11. **yokay-spec-reviewer** - Checklist-based spec review with evidence table (file:line for each criterion)
12. **yokay-spike-runner** - Time-boxed technical investigations
13. **yokay-test-runner** - Test execution with concise output
14. **yokay-auditor** - L0-L5 completeness scanning (read-only)

Agents are dispatched via the Task tool with `subagent_type` set to the plugin-prefixed agent name, e.g. `pokayokay:yokay-implementer` (the agent filename without `.md`, prefixed with `pokayokay:`).

### Agent Model Policy

Agent frontmatter follows a three-tier model policy:

| Tier | Frontmatter | Agents |
|------|-------------|--------|
| Judgment (planning, TDD implementation, adversarial spec review) | `model: inherit` | yokay-planner, yokay-implementer, yokay-spec-reviewer |
| Mechanical review/scan | `model: sonnet` | yokay-auditor, yokay-brainstormer, yokay-browser-verifier, yokay-design-reviewer, yokay-fixer, yokay-quality-reviewer, yokay-reviewer, yokay-security-scanner, yokay-spike-runner |
| Bulk scan/exec | `model: haiku` | yokay-explorer, yokay-test-runner |

Judgment agents inherit the session model so the most judgment-critical stages run on the strongest model available — orchestrated `/work` sessions assume a top-tier session model; running them from a weaker session downgrades these agents too. New agents must justify any pin against this table.

Model resolution order: `CLAUDE_CODE_SUBAGENT_MODEL` env var > per-invocation `model` param > frontmatter > session model. The env var is the escape hatch to floor a weak inherited model.

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
- **Skills** (`skills/<name>/SKILL.md`): Main skill file with `references/` subdirectory for detailed guides. Optional `agents:` frontmatter lists dispatched agents.
  - **Reference size guideline**: Target ≤500 lines per reference file. Split larger files into focused sub-topics. References are lazy-loaded but consume context when active.
- **Agents** (`agents/*.md`): Agent definitions loaded by Task tool's `subagent_type`
- **Hook Actions** (`hooks/actions/*.sh`): Shell scripts executed by bridge.py

## Testing

Shell-based integration tests in `plugins/pokayokay/tests/`:
- Tests are standalone bash scripts that verify hook behavior
- Exit code 0 = pass, non-zero = fail
- Tests mock ohno data via environment variables
