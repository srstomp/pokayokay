```
                 __                           __
    ____  ____  / /______ _  __  ______  / /______ ___  __
   / __ \/ __ \/ //_/ __ `/ / / / / __ \/ //_/ __ `/ / / /
  / /_/ / /_/ / ,< / /_/ / / /_/ / /_/ / ,< / /_/ / /_/ /
 / .___/\____/_/|_|\__,_/  \__, /\____/_/|_|\__,_/\__, /
/_/                       /____/                 /____/
```

# pokayokay

**AI-assisted development orchestration** - A Claude Code and Codex plugin that orchestrates AI-assisted development sessions with configurable human oversight, bridging the gap between hands-on control and full automation through skills, hooks, agents, and integration with ohno for task management.

## Features

- **PRD to Tasks** - Automatically break down requirements into epics, stories, and tasks
- **Orchestrated Sessions** - Work across multiple sessions without losing context
- **Human Checkpoints** - Choose your autonomy level: supervised, semi-auto, auto, or unattended
- **Multi-Dimensional Auditing** - Verify accessibility, testing, security, docs, and observability
- **24 Specialized Skills** - Route work to domain-specific workflows automatically
- **Evidence-Based Completion** - Require fresh verification before "done", "fixed", or "passing" claims
- **Root-Cause Debugging** - Reproduce, diagnose, and regression-test bugs before fixes are marked complete
- **Spike Protocol** - Time-boxed investigations with mandatory decisions

## Prerequisites

- **Claude Code** v1.0.0 or later, or **Codex**
- **Node.js** v18 or later (for ohno CLI)
- **Git** (for version control integration)

## Installation

The setup wizard is the easiest path for Claude Code from npm:

```bash
npx pokayokay
```

For current Codex support, run the setup wizard from the repository checkout so
Codex can use that checkout as the marketplace source:

```bash
cd ~/Projects/stevestomp/pokayokay
npm --prefix cli install
node cli/bin/cli.js
```

The public npm package is the setup CLI and does not contain the Codex plugin
payload. The local setup wizard will:
1. Install or register the pokayokay plugin for Claude Code, Codex, or both
2. Configure the ohno MCP server
3. Initialize ohno in your project
4. Wire runtime hooks where supported
5. Optionally set up kaizen integration

Run `npx pokayokay doctor` anytime to verify your installation.

### Manual Installation

<details>
<summary>Click to expand manual steps</summary>

Claude Code:

```bash
# 1. Add the marketplace (one-time setup)
claude plugin marketplace add srstomp/pokayokay

# 2. Install the plugin
claude plugin install pokayokay@pokayokay
```

Or from inside Claude Code REPL:

```
/plugin marketplace add srstomp/pokayokay
/plugin install pokayokay@pokayokay
```

Codex:

```bash
# Codex installs plugins in two steps: register the marketplace, then add the
# plugin from it. Run this from the pokayokay repository checkout:
cd ~/Projects/stevestomp/pokayokay
codex plugin marketplace add .
codex plugin add pokayokay@pokayokay

# Optional: run the local setup wizard to wire ohno MCP and hooks.
npm --prefix cli install
node cli/bin/cli.js
```

Codex stores the marketplace entry in `~/.codex/config.toml` under
`[marketplaces.pokayokay]` and the install record under
`[plugins."pokayokay@pokayokay"]`. Registering the marketplace alone does not
install the plugin — `codex plugin add` is required (the command is `add`, not
`install`). The local setup wizard runs both steps and adds a pokayokay-owned
hook block to `~/.codex/config.toml`. The hook block enables
`codex_hooks = true`, routes tool lifecycle events to `hooks/actions/bridge.py`,
and adds conservative `PermissionRequest` approval handling.

#### Required: ohno MCP Server

Add to your MCP configuration.

Claude Code (`~/.claude/settings.json`):

```json
{
  "mcpServers": {
    "ohno": {
      "command": "npx",
      "args": ["@stevestomp/ohno-mcp"]
    }
  }
}
```

Codex (`~/.codex/config.toml`):

```toml
[mcp_servers.ohno]
command = "npx"
args = ["@stevestomp/ohno-mcp"]
```

#### Initialize ohno

```bash
npx @stevestomp/ohno-cli init
```

</details>

## Quick Start

```bash
# 1. Run setup wizard (if not done already)
npx pokayokay

