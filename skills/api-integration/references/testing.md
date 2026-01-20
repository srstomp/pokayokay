# API Integration Testing

Mocking, integration tests, and contract testing for API clients.

## Testing Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                     TESTING PYRAMID                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                      ▲ E2E Tests                            │
│                     ▲▲▲ (Real API, CI only)                 │
│                    ▲▲▲▲▲                                    │
│                   ▲▲▲▲▲▲▲ Integration Tests                 │
│                  ▲▲▲▲▲▲▲▲▲ (Mocked API)                     │
│                 ▲▲▲▲▲▲▲▲▲▲▲                                 │
│                ▲▲▲▲▲▲▲▲▲▲▲▲▲ Unit Tests                     │
│               ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲ (Transformers, helpers)       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

| Layer | What to Test | Mocking |
|-------|--------------|---------|
| Unit | Transformers, validators, helpers | None needed |
| Integration | Service methods, error handling | Mock HTTP |
| E2E | Full flow with real API | None (real API) |
| Contract | API shape matches spec | Schema validation |

---

## Mocking HTTP Requests

### MSW (Mock Service Worker)

Best for: Browser and Node.js, request interception.

**Setup:**

```typescript
// mocks/handlers.ts
import { http, HttpResponse } from 'msw';

export const handlers = [
  // GET /users
  http.get('https://api.example.com/users', () => {
    return HttpResponse.json([
      { id: '1', email: 'user1@example.com', name: 'User 1' },
      { id: '2', email: 'user2@example.com', name: 'User 2' },
    ]);
  }),

  // GET /users/:id
  http.get('https://api.example.com/users/:id', ({ params }) => {
    const { id } = params;

    if (id === 'not-found') {
      return HttpResponse.json(
        { error: 'User not found' },
        { status: 404 }
      );
    }

    return HttpResponse.json({
      id,
      email: `user${id}@example.com`,
      name: `User ${id}`,
    });
  }),

  // POST /users
  http.post('https://api.example.com/users', async ({ request }) => {
    const body = await request.json();

    return HttpResponse.json(
      { id: 'new-id', ...body },
      { status: 201 }
    );
  }),
];

// mocks/server.ts (Node.js)
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);

// mocks/browser.ts (Browser)
import { setupWorker } from 'msw/browser';
import { handlers } from './handlers';

export const worker = setupWorker(...handlers);
```

**Test setup:**

```typescript
// setup-tests.ts
import { server } from './mocks/server';

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

**Override handlers in tests:**

```typescript
import { server } from './mocks/server';
import { http, HttpResponse } from 'msw';

test('handles server error', async () => {
  server.use(
    http.get('https://api.example.com/users/:id', () => {
      return HttpResponse.json(
        { error: 'Internal server error' },
        { status: 500 }
      );
    })
  );

  await expect(userService.get('1')).rejects.toThrow(ServerError);
});
```

### Nock (Node.js only)

```typescript
import nock from 'nock';

describe('UserService', () => {
  afterEach(() => {
    nock.cleanAll();
  });

  test('fetches user', async () => {
    nock('https://api.example.com')
      .get('/users/1')
      .reply(200, {
        id: '1',
        email: 'user@example.com',
        name: 'Test User',
      });

    const user = await userService.get('1');

    expect(user.id).toBe('1');
    expect(user.email).toBe('user@example.com');
  });

  test('handles 404', async () => {
    nock('https://api.example.com')
      .get('/users/not-found')
      .reply(404, { error: 'Not found' });

    await expect(userService.get('not-found')).rejects.toThrow(NotFoundError);
  });
});
```

### Manual Mocking

```typescript
// __mocks__/api-client.ts
export class MockApiClient {
  private responses = new Map<string, unknown>();

  mockResponse(method: string, path: string, response: unknown): void {
    this.responses.set(`${method}:${path}`, response);
  }

  mockError(method: string, path: string, error: Error): void {
    this.responses.set(`${method}:${path}`, { __error: error });
  }

  async get<T>(path: string): Promise<T> {
    return this.getResponse('GET', path);
  }

  async post<T>(path: string, _body?: unknown): Promise<T> {
    return this.getResponse('POST', path);
  }

  private getResponse<T>(method: string, path: string): T {
    const response = this.responses.get(`${method}:${path}`);

    if (response && typeof response === 'object' && '__error' in response) {
      throw (response as { __error: Error }).__error;
    }

    if (response === undefined) {
      throw new Error(`No mock for ${method} ${path}`);
    }

    return response as T;
  }
}

// Usage in tests
const mockClient = new MockApiClient();
const userService = new UserService(mockClient as any);

mockClient.mockResponse('GET', '/users/1', {
  id: '1',
  email: 'user@example.com',
});

const user = await userService.get('1');
```

---

## Test Fixtures

### Fixture Factory

```typescript
// fixtures/user.ts

interface User {
  id: string;
  email: string;
  name: string | null;
  createdAt: Date;
  updatedAt: Date;
}

