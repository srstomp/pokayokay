# Test Frameworks

Setup and configuration for Jest, Vitest, and Supertest.

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

---

## Supertest

### Basic Usage

```typescript
import request from 'supertest';
import { app } from '../../src/app';

describe('Users API', () => {
  it('gets all users', async () => {
    const response = await request(app)
      .get('/users')
      .expect('Content-Type', /json/)
      .expect(200);

    expect(response.body).toBeInstanceOf(Array);
  });
});
```

### HTTP Methods

```typescript
// GET
await request(app).get('/users');
await request(app).get('/users?page=1&limit=10');
await request(app).get('/users/123');

// POST
await request(app)
  .post('/users')
  .send({ email: 'test@example.com', name: 'Test' });

// PUT
await request(app)
  .put('/users/123')
  .send({ name: 'Updated Name' });

// PATCH
await request(app)
  .patch('/users/123')
  .send({ name: 'Updated Name' });

// DELETE
await request(app).delete('/users/123');
```

### Headers

```typescript
// Set headers
await request(app)
  .get('/users')
  .set('Authorization', 'Bearer token123')
  .set('Accept', 'application/json')
  .set('X-Custom-Header', 'value');

// Multiple headers at once
await request(app)
  .get('/users')
  .set({
    'Authorization': 'Bearer token123',
    'Accept': 'application/json',
  });

// Check response headers
const response = await request(app).get('/users');
expect(response.headers['content-type']).toMatch(/json/);
expect(response.headers['x-total-count']).toBe('100');
```

### Request Body

```typescript
// JSON body (default)
await request(app)
  .post('/users')
  .send({ email: 'test@example.com' });

// Form data
await request(app)
  .post('/upload')
  .field('name', 'My File')
  .attach('file', 'path/to/file.pdf');

// URL-encoded
await request(app)
  .post('/form')
  .type('form')
  .send({ field1: 'value1', field2: 'value2' });
```

### Assertions

```typescript
// Status code
await request(app).get('/users').expect(200);
await request(app).post('/users').send({}).expect(400);

// Content type
await request(app).get('/users').expect('Content-Type', /json/);

// Header value
await request(app).get('/health').expect('X-Response-Time', /\d+ms/);

// Body assertion (callback)
await request(app)
  .get('/users')
  .expect(200)
  .expect((res) => {
    if (!Array.isArray(res.body)) {
      throw new Error('Expected array');
    }
  });

// Chained assertions
const response = await request(app)
  .get('/users')
  .expect(200)
  .expect('Content-Type', /json/);

expect(response.body).toHaveLength(10);
```

### Working with Response

```typescript
const response = await request(app).get('/users/123');

// Status
console.log(response.status);        // 200
console.log(response.statusCode);    // 200

// Headers
console.log(response.headers);       // { 'content-type': '...', ... }
console.log(response.header);        // Same as above

// Body
console.log(response.body);          // Parsed JSON
console.log(response.text);          // Raw text

// Type check
console.log(response.type);          // 'application/json'
```

---

## Request Helper

Create a typed request helper for reuse:

```typescript
// tests/helpers/request.ts
import supertest from 'supertest';
import { app } from '../../src/app';

export const request = supertest(app);

// Typed request with auth
export async function authRequest(token: string) {
  return supertest(app).set('Authorization', `Bearer ${token}`);
}

// Or create request factory
export function createRequest(options?: { token?: string }) {
  const agent = supertest(app);
  
  if (options?.token) {
    // This doesn't work directly, need different approach
  }
  
  return agent;
}

// Better: Helper functions
export async function get(path: string, token?: string) {
  const req = request.get(path);
  if (token) req.set('Authorization', `Bearer ${token}`);
  return req;
}

export async function post(path: string, body: unknown, token?: string) {
  const req = request.post(path).send(body);
  if (token) req.set('Authorization', `Bearer ${token}`);
  return req;
}

export async function put(path: string, body: unknown, token?: string) {
  const req = request.put(path).send(body);
  if (token) req.set('Authorization', `Bearer ${token}`);
  return req;
}

export async function del(path: string, token?: string) {
  const req = request.delete(path);
  if (token) req.set('Authorization', `Bearer ${token}`);
  return req;
}
```

### Using Request Helper

```typescript
// tests/integration/users.test.ts
import { get, post, del } from '../helpers/request';
import { createAuthToken } from '../helpers/auth';

describe('Users API', () => {
  let token: string;

  beforeAll(async () => {
    token = await createAuthToken({ role: 'admin' });
  });

  it('lists users with auth', async () => {
    const response = await get('/users', token);
    expect(response.status).toBe(200);
  });

  it('creates user', async () => {
    const response = await post('/users', {
      email: 'new@example.com',
      name: 'New User',
    }, token);
    
    expect(response.status).toBe(201);
    expect(response.body.email).toBe('new@example.com');
  });
});
```

