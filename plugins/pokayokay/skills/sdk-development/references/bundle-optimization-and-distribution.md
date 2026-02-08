# Bundle Optimization and Distribution

Bundle size optimization, multi-platform builds, dual packages, and monorepo builds.

## Bundle Size Optimization

### Analyze Bundle

```bash
# With tsup
npx tsup --metafile

# Analyze output
npx esbuild-visualizer --metadata ./meta.json --open
```

### Minimize Dependencies

```typescript
// Bad: Import entire lodash
import _ from 'lodash';
const result = _.get(obj, 'a.b.c');

// Good: Import specific function
import get from 'lodash/get';
const result = get(obj, 'a.b.c');

// Better: Native alternative
const result = obj?.a?.b?.c;
```

### Tree-Shaking

```typescript
// Good: Named exports (tree-shakeable)
export { Client } from './client';
export { createClient } from './factory';

// Bad: Object export (not tree-shakeable)
export default {
  Client,
  createClient,
};

// Bad: Side effects in module scope
console.log('SDK loaded');  // Always runs
```

### Mark Side Effects

```json
// package.json
{
  "sideEffects": false
}

// Or specify files with side effects
{
  "sideEffects": [
    "./src/polyfills.ts",
    "*.css"
  ]
}
```

### Code Splitting (if needed)

```typescript
// tsup.config.ts
export default defineConfig({
  entry: ['src/index.ts'],
  splitting: true,  // Enable code splitting
  format: ['esm'],  // Only ESM supports splitting
});
```

---

## Multi-Platform Builds

### Browser Build

```typescript
// tsup.config.ts
import { defineConfig } from 'tsup';

export default defineConfig([
  // Main build (Node + Browser)
  {
    entry: ['src/index.ts'],
    format: ['esm', 'cjs'],
    dts: true,
    platform: 'neutral',
  },

  // Browser-specific UMD build
  {
    entry: ['src/index.ts'],
    format: ['iife'],
    globalName: 'MySDK',
    platform: 'browser',
    outDir: 'dist/browser',
    minify: true,
  },
]);
```

### Environment-Specific Code

```typescript
// src/internal/fetch.ts

// Use native fetch or provide polyfill
export const fetchImpl =
  typeof globalThis.fetch !== 'undefined'
    ? globalThis.fetch
    : (() => {
        throw new Error('fetch is not available. Provide a custom fetch implementation.');
      });

// Or with build-time replacement
declare const __BROWSER__: boolean;

export const storage = __BROWSER__
  ? localStorage
  : new Map<string, string>();
```

---

## Pre-publish Checklist

```bash
#!/bin/bash
# scripts/prepublish.sh

set -e

echo "Type checking..."
npm run typecheck

echo "Running tests..."
npm test

echo "Building..."
npm run build

echo "Checking package..."
npm pack --dry-run

echo "Bundle size..."
du -sh dist/*

echo "Ready to publish!"
```

### Package.json Prepublish

```json
{
  "scripts": {
    "prepublishOnly": "npm run build && npm test",
    "prepack": "npm run build"
  }
}
```

### Verify Build Output

```bash
# Check what's included
npm pack --dry-run

# Verify exports work
node -e "const sdk = require('./dist/index.cjs'); console.log(Object.keys(sdk))"

# Check types
npx tsc --noEmit -p tsconfig.json
```

---

## Dual Package (ESM + CJS)

### File Extensions

```
dist/
├── index.js       # ESM
├── index.cjs      # CJS
├── index.d.ts     # Types for ESM
└── index.d.cts    # Types for CJS (optional)
```

### Package.json

```json
{
  "type": "module",
  "exports": {
    ".": {
      "import": {
        "types": "./dist/index.d.ts",
        "default": "./dist/index.js"
      },
      "require": {
        "types": "./dist/index.d.cts",
        "default": "./dist/index.cjs"
      }
    }
  },
  "main": "./dist/index.cjs",
  "module": "./dist/index.js",
  "types": "./dist/index.d.ts"
}
```

### Handling ESM/CJS Differences

```typescript
// tsup.config.ts
export default defineConfig({
  entry: ['src/index.ts'],
  format: ['esm', 'cjs'],
  dts: true,
  shims: true,  // Add __dirname, __filename for ESM
  cjsInterop: true,
});
```

---

## Monorepo Builds

### Turborepo Configuration

```json
// turbo.json
{
  "$schema": "https://turbo.build/schema.json",
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**"]
    },
    "test": {
      "dependsOn": ["build"],
      "outputs": []
    },
    "lint": {
      "outputs": []
    }
  }
}
```

### Package Dependencies

```json
// packages/react/package.json
{
  "name": "@org/sdk-react",
  "dependencies": {
    "@org/sdk-core": "workspace:*"
  },
  "peerDependencies": {
    "react": ">=17.0.0"
  }
}
```

### Build Order

```bash
# Build all packages in dependency order
npx turbo build

# Build specific package
npx turbo build --filter=@org/sdk-core

# Build package and dependencies
npx turbo build --filter=@org/sdk-react...
```
