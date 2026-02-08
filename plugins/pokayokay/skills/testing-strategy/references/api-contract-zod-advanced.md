# Contract Testing with Zod and Advanced Techniques

Zod schema validation, response shape testing, breaking change detection, and request validation.

## Zod Schema Validation

Alternative approach using Zod for runtime validation.

### Setup

```bash
npm install zod
```

### Define Schemas

```typescript
// src/schemas/user.ts
import { z } from 'zod';

export const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  name: z.string().min(1),
  role: z.enum(['admin', 'user', 'guest']).default('user'),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime().optional(),
});

export const UserListSchema = z.object({
  data: z.array(UserSchema),
  meta: z.object({
    total: z.number().int(),
    page: z.number().int(),
    perPage: z.number().int(),
  }),
});

export const CreateUserInputSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1),
  password: z.string().min(8),
});

export const ErrorSchema = z.object({
  status: z.number().int(),
  error: z.string(),
  message: z.string(),
});

export const ValidationErrorSchema = z.object({
  status: z.literal(400),
  message: z.string(),
  errors: z.array(z.object({
    field: z.string(),
    message: z.string(),
  })),
});

export type User = z.infer<typeof UserSchema>;
export type UserList = z.infer<typeof UserListSchema>;
export type CreateUserInput = z.infer<typeof CreateUserInputSchema>;
```

### Contract Tests with Zod

```typescript
// tests/contracts/users.contract.test.ts
import { describe, it, expect } from 'vitest';
import request from 'supertest';
import { app } from '../../src/app';
import {
  UserSchema,
  UserListSchema,
  ErrorSchema,
  ValidationErrorSchema
} from '../../src/schemas/user';
import { createUser } from '../helpers/factories';

describe('Users API Contract (Zod)', () => {
  describe('GET /users', () => {
    it('returns valid UserList', async () => {
      await createUser();

      const response = await request(app)
        .get('/users')
        .expect(200);

      const result = UserListSchema.safeParse(response.body);

      expect(result.success).toBe(true);
      if (!result.success) {
        console.error(result.error.format());
      }
    });
  });

  describe('GET /users/:id', () => {
    it('returns valid User', async () => {
      const user = await createUser();

      const response = await request(app)
        .get(`/users/${user.id}`)
        .expect(200);

      expect(() => UserSchema.parse(response.body)).not.toThrow();
    });

    it('returns valid Error for 404', async () => {
      const response = await request(app)
        .get('/users/non-existent')
        .expect(404);

      expect(() => ErrorSchema.parse(response.body)).not.toThrow();
    });
  });

  describe('POST /users', () => {
    it('returns valid User on success', async () => {
      const response = await request(app)
        .post('/users')
        .send({
          email: 'new@example.com',
          name: 'New User',
          password: 'password123',
        })
        .expect(201);

      const result = UserSchema.safeParse(response.body);
      expect(result.success).toBe(true);
    });

    it('returns valid ValidationError on 400', async () => {
      const response = await request(app)
        .post('/users')
        .send({ email: 'invalid' })
        .expect(400);

      const result = ValidationErrorSchema.safeParse(response.body);
      expect(result.success).toBe(true);
    });
  });
});
```

### Zod Custom Matcher

```typescript
// tests/helpers/matchers/zod.ts
import { expect } from 'vitest';
import { ZodSchema, ZodError } from 'zod';

expect.extend({
  toMatchZodSchema(received: unknown, schema: ZodSchema) {
    const result = schema.safeParse(received);

    if (result.success) {
      return {
        pass: true,
        message: () => 'Expected not to match schema',
      };
    }

    const errors = result.error.errors
      .map(e => `${e.path.join('.')}: ${e.message}`)
      .join('\n');

    return {
      pass: false,
      message: () => `Schema validation failed:\n${errors}`,
    };
  },
});

declare module 'vitest' {
  interface Assertion<T> {
    toMatchZodSchema(schema: ZodSchema): void;
  }
}

// Usage
expect(response.body).toMatchZodSchema(UserSchema);
```

---

## Response Shape Testing

For simpler cases without full schema validation.

### Structure Matching

```typescript
describe('Response Structure', () => {
  it('returns expected shape for User', async () => {
    const user = await createUser();

    const response = await request(app)
      .get(`/users/${user.id}`)
      .expect(200);

    // Check structure without exact values
    expect(response.body).toMatchObject({
      id: expect.any(String),
      email: expect.any(String),
      name: expect.any(String),
      createdAt: expect.any(String),
    });

    // Check specific field formats
    expect(response.body.id).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    );
    expect(response.body.createdAt).toMatch(/^\d{4}-\d{2}-\d{2}T/);
  });

  it('does not include sensitive fields', async () => {
    const user = await createUser();

    const response = await request(app)
      .get(`/users/${user.id}`)
      .expect(200);

    expect(response.body.password).toBeUndefined();
    expect(response.body.passwordHash).toBeUndefined();
  });

  it('includes all required fields', async () => {
    const user = await createUser();

    const response = await request(app)
      .get(`/users/${user.id}`)
      .expect(200);

    const requiredFields = ['id', 'email', 'name', 'createdAt'];

    for (const field of requiredFields) {
      expect(response.body).toHaveProperty(field);
    }
  });
});
```

