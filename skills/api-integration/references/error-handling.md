# Error Handling

Robust error classification, retry logic, and recovery patterns.

## Error Classification

### Error Type Hierarchy

```typescript
// Base error class
class ApiError extends Error {
  constructor(
    public readonly status: number,
    public readonly code: string,
    message: string,
    public readonly details?: unknown,
    public readonly requestId?: string
  ) {
    super(message);
    this.name = 'ApiError';
  }

  static async fromResponse(response: Response): Promise<ApiError> {
    let body: any;
    try {
      body = await response.json();
    } catch {
      body = { message: response.statusText };
    }

    const requestId = response.headers.get('x-request-id') ?? undefined;

    return new ApiError(
      response.status,
      body.code ?? `HTTP_${response.status}`,
      body.message ?? response.statusText,
      body.details,
      requestId
    );
  }
}

// Specific error types
class NetworkError extends Error {
  readonly name = 'NetworkError';
  readonly isRetryable = true;
}

class TimeoutError extends Error {
  readonly name = 'TimeoutError';
  readonly isRetryable = true;
}

class ValidationError extends ApiError {
  readonly name = 'ValidationError';
  readonly isRetryable = false;

  constructor(
    message: string,
    public readonly fieldErrors: Record<string, string[]>
  ) {
    super(400, 'VALIDATION_ERROR', message, fieldErrors);
  }
}

class AuthenticationError extends ApiError {
  readonly name = 'AuthenticationError';
  readonly isRetryable = false;

  constructor(message: string = 'Authentication required') {
    super(401, 'AUTHENTICATION_ERROR', message);
  }
}

class AuthorizationError extends ApiError {
  readonly name = 'AuthorizationError';
  readonly isRetryable = false;

  constructor(message: string = 'Permission denied') {
    super(403, 'AUTHORIZATION_ERROR', message);
  }
}

class NotFoundError extends ApiError {
  readonly name = 'NotFoundError';
  readonly isRetryable = false;

  constructor(resource: string, id?: string) {
    super(
      404,
      'NOT_FOUND',
      id ? `${resource} with id '${id}' not found` : `${resource} not found`
    );
  }
}

class RateLimitError extends ApiError {
  readonly name = 'RateLimitError';
  readonly isRetryable = true;

  constructor(
    public readonly retryAfter?: number
  ) {
    super(429, 'RATE_LIMITED', 'Rate limit exceeded');
  }
}

class ServerError extends ApiError {
  readonly name = 'ServerError';
  readonly isRetryable = true;

  constructor(status: number, message: string, requestId?: string) {
    super(status, 'SERVER_ERROR', message, undefined, requestId);
  }
}
```

### Error Classification Helper

```typescript
function classifyError(error: unknown): {
  isRetryable: boolean;
  isAuthError: boolean;
  isClientError: boolean;
  isServerError: boolean;
  isNetworkError: boolean;
} {
  if (error instanceof NetworkError || error instanceof TimeoutError) {
    return {
      isRetryable: true,
      isAuthError: false,
      isClientError: false,
      isServerError: false,
      isNetworkError: true,
    };
  }

  if (error instanceof ApiError) {
    const status = error.status;
    return {
      isRetryable: status >= 500 || status === 429,
      isAuthError: status === 401 || status === 403,
      isClientError: status >= 400 && status < 500,
      isServerError: status >= 500,
      isNetworkError: false,
    };
  }

  // Unknown error
  return {
    isRetryable: false,
    isAuthError: false,
    isClientError: false,
    isServerError: false,
    isNetworkError: false,
  };
}
```

### Converting Response to Typed Error

```typescript
async function handleErrorResponse(response: Response): Promise<never> {
  const requestId = response.headers.get('x-request-id') ?? undefined;

  let body: any;
  try {
    body = await response.json();
  } catch {
    body = {};
  }

  switch (response.status) {
    case 400:
    case 422:
      throw new ValidationError(
        body.message ?? 'Validation failed',
        body.errors ?? {}
      );

    case 401:
      throw new AuthenticationError(body.message);

    case 403:
      throw new AuthorizationError(body.message);

    case 404:
      throw new NotFoundError(body.resource ?? 'Resource', body.id);

    case 429:
      const retryAfter = response.headers.get('retry-after');
      throw new RateLimitError(
        retryAfter ? parseInt(retryAfter, 10) : undefined
      );

    default:
      if (response.status >= 500) {
        throw new ServerError(
          response.status,
          body.message ?? 'Internal server error',
          requestId
        );
      }
      throw new ApiError(
        response.status,
        body.code ?? 'UNKNOWN_ERROR',
        body.message ?? 'An error occurred',
        body.details,
        requestId
      );
  }
}
```

