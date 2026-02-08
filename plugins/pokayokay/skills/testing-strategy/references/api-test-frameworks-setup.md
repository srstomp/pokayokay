# Test Framework Setup

Setup and configuration for Vitest and Jest.

## Framework Comparison

| Feature | Jest | Vitest |
|---------|------|--------|
| Speed | Good | Excellent (native ESM) |
| Config | Extensive | Minimal |
| TypeScript | Via ts-jest | Native |
| ESM Support | Requires config | Native |
| Watch Mode | Good | Excellent |
| Ecosystem | Mature | Growing |
| Best For | Established projects | Modern TypeScript/Vite |

**Recommendation**: Use Vitest for new TypeScript projects. Use Jest for existing projects or when specific Jest features are needed.

---

## Vitest Setup

### Installation

```bash
npm install -D vitest @vitest/coverage-v8 supertest @types/supertest
```

### Configuration

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Global test settings
    globals: true,
    environment: 'node',

    // Setup files
    setupFiles: ['./tests/setup.ts'],

    // Include patterns
    include: ['tests/**/*.test.ts'],

    // Exclude patterns
    exclude: ['node_modules', 'dist'],

    // Coverage
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      exclude: [
        'node_modules',
        'tests',
        '**/*.d.ts',
        '**/*.config.*',
      ],
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 80,
        statements: 80,
      },
    },

    // Timeouts
    testTimeout: 10000,
    hookTimeout: 10000,

    // Parallel execution
    pool: 'threads',
    poolOptions: {
      threads: {
        singleThread: false,
      },
    },

    // Reporter
    reporters: ['verbose'],
  },
});
```

### TypeScript Support

```json
// tsconfig.json
{
  "compilerOptions": {
    "types": ["vitest/globals"]
  }
}
```

### Setup File

```typescript
// tests/setup.ts
import { beforeAll, afterAll, beforeEach } from 'vitest';
import { db } from './helpers/db';

// Global setup
beforeAll(async () => {
  await db.connect();
  await db.migrate();
});

// Global teardown
afterAll(async () => {
  await db.close();
});

// Per-test cleanup
beforeEach(async () => {
  await db.truncateAll();
});
```

### Running Tests

```bash
# Run all tests
npx vitest

# Run in watch mode
npx vitest --watch

# Run specific file
npx vitest tests/integration/users.test.ts

# Run with coverage
npx vitest --coverage

# Run single test
npx vitest -t "creates user"

# Run with UI
npx vitest --ui
```

### Package.json Scripts

```json
{
  "scripts": {
    "test": "vitest",
    "test:watch": "vitest --watch",
    "test:coverage": "vitest --coverage",
    "test:ui": "vitest --ui",
    "test:integration": "vitest tests/integration",
    "test:e2e": "vitest tests/e2e"
  }
}
```

---

## Jest Setup

### Installation

```bash
npm install -D jest @types/jest ts-jest supertest @types/supertest
```

### Configuration

```javascript
// jest.config.js
/** @type {import('jest').Config} */
module.exports = {
  // TypeScript support
  preset: 'ts-jest',

  // Environment
  testEnvironment: 'node',

  // Setup files
  setupFilesAfterEnv: ['./tests/setup.ts'],

  // Test patterns
  testMatch: ['**/tests/**/*.test.ts'],

  // Ignore patterns
  testPathIgnorePatterns: ['/node_modules/', '/dist/'],

  // Module resolution
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },

  // Coverage
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/**/index.ts',
  ],
  coverageThreshold: {
    global: {
      lines: 80,
      functions: 80,
      branches: 80,
      statements: 80,
    },
  },
  coverageReporters: ['text', 'html', 'lcov'],

  // Timeouts
  testTimeout: 10000,

  // Verbose output
  verbose: true,

  // Clear mocks between tests
  clearMocks: true,

  // Detect open handles
  detectOpenHandles: true,

  // Force exit
  forceExit: true,
};
```

### ts-jest Configuration

```javascript
// jest.config.js (with ESM support)
module.exports = {
  preset: 'ts-jest/presets/default-esm',
  extensionsToTreatAsEsm: ['.ts'],
  moduleNameMapper: {
    '^(\\.{1,2}/.*)\\.js$': '$1',
  },
  transform: {
    '^.+\\.tsx?$': [
      'ts-jest',
      {
        useESM: true,
      },
    ],
  },
};
```

### Setup File

```typescript
// tests/setup.ts
import { db } from './helpers/db';

beforeAll(async () => {
  await db.connect();
  await db.migrate();
});

afterAll(async () => {
  await db.close();
});

beforeEach(async () => {
  await db.truncateAll();
});

// Extend Jest matchers if needed
expect.extend({
  toBeWithinRange(received: number, floor: number, ceiling: number) {
    const pass = received >= floor && received <= ceiling;
    return {
      pass,
      message: () =>
        `expected ${received} ${pass ? 'not ' : ''}to be within range ${floor} - ${ceiling}`,
    };
  },
});
```

### Running Tests

```bash
# Run all tests
npx jest

# Run in watch mode
npx jest --watch

# Run specific file
npx jest tests/integration/users.test.ts

# Run with coverage
npx jest --coverage

# Run matching pattern
npx jest -t "creates user"

# Run with verbose output
npx jest --verbose
```
