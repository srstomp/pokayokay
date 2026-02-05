# Error Handling Overview

## Error Type Design

### Custom Error Classes

```typescript
// Base error with context
class AppError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly context?: Record<string, unknown>,
    public readonly cause?: Error
  ) {
    super(message);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }

  toJSON() {
    return { name: this.name, code: this.code, message: this.message, context: this.context };
  }
}

// Domain-specific errors
class ValidationError extends AppError {
  constructor(message: string, public readonly field?: string) {
    super(message, 'VALIDATION_ERROR', { field });
  }
}

class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super(`${resource} not found: ${id}`, 'NOT_FOUND', { resource, id });
  }
}

class AuthenticationError extends AppError {
  constructor(message = 'Authentication required') {
    super(message, 'AUTH_REQUIRED');
  }
}

class AuthorizationError extends AppError {
  constructor(action: string, resource: string) {
    super(`Not authorized to ${action} ${resource}`, 'FORBIDDEN', { action, resource });
  }
}
```

### Error Code Registry

```typescript
const ErrorCodes = {
  AUTH_REQUIRED: 'E1001', AUTH_EXPIRED: 'E1002', AUTH_INVALID: 'E1003',
  VALIDATION_FAILED: 'E2001', VALIDATION_MISSING_FIELD: 'E2002', VALIDATION_INVALID_FORMAT: 'E2003',
  INSUFFICIENT_FUNDS: 'E3001', ITEM_OUT_OF_STOCK: 'E3002',
  SERVICE_UNAVAILABLE: 'E4001', RATE_LIMITED: 'E4002',
} as const;
```

## Result Pattern (No Throws)

```typescript
type Result<T, E = Error> =
  | { ok: true; value: T }
  | { ok: false; error: E };

const Ok = <T>(value: T): Result<T, never> => ({ ok: true, value });
const Err = <E>(error: E): Result<never, E> => ({ ok: false, error });

// Usage
async function parseUser(data: unknown): Result<User, ValidationError> {
  const parsed = userSchema.safeParse(data);
  if (!parsed.success) return Err(new ValidationError(parsed.error.message));
  return Ok(parsed.data);
}
```

**When to use Result vs throws:**
- Result: Expected failures (validation, business rules), functional pipelines
- Throws: Unexpected failures (programmer errors, system failures)

## User-Facing Error Messages

```
Bad:  "Error: ETIMEDOUT"
Good: "We're having trouble connecting. Please check your internet and try again."

Bad:  "Null pointer exception at line 42"
Good: "Something went wrong. We've been notified and are working on it."
```

**Guidelines:**
1. Be specific about the problem (when safe)
2. Suggest what to do next (retry, contact support)
3. Never expose technical details
4. Match tone to severity

## Error Tracking (Sentry)

```typescript
Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 0.1,
  beforeSend(event) {
    if (event.request?.data) delete event.request.data.password;
    return event;
  },
});
```

**Always track:** Unhandled exceptions, critical business logic failures, external service failures.
**Don't track:** Expected validation errors, user cancellations, rate limit hits.

## Anti-Patterns

| Anti-Pattern | Fix |
|--------------|-----|
| Swallowing errors (`catch {}`) | Handle or propagate with context |
| Generic catch-all | Preserve error type and context |
| Inconsistent error shapes | Use consistent `{ error: { code, message, requestId } }` across all endpoints |
