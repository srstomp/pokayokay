# Error Handling and Async Patterns

Error class hierarchies, retry logic, request queues, and token management.

## Error Class Hierarchy

```typescript
// src/errors.ts

/**
 * Base error for all SDK errors
 */
export class SDKError extends Error {
  constructor(
    message: string,
    public code: string,
    public cause?: Error,
  ) {
    super(message);
    this.name = 'SDKError';

    // Maintains proper stack trace
    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, this.constructor);
    }
  }

  toJSON() {
    return {
      name: this.name,
      message: this.message,
      code: this.code,
    };
  }
}

/**
 * API returned an error response
 */
export class APIError extends SDKError {
  constructor(
    message: string,
    code: string,
    public statusCode: number,
    public response?: unknown,
  ) {
    super(message, code);
    this.name = 'APIError';
  }

  static async fromResponse(response: Response): Promise<APIError> {
    let body: unknown;
    let message = `Request failed with status ${response.status}`;
    let code = 'API_ERROR';

    try {
      body = await response.json();
      if (typeof body === 'object' && body !== null) {
        const error = (body as any).error ?? body;
        message = error.message ?? message;
        code = error.code ?? code;
      }
    } catch {
      // Body not JSON, use default message
    }

    return new APIError(message, code, response.status, body);
  }

  get isRetryable(): boolean {
    return [408, 429, 500, 502, 503, 504].includes(this.statusCode);
  }
}

/**
 * Network/connection error
 */
export class NetworkError extends SDKError {
  constructor(message: string, options?: { cause?: Error }) {
    super(message, 'NETWORK_ERROR', options?.cause);
    this.name = 'NetworkError';
  }
}

/**
 * Request timed out
 */
export class TimeoutError extends SDKError {
  constructor(public timeoutMs: number) {
    super(`Request timed out after ${timeoutMs}ms`, 'TIMEOUT');
    this.name = 'TimeoutError';
  }
}

/**
 * Input validation failed
 */
export class ValidationError extends SDKError {
  constructor(
    message: string,
    public fields: Array<{ field: string; message: string }>,
  ) {
    super(message, 'VALIDATION_ERROR');
    this.name = 'ValidationError';
  }
}

/**
 * Authentication failed (401)
 */
export class AuthenticationError extends APIError {
  constructor(message: string = 'Authentication required') {
    super(message, 'UNAUTHENTICATED', 401);
    this.name = 'AuthenticationError';
  }
}

/**
 * Authorization failed (403)
 */
export class AuthorizationError extends APIError {
  constructor(message: string = 'Permission denied') {
    super(message, 'FORBIDDEN', 403);
    this.name = 'AuthorizationError';
  }
}

/**
 * Resource not found (404)
 */
export class NotFoundError extends APIError {
  constructor(resource: string, id?: string) {
    const message = id
      ? `${resource} with id '${id}' not found`
      : `${resource} not found`;
    super(message, 'NOT_FOUND', 404);
    this.name = 'NotFoundError';
  }
}

/**
 * Rate limit exceeded (429)
 */
export class RateLimitError extends APIError {
  constructor(
    public retryAfter?: number,
    message: string = 'Rate limit exceeded',
  ) {
    super(message, 'RATE_LIMITED', 429);
    this.name = 'RateLimitError';
  }
}

/**
 * Configuration error
 */
export class ConfigurationError extends SDKError {
  constructor(message: string) {
    super(message, 'CONFIGURATION_ERROR');
    this.name = 'ConfigurationError';
  }
}
```

## Error Handling in Client

```typescript
class MyClient {
  async getUser(id: string): Promise<User> {
    try {
      return await this.http.get<User>(`/users/${id}`);
    } catch (error) {
      // Transform to specific error types
      if (error instanceof APIError) {
        if (error.statusCode === 404) {
          throw new NotFoundError('User', id);
        }
        if (error.statusCode === 401) {
          throw new AuthenticationError();
        }
      }
      throw error;
    }
  }
}
```