# 2. Restart your configured AI runtime to activate MCP server

# 3. Plan from a PRD or concept brief
/pokayokay:plan docs/prd.md

# 4. View kanban board
npx @stevestomp/ohno-cli serve

# 5. Start working
/pokayokay:work supervised

# 6. Audit completeness
/pokayokay:audit --full
```

For a quick one-off change, use `/pokayokay:quick <task>`. For a bug, use
`/pokayokay:fix <bug>` so pokayokay reproduces the issue, records root cause,
adds or identifies a regression test, and verifies the fix before completion.

## Commands

### Core Workflow

| Command | Description |
|---------|-------------|
| `/pokayokay:plan [--headless] [--review] <path>` | Analyze PRD and create tasks with skill routing |
| `/pokayokay:revise [--direct]` | Revise existing plan with impact analysis |
| `/pokayokay:work [mode] [-n N]` | Start/continue work session (supervised/semi-auto/auto/unattended) |
| `/pokayokay:audit [feature]` | Audit feature completeness across 5 dimensions |
| `/pokayokay:review` | Analyze session patterns and skill effectiveness |
| `/pokayokay:handoff` | Prepare session handoff with context preservation |
| `/pokayokay:hooks` | View and manage hook configuration |
| `/pokayokay:worktrees` | List, cleanup, switch, or remove worktrees |

### Ad-Hoc Work

| Command | Description |
|---------|-------------|
| `/pokayokay:quick <task>` | Create task and work inline with TDD/verification gates |
| `/pokayokay:fix [--thorough] <bug>` | Root-cause bug fix with regression verification (`--thorough` for full pipeline) |
| `/pokayokay:spike <question>` | Time-boxed technical investigation |
| `/pokayokay:hotfix <incident>` | Production incident response |

### Development

| Command | Description |
|---------|-------------|
| `/pokayokay:api <task>` | API design - REST/GraphQL patterns |
| `/pokayokay:arch <area>` | Architecture review and refactoring |
| `/pokayokay:db <task>` | Database schema and migrations |
| `/pokayokay:test <task>` | Testing strategy and implementation |
| `/pokayokay:integrate <api>` | Third-party API integration |
| `/pokayokay:sdk <task>` | SDK creation and extraction |

### Infrastructure & Quality

| Command | Description |
|---------|-------------|
| `/pokayokay:cicd <task>` | CI/CD pipeline creation and optimization |
| `/pokayokay:security <area>` | Security audit and vulnerability scanning |
| `/pokayokay:observe <task>` | Logging, metrics, and tracing |

### Research & Documentation

| Command | Description |
|---------|-------------|
| `/pokayokay:research <topic>` | Extended technical research |
| `/pokayokay:docs <task>` | Technical documentation |

## Skills

The plugin includes 24 specialized skills loaded on demand via commands or planner routing:

### Orchestration (process skills - add structure coding agents may skip)
- `work-session` - Coordinator workflow, modes, agent dispatch
- `planning` - PRD-to-task breakdown with ohno integration
- `plan-revision` - Impact analysis on existing plans
- `spike` - Time-boxed investigation with structured output
- `deep-research` - Multi-day technology evaluation
- `session-review` - Post-session analysis and handoff prep
- `feature-audit` - L0-L5 completeness verification
- `worktrees` - Git worktree management
- `browser-verification` - Playwright UI verification
- `systematic-debugging` - Root-cause-first bug and failure diagnosis
- `verification-before-completion` - Fresh evidence before completion claims
- `finishing-branch` - Verified merge/PR/keep/discard branch finish flow

### Domain (reference material for implementer agents)
- `api-design` - REST/GraphQL endpoint design
- `api-integration` - Third-party API consumption
- `database-design` - Schema design, migrations, optimization
- `architecture-review` - Code structure, module boundaries
- `ci-cd` - GitHub Actions, GitLab CI, deployment strategies
- `cloud-infrastructure` - AWS service selection, CDK patterns
- `observability` - Logging, metrics, tracing, alerting
- `testing-strategy` - Test architecture, coverage, E2E patterns
- `security-audit` - OWASP Top 10, dependency scanning
- `error-handling` - Error hierarchies, recovery patterns
- `sdk-development` - TypeScript SDK extraction and publishing
- `documentation` - READMEs, API docs, ADRs

## Workflow Guarantees

pokayokay deliberately adds process where coding agents tend to drift:

| Gate | What it prevents | Where it applies |
|------|------------------|------------------|
| Brainstorm gate | Vague tasks becoming wrong implementations | `yokay-brainstormer`, `/work` |
| TDD gate | Behavior changes without tests | `/quick`, `yokay-implementer`, domain skills |
| Systematic debugging | Symptom patches and guess-and-check fixes | `/fix`, `yokay-fixer` |
| Spec then quality review | Good-looking code that misses requirements | `/work` task completion |
| Verification before completion | Unverified "done/fixed/passing" claims | Agents, commands, handoffs |
| Finishing branch | Ambiguous cleanup or accidental discard | Worktree and branch completion |

## Audit Dimensions

The `/pokayokay:audit` command checks 5 dimensions:

| Dimension | Levels | Description |
|-----------|--------|-------------|
| Accessibility | L0-L5 | Is the feature user-accessible? |
| Testing | T0-T4 | Test coverage and types |
| Documentation | D0-D4 | Code comments to user docs |
| Security | S0-S4 | Input validation to hardened |
| Observability | O0-O4 | Logging to full telemetry |

```bash
/pokayokay:audit                    # Quick (accessibility only)
/pokayokay:audit --dimension testing  # Specific dimension
/pokayokay:audit --full              # All dimensions
```

## Work Modes

| Mode | Task | Story | Epic |
|------|------|-------|------|
| `supervised` | PAUSE | PAUSE | PAUSE |
| `semi-auto` | log | PAUSE | PAUSE |
| `auto` | skip | log | PAUSE |
| `unattended` | skip | skip | skip |

### Parallel Execution

Run multiple tasks simultaneously for faster throughput:

```bash
# Run up to 3 tasks in parallel
/pokayokay:work semi-auto -n 3