---

## Retry Logic

### Basic Retry with Exponential Backoff

```typescript
interface RetryOptions {
  attempts: number;
  initialDelayMs: number;
  maxDelayMs: number;
  backoffMultiplier: number;
  shouldRetry?: (error: unknown, attempt: number) => boolean;
  onRetry?: (error: unknown, attempt: number, delayMs: number) => void;
}

const defaultRetryOptions: RetryOptions = {
  attempts: 3,
  initialDelayMs: 1000,
  maxDelayMs: 30000,
  backoffMultiplier: 2,
  shouldRetry: (error) => {
    if (error instanceof ApiError) {
      return error.status >= 500 || error.status === 429;
    }
    if (error instanceof NetworkError || error instanceof TimeoutError) {
      return true;
    }
    return false;
  },
};

async function withRetry<T>(
  fn: () => Promise<T>,
  options: Partial<RetryOptions> = {}
): Promise<T> {
  const opts = { ...defaultRetryOptions, ...options };
  let lastError: unknown;

  for (let attempt = 1; attempt <= opts.attempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;

      if (attempt === opts.attempts) {
        break;
      }

      if (!opts.shouldRetry?.(error, attempt)) {
        throw error;
      }

      // Calculate delay with jitter
      const baseDelay = opts.initialDelayMs * Math.pow(opts.backoffMultiplier, attempt - 1);
      const jitter = Math.random() * 0.3 * baseDelay; // ±15% jitter
      const delay = Math.min(baseDelay + jitter, opts.maxDelayMs);

      opts.onRetry?.(error, attempt, delay);

      await sleep(delay);
    }
  }

  throw lastError;
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
```

### Retry with Rate Limit Awareness

```typescript
async function withRetryRateLimit<T>(
  fn: () => Promise<T>,
  options: Partial<RetryOptions> = {}
): Promise<T> {
  return withRetry(fn, {
    ...options,
    shouldRetry: (error, attempt) => {
      // Always respect rate limit retry-after
      if (error instanceof RateLimitError) {
        return true;
      }
      // Fall back to default
      return options.shouldRetry?.(error, attempt) ??
        defaultRetryOptions.shouldRetry?.(error, attempt) ??
        false;
    },
    onRetry: async (error, attempt, delayMs) => {
      if (error instanceof RateLimitError && error.retryAfter) {
        // Use server-provided retry-after
        await sleep(error.retryAfter * 1000);
      } else {
        await sleep(delayMs);
      }
      options.onRetry?.(error, attempt, delayMs);
    },
  });
}
```

### Idempotency-Aware Retry

```typescript
type HttpMethod = 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';

// Safe to retry (idempotent)
const IDEMPOTENT_METHODS: HttpMethod[] = ['GET', 'PUT', 'DELETE'];

interface RequestConfig {
  method: HttpMethod;
  idempotencyKey?: string;
}

function shouldRetryRequest(config: RequestConfig, error: unknown): boolean {
  // Always retry if idempotency key provided
  if (config.idempotencyKey) {
    return classifyError(error).isRetryable;
  }

  // Only retry idempotent methods
  if (!IDEMPOTENT_METHODS.includes(config.method)) {
    return false;
  }

  return classifyError(error).isRetryable;
}

// Usage with idempotency key
async function createOrder(input: CreateOrderInput): Promise<Order> {
  const idempotencyKey = generateIdempotencyKey();

  return withRetry(
    () => client.post<Order>('/orders', input, {
      headers: { 'Idempotency-Key': idempotencyKey },
    }),
    {
      shouldRetry: (error) => shouldRetryRequest(
        { method: 'POST', idempotencyKey },
        error
      ),
    }
  );
}
```

