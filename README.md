```
                 __                           __
    ____  ____  / /______ _  __  ______  / /______ ___  __
   / __ \/ __ \/ //_/ __ `/ / / / / __ \/ //_/ __ `/ / / /
  / /_/ / /_/ / ,< / /_/ / / /_/ / /_/ / ,< / /_/ / /_/ /
 / .___/\____/_/|_|\__,_/  \__, /\____/_/|_|\__,_/\__, /
/_/                       /____/                 /____/
```

# pokayokay

**AI-assisted development orchestration** - A Claude Code plugin that orchestrates AI-assisted development sessions with configurable human oversight, bridging the gap between hands-on control and full automation through skills, hooks, agents, and integration with ohno for task management.

## Features

- **PRD to Tasks** - Automatically break down requirements into epics, stories, and tasks
- **Orchestrated Sessions** - Work across multiple sessions without losing context
- **Human Checkpoints** - Choose your autonomy level: supervised, semi-auto, auto, or unattended
- **Multi-Dimensional Auditing** - Verify accessibility, testing, security, docs, and observability
- **23 Specialized Skills** - Route work to domain experts automatically
- **Spike Protocol** - Time-boxed investigations with mandatory decisions

## Prerequisites

- **Claude Code** v1.0.0 or later
- **Node.js** v18 or later (for ohno CLI)
- **Git** (for version control integration)

## Installation

The easiest way to install is with the setup wizard:

```bash
npx pokayokay
```

This interactive wizard will:
1. Install the pokayokay Claude Code plugin
2. Configure the ohno MCP server
3. Initialize ohno in your project
4. Optionally set up kaizen integration

Run `npx pokayokay doctor` anytime to verify your installation.

### Manual Installation

<details>
<summary>Click to expand manual steps</summary>

```bash
# 1. Add the marketplace (one-time setup)
claude plugin marketplace add srstomp/pokayokay

# 2. Install the plugin
claude plugin install pokayokay@srstomp-pokayokay
```

Or from inside Claude Code REPL:

```
/plugin marketplace add srstomp/pokayokay
/plugin install pokayokay@srstomp-pokayokay
```

#### Required: ohno MCP Server

Add to your MCP configuration (`~/.claude/settings.json`):

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

#### Initialize ohno

```bash
npx @stevestomp/ohno-cli init
```

</details>

## Quick Start

```bash
# 1. Run setup wizard (if not done already)
npx pokayokay

# 2. Restart Claude Code to activate MCP server

# 3. Plan from a PRD
/pokayokay:plan docs/prd.md

# 4. View kanban board
npx @stevestomp/ohno-cli serve

# 5. Start working
/pokayokay:work supervised

# 6. Audit completeness
/pokayokay:audit --full
```

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
| `/pokayokay:quick <task>` | Create task and immediately start working |
| `/pokayokay:fix <bug>` | Bug fix with diagnosis workflow |
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

The plugin includes 23 specialized skills that are automatically loaded based on task type:

### Backend & API
- `api-design` - REST/GraphQL endpoint design
- `api-integration` - Third-party API consumption
- `database-design` - Schema design, migrations, optimization
- `architecture-review` - Code structure, module boundaries

### DevOps & Infrastructure
- `ci-cd-expert` - GitHub Actions, GitLab CI, deployment strategies
- `observability` - Logging, metrics, tracing, alerting

### Quality & Security
- `testing-strategy` - Test architecture, coverage, E2E patterns
- `security-audit` - OWASP Top 10, dependency scanning

### Investigation
- `spike` - Time-boxed technical investigation (2-4 hours)
- `deep-research` - Multi-day technology evaluation

### Planning
- `plan-revision` - Guided plan revision with impact analysis

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

### Session Resume

Resume interrupted work sessions without losing context:

```bash
# Resume the last session, picking up where you left off
/pokayokay:work --continue
```

Loads tasks with saved WIP data from ohno, skips brainstorming for resumed tasks, and dispatches the implementer with previous context.

### Headless Session Chaining

When context fills during auto-mode work, sessions can automatically chain — finishing gracefully and spawning a new session that resumes from WIP. This is configured in `.claude/pokayokay.json`, not via a command flag:

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

**On completion:** Choose to merge, create PR, keep worktree, or discard work.

## Sub-Agents

pokayokay includes **12 specialized sub-agents** that run in isolated context windows for verbose operations:

| Agent | Model | Purpose |
|-------|-------|---------|
| `yokay-auditor` | Sonnet | L0-L5 completeness scanning (read-only) |
| `yokay-brainstormer` | Sonnet | Refines ambiguous tasks into clear requirements |
| `yokay-browser-verifier` | Sonnet | Browser verification for UI changes (read-only) |
| `yokay-explorer` | Haiku | Fast codebase exploration (read-only, 5-10x cheaper) |
| `yokay-fixer` | Sonnet | Auto-retry on test failures with targeted fixes |
| `yokay-implementer` | Sonnet | TDD implementation with fresh context |
| `yokay-quality-reviewer` | Haiku | Code quality, tests, and conventions review |
| `yokay-reviewer` | Sonnet | Code review and analysis (read-only) |
| `yokay-security-scanner` | Sonnet | OWASP vulnerability scanning (read-only) |
| `yokay-spec-reviewer` | Haiku | Verifies implementation matches spec |
| `yokay-spike-runner` | Sonnet | Time-boxed investigations |
| `yokay-test-runner` | Haiku | Test execution with concise output |

### Why Sub-Agents?

- **Context isolation** - Verbose scan output stays separate from main conversation
- **Cost optimization** - Haiku agents are 5-10x cheaper for exploration
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

After implementation, work passes through two sequential reviews:

| Stage | Agent | Checks |
|-------|-------|--------|
| 1. Spec Review | `yokay-spec-reviewer` | Does implementation match requirements? |
| 2. Quality Review | `yokay-quality-reviewer` | Is the code well-written and tested? |

Both must PASS before a task is marked complete. This separation ensures completeness (spec) and quality are independently verified.

## Hook System

pokayokay includes a **guaranteed hook system** that executes actions at key lifecycle points via Claude Code's native hooks:

| Hook | Trigger | Actions |
|------|---------|---------|
| pre-session | Session starts | Verify working directory clean |
| pre-task | Task starts | Check blockers, suggest skills |
| post-task | Task completes | Sync, commit, detect spike, capture knowledge |
| post-story | Story completes | Run tests, audit gate |
| post-epic | Epic completes | Full audit, audit gate |
| on-blocker | Task blocked | Notification, suggest alternatives |
| pre-commit | Before git commit | Run linter |
| post-session | Session ends | Sync, print summary |

### Intelligent Hooks

Beyond lifecycle automation, hooks provide intelligent guidance:

| Action | Hook | Purpose |
|--------|------|---------|
| `suggest-skills` | pre-task | Suggests relevant skills based on task keywords |
| `detect-spike` | post-task | Detects uncertainty signals, suggests spike conversion |
| `capture-knowledge` | post-task | Auto-suggests docs for spike/research tasks |
| `audit-gate` | post-story/epic | Checks quality thresholds at boundaries |

Hooks are configured in `.claude/settings.local.json` and executed by `bridge.py`. The ohno MCP server provides **boundary metadata** when tasks complete, enabling automatic detection of story/epic completion.

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
claude --plugin-dir ./pokayokay
```

## Dependencies

- [ohno](https://github.com/srstomp/ohno) - Task management via MCP

## License

MIT