const defaultUser: User = {
  id: 'default-id',
  email: 'default@example.com',
  name: 'Default User',
  createdAt: new Date('2024-01-01'),
  updatedAt: new Date('2024-01-01'),
};

export function createUser(overrides: Partial<User> = {}): User {
  return {
    ...defaultUser,
    ...overrides,
    id: overrides.id ?? `user-${Math.random().toString(36).slice(2)}`,
  };
}

export function createUsers(count: number): User[] {
  return Array.from({ length: count }, (_, i) =>
    createUser({
      id: `user-${i + 1}`,
      email: `user${i + 1}@example.com`,
      name: `User ${i + 1}`,
    })
  );
}

// API response fixture (raw API shape)
interface ApiUser {
  id: string;
  email: string;
  name: string | null;
  created_at: string;
  updated_at: string;
}

export function createApiUser(overrides: Partial<ApiUser> = {}): ApiUser {
  return {
    id: 'default-id',
    email: 'default@example.com',
    name: 'Default User',
    created_at: '2024-01-01T00:00:00Z',
    updated_at: '2024-01-01T00:00:00Z',
    ...overrides,
  };
}
```

### Fixture Files

```typescript
// fixtures/users.json
{
  "valid": {
    "id": "1",
    "email": "valid@example.com",
    "name": "Valid User",
    "created_at": "2024-01-01T00:00:00Z"
  },
  "withNullName": {
    "id": "2",
    "email": "nullname@example.com",
    "name": null,
    "created_at": "2024-01-01T00:00:00Z"
  },
  "list": [
    { "id": "1", "email": "user1@example.com", "name": "User 1" },
    { "id": "2", "email": "user2@example.com", "name": "User 2" }
  ]
}

// Usage
import fixtures from '../fixtures/users.json';

test('parses user with null name', () => {
  const user = toUser(fixtures.withNullName);
  expect(user.name).toBeNull();
});
```

---

## Unit Tests

### Testing Transformers

```typescript
// transformers.test.ts
import { toUser, toUserList } from './transformers';
import { createApiUser } from '../fixtures/user';

describe('toUser', () => {
  test('transforms API user to domain user', () => {
    const apiUser = createApiUser({
      id: '123',
      email: 'test@example.com',
      name: 'Test User',
      created_at: '2024-01-15T10:30:00Z',
    });

    const user = toUser(apiUser);

    expect(user.id).toBe('123');
    expect(user.email).toBe('test@example.com');
    expect(user.name).toBe('Test User');
    expect(user.createdAt).toEqual(new Date('2024-01-15T10:30:00Z'));
  });

  test('handles null name', () => {
    const apiUser = createApiUser({ name: null });

    const user = toUser(apiUser);

    expect(user.name).toBeNull();
  });
});

describe('toUserList', () => {
  test('transforms array of API users', () => {
    const apiUsers = [
      createApiUser({ id: '1' }),
      createApiUser({ id: '2' }),
    ];

    const users = toUserList(apiUsers);

    expect(users).toHaveLength(2);
    expect(users[0].id).toBe('1');
    expect(users[1].id).toBe('2');
  });

  test('returns empty array for empty input', () => {
    expect(toUserList([])).toEqual([]);
  });
});
```

### Testing Validators

```typescript
// validators.test.ts
import { validateCreateUserInput } from './validators';

describe('validateCreateUserInput', () => {
  test('accepts valid input', () => {
    const input = {
      email: 'valid@example.com',
      name: 'Valid Name',
    };

    expect(() => validateCreateUserInput(input)).not.toThrow();
  });

  test('rejects invalid email', () => {
    const input = {
      email: 'invalid-email',
      name: 'Valid Name',
    };

    expect(() => validateCreateUserInput(input)).toThrow('Invalid email');
  });

  test('rejects empty name', () => {
    const input = {
      email: 'valid@example.com',
      name: '',
    };

    expect(() => validateCreateUserInput(input)).toThrow('Name is required');
  });
});
```

---

## Integration Tests

### Service Method Tests

```typescript
// user-service.test.ts
import { http, HttpResponse } from 'msw';
import { setupServer } from 'msw/node';
import { UserService } from './user-service';
import { ApiClient } from './api-client';
import { createApiUser } from '../fixtures/user';

const server = setupServer();

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

