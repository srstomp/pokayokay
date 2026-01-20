```
                 __                           __
    ____  ____  / /______ _  __  ______  / /______ ___  __
   / __ \/ __ \/ //_/ __ `/ / / / / __ \/ //_/ __ `/ / / /
  / /_/ / /_/ / ,< / /_/ / / /_/ / /_/ / ,< / /_/ / /_/ /
 / .___/\____/_/|_|\__,_/  \__, /\____/_/|_|\__,_/\__, /
/_/                       /____/                 /____/
```

# yokay

**AI-assisted development orchestration** - A Claude Code plugin that orchestrates AI-assisted development sessions with configurable human oversight, bridging the gap between hands-on control and full automation through skills, hooks, agents, and integration with ohno for task management.

## Features

- **PRD to Tasks** - Automatically break down requirements into epics, stories, and tasks
- **Orchestrated Sessions** - Work across multiple sessions without losing context
- **Human Checkpoints** - Choose your autonomy level: supervised, semi-auto, or autonomous
- **Multi-Dimensional Auditing** - Verify accessibility, testing, security, docs, and observability
- **25+ Specialized Skills** - Route work to domain experts automatically
- **Spike Protocol** - Time-boxed investigations with mandatory decisions

## Installation

```bash
claude plugin add srstomp/pokayokay
```

### Required: ohno MCP Server

Add to your MCP configuration:

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

## Quick Start

```bash
# 1. Initialize ohno in your project
npx @stevestomp/ohno-cli init

# 2. Plan from a PRD
/pokayokay:plan docs/prd.md

# 3. View kanban board
npx @stevestomp/ohno-cli serve

# 4. Start working
/pokayokay:work supervised

# 5. Audit completeness
/pokayokay:audit --full
```

## Commands

### Core Workflow

| Command | Description |
|---------|-------------|
| `/pokayokay:plan <path>` | Analyze PRD and create tasks with skill routing |
| `/pokayokay:work [mode]` | Start/continue work session (supervised/semi-auto/autonomous) |
| `/pokayokay:audit [feature]` | Audit feature completeness across 5 dimensions |
| `/pokayokay:review` | Analyze session patterns and skill effectiveness |
| `/pokayokay:handoff` | Prepare session handoff with context preservation |
| `/pokayokay:hooks` | View and manage hook configuration |

### Ad-Hoc Work

| Command | Description |
|---------|-------------|
| `/pokayokay:quick <task>` | Create task and immediately start working |
| `/pokayokay:fix <bug>` | Bug fix with diagnosis workflow |
| `/pokayokay:spike <question>` | Time-boxed technical investigation |
| `/pokayokay:hotfix <incident>` | Production incident response |

### Design & UX

| Command | Description |
|---------|-------------|
| `/pokayokay:ux <task>` | UX design - user flows, wireframes, interactions |
| `/pokayokay:ui <task>` | Visual design - typography, color, motion |
| `/pokayokay:persona <task>` | Create user personas and journey maps |
| `/pokayokay:a11y <target>` | Accessibility audit (WCAG 2.2 AA) |
| `/pokayokay:marketing <page>` | Marketing and landing pages |

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

The plugin includes 25+ specialized skills that are automatically loaded based on task type:

### Design & UX
- `ux-design` - User flows, wireframes, information architecture
- `aesthetic-ui-designer` - Visual design, typography, color systems
- `persona-creation` - User research and persona development
- `accessibility-auditor` - WCAG 2.2 compliance

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
| `autonomous` | skip | log | PAUSE |

## Sub-Agents

Yokay includes **6 specialized sub-agents** that run in isolated context windows for verbose operations:

| Agent | Model | Purpose |
|-------|-------|---------|
| `yokay-auditor` | Sonnet | L0-L5 completeness scanning (read-only) |
| `yokay-explorer` | Haiku | Fast codebase exploration (read-only, 5-10x cheaper) |
| `yokay-reviewer` | Sonnet | Code review and analysis (read-only) |
| `yokay-spike-runner` | Sonnet | Time-boxed investigations |
| `yokay-security-scanner` | Sonnet | OWASP vulnerability scanning (read-only) |
| `yokay-test-runner` | Haiku | Test execution with concise output |

### Why Sub-Agents?

- **Context isolation** - Verbose scan output stays separate from main conversation
- **Cost optimization** - Haiku agents are 5-10x cheaper for exploration
- **Enforced constraints** - Read-only agents can't accidentally modify files
- **Parallel execution** - Run multiple investigations simultaneously

Commands like `/pokayokay:audit`, `/pokayokay:security`, and `/pokayokay:spike` automatically delegate to the appropriate agent.

## Hook System

Yokay includes a **guaranteed hook system** that executes actions at key lifecycle points via Claude Code's native hooks:

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

See [HOOKS.md](hooks/HOOKS.md) for configuration and customization.

## Spike Protocol

For high-uncertainty work:

1. **Time-box**: 2-4 hours (max 1 day)
2. **50% Checkpoint**: Assess progress
3. **Mandatory Decision**: GO / NO-GO / PIVOT / MORE-INFO
4. **Output**: `.claude/spikes/[name].md`

## Documentation

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
