# Error Handling: Retry Logic & Circuit Breaker

Retry strategies with exponential backoff, rate limit awareness, idempotency, and circuit breaker pattern.

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
