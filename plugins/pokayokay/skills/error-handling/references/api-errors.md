# API Error Handling

HTTP error responses, status codes, and API error design patterns.

## Standard Error Response Shape

### Core Structure

```typescript
interface APIErrorResponse {
  error: {
    code: string;           // Machine-readable error code
    message: string;        // Human-readable message
    details?: unknown;      // Additional structured context
    requestId?: string;     // Correlation ID for debugging
    timestamp?: string;     // ISO 8601 timestamp
    path?: string;          // Request path
    docs?: string;          // Link to documentation
  };
}

// Example response
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request body",
    "details": {
      "fields": [
        { "field": "email", "message": "Invalid email format" },
        { "field": "age", "message": "Must be a positive number" }
      ]
    },
    "requestId": "req_abc123xyz",
    "timestamp": "2024-01-15T10:30:00Z",
    "path": "/api/users",
    "docs": "https://api.example.com/docs/errors#VALIDATION_ERROR"
  }
}
```

### TypeScript Types

```typescript
// Error codes as const for type safety
const ErrorCodes = {
  // Client errors (4xx)
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  AUTH_REQUIRED: 'AUTH_REQUIRED',
  AUTH_EXPIRED: 'AUTH_EXPIRED',
  AUTH_INVALID: 'AUTH_INVALID',
  FORBIDDEN: 'FORBIDDEN',
  NOT_FOUND: 'NOT_FOUND',
  CONFLICT: 'CONFLICT',
  RATE_LIMITED: 'RATE_LIMITED',
  
  // Server errors (5xx)
  INTERNAL_ERROR: 'INTERNAL_ERROR',
  SERVICE_UNAVAILABLE: 'SERVICE_UNAVAILABLE',
  GATEWAY_TIMEOUT: 'GATEWAY_TIMEOUT',
} as const;

type ErrorCode = typeof ErrorCodes[keyof typeof ErrorCodes];

interface ValidationDetail {
  field: string;
  message: string;
  code?: string;
  value?: unknown;
}

interface APIError {
  code: ErrorCode;
  message: string;
  details?: ValidationDetail[] | Record<string, unknown>;
  requestId?: string;
}
```

## HTTP Status Code Mapping

### Status Code Reference

| Status | Name | Use Case | Retryable |
|--------|------|----------|-----------|
| 400 | Bad Request | Invalid input, malformed JSON | No (fix request) |
| 401 | Unauthorized | Missing or invalid auth | No (authenticate) |
| 403 | Forbidden | Valid auth, insufficient permissions | No (need access) |
| 404 | Not Found | Resource doesn't exist | No |
| 405 | Method Not Allowed | Wrong HTTP method | No |
| 409 | Conflict | State conflict, duplicate | Maybe (check state) |
| 410 | Gone | Resource permanently deleted | No |
| 422 | Unprocessable Entity | Semantic validation failure | No (fix data) |
| 429 | Too Many Requests | Rate limit exceeded | Yes (after delay) |
| 500 | Internal Server Error | Unexpected server error | Yes (transient) |
| 502 | Bad Gateway | Upstream service failure | Yes |
| 503 | Service Unavailable | Maintenance, overload | Yes (after delay) |
| 504 | Gateway Timeout | Upstream timeout | Yes |

### Error to Status Mapping

```typescript
function getStatusCode(error: AppError): number {
  if (error instanceof ValidationError) return 400;
  if (error instanceof AuthenticationError) return 401;
  if (error instanceof AuthorizationError) return 403;
  if (error instanceof NotFoundError) return 404;
  if (error instanceof ConflictError) return 409;
  if (error instanceof RateLimitError) return 429;
  if (error instanceof ExternalServiceError) return 503;
  return 500;
}

// Or use statusCode on error class
abstract class AppError extends Error {
  abstract readonly statusCode: number;
}
```

## Express Error Handler

### Centralized Handler

