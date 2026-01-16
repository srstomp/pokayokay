```
                 __                           __
    ____  ____  / /______ _  __  ______  / /______ ___  __
   / __ \/ __ \/ //_/ __ `/ / / / / __ \/ //_/ __ `/ / / /
  / /_/ / /_/ / ,< / /_/ / / /_/ / /_/ / ,< / /_/ / /_/ /
 / .___/\____/_/|_|\__,_/  \__, /\____/_/|_|\__,_/\__, /
/_/                       /____/                 /____/
```

# pokayokay

**AI-assisted development with human control.** Transform PRDs into actionable tasks, orchestrate multi-session development, and ensure features are actually user-accessible.

## Features

- **PRD to Tasks** - Automatically break down requirements into epics, stories, and tasks
- **Orchestrated Sessions** - Work across multiple sessions without losing context
- **Human Checkpoints** - Choose your autonomy level: supervised, semi-auto, or autonomous
- **Completeness Auditing** - Verify features are user-accessible, not just "code complete"
- **Skill Routing** - Automatically route work to specialized AI skills

## Installation

```bash
claude plugin marketplace add https://github.com/srstomp/pokayokay
claude plugin install pokayokay
```

### Required: ohno MCP Server

Add to `~/.claude/settings.json`:

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
/pokayokay:audit
```

## Commands

| Command | Description |
|---------|-------------|
| `/pokayokay:plan <path>` | Analyze PRD and create tasks |
| `/pokayokay:work [mode]` | Start/continue work session |
| `/pokayokay:audit [feature]` | Audit feature completeness |
| `/pokayokay:review` | Analyze completed sessions |
| `/pokayokay:api <task>` | API design |
| `/pokayokay:ux <task>` | UX design |
| `/pokayokay:ui <task>` | Visual design |
| `/pokayokay:arch <task>` | Architecture review |
| `/pokayokay:handoff` | Session handoff |

## Documentation

See [GUIDE.md](GUIDE.md) for complete documentation including:
- Detailed workflow examples
- Work modes explained
- Completeness levels (L0-L5)
- Skills reference
- ohno CLI commands
- Use cases and best practices

## Development

```bash
git clone https://github.com/srstomp/pokayokay.git
claude --plugin-dir ./pokayokay/plugins/pokayokay
```

## Dependencies

- [ohno](https://github.com/srstomp/ohno) - Task management via MCP

## License

MIT
