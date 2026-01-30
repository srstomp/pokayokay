# pokayokay

Setup wizard for [pokayokay](https://github.com/srstomp/pokayokay) - AI-assisted development orchestration.

## Quick Start

```bash
npx pokayokay
```

This interactive wizard will:
1. Install the pokayokay Claude Code plugin
2. Configure the ohno MCP server
3. Initialize ohno in your project
4. Optionally set up kaizen integration

## Commands

| Command | Description |
|---------|-------------|
| `npx pokayokay` | Run interactive setup wizard |
| `npx pokayokay doctor` | Validate installation |
| `npx pokayokay help` | Show help message |

## What Gets Configured

### pokayokay Plugin
The Claude Code plugin that provides orchestration commands:
- `/pokayokay:plan` - Plan from PRD
- `/pokayokay:work` - Start work sessions
- `/pokayokay:audit` - Audit completeness

### ohno MCP Server
Task management via Model Context Protocol:
- Track tasks, stories, and epics
- Dependency management
- Progress tracking

### kaizen Integration (Optional)
Failure pattern capture and learning:
- Auto-capture review failures
- Create fix tasks automatically
- Improve over time

## Manual Setup

If you prefer manual setup:

```bash
# 1. Install plugin
claude plugin marketplace add srstomp/pokayokay
claude plugin install pokayokay@srstomp-pokayokay

# 2. Add to ~/.claude/settings.json
{
  "mcpServers": {
    "ohno": {
      "command": "npx",
      "args": ["@stevestomp/ohno-mcp"]
    }
  }
}

# 3. Initialize ohno
npx @stevestomp/ohno-cli init
```

## Requirements

- Node.js 18+
- Claude Code CLI

## License

MIT