```typescript
import { Request, Response, NextFunction } from 'express';
import * as Sentry from '@sentry/node';

function errorHandler(
  err: Error,
  req: Request,
  res: Response,
  next: NextFunction
) {
  const requestId = req.headers['x-request-id'] as string || req.id;

  // Log all errors
  req.log?.error({ err, requestId }, 'Request error');

  // Handle known errors
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      error: {
        code: err.code,
        message: err.message,
        details: err.context,
        requestId,
        timestamp: new Date().toISOString(),
        path: req.path,
      },
    });
  }

  // Handle validation library errors (e.g., Zod)
  if (err instanceof z.ZodError) {
    return res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Request validation failed',
        details: {
          fields: err.issues.map(issue => ({
            field: issue.path.join('.'),
            message: issue.message,
            code: issue.code,
          })),
        },
        requestId,
        timestamp: new Date().toISOString(),
        path: req.path,
      },
    });
  }

  // Unknown error - don't leak details
  Sentry.withScope((scope) => {
    scope.setTag('requestId', requestId);
    scope.setUser({ id: req.user?.id });
    Sentry.captureException(err);
  });

  res.status(500).json({
    error: {
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred',
      requestId,
      timestamp: new Date().toISOString(),
      path: req.path,
    },
  });
}

// Register as last middleware
app.use(errorHandler);
```

### Async Route Wrapper

```typescript
// Wrap async routes to catch errors
const asyncHandler = (fn: RequestHandler) => (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

// Usage
app.get('/users/:id', asyncHandler(async (req, res) => {
  const user = await userService.getById(req.params.id);
  if (!user) throw new NotFoundError('User', req.params.id);
  res.json({ data: user });
}));

// Or use express-async-errors package
import 'express-async-errors';
// Then async errors automatically propagate
```

## Validation Error Responses

### Field-Level Errors

```typescript
// Response for form validation
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "details": {
      "fields": [
        {
          "field": "email",
          "message": "Invalid email format",
          "code": "INVALID_FORMAT",
          "value": "not-an-email"
        },
        {
          "field": "password",
          "message": "Password must be at least 8 characters",
          "code": "TOO_SHORT",
          "constraints": { "minLength": 8 }
        },
        {
          "field": "age",
          "message": "Age must be a positive number",
          "code": "INVALID_RANGE",
          "constraints": { "min": 0 }
        }
      ]
    },
    "requestId": "req_xyz789"
  }
}
```

### Zod Integration

```typescript
import { z } from 'zod';

const userSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  name: z.string().min(1).max(100),
});

app.post('/users', asyncHandler(async (req, res) => {
  const result = userSchema.safeParse(req.body);
  
  if (!result.success) {
    return res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid request body',
        details: {
          fields: result.error.issues.map(issue => ({
            field: issue.path.join('.'),
            message: issue.message,
            code: issue.code,
          })),
        },
        requestId: req.id,
      },
    });
  }
  
  const user = await userService.create(result.data);
  res.status(201).json({ data: user });
}));
```

## Rate Limit Responses

### Standard Format

```typescript
// Rate limit headers
res.set({
  'X-RateLimit-Limit': '100',
  'X-RateLimit-Remaining': '0',
  'X-RateLimit-Reset': '1705319400', // Unix timestamp
  'Retry-After': '60', // Seconds
});

// Response body
{
  "error": {
    "code": "RATE_LIMITED",
    "message": "Rate limit exceeded. Try again in 60 seconds.",
    "details": {
      "limit": 100,
      "remaining": 0,
      "resetAt": "2024-01-15T10:30:00Z",
      "retryAfter": 60
    },
    "requestId": "req_abc123"
  }
}
```

### Rate Limit Middleware

```typescript
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    res.status(429).json({
      error: {
        code: 'RATE_LIMITED',
        message: 'Too many requests. Please try again later.',
        details: {
          retryAfter: Math.ceil(req.rateLimit.resetTime.getTime() / 1000),
        },
        requestId: req.id,
      },
    });
  },
});
```

## Client Error Handling

### Fetch Wrapper

```typescript
class APIClient {
  private baseUrl: string;

  async request<T>(path: string, options?: RequestInit): Promise<T> {
    const response = await fetch(`${this.baseUrl}${path}`, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...options?.headers,
      },
    });

    if (!response.ok) {
      const errorBody = await response.json().catch(() => null);
      throw this.handleError(response.status, errorBody);
    }

    return response.json();
  }

  private handleError(status: number, body: any): AppError {
    const error = body?.error;
    
    switch (status) {
      case 400:
        return new ValidationError(
          error?.message || 'Invalid request',
          error?.details?.fields
        );
      case 401:
        return new AuthenticationError(error?.message);
      case 403:
        return new AuthorizationError(
          error?.details?.action || 'access',
          error?.details?.resource || 'resource'
        );
      case 404:
        return new NotFoundError(
          error?.details?.resource || 'Resource',
          error?.details?.id || 'unknown'
        );
      case 429:
        return new RateLimitError(error?.details?.retryAfter);
      default:
        return new APIError(
          error?.message || 'An error occurred',
          error?.code || 'UNKNOWN_ERROR',
          status
        );
    }
  }
}
```

