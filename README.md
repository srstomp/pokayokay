```
                 __                           __
    ____  ____  / /______ _  __  ______  / /______ ___  __
   / __ \/ __ \/ //_/ __ `/ / / / / __ \/ //_/ __ `/ / / /
  / /_/ / /_/ / ,< / /_/ / / /_/ / /_/ / ,< / /_/ / /_/ /
 / .___/\____/_/|_|\__,_/  \__, /\____/_/|_|\__,_/\__, /
/_/                       /____/                 /____/
```

# yokay

**AI-assisted development orchestration** - Transform PRDs into actionable tasks, orchestrate multi-session development, and ensure features are actually user-accessible.

## Features

- **PRD to Tasks** - Automatically break down requirements into epics, stories, and tasks
- **Orchestrated Sessions** - Work across multiple sessions without losing context
- **Human Checkpoints** - Choose your autonomy level: supervised, semi-auto, or autonomous
- **Multi-Dimensional Auditing** - Verify accessibility, testing, security, docs, and observability
- **25+ Specialized Skills** - Route work to domain experts automatically
- **Spike Protocol** - Time-boxed investigations with mandatory decisions

## Installation

```bash
claude plugin add https://github.com/srstomp/pokayokay
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
/yokay:plan docs/prd.md

# 3. View kanban board
npx @stevestomp/ohno-cli serve

# 4. Start working
/yokay:work supervised

# 5. Audit completeness
/yokay:audit --full
```

## Commands

### Core Workflow

| Command | Description |
|---------|-------------|
| `/yokay:plan <path>` | Analyze PRD and create tasks with skill routing |
| `/yokay:work [mode]` | Start/continue work session (supervised/semi-auto/autonomous) |
| `/yokay:audit [feature]` | Audit feature completeness across 5 dimensions |
| `/yokay:review` | Analyze session patterns and skill effectiveness |
| `/yokay:handoff` | Prepare session handoff with context preservation |

### Design

| Command | Description |
|---------|-------------|
| `/yokay:ux <task>` | UX design - user flows, wireframes, interactions |
| `/yokay:ui <task>` | Visual design - typography, color, motion |

### Development

| Command | Description |
|---------|-------------|
| `/yokay:api <task>` | API design - REST/GraphQL patterns |
| `/yokay:arch <area>` | Architecture review and refactoring |

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

The `/yokay:audit` command checks 5 dimensions:

| Dimension | Levels | Description |
|-----------|--------|-------------|
| Accessibility | L0-L5 | Is the feature user-accessible? |
| Testing | T0-T4 | Test coverage and types |
| Documentation | D0-D4 | Code comments to user docs |
| Security | S0-S4 | Input validation to hardened |
| Observability | O0-O4 | Logging to full telemetry |

```bash
/yokay:audit                    # Quick (accessibility only)
/yokay:audit --dimension testing  # Specific dimension
/yokay:audit --full              # All dimensions
```

## Work Modes

| Mode | Task | Story | Epic |
|------|------|-------|------|
| `supervised` | PAUSE | PAUSE | PAUSE |
| `semi-auto` | log | PAUSE | PAUSE |
| `autonomous` | skip | log | PAUSE |

## Spike Protocol

For high-uncertainty work:

1. **Time-box**: 2-4 hours (max 1 day)
2. **50% Checkpoint**: Assess progress
3. **Mandatory Decision**: GO / NO-GO / PIVOT / MORE-INFO
4. **Output**: `.claude/spikes/[name].md`

## Documentation

See [GUIDE.md](plugins/yokay/GUIDE.md) for:
- Command relationships diagram
- Skill routing patterns
- Keyword detection
- Integration with ohno

## Development

```bash
git clone https://github.com/srstomp/pokayokay.git
claude --plugin-dir ./pokayokay/plugins/yokay
```

## Dependencies

- [ohno](https://github.com/srstomp/ohno) - Task management via MCP

## License

MIT