## Error Type Checking

```typescript
// User code
try {
  const user = await client.getUser('123');
} catch (error) {
  if (error instanceof NotFoundError) {
    console.log('User not found');
  } else if (error instanceof AuthenticationError) {
    console.log('Need to login');
  } else if (error instanceof RateLimitError) {
    console.log(`Rate limited, retry after ${error.retryAfter}s`);
  } else if (error instanceof SDKError) {
    console.log(`SDK error: ${error.code} - ${error.message}`);
  } else {
    console.log('Unknown error:', error);
  }
}
```

---

## Async Patterns

### Async Method Patterns

```typescript
// Standard async method
async getUser(id: string): Promise<User> {
  const response = await this.http.get<User>(`/users/${id}`);
  return response;
}

// With loading/result pattern (for React)
interface AsyncResult<T> {
  data?: T;
  error?: SDKError;
  isLoading: boolean;
}

// With cancellation
async getUser(id: string, signal?: AbortSignal): Promise<User> {
  return this.http.get<User>(`/users/${id}`, { signal });
}
```

### Retry Logic

```typescript
// internal/retry.ts
interface RetryOptions {
  attempts: number;
  delay: number;
  backoff: number;
  maxDelay: number;
  shouldRetry?: (error: Error) => boolean;
}

async function withRetry<T>(
  fn: () => Promise<T>,
  options: RetryOptions
): Promise<T> {
  let lastError: Error | undefined;

  for (let attempt = 0; attempt < options.attempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error as Error;

      const shouldRetry = options.shouldRetry?.(lastError) ?? true;

      if (!shouldRetry || attempt >= options.attempts - 1) {
        throw lastError;
      }

      const delay = Math.min(
        options.delay * Math.pow(options.backoff, attempt),
        options.maxDelay
      );

      await sleep(delay);
    }
  }

  throw lastError;
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
```

### Request Queue

```typescript
// internal/queue.ts
class RequestQueue {
  private queue: Array<() => Promise<void>> = [];
  private running = 0;
  private maxConcurrent: number;

  constructor(maxConcurrent = 5) {
    this.maxConcurrent = maxConcurrent;
  }

  async add<T>(fn: () => Promise<T>): Promise<T> {
    return new Promise((resolve, reject) => {
      const run = async () => {
        this.running++;
        try {
          const result = await fn();
          resolve(result);
        } catch (error) {
          reject(error);
        } finally {
          this.running--;
          this.processNext();
        }
      };

      if (this.running < this.maxConcurrent) {
        run();
      } else {
        this.queue.push(run);
      }
    });
  }

  private processNext(): void {
    if (this.queue.length > 0 && this.running < this.maxConcurrent) {
      const next = this.queue.shift()!;
      next();
    }
  }
}
```

### Token Refresh Queue

```typescript
// Deduplicate concurrent refresh requests
class TokenManager {
  private refreshPromise: Promise<string> | null = null;

  async getValidToken(): Promise<string> {
    const token = this.getStoredToken();

    if (token && !this.isExpired(token)) {
      return token;
    }

    // Deduplicate refresh requests
    if (!this.refreshPromise) {
      this.refreshPromise = this.refreshToken();

      this.refreshPromise.finally(() => {
        this.refreshPromise = null;
      });
    }

    return this.refreshPromise;
  }

  private async refreshToken(): Promise<string> {
    const refreshToken = this.getRefreshToken();

    if (!refreshToken) {
      throw new AuthenticationError('No refresh token');
    }

    const response = await fetch('/auth/refresh', {
      method: 'POST',
      body: JSON.stringify({ refreshToken }),
    });

    if (!response.ok) {
      throw new AuthenticationError('Token refresh failed');
    }

    const { accessToken } = await response.json();
    this.storeToken(accessToken);

    return accessToken;
  }
}
```
