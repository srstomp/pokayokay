# API Documentation Guide

Patterns for documenting REST APIs effectively.

## Documentation Structure

### Per-Endpoint Documentation

```markdown
## Endpoint Name

Brief description of what this endpoint does.

### Request

\`\`\`http
METHOD /path/{param}
\`\`\`

#### Path Parameters

| Name | Type | Description |
|------|------|-------------|
| param | string | Description |

#### Query Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| page | integer | No | 1 | Page number |

#### Request Body

\`\`\`json
{
  "field": "value"
}
\`\`\`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| field | string | Yes | What it does |

### Response

#### Success (200)

\`\`\`json
{
  "data": { }
}
\`\`\`

#### Errors

| Status | Code | Description |
|--------|------|-------------|
| 400 | INVALID_INPUT | Request validation failed |
| 404 | NOT_FOUND | Resource doesn't exist |
```

## OpenAPI Integration

### OpenAPI Specification Pattern

```yaml
openapi: 3.0.3
info:
  title: My API
  version: 1.0.0
  description: |
    API description with markdown support.
    
    ## Authentication
    All endpoints require Bearer token authentication.

servers:
  - url: https://api.example.com/v1
    description: Production
  - url: https://staging-api.example.com/v1
    description: Staging

paths:
  /users:
    get:
      summary: List users
      description: Returns a paginated list of users.
      tags:
        - Users
      parameters:
        - name: page
          in: query
          schema:
            type: integer
            default: 1
        - name: limit
          in: query
          schema:
            type: integer
            default: 20
            maximum: 100
      responses:
        '200':
          description: Success
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserList'
              example:
                data:
                  - id: "usr_123"
                    email: "jane@example.com"
                meta:
                  total: 100
                  page: 1

components:
  schemas:
    User:
      type: object
      required:
        - id
        - email
      properties:
        id:
          type: string
          description: Unique user identifier
          example: "usr_123"
        email:
          type: string
          format: email
          example: "jane@example.com"
        name:
          type: string
          example: "Jane Doe"
        createdAt:
          type: string
          format: date-time
          
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

security:
  - bearerAuth: []
```

### Generating Docs from OpenAPI

```bash
# Redocly - HTML documentation
npx @redocly/cli build-docs openapi.yaml -o docs/api.html

# Swagger UI - Interactive docs
docker run -p 80:8080 \
  -e SWAGGER_JSON=/spec/openapi.yaml \
  -v ./openapi.yaml:/spec/openapi.yaml \
  swaggerapi/swagger-ui

# Generate TypeScript types
npx openapi-typescript openapi.yaml -o types/api.d.ts

# Validate spec
npx @redocly/cli lint openapi.yaml
```

## Request/Response Examples

### Example Quality

**Include realistic data**:
```json
// ✅ Good - realistic values
{
  "email": "jane.doe@example.com",
  "name": "Jane Doe",
  "role": "admin"
}

// ❌ Bad - placeholder data
{
  "email": "string",
  "name": "string",
  "role": "string"
}
```

**Show common variations**:
```markdown
### Request Examples

**Minimal request (required fields only)**:
\`\`\`json
{
  "email": "user@example.com"
}
\`\`\`

**Full request (all fields)**:
\`\`\`json
{
  "email": "user@example.com",
  "name": "Jane Doe",
  "role": "admin",
  "notifications": {
    "email": true,
    "push": false
  }
}
\`\`\`
```

## Error Documentation

### Error Response Format

```markdown
## Error Responses

All errors follow this format:

\`\`\`json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable message",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      }
    ],
    "requestId": "req_abc123"
  }
}
\`\`\`

### Error Codes

| Code | HTTP Status | Description | Resolution |
|------|-------------|-------------|------------|
| INVALID_INPUT | 400 | Request validation failed | Check request body |
| UNAUTHORIZED | 401 | Missing or invalid token | Provide valid auth |
| FORBIDDEN | 403 | Insufficient permissions | Request access |
| NOT_FOUND | 404 | Resource doesn't exist | Check resource ID |
| RATE_LIMITED | 429 | Too many requests | Wait and retry |
| INTERNAL_ERROR | 500 | Server error | Contact support |
```

## Authentication Documentation

### Auth Section Pattern

