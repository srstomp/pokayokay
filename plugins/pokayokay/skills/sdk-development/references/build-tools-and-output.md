# Build Tools and Output Formats

Build tool comparison, tsup configuration, output formats, package.json exports, and TypeScript config.

## Build Tool Comparison

| Tool | Speed | Config | ESM | CJS | DTS | Recommended |
|------|-------|--------|-----|-----|-----|-------------|
| **tsup** | Fast | Minimal | Yes | Yes | Yes | Most SDKs |
| **unbuild** | Fast | Minimal | Yes | Yes | Yes | Libraries |
| **tsc** | Medium | tsconfig | Yes | Yes | Yes | Simple |
| **rollup** | Medium | Verbose | Yes | Yes | Plugin | Complex |
| **esbuild** | Fastest | Code | Yes | Yes | No | With tsc |

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
