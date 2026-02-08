# Mocking Fundamentals

When to mock, mock types, and MSW (Mock Service Worker) patterns.

## The Mocking Decision Tree

```
Should I mock this dependency?

1. Is it an external service (API, database, payment processor)?
   - YES -> Mock at the network boundary (MSW, nock)
   - NO ->

2. Is it slow (file system, crypto, heavy computation)?
   - YES -> Consider mocking for unit tests
   - NO ->

3. Is it non-deterministic (time, random, UUIDs)?
   - YES -> Mock for reproducible tests
   - NO ->

4. Is it causing test pollution (global state, singletons)?
   - YES -> Mock or isolate
   - NO ->

5. Is it a simple internal module?
   - NO -> Don't mock, use the real thing
```

## What to Mock

| Mock | Don't Mock |
|------|------------|
| External APIs | Your own business logic |
| Databases in unit tests | Simple utilities |
| Time and dates | Pure functions |
| Random generators | Data transformations |
| File system | In-memory operations |
| Payment processors | Internal services (in integration) |
| Email services | |
| Third-party SDKs | |

## Mock Types and Usage

### Stubs: Return Canned Data

```typescript
// Stub: Provides predetermined responses
const userServiceStub = {
  getUser: vi.fn().mockReturnValue({ id: '1', name: 'Test User' }),
  getUsers: vi.fn().mockReturnValue([]),
};

// Async stub
const asyncStub = vi.fn().mockResolvedValue({ data: 'result' });

// Stub that returns different values
const multiStub = vi.fn()
  .mockReturnValueOnce('first call')
  .mockReturnValueOnce('second call')
  .mockReturnValue('subsequent calls');
```

### Mocks: Verify Interactions

```typescript
// Mock: Track and verify calls
const sendEmail = vi.fn();

await processOrder(order);

// Verify call happened
expect(sendEmail).toHaveBeenCalled();
expect(sendEmail).toHaveBeenCalledTimes(1);
expect(sendEmail).toHaveBeenCalledWith({
  to: order.email,
  subject: 'Order Confirmation',
  body: expect.stringContaining(order.id),
});

// Verify call order
const logger = {
  info: vi.fn(),
  error: vi.fn(),
};

await processWithLogging(data);

expect(logger.info).toHaveBeenCalledBefore(logger.error);
```

### Spies: Observe Real Behavior

```typescript
// Spy: Watch real implementation
const consoleSpy = vi.spyOn(console, 'error');

await riskyOperation();

expect(consoleSpy).not.toHaveBeenCalled();
consoleSpy.mockRestore();

// Spy with modification
const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(
  new Response(JSON.stringify({ data: 'mocked' }))
);

await loadData();

expect(fetchSpy).toHaveBeenCalledWith('/api/data');
fetchSpy.mockRestore();
```

### Fakes: Working Implementations

```typescript
// Fake: Simplified but functional implementation
class FakeUserRepository {
  private users = new Map<string, User>();

  async create(user: User): Promise<User> {
    this.users.set(user.id, user);
    return user;
  }

  async findById(id: string): Promise<User | null> {
    return this.users.get(id) || null;
  }

  async delete(id: string): Promise<void> {
    this.users.delete(id);
  }

  // Test helper
  clear() {
    this.users.clear();
  }
}

// Usage
describe('UserService', () => {
  const fakeRepo = new FakeUserRepository();
  const service = new UserService(fakeRepo);

  beforeEach(() => {
    fakeRepo.clear();
  });

  it('creates and retrieves user', async () => {
    const user = await service.createUser({ name: 'Test' });
    const retrieved = await service.getUser(user.id);
    expect(retrieved).toEqual(user);
  });
});
```

---

## MSW (Mock Service Worker)

### Setup

```typescript
// mocks/handlers.ts
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.get('/api/users', () => {
    return HttpResponse.json([
      { id: '1', name: 'John' },
      { id: '2', name: 'Jane' },
    ]);
  }),

  http.get('/api/users/:id', ({ params }) => {
    return HttpResponse.json({ id: params.id, name: 'John' });
  }),

  http.post('/api/users', async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json({ id: '3', ...body }, { status: 201 });
  }),

  http.delete('/api/users/:id', () => {
    return new HttpResponse(null, { status: 204 });
  }),
];

// mocks/server.ts
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);
```

### Test Setup

```typescript
// vitest.setup.ts
import { beforeAll, afterAll, afterEach } from 'vitest';
import { server } from './mocks/server';

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

### Per-Test Overrides

```typescript
import { http, HttpResponse } from 'msw';
import { server } from './mocks/server';

describe('Users', () => {
  it('handles empty user list', async () => {
    server.use(
      http.get('/api/users', () => {
        return HttpResponse.json([]);
      })
    );

    render(<UserList />);
    expect(screen.getByText('No users found')).toBeInTheDocument();
  });

  it('handles API error', async () => {
    server.use(
      http.get('/api/users', () => {
        return HttpResponse.json(
          { error: 'Internal server error' },
          { status: 500 }
        );
      })
    );

    render(<UserList />);
    await waitFor(() => {
      expect(screen.getByRole('alert')).toHaveTextContent('Error loading users');
    });
  });

  it('handles network failure', async () => {
    server.use(
      http.get('/api/users', () => {
        return HttpResponse.error();
      })
    );

    render(<UserList />);
    await waitFor(() => {
      expect(screen.getByText('Network error')).toBeInTheDocument();
    });
  });
});
```

### Request Assertions

```typescript
import { http, HttpResponse } from 'msw';

it('sends correct data on submit', async () => {
  let capturedBody: any;

  server.use(
    http.post('/api/users', async ({ request }) => {
      capturedBody = await request.json();
      return HttpResponse.json({ id: '1', ...capturedBody }, { status: 201 });
    })
  );

  render(<UserForm />);

  await userEvent.type(screen.getByLabelText('Name'), 'John Doe');
  await userEvent.type(screen.getByLabelText('Email'), 'john@example.com');
  await userEvent.click(screen.getByRole('button', { name: 'Submit' }));

  await waitFor(() => {
    expect(capturedBody).toEqual({
      name: 'John Doe',
      email: 'john@example.com',
    });
  });
});
```

### Delayed Responses

```typescript
import { http, HttpResponse, delay } from 'msw';

it('shows loading state', async () => {
  server.use(
    http.get('/api/users', async () => {
      await delay(100);
      return HttpResponse.json([{ id: '1', name: 'John' }]);
    })
  );

  render(<UserList />);

  // Loading state visible
  expect(screen.getByText('Loading...')).toBeInTheDocument();

  // After delay, data visible
  await waitFor(() => {
    expect(screen.queryByText('Loading...')).not.toBeInTheDocument();
    expect(screen.getByText('John')).toBeInTheDocument();
  });
});
```

### Response Sequences

```typescript
import { http, HttpResponse } from 'msw';

it('retries on failure', async () => {
  let callCount = 0;

  server.use(
    http.get('/api/users', () => {
      callCount++;
      if (callCount === 1) {
        return HttpResponse.json({ error: 'Server busy' }, { status: 503 });
      }
      return HttpResponse.json([{ id: '1', name: 'John' }]);
    })
  );

  render(<UserListWithRetry />);

  await waitFor(() => {
    expect(screen.getByText('John')).toBeInTheDocument();
  });

  expect(callCount).toBe(2);
});
```
