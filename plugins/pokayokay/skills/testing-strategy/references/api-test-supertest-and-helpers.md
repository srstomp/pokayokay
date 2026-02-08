# Supertest, Helpers, and Test Utilities

Supertest usage, request helpers, server management, custom matchers, snapshots, and debugging.

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