# Adaptive sizing (starts at 2, adjusts based on outcomes)
/pokayokay:work semi-auto -n auto
```

> **Note:** `-p` is reserved for the Claude CLI `--prompt` flag. Use `-n` for parallel count.

**How it works:**
- Coordinator dispatches N implementer agents in a single message
- Each agent works independently with fresh context
- Results processed as they complete
- Dependency graph prevents unsafe parallelization

**Adaptive mode (`-n auto`):**
- Starts at 2 parallel tasks
- Scales up (max 4) when tasks succeed consecutively
- Scales down (min 2) when failures occur
- Displays batch size changes during session

**Recommended settings:**
- Default: 1 (sequential, safest)
- Independent tasks: 2-3
- Adaptive: `auto` (recommended for most sessions)
- Maximum: 5

**Tradeoffs:**
- Higher token usage (N concurrent contexts)
- Potential git conflicts (auto-resolved when possible)
- No shared learning between parallel agents

### Token And Context Budgeting

pokayokay tracks subagent usage when runtime telemetry is available and prints
it in the session summary. Use the numbers as a session-review signal, not as a
hard billing source: some runtimes may report unavailable token counts.

Practical defaults:

| Work type | Token-aware default |
|-----------|---------------------|
| Tiny edit or support request | `/pokayokay:quick` inline |
| Bug with unclear cause | `/pokayokay:fix` with root-cause debugging before edits |
| Broad codebase question | Explorer/test-runner style agents before full pipelines |
| Clear implementation task | One implementer, then spec/quality review |
| Independent backlog batch | `/pokayokay:work -n 2` or `-n auto` before larger fan-out |

Codex skills use progressive disclosure, so keep skill descriptions concise and
let references stay lazy-loaded. Claude Code and Codex subagents both preserve
the main context, but they add separate model/tool work; spend that budget when
isolation, review quality, or wall-clock speed is worth it.

### Session Resume

Resume interrupted work sessions without losing context:

```bash
# Resume the last session, picking up where you left off
/pokayokay:work --continue
```

Loads tasks with saved WIP data from ohno, skips brainstorming for resumed tasks, and dispatches the implementer with previous context.

### Headless Session Chaining

When context fills during auto-mode work, sessions can automatically chain — finishing gracefully and spawning a new session that resumes from WIP. This is configured in `.pokayokay/config.json`, with `.claude/pokayokay.json` still supported for existing Claude Code projects:

```json
{
  "headless": {
    "max_chains": 10,
    "report": "on_complete",
    "notify": "terminal"
  }
}
```

Chaining requires an explicit scope to prevent runaway sessions:

```bash
# Scope to a story — chains will continue until story tasks are done
/pokayokay:work auto --story story-abc123

