# Contributing to pokayokay

Thanks for your interest in contributing to pokayokay! This guide will help you get started.

## Getting Started

1. Fork and clone the repository
2. Install dependencies: `cd cli && npm install`
3. Load the plugin locally: `claude --plugin-dir ./pokayokay`

## Development

### Project Structure

The plugin lives in `plugins/pokayokay/` with four main areas:

- `commands/` - Slash command definitions (markdown files)
- `skills/` - Domain knowledge and workflows (SKILL.md + references/)
- `agents/` - Subagent definitions for Task tool dispatch
- `hooks/actions/` - Shell scripts and bridge.py for hook execution

### Running Tests

```bash
# Run a specific test
bash plugins/pokayokay/tests/<test-name>.test.sh

# Run all tests
for test in plugins/pokayokay/tests/*.test.sh; do bash "$test"; done
```

### Validating the Plugin

```bash
claude plugin validate plugins/pokayokay
```

## File Conventions

- **Commands**: Markdown files with frontmatter (`description`, `argument-hint`, optional `skill` reference)
- **Skills**: Subdirectory with `SKILL.md` and `references/` for detailed guides. Keep reference files under 500 lines.
- **Agents**: Markdown files loaded by `subagent_type` name (filename without .md)
- **Hook Actions**: Shell scripts executed by `bridge.py`

## Submitting Changes

1. Create a branch for your changes
2. Make your changes and add tests where applicable
3. Run the test suite to verify nothing is broken
4. Submit a pull request with a clear description of what changed and why

## Reporting Issues

Open an issue on GitHub with:
- A clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Your environment (OS, Node version, Claude Code version)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
