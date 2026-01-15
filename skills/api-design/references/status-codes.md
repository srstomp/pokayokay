# Status Codes

HTTP status codes and error handling patterns.

## Status Code Categories

```
1xx - Informational (rarely used in APIs)
2xx - Success
3xx - Redirection
4xx - Client Error
5xx - Server Error
```

---

## 2xx Success

### 200 OK

General success for GET, PUT, PATCH.

```yaml
# GET - Resource retrieved
GET /users/123 → 200 OK
{ "id": "123", "name": "John" }

# PUT - Resource updated
PUT /users/123 → 200 OK
{ "id": "123", "name": "Updated" }

# PATCH - Resource partially updated
PATCH /users/123 → 200 OK
{ "id": "123", "name": "Updated" }

# POST action (non-creation)
POST /users/123/send-email → 200 OK
{ "sent": true }
```

### 201 Created

Resource successfully created (POST).

```yaml
POST /users → 201 Created
Headers:
  Location: /users/124
Body:
{ "id": "124", "name": "New User" }
```

**Always include:**
- `Location` header with new resource URL
- Created resource in body

### 202 Accepted

Request accepted for async processing.

```yaml
POST /reports/generate → 202 Accepted
{
  "jobId": "job_123",
  "status": "processing",
  "statusUrl": "/jobs/job_123"
}
```

**Use when:**
- Processing takes significant time
- Result not immediately available
- Provide status check URL

### 204 No Content

Success with no body to return.

```yaml
DELETE /users/123 → 204 No Content
(empty body)

PUT /users/123/archive → 204 No Content
(empty body)
```

**Use for:**
- DELETE operations
- Actions that don't return data
- When client doesn't need confirmation body

---

## 3xx Redirection

### 301 Moved Permanently

Resource permanently moved.

```yaml
GET /old/users/123 → 301 Moved Permanently
Location: /api/v2/users/123
```

### 303 See Other

Redirect to different resource (usually after POST).

```yaml
POST /orders → 303 See Other
Location: /orders/456
```

### 304 Not Modified

Cached resource still valid.

```yaml
GET /users/123
If-None-Match: "etag123"
→ 304 Not Modified
(empty body, use cached version)
```

### 307 Temporary Redirect

Temporary redirect, preserve method.

```yaml
POST /users → 307 Temporary Redirect
Location: /api/v2/users
(client should POST to new location)
```

---

## 4xx Client Errors

### 400 Bad Request

Malformed request, invalid syntax.

```yaml
# Invalid JSON
POST /users
Body: { invalid json }
→ 400 Bad Request
{
  "error": {
    "code": "INVALID_JSON",
    "message": "Request body contains invalid JSON"
  }
}

# Missing required field
POST /users
Body: { "name": "John" }
→ 400 Bad Request
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [
      { "field": "email", "message": "Required field" }
    ]
  }
}
```

### 401 Unauthorized

Authentication required or failed.

```yaml
# No authentication provided
GET /users/me → 401 Unauthorized
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Authentication required"
  }
}

# Invalid credentials
POST /auth/login
Body: { "email": "...", "password": "wrong" }
→ 401 Unauthorized
{
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "Invalid email or password"
  }
}

# Expired token
GET /users/me
Authorization: Bearer <expired>
→ 401 Unauthorized
{
  "error": {
    "code": "TOKEN_EXPIRED",
    "message": "Access token has expired"
  }
}
```

**Headers:**
```http
WWW-Authenticate: Bearer realm="api"
```

### 403 Forbidden

Authenticated but not authorized.

```yaml
# Not owner
DELETE /users/456 → 403 Forbidden
{
  "error": {
    "code": "FORBIDDEN",
    "message": "You don't have permission to delete this user"
  }
}

# Insufficient role
POST /admin/users → 403 Forbidden
{
  "error": {
    "code": "INSUFFICIENT_PERMISSIONS",
    "message": "Admin role required"
  }
}

# Resource access denied
GET /documents/private-doc → 403 Forbidden
{
  "error": {
    "code": "ACCESS_DENIED",
    "message": "You don't have access to this document"
  }
}
```