---

## Circuit Breaker

Prevent cascading failures when API is down.

```typescript
enum CircuitState {
  Closed = 'CLOSED',     // Normal operation
  Open = 'OPEN',         // Failing, reject requests
  HalfOpen = 'HALF_OPEN' // Testing if recovered
}

interface CircuitBreakerOptions {
  failureThreshold: number;    // Failures before opening
  resetTimeoutMs: number;      // Time before trying again
  successThreshold: number;    // Successes to close from half-open
}

class CircuitBreaker {
  private state = CircuitState.Closed;
  private failureCount = 0;
  private successCount = 0;
  private lastFailureTime = 0;

  constructor(private options: CircuitBreakerOptions) {}

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === CircuitState.Open) {
      if (Date.now() - this.lastFailureTime >= this.options.resetTimeoutMs) {
        this.state = CircuitState.HalfOpen;
        this.successCount = 0;
      } else {
        throw new CircuitOpenError('Circuit breaker is open');
      }
    }

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  private onSuccess(): void {
    this.failureCount = 0;

    if (this.state === CircuitState.HalfOpen) {
      this.successCount++;
      if (this.successCount >= this.options.successThreshold) {
        this.state = CircuitState.Closed;
      }
    }
  }

  private onFailure(): void {
    this.failureCount++;
    this.lastFailureTime = Date.now();

    if (this.state === CircuitState.HalfOpen) {
      this.state = CircuitState.Open;
    } else if (this.failureCount >= this.options.failureThreshold) {
      this.state = CircuitState.Open;
    }
  }

  get currentState(): CircuitState {
    return this.state;
  }
}

class CircuitOpenError extends Error {
  readonly name = 'CircuitOpenError';
}

// Usage
const circuitBreaker = new CircuitBreaker({
  failureThreshold: 5,
  resetTimeoutMs: 30000,
  successThreshold: 2,
});

async function fetchWithCircuitBreaker<T>(fn: () => Promise<T>): Promise<T> {
  return circuitBreaker.execute(fn);
}
```

---

## Fallback Strategies

### Graceful Degradation

```typescript
interface FallbackOptions<T> {
  fallbackValue: T;
  shouldFallback?: (error: unknown) => boolean;
  onFallback?: (error: unknown) => void;
}

async function withFallback<T>(
  fn: () => Promise<T>,
  options: FallbackOptions<T>
): Promise<T> {
  try {
    return await fn();
  } catch (error) {
    const shouldFallback = options.shouldFallback?.(error) ?? true;

    if (shouldFallback) {
      options.onFallback?.(error);
      return options.fallbackValue;
    }

    throw error;
  }
}

// Usage
const user = await withFallback(
  () => userService.get(id),
  {
    fallbackValue: null,
    shouldFallback: (error) => error instanceof NotFoundError,
    onFallback: (error) => console.warn('User not found, returning null'),
  }
);
```

### Cached Fallback

```typescript
class CachedFallback<T> {
  private cache: T | undefined;

  async execute(fn: () => Promise<T>): Promise<T> {
    try {
      const result = await fn();
      this.cache = result;
      return result;
    } catch (error) {
      if (this.cache !== undefined) {
        console.warn('Using cached fallback due to error:', error);
        return this.cache;
      }
      throw error;
    }
  }
}

// Usage
const userCacheFallback = new CachedFallback<User>();

async function getUser(id: string): Promise<User> {
  return userCacheFallback.execute(() => client.get<User>(`/users/${id}`));
}
```

### Multiple Source Fallback

```typescript
async function withSources<T>(
  sources: Array<() => Promise<T>>,
  options?: { onSourceFailed?: (index: number, error: unknown) => void }
): Promise<T> {
  let lastError: unknown;

  for (let i = 0; i < sources.length; i++) {
    try {
      return await sources[i]();
    } catch (error) {
      lastError = error;
      options?.onSourceFailed?.(i, error);
    }
  }

  throw lastError;
}

// Usage: Try primary API, then backup, then cache
const data = await withSources([
  () => primaryApi.getData(),
  () => backupApi.getData(),
  () => cache.getData(),
]);
```

---

