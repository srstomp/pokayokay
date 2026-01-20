# Requests and Responses

Request/response formats, headers, and content types.

## Request Format

### Headers

```http
# Required
Content-Type: application/json
Accept: application/json

# Authentication
Authorization: Bearer <token>
X-API-Key: <api-key>

# Idempotency (for POST/PATCH)
Idempotency-Key: <unique-key>

# Versioning (if not in URL)
API-Version: 2024-01-15
Accept: application/vnd.api+json;version=2

# Request tracking
X-Request-ID: <client-generated-uuid>

# Conditional requests
If-None-Match: "<etag>"
If-Match: "<etag>"
If-Modified-Since: <date>
```

### Request Body

```json
// POST /users
{
  "email": "user@example.com",
  "name": "John Doe",
  "password": "securePassword123",
  "role": "user",
  "preferences": {
    "newsletter": true,
    "language": "en"
  }
}
```

**Rules:**
- Use camelCase for field names (or snake_case, but be consistent)
- Include only necessary fields
- Validate on server, never trust client

### Field Naming Conventions

```json
// camelCase (JavaScript convention)
{
  "firstName": "John",
  "lastName": "Doe",
  "createdAt": "2024-01-15T10:30:00Z"
}

// snake_case (Python/Ruby convention)
{
  "first_name": "John",
  "last_name": "Doe",
  "created_at": "2024-01-15T10:30:00Z"
}
```

Pick one and use it everywhere.

---

## Response Format

### Success Response

#### Single Resource

```json
// GET /users/123
{
  "id": "123",
  "email": "user@example.com",
  "name": "John Doe",
  "role": "user",
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-20T14:45:00Z"
}
```

#### Collection

```json
// GET /users
{
  "data": [
    { "id": "1", "email": "user1@example.com", "name": "User 1" },
    { "id": "2", "email": "user2@example.com", "name": "User 2" }
  ],
  "meta": {
    "total": 100,
    "page": 1,
    "perPage": 20,
    "totalPages": 5
  },
  "links": {
    "self": "/users?page=1",
    "next": "/users?page=2",
    "last": "/users?page=5"
  }
}
```

#### Created Resource

```json
// POST /users → 201 Created
// Headers: Location: /users/124
{
  "id": "124",
  "email": "new@example.com",
  "name": "New User",
  "createdAt": "2024-01-21T09:00:00Z"
}
```

### Response Headers

```http
# Standard
Content-Type: application/json
Date: Sun, 21 Jan 2024 09:00:00 GMT

# Resource info
Location: /users/124              # For 201 Created
ETag: "abc123"                    # For caching
Last-Modified: Sun, 21 Jan 2024   # For caching

# Pagination
X-Total-Count: 100
X-Page: 1
X-Per-Page: 20
Link: </users?page=2>; rel="next", </users?page=5>; rel="last"

# Rate limiting
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1705835000

# Request tracking
X-Request-ID: req_abc123

# Deprecation
Deprecation: true
Sunset: Sat, 01 Jun 2024 00:00:00 GMT
Link: </docs/migration>; rel="deprecation"
```

---

## Response Envelope Patterns

### Minimal (No Envelope)

```json
// Single resource - return directly
{ "id": "123", "name": "John" }

// Collection - return array directly
[
  { "id": "1", "name": "User 1" },
  { "id": "2", "name": "User 2" }
]
```

**Pros:** Simple, less bytes
**Cons:** No room for metadata, harder to extend

### Data Wrapper

```json
// Single resource
{
  "data": { "id": "123", "name": "John" }
}

// Collection
{
  "data": [
    { "id": "1", "name": "User 1" },
    { "id": "2", "name": "User 2" }
  ],
  "meta": {
    "total": 100
  }
}
```

**Pros:** Consistent, room for metadata
**Cons:** Extra nesting

### Full Envelope

```json
{
  "success": true,
  "data": { "id": "123", "name": "John" },
  "meta": {
    "requestId": "req_abc123",
    "timestamp": "2024-01-21T09:00:00Z"
  }
}
```

**Pros:** Very explicit, great for debugging
**Cons:** Verbose, redundant (HTTP status already indicates success)

### Recommended: Hybrid Approach

```json
// Single resource - no envelope
{ "id": "123", "name": "John" }

// Collection - with meta
{
  "data": [...],
  "meta": { "total": 100, "page": 1 }
}

// Error - consistent envelope
{
  "error": {
    "code": "NOT_FOUND",
    "message": "User not found"
  }
}
```

---

## Data Types and Formats

### Dates and Times

```json
// ISO 8601 with timezone (recommended)
{
  "createdAt": "2024-01-15T10:30:00Z",        // UTC
  "updatedAt": "2024-01-15T10:30:00+05:30",   // With offset
  "eventDate": "2024-01-15"                    // Date only
}

// Unix timestamp (alternative)
{
  "createdAt": 1705315800,
  "createdAtMs": 1705315800000
}
```