```markdown
## Authentication

All API requests require authentication via Bearer token.

### Obtaining a Token

\`\`\`http
POST /auth/token
Content-Type: application/json

{
  "client_id": "your_client_id",
  "client_secret": "your_client_secret"
}
\`\`\`

Response:
\`\`\`json
{
  "access_token": "eyJhbG...",
  "token_type": "bearer",
  "expires_in": 3600
}
\`\`\`

### Using the Token

Include the token in the Authorization header:

\`\`\`http
GET /api/v1/users
Authorization: Bearer eyJhbG...
\`\`\`

### Token Expiration

Tokens expire after 1 hour. Request a new token when you receive
a 401 response with code `TOKEN_EXPIRED`.
```

## Rate Limiting Documentation

```markdown
## Rate Limits

| Plan | Requests/minute | Requests/day |
|------|-----------------|--------------|
| Free | 60 | 1,000 |
| Pro | 600 | 50,000 |
| Enterprise | 6,000 | Unlimited |

### Rate Limit Headers

Every response includes rate limit information:

| Header | Description |
|--------|-------------|
| `X-RateLimit-Limit` | Requests allowed per window |
| `X-RateLimit-Remaining` | Requests remaining |
| `X-RateLimit-Reset` | Unix timestamp when limit resets |

### Handling Rate Limits

When rate limited, you'll receive:

\`\`\`http
HTTP/1.1 429 Too Many Requests
Retry-After: 30
X-RateLimit-Reset: 1705320000

{
  "error": {
    "code": "RATE_LIMITED",
    "message": "Rate limit exceeded. Try again in 30 seconds."
  }
}
\`\`\`

**Best practices**:
- Implement exponential backoff
- Cache responses where appropriate
- Batch requests when possible
```

## Versioning Documentation

```markdown
## API Versioning

The API version is included in the URL path:

\`\`\`
https://api.example.com/v1/users
https://api.example.com/v2/users
\`\`\`

### Version Lifecycle

| Version | Status | Support Until |
|---------|--------|---------------|
| v2 | Current | — |
| v1 | Deprecated | 2025-01-01 |

### Migration Guide

See [v1 to v2 Migration](./migration-v1-v2.md) for breaking changes
and upgrade instructions.

### Deprecation Policy

- Deprecated versions supported for 12 months minimum
- Deprecation warnings in response headers
- Email notification 90 days before EOL
```

## Code Examples

### Multi-Language Examples

```markdown
## Usage Examples

### cURL

\`\`\`bash
curl -X POST https://api.example.com/v1/users \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "name": "Jane"}'
\`\`\`

### JavaScript

\`\`\`javascript
const response = await fetch('https://api.example.com/v1/users', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    email: 'user@example.com',
    name: 'Jane'
  })
});

const data = await response.json();
\`\`\`

### Python

\`\`\`python
import requests

response = requests.post(
    'https://api.example.com/v1/users',
    headers={'Authorization': f'Bearer {token}'},
    json={'email': 'user@example.com', 'name': 'Jane'}
)

data = response.json()
\`\`\`
```

## Webhooks Documentation

```markdown
## Webhooks

### Registering a Webhook

\`\`\`http
POST /webhooks
{
  "url": "https://your-app.com/webhook",
  "events": ["user.created", "user.deleted"]
}
\`\`\`

### Webhook Payload

\`\`\`json
{
  "id": "evt_123",
  "type": "user.created",
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "user": {
      "id": "usr_456",
      "email": "jane@example.com"
    }
  }
}
\`\`\`

### Verifying Signatures

Each webhook includes a signature header:

\`\`\`
X-Webhook-Signature: sha256=abc123...
\`\`\`

Verify using HMAC-SHA256:

\`\`\`javascript
const crypto = require('crypto');

function verifyWebhook(payload, signature, secret) {
  const expected = crypto
    .createHmac('sha256', secret)
    .update(payload)
    .digest('hex');
  return `sha256=${expected}` === signature;
}
\`\`\`
```

## Best Practices

### Documentation Quality

- **Keep examples current** — Test with each release
- **Use realistic data** — No "string" or "example" placeholders
- **Show errors** — Document failure cases, not just success
- **Version examples** — Match code samples to API version

### Organization

- **Group by resource** — Users, Orders, Products
- **Consistent ordering** — CRUD order (List, Get, Create, Update, Delete)
- **Linkable sections** — Anchor IDs for deep linking
- **Search-friendly** — Include keywords users might search for
