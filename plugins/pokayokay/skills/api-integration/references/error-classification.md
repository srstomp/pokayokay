# Error Classification

Error type hierarchy, classification helpers, and response-to-error conversion.

## Error Type Hierarchy

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

## Error Classification Helper

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

## Converting Response to Typed Error

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
