# CI/CD and Documentation

GitHub Actions workflows, documentation strategies, pre-publish checklists, and deprecation.

## CI/CD

### GitHub Actions: Test + Publish

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        node-version: [18, 20, 22]

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Type check
        run: npm run typecheck

      - name: Lint
        run: npm run lint

      - name: Test
        run: npm test

      - name: Build
        run: npm run build
```

### GitHub Actions: Publish on Release

```yaml
# .github/workflows/publish.yml
name: Publish

on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          registry-url: 'https://registry.npmjs.org'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build

      - name: Test
        run: npm test

      - name: Publish to npm
        run: npm publish --access public
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

### GitHub Actions: Publish with Changesets

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    branches: [main]

concurrency: ${{ github.workflow }}-${{ github.ref }}

jobs:
  release:
    name: Release
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build

      - name: Create Release Pull Request or Publish
        uses: changesets/action@v1
        with:
          publish: npx changeset publish
          version: npx changeset version
          commit: 'chore: release'
          title: 'chore: release'
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

### Publish to GitHub Packages

```yaml
# .github/workflows/publish-gpr.yml
name: Publish to GitHub Packages

on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          registry-url: 'https://npm.pkg.github.com'
          scope: '@org'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build

      - name: Publish
        run: npm publish
        env:
          NODE_AUTH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## Documentation

### README Structure

```markdown
# My SDK

Short description of what the SDK does.

## Installation

npm install @org/my-sdk

## Quick Start

import { MyClient } from '@org/my-sdk';

const client = new MyClient({
  apiKey: 'your-api-key',
});

const user = await client.getUser('123');
console.log(user);

## Documentation

- [Getting Started](./docs/getting-started.md)
- [API Reference](./docs/api-reference.md)
- [Examples](./examples)

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `apiKey` | `string` | - | API key for authentication |
| `baseUrl` | `string` | `https://api.example.com` | API base URL |
| `timeout` | `number` | `30000` | Request timeout in ms |

## Error Handling

import { MyClient, SDKError, NotFoundError } from '@org/my-sdk';

try {
  const user = await client.getUser('123');
} catch (error) {
  if (error instanceof NotFoundError) {
    console.log('User not found');
  } else if (error instanceof SDKError) {
    console.log('SDK error:', error.code);
  }
}

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md)

## License

MIT
```

### API Reference (TypeDoc)

```bash
# Install TypeDoc
npm install -D typedoc

# Generate docs
npx typedoc src/index.ts --out docs/api
```

```json
// typedoc.json
{
  "entryPoints": ["src/index.ts"],
  "out": "docs/api",
  "plugin": ["typedoc-plugin-markdown"],
  "readme": "none",
  "excludePrivate": true,
  "excludeProtected": true
}
```

---

## Pre-Publish Checklist

```markdown
## Before Publishing

### Code Quality
- [ ] All tests passing
- [ ] No TypeScript errors
- [ ] Linting passes
- [ ] No console.log statements
- [ ] No TODO/FIXME in production code

### Build
- [ ] Build succeeds
- [ ] Bundle size reasonable
- [ ] Types generated correctly
- [ ] ESM and CJS both work

### Documentation
- [ ] README updated
- [ ] CHANGELOG updated
- [ ] API docs generated
- [ ] Examples work

### Package
- [ ] Version bumped
- [ ] Files array correct
- [ ] Dependencies correct
- [ ] Peer dependencies documented

### Testing
- [ ] npm pack looks correct
- [ ] Install from tarball works
- [ ] Import/require both work
- [ ] Types resolve correctly

### Publishing
- [ ] Git tag created
- [ ] GitHub release created
- [ ] npm publish successful
```

### Publish Script

```bash
#!/bin/bash
# scripts/publish.sh

set -e

# Ensure clean working directory
if [[ -n $(git status --porcelain) ]]; then
  echo "Working directory not clean"
  exit 1
fi

# Run checks
echo "Running checks..."
npm run typecheck
npm run lint
npm test

# Build
echo "Building..."
npm run build

# Verify package
echo "Verifying package..."
npm pack --dry-run

# Confirm
echo ""
read -p "Publish version $(node -p "require('./package.json').version")? [y/N] " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  # Publish
  npm publish --access public

  # Tag release
  VERSION=$(node -p "require('./package.json').version")
  git tag "v$VERSION"
  git push origin "v$VERSION"

  echo "Published v$VERSION"
else
  echo "Cancelled"
  exit 1
fi
```

---

## Deprecation

### Deprecate a Version

```bash
# Deprecate specific version
npm deprecate @org/my-sdk@1.0.0 "Critical bug, please upgrade to 1.0.1"

# Deprecate version range
npm deprecate @org/my-sdk@"<2.0.0" "Please upgrade to v2"
```

### Deprecate Package

```bash
# Deprecate entire package
npm deprecate @org/my-sdk "This package is no longer maintained. Use @org/new-sdk instead."
```

### Unpublish (Limited)

```bash
# Unpublish specific version (within 72 hours)
npm unpublish @org/my-sdk@1.0.0

# Unpublish entire package (rarely allowed)
npm unpublish @org/my-sdk --force
```

**Note:** npm limits unpublishing to protect the ecosystem. Prefer deprecation.
