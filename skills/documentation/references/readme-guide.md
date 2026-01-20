# README Guide

Comprehensive guidance for creating effective README files.

## README Anatomy

### Complete Structure

```markdown
# Project Name

[![Build Status](badge-url)](ci-url)
[![npm version](badge-url)](npm-url)
[![License](badge-url)](license-url)

Brief description of what this project does and who it's for.

## Features

- Feature 1 with brief explanation
- Feature 2 with brief explanation
- Feature 3 with brief explanation

## Installation

\`\`\`bash
npm install project-name
\`\`\`

## Quick Start

\`\`\`javascript
import { something } from 'project-name';

// Basic usage example
const result = something.do();
console.log(result);
\`\`\`

## Usage

### Basic Usage

More detailed usage examples...

### Advanced Usage

Complex scenarios...

## API Reference

Brief API overview or link to full docs.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| option1 | string | 'default' | What it does |
| option2 | boolean | false | What it enables |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[MIT](LICENSE)
```

## Section Patterns

### Project Description

**Good**: Specific, actionable, explains value
```markdown
A fast, lightweight library for parsing and validating JSON schemas
with TypeScript support and zero dependencies.
```

**Bad**: Vague, buzzwordy
```markdown
A next-generation, enterprise-ready, scalable solution for your 
JSON processing needs.
```

### Feature Lists

**Concise bullets with context**:
```markdown
## Features

- **Type-safe** — Full TypeScript support with strict types
- **Fast** — Benchmarks at 10x faster than alternatives
- **Lightweight** — 5KB gzipped, zero dependencies
- **Extensible** — Plugin system for custom validators
```

### Installation Sections

**Multiple package managers**:
```markdown
## Installation

npm:
\`\`\`bash
npm install project-name
\`\`\`

yarn:
\`\`\`bash
yarn add project-name
\`\`\`

pnpm:
\`\`\`bash
pnpm add project-name
\`\`\`
```

**With prerequisites**:
```markdown
## Installation

### Prerequisites

- Node.js >= 18
- npm >= 9

### Install

\`\`\`bash
npm install project-name
\`\`\`
```

### Quick Start Examples

**Show immediate value**:
```markdown
## Quick Start

\`\`\`javascript
import { validate } from 'schema-validator';

// Define a schema
const userSchema = {
  type: 'object',
  properties: {
    name: { type: 'string' },
    age: { type: 'number', minimum: 0 }
  },
  required: ['name']
};

// Validate data
const result = validate(userSchema, { name: 'Jane', age: 25 });
console.log(result.valid); // true
\`\`\`
```

### Configuration Tables

**Clear, scannable format**:
```markdown
## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `strict` | boolean | `false` | Enable strict validation mode |
| `timeout` | number | `5000` | Request timeout in milliseconds |
| `retries` | number | `3` | Number of retry attempts |
| `baseUrl` | string | — | Base URL for API requests (required) |
```

### Environment Variables

```markdown
## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `API_KEY` | Yes | Your API authentication key |
| `DEBUG` | No | Enable debug logging (`true`/`false`) |
| `LOG_LEVEL` | No | Logging verbosity: `error`, `warn`, `info`, `debug` |
```

## Badges

### Common Badges

```markdown
<!-- Build status -->
[![Build Status](https://github.com/user/repo/workflows/CI/badge.svg)](https://github.com/user/repo/actions)

<!-- npm version -->
[![npm version](https://badge.fury.io/js/package-name.svg)](https://www.npmjs.com/package/package-name)

<!-- License -->
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

<!-- Coverage -->
[![Coverage Status](https://coveralls.io/repos/github/user/repo/badge.svg)](https://coveralls.io/github/user/repo)

<!-- TypeScript -->
[![TypeScript](https://img.shields.io/badge/TypeScript-Ready-blue.svg)](https://www.typescriptlang.org/)

<!-- Downloads -->
[![npm downloads](https://img.shields.io/npm/dm/package-name.svg)](https://www.npmjs.com/package/package-name)
```

### Badge Placement

```markdown
# Project Name

[![CI](badge)](url) [![npm](badge)](url) [![License](badge)](url)

Description follows badges on separate line.
```

**Keep badge count reasonable** — 3-5 most relevant badges.

## README Variants

### Library/Package README

Focus on: Installation, quick start, API reference
```markdown
# Library Name

Brief description.

## Installation
## Quick Start  
## API Reference
## Contributing
## License
```

### Application README

Focus on: Setup, running, deployment
```markdown
# App Name

Brief description.

## Prerequisites
## Installation
## Configuration
## Running
## Deployment
## Contributing
## License
```

### Monorepo README

Focus on: Structure, navigation, package list
```markdown
# Monorepo Name

Brief description.

## Packages

| Package | Description |
|---------|-------------|
| [@scope/core](packages/core) | Core functionality |
| [@scope/cli](packages/cli) | Command line interface |

## Development
## Contributing
## License
```

### Internal Project README

Focus on: Context, setup, team conventions
```markdown
# Project Name

What this project does in the company context.

## Getting Started
## Development
## Team Conventions
## Related Documentation
```

## Writing Quality

### Be Concise

```markdown
❌ This library provides functionality that enables users to validate
   JSON data structures against predefined schema definitions.

✅ Validate JSON against schemas.
```

### Be Specific

```markdown
❌ Install the package.
✅ npm install package-name
```

### Be Current

```markdown
❌ Works with Node 12+
✅ Requires Node 18 or later (tested on Node 18, 20, 22)
```

### Use Active Voice

```markdown
❌ The configuration file should be created in the root directory.
✅ Create a config file in the root directory.
```

## Maintenance

### Keeping README Fresh

1. **Version quick start** — Test with each release
2. **Automate what you can** — Generate from code where possible
3. **Review in PRs** — Include README updates in feature PRs
4. **Check links** — Use link checkers in CI

### README Health Checklist

- [ ] Quick start actually works
- [ ] Version numbers are current
- [ ] All links resolve
- [ ] Screenshots match current UI
- [ ] Installation instructions tested
- [ ] Examples run without error