**401 vs 403:**
- 401: "Who are you?" (identity unknown)
- 403: "I know who you are, but no." (identity known, access denied)

### 404 Not Found

Resource doesn't exist.

```yaml
GET /users/99999 → 404 Not Found
{
  "error": {
    "code": "NOT_FOUND",
    "message": "User not found"
  }
}

# Don't reveal existence for security
GET /users/99999 → 404 Not Found
{
  "error": {
    "code": "NOT_FOUND",
    "message": "Resource not found"
  }
}
```

### 405 Method Not Allowed

HTTP method not supported for endpoint.

```yaml
DELETE /users → 405 Method Not Allowed
{
  "error": {
    "code": "METHOD_NOT_ALLOWED",
    "message": "DELETE not allowed on this endpoint"
  }
}
```

**Headers:**
```http
Allow: GET, POST
```

### 409 Conflict

Request conflicts with current state.

```yaml
# Duplicate resource
POST /users
Body: { "email": "existing@example.com" }
→ 409 Conflict
{
  "error": {
    "code": "DUPLICATE_RESOURCE",
    "message": "User with this email already exists"
  }
}

# State conflict
POST /orders/123/ship → 409 Conflict
{
  "error": {
    "code": "INVALID_STATE",
    "message": "Order is already shipped"
  }
}

# Optimistic locking
PUT /users/123
If-Match: "old-etag"
→ 409 Conflict
{
  "error": {
    "code": "CONFLICT",
    "message": "Resource was modified by another request"
  }
}
```

### 410 Gone

Resource permanently deleted.

```yaml
GET /users/123 → 410 Gone
{
  "error": {
    "code": "GONE",
    "message": "This user has been permanently deleted"
  }
}
```

### 415 Unsupported Media Type

Content-Type not supported.

```yaml
POST /users
Content-Type: application/xml
→ 415 Unsupported Media Type
{
  "error": {
    "code": "UNSUPPORTED_MEDIA_TYPE",
    "message": "Only application/json is supported"
  }
}
```

### 422 Unprocessable Entity

Semantic validation failure (syntax ok, semantics wrong).

```yaml
# Business logic validation
POST /orders
Body: { "quantity": -5 }
→ 422 Unprocessable Entity
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Quantity must be positive"
  }
}

# Domain rule violation
POST /transfers
Body: { "amount": 1000000 }
→ 422 Unprocessable Entity
{
  "error": {
    "code": "INSUFFICIENT_FUNDS",
    "message": "Account balance insufficient"
  }
}
```

**400 vs 422:**
- 400: Malformed request (bad JSON, wrong types)
- 422: Well-formed but invalid (business rules violated)

### 429 Too Many Requests

Rate limit exceeded.

```yaml
GET /users → 429 Too Many Requests
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests. Try again in 60 seconds."
  }
}
```

**Headers:**
```http
Retry-After: 60
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1705835000
```

---

## 5xx Server Errors

### 500 Internal Server Error

Unexpected server error.

```yaml
GET /users → 500 Internal Server Error
{
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "An unexpected error occurred",
    "requestId": "req_abc123"
  }
}
```

**Important:**
- Never expose stack traces in production
- Always include request ID for debugging
- Log full details server-side

### 502 Bad Gateway

Upstream service error.

```yaml
GET /external-data → 502 Bad Gateway
{
  "error": {
    "code": "BAD_GATEWAY",
    "message": "Unable to reach external service"
  }
}
```

### 503 Service Unavailable

Service temporarily unavailable.

```yaml
GET /users → 503 Service Unavailable
{
  "error": {
    "code": "SERVICE_UNAVAILABLE",
    "message": "Service is undergoing maintenance"
  }
}
```

**Headers:**
```http
Retry-After: 3600
```

### 504 Gateway Timeout

Upstream service timeout.

```yaml
GET /slow-external → 504 Gateway Timeout
{
  "error": {
    "code": "GATEWAY_TIMEOUT",
    "message": "External service did not respond in time"
  }
}
```

---

## Error Response Format

### Standard Structure

