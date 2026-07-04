# pokayokay

Setup wizard for [pokayokay](https://github.com/srstomp/pokayokay) - AI-assisted development orchestration.

## Quick Start

```bash
npx pokayokay
```

This interactive wizard will:
1. Install the pokayokay plugin for Claude Code, Codex, or both
2. Configure the ohno MCP server
3. Initialize ohno in your project
4. Optionally set up kaizen integration

> **Note:** First-time Codex installation must be run from a checkout of the
> pokayokay repo (`git clone https://github.com/srstomp/pokayokay && cd pokayokay && npx pokayokay`);
> Codex registers the marketplace from the on-disk repo. Re-runs with the Codex
> plugin already installed work from any directory.

## Commands

| Command | Description |
|---------|-------------|
| `npx pokayokay` | Run interactive setup wizard |
| `npx pokayokay doctor` | Validate installation |
| `npx pokayokay help` | Show help message |

## What Gets Configured

### pokayokay Plugin
The Claude Code/Codex plugin that provides orchestration commands:
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
# 1. Install plugin for Claude Code
claude plugin marketplace add srstomp/pokayokay
claude plugin install pokayokay@pokayokay

# 2. Or configure Codex from this repository
npx pokayokay

# 3. Add to ~/.claude/settings.json for Claude Code
{
  "mcpServers": {
    "ohno": {
      "command": "npx",
      "args": ["@stevestomp/ohno-mcp"]
    }
  }
}

# 4. Or add to ~/.codex/config.toml for Codex
[mcp_servers.ohno]
command = "npx"
args = ["@stevestomp/ohno-mcp"]

# 5. Initialize ohno
npx @stevestomp/ohno-cli init
```

## Requirements

- Node.js 18+
- Claude Code CLI or Codex

## License

MIT
