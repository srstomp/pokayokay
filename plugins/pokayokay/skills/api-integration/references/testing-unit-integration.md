# API Integration Testing: Unit & Integration Tests

Unit tests for transformers/validators and integration tests for service methods.

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