```json
{
  "error": {
    "status": 400,
    "code": "VALIDATION_ERROR",
    "message": "Human-readable message",
    "details": [],
    "requestId": "req_abc123",
    "timestamp": "2024-01-21T09:00:00Z",
    "path": "/users",
    "documentation": "https://docs.api.com/errors/validation"
  }
}
```

### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| status | number | HTTP status code |
| code | string | Machine-readable error code |
| message | string | Human-readable description |
| details | array | Detailed error info (validation) |
| requestId | string | Unique ID for debugging |
| timestamp | string | When error occurred |
| path | string | Request path |
| documentation | string | Link to error docs |

### Validation Error Details

```json
{
  "error": {
    "status": 400,
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [
      {
        "field": "email",
        "code": "INVALID_FORMAT",
        "message": "Must be a valid email address",
        "value": "not-an-email"
      },
      {
        "field": "password",
        "code": "TOO_SHORT",
        "message": "Must be at least 8 characters",
        "constraints": { "minLength": 8 }
      },
      {
        "field": "items[0].quantity",
        "code": "OUT_OF_RANGE",
        "message": "Must be between 1 and 100",
        "constraints": { "min": 1, "max": 100 },
        "value": 0
      }
    ]
  }
}
```

### Error Codes (Examples)

```yaml
# Authentication
UNAUTHORIZED: Missing authentication
INVALID_CREDENTIALS: Wrong username/password
TOKEN_EXPIRED: Access token expired
TOKEN_INVALID: Token malformed

# Authorization
FORBIDDEN: Access denied
INSUFFICIENT_PERMISSIONS: Missing required permission
RESOURCE_ACCESS_DENIED: Not owner of resource

# Validation
VALIDATION_ERROR: Request validation failed
INVALID_FORMAT: Field format invalid
REQUIRED: Required field missing
TOO_SHORT: Below minimum length
TOO_LONG: Above maximum length
OUT_OF_RANGE: Number outside valid range

# Resource
NOT_FOUND: Resource doesn't exist
DUPLICATE_RESOURCE: Resource already exists
CONFLICT: State conflict
GONE: Permanently deleted

# Rate Limiting
RATE_LIMIT_EXCEEDED: Too many requests

# Server
INTERNAL_ERROR: Unexpected server error
SERVICE_UNAVAILABLE: Maintenance/overload
BAD_GATEWAY: Upstream service error
GATEWAY_TIMEOUT: Upstream timeout
```

---

## Status Code Decision Tree

```
Start
│
├─ Request successful?
│  ├─ Yes → Created new resource?
│  │         ├─ Yes → 201 Created
│  │         └─ No → Need to return data?
│  │                  ├─ Yes → 200 OK
│  │                  └─ No → 204 No Content
│  │
│  └─ No → Is it async?
│           └─ Yes → 202 Accepted
│
├─ Client error?
│  ├─ Authentication issue?
│  │  ├─ Not authenticated → 401 Unauthorized
│  │  └─ Authenticated but forbidden → 403 Forbidden
│  │
│  ├─ Resource not found? → 404 Not Found
│  │
│  ├─ Validation issue?
│  │  ├─ Malformed request → 400 Bad Request
│  │  └─ Semantic error → 422 Unprocessable Entity
│  │
│  ├─ State conflict? → 409 Conflict
│  │
│  └─ Rate limited? → 429 Too Many Requests
│
└─ Server error?
   ├─ Our fault → 500 Internal Server Error
   ├─ Upstream issue → 502 Bad Gateway / 504 Timeout
   └─ Unavailable → 503 Service Unavailable
```

---

## Idempotency Considerations

| Status | Idempotent? | Can Retry Safely? |
|--------|-------------|-------------------|
| 200 | Yes | Yes |
| 201 | No | No (may create duplicate) |
| 204 | Yes | Yes |
| 400 | Yes | Yes (same error) |
| 401 | Yes | Yes (after auth fix) |
| 404 | Yes | Yes |
| 409 | Depends | Check current state |
| 429 | Yes | Yes (after delay) |
| 500 | No | Maybe |
| 503 | Yes | Yes (after delay) |

For non-idempotent operations (POST), use `Idempotency-Key` header to allow safe retries.
