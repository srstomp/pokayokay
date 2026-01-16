```
                 __                           __
    ____  ____  / /______ _  __  ______  / /______ ___  __
   / __ \/ __ \/ //_/ __ `/ / / / / __ \/ //_/ __ `/ / / /
  / /_/ / /_/ / ,< / /_/ / / /_/ / /_/ / ,< / /_/ / /_/ /
 / .___/\____/_/|_|\__,_/  \__, /\____/_/|_|\__,_/\__, /
/_/                       /____/                 /____/
```

# pokayokay

Claude Code plugin for PRD analysis, project orchestration, and development workflows.

## Installation

```bash
git clone https://github.com/srstomp/pokayokay.git
claude plugin install ./pokayokay --scope user
```

For development (loads plugin without installing):
```bash
claude --plugin-dir ./pokayokay
```

### Required: ohno MCP Server

This plugin integrates with [ohno](https://github.com/srstomp/ohno) for task management. Add to your Claude Code settings:

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

## Commands

Once installed, these commands are available in Claude Code:

```
/pokayokay:plan <prd-path>    # Analyze PRD, create implementation plan
/pokayokay:work [mode]        # Start/continue work session
/pokayokay:audit [feature]    # Audit feature completeness
/pokayokay:review             # Analyze completed sessions
/pokayokay:api <task>         # API design
/pokayokay:ux <task>          # UX design
/pokayokay:ui <task>          # Visual design
/pokayokay:arch <task>        # Architecture review
/pokayokay:handoff            # Session handoff protocol
```

## Workflow

### 1. Initialize ohno

```bash
npx @stevestomp/ohno-cli init
```

### 2. Analyze PRD

```
/pokayokay:plan docs/prd.md
```

This creates tasks in ohno from your PRD.

### 3. View Kanban

```bash
npx @stevestomp/ohno-cli serve
# Opens http://localhost:3456
```

### 4. Work on Tasks

```
/pokayokay:work supervised
```

Work modes:
- **supervised**: Pause after every task
- **semi-auto**: Pause at story/epic boundaries
- **autonomous**: Pause only at epic boundaries

### 5. Audit Completeness

```
/pokayokay:audit
```

Checks levels L0-L5:
- L0: Not Started
- L1: Backend Only
- L2: Frontend Exists
- L3: Routable
- L4: Accessible
- L5: Complete

### 6. Review Sessions

```
/pokayokay:review
```

## Plugin Structure

```
pokayokay/
├── .claude-plugin/
│   └── plugin.json         # Plugin manifest
├── .mcp.json               # MCP server config (ohno)
├── commands/               # Slash commands (/pokayokay:*)
│   ├── plan.md
│   ├── work.md
│   ├── audit.md
│   ├── review.md
│   ├── api.md
│   ├── ux.md
│   ├── ui.md
│   └── arch.md
├── skills/                 # Skill definitions
│   ├── prd-analyzer/
│   ├── project-harness/
│   ├── product-manager/
│   └── ...
├── package.json
└── README.md
```

## Skills

| Skill | Purpose |
|-------|---------|
| prd-analyzer | PRD → implementation plan |
| project-harness | Work session orchestration |
| product-manager | Feature completeness audit |
| session-review | Session analysis |
| api-design | RESTful API design |
| ux-design | UX patterns and flows |
| aesthetic-ui-designer | Visual design |
| architecture-review | Code structure analysis |

## Dependencies

- [ohno](https://github.com/srstomp/ohno) - Task management via MCP

## License

MIT
