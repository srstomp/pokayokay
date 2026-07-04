# AGENTS.md

This file provides guidance to Codex when working with code in this repository.

## Project Overview

pokayokay is a development-orchestration plugin built primarily for Claude Code, with additive Codex support. It integrates with ohno (task management via MCP) to provide structured workflows with configurable human oversight.

**Important: the Codex and Claude Code surfaces differ.** On Codex, the plugin provides skills, the ohno MCP server, and lifecycle hooks. The `commands/` and `agents/` directories are Claude Code-only — Codex has no Task-tool subagent dispatch, and the `.codex-plugin/plugin.json` manifest exposes only `skills/` and `.mcp.json`. When a skill references dispatching a `yokay-*` agent, execute that agent's role inline instead: read the corresponding `plugins/pokayokay/agents/yokay-<name>.md` and follow its checklist and output contract directly.

## Development Commands

```bash
# Register this checkout as a Codex plugin marketplace, then install the
# plugin from it (run from repo root)
codex plugin marketplace add .
codex plugin add pokayokay@pokayokay

# Run the CLI setup wizard locally (wires ohno MCP + Codex hooks)
npm --prefix cli install
node cli/bin/cli.js

# Run specific shell tests
bash plugins/pokayokay/tests/<test-name>.test.sh

# Run the full test suite (shell + node, per-test PASS/FAIL, non-zero exit on failure)
npm test
# or directly:
bash plugins/pokayokay/tests/run-tests.sh

# Codex-specific test suites
bash plugins/pokayokay/tests/codex-compatibility.test.sh
node --test plugins/pokayokay/tests/cli-dual-runtime.test.mjs
```

Note: Codex installs in two steps — `codex plugin marketplace add` registers the source under `[marketplaces.pokayokay]` in `~/.codex/config.toml`, and `codex plugin add pokayokay@pokayokay` installs the plugin (recorded under `[plugins."pokayokay@pokayokay"]`). The marketplace step alone does not install anything. The command is `add`, not `install`, and there is no `codex plugin validate`.

## Architecture

### Plugin Structure (`plugins/pokayokay/`)

```
plugins/pokayokay/
├── .claude-plugin/  # Claude Code manifest
├── .codex-plugin/   # Codex manifest (exposes skills/ and .mcp.json only)
├── .mcp.json        # ohno MCP server config (shared)
├── commands/        # Slash command definitions (Claude Code only)
├── skills/          # Domain knowledge and workflows (shared; subdirs with SKILL.md + references/)
├── agents/          # Subagent definitions (Claude Code Task-tool dispatch; inline checklists on Codex)
│   └── templates/   # Prompt templates for agent dispatch
└── hooks/
    └── actions/     # Shell scripts + bridge.py for hook execution (shared)
```

### Hook System (Codex)

The CLI setup wizard adds a pokayokay-owned hook block to `~/.codex/config.toml`. The block enables `codex_hooks = true`, routes tool lifecycle events to `hooks/actions/bridge.py`, and adds conservative `PermissionRequest` approval handling. `bridge.py` normalizes Codex and Claude Code hook payloads into a shared runtime, then routes to the action scripts:

```
Codex Hook Event
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
        ├── PermissionRequest → auto-allow obvious safe commands, auto-deny destructive ones,
        │                       fall back to the normal Codex approval prompt otherwise
        └── SessionEnd → sync, session-summary, curate-memory.sh, session-chain
```

The `PermissionRequest` hook shape is Codex-specific; Claude Code permission behavior stays in Claude settings. See `plugins/pokayokay/skills/work-session/references/approval-policy.md` for the allow/deny policy.

### Working Without Subagent Dispatch

On Claude Code, the `/work`, `/fix`, and `/hotfix` commands dispatch specialized `yokay-*` agents via the Task tool. On Codex there is no equivalent, so the work pipeline runs inline within the session. The agent definitions still apply as role checklists:

- **yokay-planner** (`agents/yokay-planner.md`) - PRD analysis with structured acceptance criteria (MUST/SHOULD/COULD)
- **yokay-implementer** (`agents/yokay-implementer.md`) - AC-first TDD implementation with verification-before-completion
- **yokay-spec-reviewer** (`agents/yokay-spec-reviewer.md`) - Adversarial spec review with evidence table (file:line per criterion)
- **yokay-quality-reviewer** (`agents/yokay-quality-reviewer.md`) - Code quality review (coverage, lint, test-AC mapping) + design compliance

When executing one of these roles inline, follow the agent file's Behavioral Defaults, Critical Rules, and Output Contract. Run review roles after implementation as separate, self-contained passes rather than skipping them.

### CLI (`cli/`)

Setup wizard for installing the plugin (Claude Code, Codex, or both), configuring ohno MCP, and optional kaizen integration. Published as `pokayokay` on npm. Runtime detection lives in `cli/src/detect.js`; per-runtime install steps in `cli/src/steps/plugin.js`.

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

- **Skills** (`skills/<name>/SKILL.md`): Main skill file with `references/` subdirectory for detailed guides. Optional `agents:` frontmatter lists the agent roles involved (dispatched on Claude Code; executed inline on Codex).
  - **Reference size guideline**: Target ≤500 lines per reference file. Split larger files into focused sub-topics. References are lazy-loaded but consume context when active.
- **Agents** (`agents/*.md`): Agent role definitions — frontmatter (`tools`, `model`, `permissionMode`) is Claude Code-only; body text is runtime-neutral
- **Commands** (`commands/*.md`): Claude Code-only slash command definitions
- **Hook Actions** (`hooks/actions/*.sh`): Shell scripts executed by bridge.py on both runtimes

## Testing

Shell-based integration tests in `plugins/pokayokay/tests/`:
- Tests are standalone bash scripts that verify hook behavior
- Exit code 0 = pass, non-zero = fail
- Tests mock ohno data via environment variables
- `codex-compatibility.test.sh` validates the Codex manifest, `.mcp.json`, and hook wiring
- `bridge-runtime-normalization.test.sh` validates Codex↔Claude hook payload normalization
- `cli-dual-runtime.test.mjs` (node --test) covers dual-runtime install paths in the CLI