### Type Checking

```typescript
describe('Response Types', () => {
  it('returns correct types', async () => {
    const user = await createUser();

    const response = await request(app)
      .get(`/users/${user.id}`)
      .expect(200);

    expect(typeof response.body.id).toBe('string');
    expect(typeof response.body.email).toBe('string');
    expect(typeof response.body.name).toBe('string');
    expect(['admin', 'user', 'guest']).toContain(response.body.role);
  });

  it('returns array for list endpoints', async () => {
    const response = await request(app)
      .get('/users')
      .expect(200);

    expect(Array.isArray(response.body.data)).toBe(true);
    expect(typeof response.body.meta.total).toBe('number');
  });
});
```

---

## Breaking Change Detection

### Snapshot Contract Testing

```typescript
// tests/contracts/snapshots.test.ts
describe('API Contract Snapshots', () => {
  it('User response shape', async () => {
    const user = await createUser({
      email: 'snapshot@test.com',
      name: 'Snapshot User',
    });

    const response = await request(app)
      .get(`/users/${user.id}`)
      .expect(200);

    // Snapshot with dynamic fields masked
    expect(response.body).toMatchSnapshot({
      id: expect.any(String),
      createdAt: expect.any(String),
      updatedAt: expect.any(String),
    });
  });

  it('Error response shape', async () => {
    const response = await request(app)
      .get('/users/non-existent')
      .expect(404);

    expect(response.body).toMatchInlineSnapshot(`
      {
        "error": "Not Found",
        "message": "User not found",
        "status": 404,
      }
    `);
  });
});
```

### Field Presence Tests

```typescript
// Catch accidental field removal
describe('Backward Compatibility', () => {
  const v1RequiredFields = ['id', 'email', 'name', 'createdAt'];
  const v1OptionalFields = ['role', 'updatedAt', 'avatar'];

  it('includes all v1 required fields', async () => {
    const user = await createUser();

    const response = await request(app)
      .get(`/users/${user.id}`)
      .expect(200);

    for (const field of v1RequiredFields) {
      expect(response.body).toHaveProperty(field);
      expect(response.body[field]).not.toBeNull();
    }
  });

  it('supports all v1 optional fields', async () => {
    const user = await createUser({ role: 'admin' });

    const response = await request(app)
      .get(`/users/${user.id}`)
      .expect(200);

    // Optional fields can be present or absent, but not renamed
    for (const field of v1OptionalFields) {
      if (response.body[field] !== undefined) {
        expect(typeof response.body[field]).not.toBe('undefined');
      }
    }
  });
});
```

---

## Request Validation Testing

### Input Schema Tests

```typescript
describe('Request Validation', () => {
  describe('POST /users input validation', () => {
    it('accepts valid input', async () => {
      await request(app)
        .post('/users')
        .send({
          email: 'valid@example.com',
          name: 'Valid Name',
          password: 'securePassword123',
        })
        .expect(201);
    });

    it('rejects missing required fields', async () => {
      const response = await request(app)
        .post('/users')
        .send({})
        .expect(400);

      expect(response.body.errors).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ field: 'email' }),
          expect.objectContaining({ field: 'name' }),
          expect.objectContaining({ field: 'password' }),
        ])
      );
    });

    it('rejects invalid email format', async () => {
      const response = await request(app)
        .post('/users')
        .send({
          email: 'not-an-email',
          name: 'Test',
          password: 'password123',
        })
        .expect(400);

      expect(response.body.errors[0].field).toBe('email');
    });

    it('rejects password too short', async () => {
      const response = await request(app)
        .post('/users')
        .send({
          email: 'test@example.com',
          name: 'Test',
          password: '123', // Too short
        })
        .expect(400);

      expect(response.body.errors[0].field).toBe('password');
    });

    it('ignores unknown fields', async () => {
      const response = await request(app)
        .post('/users')
        .send({
          email: 'test@example.com',
          name: 'Test',
          password: 'password123',
          unknownField: 'should be ignored',
          anotherUnknown: 123,
        })
        .expect(201);

      expect(response.body.unknownField).toBeUndefined();
    });
  });
});
```

---

## CI Integration for Contract Tests

```yaml
# .github/workflows/contract-tests.yml
name: Contract Tests

on:
  push:
    paths:
      - 'openapi.yaml'
      - 'src/**'
      - 'tests/contracts/**'

jobs:
  contract-tests:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm ci

      - name: Validate OpenAPI spec
        run: npx @redocly/cli lint openapi.yaml

      - name: Run contract tests
        run: npm run test:contracts

      - name: Check for breaking changes
        run: npx @redocly/cli diff openapi.yaml origin/main:openapi.yaml
```