**Always:**
- Use ISO 8601 for JSON
- Include timezone
- Be consistent (all UTC or all with offset)

### Numbers

```json
{
  "count": 42,                    // Integer
  "price": 29.99,                 // Decimal
  "rating": 4.5,                  // Float
  "largeNumber": "9007199254740993"  // String for > MAX_SAFE_INTEGER
}
```

### Money

```json
// Option 1: Smallest unit (cents)
{
  "amount": 2999,
  "currency": "USD"
}

// Option 2: Decimal string
{
  "amount": "29.99",
  "currency": "USD"
}

// Option 3: Object
{
  "price": {
    "amount": 2999,
    "currency": "USD",
    "formatted": "$29.99"
  }
}
```

### IDs

```json
// String IDs (recommended for flexibility)
{
  "id": "123",
  "userId": "usr_abc123",
  "orderId": "ord_xyz789"
}

// UUID
{
  "id": "550e8400-e29b-41d4-a716-446655440000"
}

// Integer (legacy)
{
  "id": 123
}
```

### Booleans

```json
{
  "isActive": true,
  "hasPassword": false,
  "emailVerified": true
}
```

### Null vs Omission

```json
// Explicit null (field exists but empty)
{
  "name": "John",
  "middleName": null,
  "avatar": null
}

// Omitted (field not applicable)
{
  "name": "John"
  // middleName and avatar omitted
}
```

**Guideline:** 
- Omit optional fields that have no value
- Use null when the field is meaningful but empty
- Be consistent within your API

---

## Content Negotiation

### Accept Header

```http
# Request specific format
Accept: application/json
Accept: application/xml
Accept: text/csv

# Multiple with preference
Accept: application/json, application/xml;q=0.9, */*;q=0.8

# Vendor media type (for versioning)
Accept: application/vnd.myapi.v2+json
```

### Content-Type Response

```http
# Standard JSON
Content-Type: application/json

# JSON:API
Content-Type: application/vnd.api+json

# Vendor specific
Content-Type: application/vnd.myapi.v2+json

# With charset
Content-Type: application/json; charset=utf-8
```

### File Downloads

```http
# PDF response
Content-Type: application/pdf
Content-Disposition: attachment; filename="report.pdf"

# CSV export
Content-Type: text/csv
Content-Disposition: attachment; filename="users.csv"
```

---

## Special Response Patterns

### Async Operations

```json
// POST /reports/generate → 202 Accepted
{
  "jobId": "job_abc123",
  "status": "pending",
  "statusUrl": "/jobs/job_abc123",
  "estimatedTime": 30
}

// GET /jobs/job_abc123
{
  "jobId": "job_abc123",
  "status": "completed",
  "result": {
    "downloadUrl": "/reports/rpt_xyz789.pdf",
    "expiresAt": "2024-01-22T09:00:00Z"
  }
}
```

### Partial Content

```http
# Request
GET /files/large-video.mp4
Range: bytes=0-1023

# Response → 206 Partial Content
Content-Range: bytes 0-1023/1048576
Content-Length: 1024
```

### No Content

```http
# DELETE /users/123 → 204 No Content
# (empty body)

# PUT /users/123/archive → 204 No Content
# (empty body, action successful)
```

### Redirects

```http
# Resource moved → 301 Moved Permanently
Location: /api/v2/users/123

# See other resource → 303 See Other
# (after POST, redirect to GET the created resource)
Location: /users/124

# Temporary redirect → 307 Temporary Redirect
Location: /users/123?format=full
```

---

## Request Validation Response

```json
// 400 Bad Request or 422 Unprocessable Entity
{
  "error": {
    "status": 400,
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
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
        "constraints": {
          "minLength": 8
        }
      },
      {
        "field": "age",
        "code": "OUT_OF_RANGE",
        "message": "Must be between 18 and 120",
        "constraints": {
          "min": 18,
          "max": 120
        }
      }
    ]
  }
}
```

---

## Sparse Fieldsets

Allow clients to request only needed fields:

```http
# Request specific fields
GET /users/123?fields=id,name,email

# Response
{
  "id": "123",
  "name": "John Doe",
  "email": "john@example.com"
}

# Nested field selection
GET /users/123?fields=id,name,orders.id,orders.total
```

## Embedding Related Resources

```http
# Request with includes
GET /orders/123?include=user,items.product

# Response
{
  "id": "123",
  "total": 99.99,
  "user": {
    "id": "456",
    "name": "John Doe"
  },
  "items": [
    {
      "id": "789",
      "quantity": 2,
      "product": {
        "id": "prod_1",
        "name": "Widget"
      }
    }
  ]
}
```