### React Query Integration

```typescript
import { QueryClient } from '@tanstack/react-query';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: (failureCount, error) => {
        // Don't retry 4xx errors
        if (error instanceof AppError && error.statusCode < 500) {
          return false;
        }
        return failureCount < 3;
      },
    },
    mutations: {
      retry: false, // Don't retry mutations by default
    },
  },
});

// Per-query error handling
const { data, error } = useQuery({
  queryKey: ['user', id],
  queryFn: () => api.getUser(id),
  useErrorBoundary: (error) => {
    // Only throw to boundary for server errors
    return error instanceof AppError && error.statusCode >= 500;
  },
});
```

## Error Documentation

### OpenAPI Error Definitions

```yaml
components:
  schemas:
    Error:
      type: object
      required:
        - error
      properties:
        error:
          type: object
          required:
            - code
            - message
          properties:
            code:
              type: string
              description: Machine-readable error code
              example: VALIDATION_ERROR
            message:
              type: string
              description: Human-readable message
              example: Invalid request body
            details:
              type: object
              description: Additional error context
            requestId:
              type: string
              description: Request correlation ID
              example: req_abc123

    ValidationError:
      allOf:
        - $ref: '#/components/schemas/Error'
        - type: object
          properties:
            error:
              properties:
                details:
                  type: object
                  properties:
                    fields:
                      type: array
                      items:
                        type: object
                        properties:
                          field:
                            type: string
                          message:
                            type: string

  responses:
    BadRequest:
      description: Invalid request
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ValidationError'
    
    Unauthorized:
      description: Authentication required
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
    
    NotFound:
      description: Resource not found
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
```

### Error Code Documentation

```typescript
/**
 * API Error Codes Reference
 * 
 * Authentication Errors (AUTH_*)
 * - AUTH_REQUIRED: No authentication provided
 * - AUTH_EXPIRED: Token has expired
 * - AUTH_INVALID: Invalid credentials
 * 
 * Validation Errors (VALIDATION_*)
 * - VALIDATION_ERROR: General validation failure
 * - VALIDATION_MISSING_FIELD: Required field missing
 * - VALIDATION_INVALID_FORMAT: Field format invalid
 * 
 * Business Logic Errors
 * - INSUFFICIENT_FUNDS: Not enough balance
 * - ITEM_OUT_OF_STOCK: Requested item unavailable
 * 
 * System Errors
 * - INTERNAL_ERROR: Unexpected server error
 * - SERVICE_UNAVAILABLE: Downstream service down
 */
```

## Best Practices

### 1. Be Consistent

```typescript
// ❌ Inconsistent error shapes
{ error: "message" }
{ message: "...", code: 123 }
{ errors: ["..."] }

// ✅ Always same shape
{ error: { code: "...", message: "...", requestId: "..." } }
```

### 2. Include Request ID

```typescript
// Always include for debugging
app.use((req, res, next) => {
  req.id = req.headers['x-request-id'] as string || crypto.randomUUID();
  res.set('X-Request-ID', req.id);
  next();
});
```

### 3. Don't Leak Internals

```typescript
// ❌ Exposes implementation
{
  "error": {
    "message": "ECONNREFUSED 127.0.0.1:5432",
    "stack": "Error: connect ECONNREFUSED..."
  }
}

// ✅ Safe message
{
  "error": {
    "code": "SERVICE_UNAVAILABLE",
    "message": "Service temporarily unavailable",
    "requestId": "req_abc123"
  }
}
```

### 4. Make Errors Actionable

```typescript
// ❌ Not helpful
{ "error": { "message": "Invalid" } }

// ✅ Actionable
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email address is required",
    "details": { "field": "email" },
    "docs": "https://api.example.com/docs/users#create"
  }
}
```