describe('UserService', () => {
  let client: ApiClient;
  let userService: UserService;

  beforeEach(() => {
    client = new ApiClient({ baseUrl: 'https://api.example.com' });
    userService = new UserService(client);
  });

  describe('get', () => {
    test('fetches and transforms user', async () => {
      server.use(
        http.get('https://api.example.com/users/123', () => {
          return HttpResponse.json(createApiUser({
            id: '123',
            email: 'test@example.com',
          }));
        })
      );

      const user = await userService.get('123');

      expect(user.id).toBe('123');
      expect(user.email).toBe('test@example.com');
      expect(user.createdAt).toBeInstanceOf(Date);
    });

    test('throws NotFoundError for 404', async () => {
      server.use(
        http.get('https://api.example.com/users/not-found', () => {
          return HttpResponse.json(
            { error: 'User not found' },
            { status: 404 }
          );
        })
      );

      await expect(userService.get('not-found')).rejects.toThrow(NotFoundError);
    });

    test('throws ServerError for 500', async () => {
      server.use(
        http.get('https://api.example.com/users/123', () => {
          return HttpResponse.json(
            { error: 'Internal error' },
            { status: 500 }
          );
        })
      );

      await expect(userService.get('123')).rejects.toThrow(ServerError);
    });
  });

  describe('create', () => {
    test('creates user with valid input', async () => {
      server.use(
        http.post('https://api.example.com/users', async ({ request }) => {
          const body = await request.json() as any;
          return HttpResponse.json(
            createApiUser({ id: 'new-id', ...body }),
            { status: 201 }
          );
        })
      );

      const user = await userService.create({
        email: 'new@example.com',
        name: 'New User',
      });

      expect(user.id).toBe('new-id');
      expect(user.email).toBe('new@example.com');
    });

    test('throws ValidationError for 422', async () => {
      server.use(
        http.post('https://api.example.com/users', () => {
          return HttpResponse.json(
            {
              error: 'Validation failed',
              details: { email: ['Email is already taken'] },
            },
            { status: 422 }
          );
        })
      );

      await expect(
        userService.create({ email: 'taken@example.com', name: 'User' })
      ).rejects.toThrow(ValidationError);
    });
  });
});
```

### Error Handling Tests

```typescript
// error-handling.test.ts
import { withRetry } from './retry';
import { ApiError, ServerError, RateLimitError } from './errors';

describe('withRetry', () => {
  test('returns immediately on success', async () => {
    const fn = jest.fn().mockResolvedValue('success');

    const result = await withRetry(fn, { attempts: 3 });

    expect(result).toBe('success');
    expect(fn).toHaveBeenCalledTimes(1);
  });

  test('retries on server error', async () => {
    const fn = jest
      .fn()
      .mockRejectedValueOnce(new ServerError(500, 'Error'))
      .mockRejectedValueOnce(new ServerError(500, 'Error'))
      .mockResolvedValue('success');

    const result = await withRetry(fn, { attempts: 3, initialDelayMs: 10 });

    expect(result).toBe('success');
    expect(fn).toHaveBeenCalledTimes(3);
  });

  test('throws after max attempts', async () => {
    const error = new ServerError(500, 'Error');
    const fn = jest.fn().mockRejectedValue(error);

    await expect(
      withRetry(fn, { attempts: 3, initialDelayMs: 10 })
    ).rejects.toThrow(error);

    expect(fn).toHaveBeenCalledTimes(3);
  });

  test('does not retry client errors', async () => {
    const error = new ApiError(400, 'BAD_REQUEST', 'Invalid input');
    const fn = jest.fn().mockRejectedValue(error);

    await expect(
      withRetry(fn, { attempts: 3 })
    ).rejects.toThrow(error);

    expect(fn).toHaveBeenCalledTimes(1);
  });

  test('respects rate limit retry-after', async () => {
    const fn = jest
      .fn()
      .mockRejectedValueOnce(new RateLimitError(1)) // 1 second
      .mockResolvedValue('success');

    const start = Date.now();
    await withRetry(fn, { attempts: 3 });
    const duration = Date.now() - start;

    expect(duration).toBeGreaterThanOrEqual(900);
  });
});
```

### Auth Flow Tests

```typescript
// auth.test.ts
import { TokenManager } from './token-manager';

describe('TokenManager', () => {
  let tokenManager: TokenManager;
  let mockRefresh: jest.Mock;

  beforeEach(() => {
    mockRefresh = jest.fn();
    tokenManager = new TokenManager('https://api.example.com/oauth/token');
  });

  test('returns access token when valid', async () => {
    tokenManager.setTokens({
      accessToken: 'valid-token',
      refreshToken: 'refresh-token',
      expiresAt: Date.now() + 3600000, // 1 hour from now
    });

    const token = await tokenManager.getAccessToken();

    expect(token).toBe('valid-token');
  });

  test('refreshes token when expired', async () => {
    server.use(
      http.post('https://api.example.com/oauth/token', () => {
        return HttpResponse.json({
          access_token: 'new-token',
          refresh_token: 'new-refresh-token',
          expires_in: 3600,
        });
      })
    );

    tokenManager.setTokens({
      accessToken: 'expired-token',
      refreshToken: 'refresh-token',
      expiresAt: Date.now() - 1000, // Expired
    });

    const token = await tokenManager.getAccessToken();

    expect(token).toBe('new-token');
  });

  test('throws when no tokens available', async () => {
    await expect(tokenManager.getAccessToken()).rejects.toThrow(
      'No tokens available'
    );
  });
});
```

---

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
