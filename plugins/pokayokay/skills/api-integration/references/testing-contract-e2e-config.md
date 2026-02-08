# API Integration Testing: Contract, E2E & Configuration

Contract testing, end-to-end tests with real APIs, and test configuration.

## Contract Testing

### Schema Validation

```typescript
// Validate responses match expected schema
import { z } from 'zod';

const UserSchema = z.object({
  id: z.string(),
  email: z.string().email(),
  name: z.string().nullable(),
  created_at: z.string().datetime(),
  updated_at: z.string().datetime(),
});

const UserListSchema = z.array(UserSchema);

describe('API Contract', () => {
  test('GET /users returns valid schema', async () => {
    const response = await fetch('https://api.example.com/users');
    const data = await response.json();

    expect(() => UserListSchema.parse(data)).not.toThrow();
  });

  test('GET /users/:id returns valid schema', async () => {
    const response = await fetch('https://api.example.com/users/1');
    const data = await response.json();

    expect(() => UserSchema.parse(data)).not.toThrow();
  });
});
```

### OpenAPI Contract Test

```typescript
// Validate responses against OpenAPI spec
import SwaggerParser from '@apidevtools/swagger-parser';
import Ajv from 'ajv';

describe('OpenAPI Contract', () => {
  let ajv: Ajv;
  let schemas: Record<string, unknown>;

  beforeAll(async () => {
    const spec = await SwaggerParser.dereference('./api-spec.yaml');
    schemas = spec.components?.schemas ?? {};
    ajv = new Ajv();
  });

  test('GET /users matches UserList schema', async () => {
    const response = await fetch('https://api.example.com/users');
    const data = await response.json();

    const validate = ajv.compile(schemas.UserList);
    const valid = validate(data);

    expect(valid).toBe(true);
    if (!valid) {
      console.error(validate.errors);
    }
  });
});
```

---

## E2E Tests (Real API)

```typescript
// e2e/user-api.e2e.test.ts

// Only run in CI with real API
const describeE2E = process.env.CI ? describe : describe.skip;

describeE2E('User API E2E', () => {
  let createdUserId: string;

  test('creates a user', async () => {
    const user = await userService.create({
      email: `test-${Date.now()}@example.com`,
      name: 'E2E Test User',
    });

    expect(user.id).toBeDefined();
    expect(user.email).toContain('test-');

    createdUserId = user.id;
  });

  test('fetches created user', async () => {
    const user = await userService.get(createdUserId);

    expect(user.id).toBe(createdUserId);
    expect(user.name).toBe('E2E Test User');
  });

  test('updates user', async () => {
    const user = await userService.update(createdUserId, {
      name: 'Updated Name',
    });

    expect(user.name).toBe('Updated Name');
  });

  test('deletes user', async () => {
    await userService.delete(createdUserId);

    await expect(userService.get(createdUserId)).rejects.toThrow(NotFoundError);
  });
});
```

---

## Test Configuration

### Jest Configuration

```javascript
// jest.config.js
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  setupFilesAfterEnv: ['./tests/setup.ts'],
  testMatch: [
    '**/*.test.ts',
    '!**/*.e2e.test.ts', // Exclude E2E by default
  ],
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/**/index.ts',
  ],
};

// jest.e2e.config.js
module.exports = {
  ...require('./jest.config'),
  testMatch: ['**/*.e2e.test.ts'],
};
```

### Test Scripts

```json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "test:e2e": "jest --config jest.e2e.config.js"
  }
}
```
