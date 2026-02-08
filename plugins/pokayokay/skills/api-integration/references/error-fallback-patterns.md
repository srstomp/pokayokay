# Error Handling: Fallback & Recovery Patterns

Graceful degradation, Result types, error boundaries, centralized error handling, and error reporting.

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
