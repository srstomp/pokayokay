# Publishing

npm publishing, private registries, versioning, and CI/CD.

## npm Publishing

### First-Time Setup

```bash
# Login to npm
npm login

# Verify login
npm whoami

# For scoped packages, set access
npm config set access public  # For public packages
```

### Publish Public Package

```bash
# Dry run first
npm publish --dry-run

# Publish
npm publish

# Publish scoped package as public
npm publish --access public
```

### Publish Private Package

```bash
# Requires npm paid plan or organization
npm publish --access restricted

# Or configure in package.json
{
  "publishConfig": {
    "access": "restricted"
  }
}
```

### Package.json for Publishing

```json
{
  "name": "@org/my-sdk",
  "version": "1.0.0",
  "description": "SDK for My Service",
  "keywords": ["sdk", "api", "client"],
  "author": "Your Name <you@example.com>",
  "license": "MIT",
  "repository": {
    "type": "git",
    "url": "https://github.com/org/my-sdk.git"
  },
  "bugs": {
    "url": "https://github.com/org/my-sdk/issues"
  },
  "homepage": "https://github.com/org/my-sdk#readme",
  
  "type": "module",
  "exports": {
    ".": {
      "import": "./dist/index.js",
      "require": "./dist/index.cjs",
      "types": "./dist/index.d.ts"
    }
  },
  "main": "./dist/index.cjs",
  "module": "./dist/index.js",
  "types": "./dist/index.d.ts",
  
  "files": [
    "dist",
    "README.md",
    "LICENSE",
    "CHANGELOG.md"
  ],
  
  "scripts": {
    "build": "tsup",
    "test": "vitest run",
    "prepublishOnly": "npm run build && npm test"
  },
  
  "engines": {
    "node": ">=18.0.0"
  },
  
  "publishConfig": {
    "access": "public"
  }
}
```

---

## Private Registries

### GitHub Packages

```bash
# .npmrc in project root
@org:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=${GITHUB_TOKEN}
```

```json
// package.json
{
  "name": "@org/my-sdk",
  "publishConfig": {
    "registry": "https://npm.pkg.github.com"
  }
}
```

```bash
# Publish to GitHub Packages
npm publish
```

### npm Private Packages

```json
// package.json
{
  "name": "@org/my-sdk",
  "private": false,
  "publishConfig": {
    "access": "restricted"
  }
}
```

### Verdaccio (Self-Hosted)

```bash
# Install Verdaccio
npm install -g verdaccio

# Start server
verdaccio

# Configure npm to use local registry
npm set registry http://localhost:4873/

# Publish to local registry
npm publish
```

### Using Private Packages

```bash
# .npmrc for consumers
@org:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=${GITHUB_TOKEN}

# Or for npm private
//registry.npmjs.org/:_authToken=${NPM_TOKEN}
```

---

## Versioning

### Semantic Versioning

```
MAJOR.MINOR.PATCH

1.0.0 → 1.0.1  (patch: bug fix)
1.0.1 → 1.1.0  (minor: new feature, backward compatible)
1.1.0 → 2.0.0  (major: breaking change)
```

### Version Commands

```bash
# Bump version
npm version patch  # 1.0.0 → 1.0.1
npm version minor  # 1.0.1 → 1.1.0
npm version major  # 1.1.0 → 2.0.0

# Prerelease
npm version prerelease --preid=alpha  # 1.0.0 → 1.0.1-alpha.0
npm version prerelease --preid=beta   # 1.0.1-alpha.0 → 1.0.1-beta.0

# Specific version
npm version 2.0.0-rc.1
```

### Prerelease Versions

```
1.0.0-alpha.1  → Early development
1.0.0-beta.1   → Feature complete, testing
1.0.0-rc.1     → Release candidate
1.0.0          → Stable release
```

```bash
# Publish prerelease with tag
npm publish --tag alpha
npm publish --tag beta
npm publish --tag next

# Users install with tag
npm install @org/my-sdk@alpha
npm install @org/my-sdk@next
```

### Changesets (Recommended)

```bash
# Install changesets
npm install -D @changesets/cli

# Initialize
npx changeset init

# Create changeset for changes
npx changeset

# Version packages
npx changeset version

# Publish
npx changeset publish
```

```markdown
# .changeset/happy-dogs-dance.md
---
"@org/my-sdk": minor
---

Added new authentication methods
```

---

## CHANGELOG

### Format (Keep a Changelog)

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New feature X

### Changed
- Updated behavior Y

### Deprecated
- Method Z is deprecated, use W instead

### Removed
- Removed support for Node.js 16

### Fixed
- Bug in authentication flow

### Security
- Updated dependencies to fix CVE-XXXX

## [2.0.0] - 2024-01-15

### Breaking Changes
- Renamed `login()` to `signIn()`
- Changed response format for `getUser()`

### Added
- OAuth 2.0 support
- Token refresh

### Migration Guide
See [MIGRATION.md](./MIGRATION.md) for upgrading from v1.

## [1.1.0] - 2024-01-01

### Added
- New `logout()` method

[Unreleased]: https://github.com/org/my-sdk/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/org/my-sdk/compare/v1.1.0...v2.0.0
[1.1.0]: https://github.com/org/my-sdk/releases/tag/v1.1.0
```

---

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

\`\`\`bash
npm install @org/my-sdk
\`\`\`

## Quick Start

\`\`\`typescript
import { MyClient } from '@org/my-sdk';

const client = new MyClient({
  apiKey: 'your-api-key',
});

const user = await client.getUser('123');
console.log(user);
\`\`\`

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

\`\`\`typescript
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
\`\`\`

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
  echo "❌ Working directory not clean"
  exit 1
fi

# Run checks
echo "🔍 Running checks..."
npm run typecheck
npm run lint
npm test

# Build
echo "🏗️ Building..."
npm run build

# Verify package
echo "📦 Verifying package..."
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
  
  echo "✅ Published v$VERSION"
else
  echo "❌ Cancelled"
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