## Error Handling Patterns

### Result Type Pattern

```typescript
type Result<T, E = Error> =
  | { success: true; data: T }
  | { success: false; error: E };

async function safeApiCall<T>(fn: () => Promise<T>): Promise<Result<T, ApiError>> {
  try {
    const data = await fn();
    return { success: true, data };
  } catch (error) {
    if (error instanceof ApiError) {
      return { success: false, error };
    }
    throw error; // Re-throw unexpected errors
  }
}

// Usage
const result = await safeApiCall(() => userService.get(id));

if (result.success) {
  console.log('User:', result.data);
} else {
  console.error('Error:', result.error.message);
}
```

### Error Boundary Pattern (React)

```typescript
// api-error-boundary.tsx
interface Props {
  children: React.ReactNode;
  fallback: React.ReactNode;
  onError?: (error: ApiError) => void;
}

interface State {
  error: ApiError | null;
}

class ApiErrorBoundary extends React.Component<Props, State> {
  state: State = { error: null };

  static getDerivedStateFromError(error: unknown): State | null {
    if (error instanceof ApiError) {
      return { error };
    }
    return null;
  }

  componentDidCatch(error: unknown): void {
    if (error instanceof ApiError) {
      this.props.onError?.(error);
    }
  }

  render() {
    if (this.state.error) {
      return this.props.fallback;
    }
    return this.props.children;
  }
}
```

### Centralized Error Handler

```typescript
type ErrorHandler = (error: ApiError) => void | Promise<void>;

class ErrorHandlerRegistry {
  private handlers = new Map<number | 'default', ErrorHandler>();

  register(status: number | 'default', handler: ErrorHandler): void {
    this.handlers.set(status, handler);
  }

  async handle(error: ApiError): Promise<void> {
    const handler = this.handlers.get(error.status) ?? this.handlers.get('default');
    await handler?.(error);
  }
}

// Setup
const errorHandlers = new ErrorHandlerRegistry();

errorHandlers.register(401, async (error) => {
  // Clear auth state and redirect to login
  await authService.logout();
  router.push('/login');
});

errorHandlers.register(403, (error) => {
  toast.error('You do not have permission to perform this action');
});

errorHandlers.register(429, (error) => {
  toast.warning('Too many requests. Please slow down.');
});

errorHandlers.register('default', (error) => {
  toast.error(error.message);
  console.error('API Error:', error);
});

// Usage in client
client.addErrorInterceptor(async (error) => {
  await errorHandlers.handle(error);
  return error;
});
```

---

## Error Reporting

### Structured Error Logging

```typescript
interface ErrorLog {
  timestamp: string;
  error: {
    name: string;
    message: string;
    status?: number;
    code?: string;
  };
  request?: {
    method: string;
    url: string;
    requestId?: string;
  };
  context?: Record<string, unknown>;
}

function logApiError(
  error: ApiError,
  request?: { method: string; url: string },
  context?: Record<string, unknown>
): void {
  const log: ErrorLog = {
    timestamp: new Date().toISOString(),
    error: {
      name: error.name,
      message: error.message,
      status: error.status,
      code: error.code,
    },
    request: request ? {
      ...request,
      requestId: error.requestId,
    } : undefined,
    context,
  };

  // Send to logging service
  console.error('API Error:', JSON.stringify(log));

  // Or send to error tracking (Sentry, etc.)
  // Sentry.captureException(error, { extra: log });
}
```

### Error Aggregation

```typescript
class ErrorAggregator {
  private errors: Map<string, { count: number; lastSeen: Date; sample: ApiError }> = new Map();

  record(error: ApiError): void {
    const key = `${error.status}:${error.code}`;
    const existing = this.errors.get(key);

    if (existing) {
      existing.count++;
      existing.lastSeen = new Date();
    } else {
      this.errors.set(key, {
        count: 1,
        lastSeen: new Date(),
        sample: error,
      });
    }
  }

  getReport(): Array<{ key: string; count: number; lastSeen: Date; sample: ApiError }> {
    return Array.from(this.errors.entries()).map(([key, value]) => ({
      key,
      ...value,
    }));
  }

  clear(): void {
    this.errors.clear();
  }
}
```
