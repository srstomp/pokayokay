# API Integration Testing: Mocking & Fixtures

Testing strategy overview, HTTP mocking approaches, and test fixture patterns.

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