# Scope to an epic
/pokayokay:work auto --epic epic-def456
```

Chain reports are generated to `.ohno/reports/`. The max chains limit (default 10) prevents runaway execution.

### Worktree Isolation

Tasks automatically run in isolated git worktrees based on type:

| Task Type | Behavior | Override |
|-----------|----------|----------|
| feature, bug, spike | Worktree | `--in-place` |
| chore, docs | In-place | `--worktree` |

```bash
# Default: smart based on task type
/pokayokay:work

# Force worktree for a chore
/pokayokay:work --worktree

# Force in-place for a feature
/pokayokay:work --in-place
```

**Story-based reuse:** Tasks in the same story share a worktree, keeping related changes together.

**On completion:** Use `finishing-branch` to verify the branch and choose to
merge, create PR, keep the worktree, or discard work.

## Sub-Agents

pokayokay includes **14 Claude Code sub-agents** that run in isolated context
windows for verbose operations. The model column below reflects Claude Code
agent frontmatter aliases (`haiku`, `sonnet`, `opus`).

| Agent | Claude model alias | Purpose |
|-------|-------|---------|
| `yokay-auditor` | Sonnet | L0-L5 completeness scanning (read-only) |
| `yokay-brainstormer` | Sonnet | Refines ambiguous tasks into clear requirements |
| `yokay-browser-verifier` | Sonnet | Browser verification for UI changes (read-only) |
| `yokay-design-reviewer` | Sonnet | Pre-implementation design and codebase-pattern review (read-only) |
| `yokay-explorer` | Haiku | Fast codebase exploration (read-only, 5-10x cheaper) |
| `yokay-fixer` | Sonnet | Auto-retry on test failures with targeted fixes |
| `yokay-implementer` | Sonnet | TDD implementation with fresh context |
| `yokay-planner` | Opus | PRD analysis and structured plan generation |
| `yokay-reviewer` | Sonnet | Code review and analysis (read-only) |
| `yokay-security-scanner` | Sonnet | OWASP vulnerability scanning (read-only) |
| `yokay-spec-reviewer` | Opus | Adversarial spec compliance review |
| `yokay-quality-reviewer` | Sonnet | Code quality review (after spec passes) |
| `yokay-spike-runner` | Sonnet | Time-boxed investigations |
| `yokay-test-runner` | Haiku | Test execution with concise output |

### Codex Agent Model Behavior

Codex does not use the Claude `haiku` / `sonnet` / `opus` aliases from these
Markdown agent files. In Codex, pokayokay currently relies on skills, hooks,
and MCP integration. A Codex-native agent layer would use `.codex/agents/*.toml`
files with OpenAI model IDs such as `gpt-5.4`, `gpt-5.4-mini`, or Codex models,
plus optional `model_reasoning_effort`. If a Codex subagent omits model
settings, it inherits the parent session model and reasoning effort.

### Why Sub-Agents?

- **Context isolation** - Verbose scan output stays separate from main conversation
- **Cost optimization** - Lightweight Claude aliases are used for simple exploration and test-running agents
- **Enforced constraints** - Read-only agents can't accidentally modify files
- **Parallel execution** - Run multiple investigations simultaneously

Commands like `/pokayokay:audit`, `/pokayokay:security`, and `/pokayokay:spike` automatically delegate to the appropriate agent.

### Brainstorm Gate

For ambiguous or under-specified tasks, `yokay-brainstormer` runs **before** implementation:

1. Detects vague descriptions or missing acceptance criteria
2. Explores codebase for context
3. Produces clear requirements and technical approach
4. Requests confirmation before implementation proceeds

This prevents wasted work from misunderstood requirements.

### Two-Stage Review

After implementation, two sequential reviewers check the work:

| Stage | Agent | Checks |
|-------|-------|--------|
| 1 | `yokay-spec-reviewer` | Adversarial spec compliance (requirements met? no scope creep?) |
| 2 | `yokay-quality-reviewer` | Code quality (well-written and tested?) |

Stage 2 only runs if Stage 1 passes. Both must PASS before a task is marked
complete, and the quality reviewer must cite fresh automated-check evidence or
state why a check was unavailable.

## Hook System

pokayokay includes a **guaranteed hook system** that executes actions at key lifecycle points through Claude Code and Codex hooks:

| Hook | Trigger | Actions |
|------|---------|---------|
| pre-session | Session starts | Verify clean, pre-flight (unattended), recover |
| pre-task | Task starts | Check blockers, suggest skills, setup worktree |
| post-task | Task completes | Sync, commit, detect spike, capture knowledge |
| post-story | Story completes | Test, story integration, audit gate |
| post-epic | Epic completes | Audit gate |
| on-blocker | Task blocked | Notification |
| pre-commit | Before git commit | Lint, check ref sizes |
| permission-request | Codex approval prompt | Allow obvious read-only/test/ohno commands, deny destructive/deploy commands |
| post-session | Session ends | Sync, session summary, curate memory, session chain |

### Intelligent Hooks

Beyond lifecycle automation, hooks provide intelligent guidance:

| Action | Hook | Purpose |
|--------|------|---------|
| `suggest-skills` | pre-task | Suggests relevant skills based on task keywords |
| `detect-spike` | post-task | Detects uncertainty signals, suggests spike conversion |
| `capture-knowledge` | post-task | Auto-suggests docs for spike/research tasks |
| `audit-gate` | post-story/epic | Checks quality thresholds at boundaries |

Hooks are registered through the plugin system and routed by `bridge.py`. Claude
Code loads plugin hooks from `hooks/hooks.json`; Codex setup writes equivalent
hook wiring to `~/.codex/config.toml` because Codex hooks are configured
through config files. The ohno MCP server provides **boundary metadata** when
tasks complete, enabling automatic detection of story/epic completion.

Codex approval handling is intentionally conservative. pokayokay may auto-allow
read-only inspection, pokayokay tests, and ohno bookkeeping. Destructive,
deployment, publishing, push, and history-rewrite commands are denied or left
to the normal human approval flow.

Use `/pokayokay:hooks` to view and manage hook configuration.

See [HOOKS.md](plugins/pokayokay/hooks/HOOKS.md) for configuration and customization.

## Spike Protocol

For high-uncertainty work:

1. **Time-box**: 2-4 hours (max 1 day)
2. **50% Checkpoint**: Assess progress
3. **Mandatory Decision**: GO / NO-GO / PIVOT / MORE-INFO
4. **Output**: `.claude/spikes/[name].md`

## Documentation

- [GUIDE.md](GUIDE.md) - Detailed usage guide
- [CHEATSHEET.md](CHEATSHEET.md) - Quick reference card
- [CHANGELOG.md](CHANGELOG.md) - Version history

See [GUIDE.md](GUIDE.md) for:
- Command relationships diagram
- Skill routing patterns
- Keyword detection
- Integration with ohno

## Development

```bash
git clone https://github.com/srstomp/pokayokay.git

# Claude Code development
claude --plugin-dir ./plugins/pokayokay

# Codex local marketplace development
codex plugin marketplace add .
codex plugin add pokayokay@pokayokay
npm --prefix cli install
node cli/bin/cli.js
```

Useful checks while developing:

```bash
bash plugins/pokayokay/tests/codex-compatibility.test.sh
node plugins/pokayokay/tests/cli-dual-runtime.test.mjs
bash plugins/pokayokay/tests/bridge-runtime-normalization.test.sh
```

## Dependencies

- [ohno](https://github.com/srstomp/ohno) - Task management via MCP

## License

MIT