---

## Test Server Management

### Express App

```typescript
// src/app.ts
import express from 'express';

export const app = express();

app.use(express.json());
// ... routes

// Don't listen here, do it in server.ts
```

```typescript
// src/server.ts
import { app } from './app';

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

### Testing Without Starting Server

```typescript
// Supertest handles the server automatically
import request from 'supertest';
import { app } from '../../src/app';

// No need to start/stop server
// Supertest binds to ephemeral port

it('works without server.listen()', async () => {
  await request(app).get('/health').expect(200);
});
```

### Testing with Running Server

```typescript
// For integration with real database connections
import { app } from '../../src/app';
import http from 'http';

let server: http.Server;

beforeAll((done) => {
  server = app.listen(0, done); // Port 0 = random available port
});

afterAll((done) => {
  server.close(done);
});

// Get the actual port
const address = server.address();
const port = typeof address === 'object' ? address?.port : null;
```

---

## Custom Matchers

### Vitest Custom Matchers

```typescript
// tests/matchers.ts
import { expect } from 'vitest';

expect.extend({
  toBeValidUUID(received: string) {
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    const pass = uuidRegex.test(received);
    
    return {
      pass,
      message: () => `expected ${received} ${pass ? 'not ' : ''}to be a valid UUID`,
    };
  },
  
  toBeISODate(received: string) {
    const date = new Date(received);
    const pass = !isNaN(date.getTime()) && received === date.toISOString();
    
    return {
      pass,
      message: () => `expected ${received} ${pass ? 'not ' : ''}to be a valid ISO date`,
    };
  },
  
  toMatchApiError(received: unknown, expectedCode: string) {
    const pass = 
      typeof received === 'object' &&
      received !== null &&
      'code' in received &&
      (received as { code: string }).code === expectedCode;
    
    return {
      pass,
      message: () => `expected error code ${expectedCode}, got ${JSON.stringify(received)}`,
    };
  },
});

// Type declarations
declare module 'vitest' {
  interface Assertion<T> {
    toBeValidUUID(): void;
    toBeISODate(): void;
    toMatchApiError(code: string): void;
  }
}
```

### Jest Custom Matchers

```typescript
// tests/matchers.ts
expect.extend({
  toBeValidUUID(received: string) {
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    const pass = uuidRegex.test(received);
    
    return {
      pass,
      message: () => `expected ${received} ${pass ? 'not ' : ''}to be a valid UUID`,
    };
  },
});

// Type declarations
declare global {
  namespace jest {
    interface Matchers<R> {
      toBeValidUUID(): R;
    }
  }
}
```

### Using Custom Matchers

```typescript
// tests/setup.ts
import './matchers';

// tests/integration/users.test.ts
it('returns user with valid UUID', async () => {
  const response = await request(app)
    .post('/users')
    .send({ email: 'test@example.com' })
    .expect(201);

  expect(response.body.id).toBeValidUUID();
  expect(response.body.createdAt).toBeISODate();
});
```

---

## Snapshot Testing

### API Response Snapshots

```typescript
it('returns user with expected shape', async () => {
  const user = await createUser({
    email: 'snapshot@example.com',
    name: 'Snapshot User',
  });

  const response = await request(app)
    .get(`/users/${user.id}`)
    .expect(200);

  // Snapshot entire response (be careful with dynamic fields)
  expect(response.body).toMatchSnapshot({
    id: expect.any(String),
    createdAt: expect.any(String),
    updatedAt: expect.any(String),
  });
});
```

### Inline Snapshots

```typescript
it('returns validation error', async () => {
  const response = await request(app)
    .post('/users')
    .send({ email: 'invalid' })
    .expect(400);

  expect(response.body).toMatchInlineSnapshot(`
    {
      "errors": [
        {
          "field": "email",
          "message": "Invalid email format",
        },
      ],
      "message": "Validation failed",
    }
  `);
});
```

---

## Debugging Tests

### Vitest

```bash
# Run with debugging output
DEBUG=* npx vitest

# Run single test file
npx vitest tests/integration/users.test.ts

# Run with reporter
npx vitest --reporter=verbose
```

### Jest

```bash
# Run with debugging
node --inspect-brk node_modules/.bin/jest --runInBand

# Verbose output
npx jest --verbose

# Detect open handles
npx jest --detectOpenHandles
```

### Log Response in Tests

```typescript
it('debugging test', async () => {
  const response = await request(app)
    .get('/users')
    .expect(200);

  // Debug output
  console.log('Status:', response.status);
  console.log('Headers:', response.headers);
  console.log('Body:', JSON.stringify(response.body, null, 2));

  expect(response.body).toBeDefined();
});
```
