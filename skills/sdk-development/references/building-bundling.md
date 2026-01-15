# Building and Bundling

Build tools, output formats, and distribution.

## Build Tool Comparison

| Tool | Speed | Config | ESM | CJS | DTS | Recommended |
|------|-------|--------|-----|-----|-----|-------------|
| **tsup** | Fast | Minimal | ✅ | ✅ | ✅ | Most SDKs |
| **unbuild** | Fast | Minimal | ✅ | ✅ | ✅ | Libraries |
| **tsc** | Medium | tsconfig | ✅ | ✅ | ✅ | Simple |
| **rollup** | Medium | Verbose | ✅ | ✅ | Plugin | Complex |
| **esbuild** | Fastest | Code | ✅ | ✅ | ❌ | With tsc |

---

## tsup (Recommended)

### Installation

```bash
npm install -D tsup typescript
```

### Basic Configuration

```typescript
// tsup.config.ts
import { defineConfig } from 'tsup';

export default defineConfig({
  entry: ['src/index.ts'],
  format: ['esm', 'cjs'],
  dts: true,
  clean: true,
  sourcemap: true,
});
```

### Full Configuration

```typescript
// tsup.config.ts
import { defineConfig } from 'tsup';

export default defineConfig({
  // Entry points
  entry: {
    index: 'src/index.ts',
    react: 'src/react/index.ts',  // Sub-path export
  },
  
  // Output formats
  format: ['esm', 'cjs'],
  
  // TypeScript declarations
  dts: true,
  
  // Source maps for debugging
  sourcemap: true,
  
  // Clean output directory
  clean: true,
  
  // Minify for production
  minify: process.env.NODE_ENV === 'production',
  
  // External packages (don't bundle)
  external: ['react', 'react-dom'],
  
  // No code splitting (single file per entry)
  splitting: false,
  
  // Tree-shaking
  treeshake: true,
  
  // Target environment
  target: 'es2020',
  
  // Node.js compatibility
  platform: 'neutral',
  
  // Custom esbuild options
  esbuildOptions(options) {
    options.drop = ['console', 'debugger'];
  },
  
  // Inject shims
  shims: true,
  
  // Banner
  banner: {
    js: '/* My SDK v1.0.0 */',
  },
});
```

### Package.json Scripts

```json
{
  "scripts": {
    "build": "tsup",
    "build:watch": "tsup --watch",
    "dev": "tsup --watch",
    "typecheck": "tsc --noEmit"
  }
}
```

---

## Output Formats

### ESM (ECMAScript Modules)

```javascript
// dist/index.js (ESM)
export { MyClient } from './client.js';
export { SDKError } from './errors.js';
```

- Modern format
- Tree-shakeable
- Native browser support
- Node.js 14+ support

### CJS (CommonJS)

```javascript
// dist/index.cjs (CJS)
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MyClient = require("./client.js").MyClient;
exports.SDKError = require("./errors.js").SDKError;
```

- Legacy format
- Node.js compatibility
- Required for older bundlers

### Type Declarations

```typescript
// dist/index.d.ts
export declare class MyClient {
    constructor(config: ClientConfig);
    getUser(id: string): Promise<User>;
}
export interface ClientConfig {
    baseUrl: string;
    apiKey?: string;
}
```

- TypeScript support
- IntelliSense in editors
- Required for typed SDK

---

## Package.json Exports

### Modern Exports Field

```json
{
  "name": "@org/my-sdk",
  "version": "1.0.0",
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
    },
    "./react": {
      "import": {
        "types": "./dist/react.d.ts",
        "default": "./dist/react.js"
      },
      "require": {
        "types": "./dist/react.d.cts",
        "default": "./dist/react.cjs"
      }
    }
  },
  
  "main": "./dist/index.cjs",
  "module": "./dist/index.js",
  "types": "./dist/index.d.ts",
  
  "files": ["dist"]
}
```

### Sub-path Exports

```json
{
  "exports": {
    ".": "./dist/index.js",
    "./client": "./dist/client.js",
    "./errors": "./dist/errors.js",
    "./types": "./dist/types.js"
  }
}
```

```typescript
// Users can import specific parts
import { MyClient } from '@org/my-sdk';
import { SDKError } from '@org/my-sdk/errors';
import type { User } from '@org/my-sdk/types';
```

### Conditional Exports

```json
{
  "exports": {
    ".": {
      "node": {
        "import": "./dist/node.js",
        "require": "./dist/node.cjs"
      },
      "browser": "./dist/browser.js",
      "default": "./dist/index.js"
    }
  }
}
```

---

## TypeScript Configuration

### tsconfig.json for SDK

```json
{
  "compilerOptions": {
    // Output
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "outDir": "dist",
    
    // Strictness
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    
    // Interop
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "forceConsistentCasingInFileNames": true,
    
    // Other
    "skipLibCheck": true,
    "resolveJsonModule": true,
    "isolatedModules": true
  },
  "include": ["src"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}
```

### tsconfig for Build

```json
// tsconfig.build.json
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "declaration": true,
    "declarationDir": "dist",
    "emitDeclarationOnly": true
  },
  "include": ["src"],
  "exclude": ["**/*.test.ts", "**/*.spec.ts"]
}
```

---

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
// ❌ Bad: Import entire lodash
import _ from 'lodash';
const result = _.get(obj, 'a.b.c');

// ✅ Good: Import specific function
import get from 'lodash/get';
const result = get(obj, 'a.b.c');

// ✅ Better: Native alternative
const result = obj?.a?.b?.c;
```

### Tree-Shaking

```typescript
// ✅ Good: Named exports (tree-shakeable)
export { Client } from './client';
export { createClient } from './factory';

// ❌ Bad: Object export (not tree-shakeable)
export default {
  Client,
  createClient,
};

// ❌ Bad: Side effects in module scope
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

echo "🔍 Type checking..."
npm run typecheck

echo "🧪 Running tests..."
npm test

echo "🏗️ Building..."
npm run build

echo "📦 Checking package..."
npm pack --dry-run

echo "📊 Bundle size..."
du -sh dist/*

echo "✅ Ready to publish!"
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
node --experimental-specifier-resolution=node -e "import('./dist/index.js').then(m => console.log(Object.keys(m)))"

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
