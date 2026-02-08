# Publishing and Registries

npm publishing, private registries, versioning, and changelogs.

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
```

```json
// Or configure in package.json
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

```
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

```
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

1.0.0 -> 1.0.1  (patch: bug fix)
1.0.1 -> 1.1.0  (minor: new feature, backward compatible)
1.1.0 -> 2.0.0  (major: breaking change)
```

### Version Commands

```bash
# Bump version
npm version patch  # 1.0.0 -> 1.0.1
npm version minor  # 1.0.1 -> 1.1.0
npm version major  # 1.1.0 -> 2.0.0

# Prerelease
npm version prerelease --preid=alpha  # 1.0.0 -> 1.0.1-alpha.0
npm version prerelease --preid=beta   # 1.0.1-alpha.0 -> 1.0.1-beta.0

# Specific version
npm version 2.0.0-rc.1
```

### Prerelease Versions

```
1.0.0-alpha.1  -> Early development
1.0.0-beta.1   -> Feature complete, testing
1.0.0-rc.1     -> Release candidate
1.0.0          -> Stable release
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
