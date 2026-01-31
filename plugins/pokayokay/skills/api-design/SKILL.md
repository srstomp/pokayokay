---
name: api-design
description: Design RESTful APIs with consistent patterns, clear conventions, and comprehensive documentation. Covers endpoint design, HTTP methods, status codes, request/response formats, pagination, filtering, versioning, authentication, and OpenAPI specifications. Use this skill when designing new APIs, reviewing API designs, or establishing API standards for a project or organization.
---

# API Design

Design clear, consistent, and developer-friendly REST APIs.

## Design Process

```
┌──────────────────────────────────────────────────────────────────┐
│                      API DESIGN PROCESS                          │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  0. UX INTEGRATION (optional)                                    │
│  ┌──────────────────────────┐                                    │
│  │ Check for ux-spec.md     │                                    │
│  │ Extract user flows       │                                    │
│  │ Map actions → endpoints  │                                    │
│  └──────────────────────────┘                                    │
│           ↓                                                      │
│  1. RESOURCES         2. OPERATIONS       3. CONTRACTS          │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐       │
│  │ Identify    │  →  │ Define CRUD │  →  │ Request/    │       │
│  │ entities    │     │ + actions   │     │ Response    │       │
│  │ & relations │     │ + methods   │     │ schemas     │       │
│  └─────────────┘     └─────────────┘     └─────────────┘       │
│                                                                  │
│  4. ERRORS            5. DOCS             6. REVIEW             │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐       │
│  │ Status codes│  →  │ OpenAPI     │  →  │ Consistency │       │
│  │ Error format│     │ Examples    │     │ Usability   │       │
│  │ Edge cases  │     │ Descriptions│     │ Security    │       │
│  └─────────────┘     └─────────────┘     └─────────────┘       │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

## UX Specification Integration

When UX specifications exist from the design phase, use them to inform API endpoint design.

**Check for design artifacts:**

```bash
# Look for UX specification in .claude/design directory
find .claude/design -name "ux-spec.md" 2>/dev/null
```

**If `.claude/design/*/ux-spec.md` exists:**

1. **Read the UX specification** — Focus on "User Flows" and "Interaction Patterns" sections
2. **Extract endpoint requirements:**
   - **User actions** → Map to HTTP methods and endpoints
   - **Data displayed** → Identify GET endpoints and response schemas
   - **State transitions** → Identify POST/PATCH/DELETE endpoints
   - **Decision points** → May need filtering, conditional logic, or aggregations
   - **Edge cases** → Map to error responses and status codes

3. **Identify resources from UX:**
   - **Nouns in flows** → Resources (cart, order, item, user, payment)
   - **Collections** → Plural endpoints (items, orders, recommendations)
   - **Relationships** → Nested resources (user's orders, cart items)

4. **Map flows to endpoints:**

```markdown
UX Flow: "User views cart → selects shipping → enters payment → confirms order"

Endpoints:
- GET /cart → View cart items and total
- GET /shipping-methods → List available shipping options
- PATCH /cart/shipping → Update selected shipping method
- POST /orders → Create order with payment
- GET /orders/{id} → Display order confirmation

UX Interaction: "User clicks +/- to update quantity"

Endpoint:
- PATCH /cart/items/{id} → Update item quantity
  Request: { "quantity": 3 }
  Response: 200 OK (updated cart)
  Errors: 400 (invalid quantity), 404 (item not found)
```

5. **Document UX integration:**

```markdown
## Design Integration

**UX Specification:** `.claude/design/checkout-flow/ux-spec.md`

### User Flow Mapping

| Flow Step | API Endpoint | Notes |
|-----------|--------------|-------|
| View cart | GET /cart | Returns items, quantities, subtotal |
| Select shipping | GET /shipping-methods | Available options with costs |
| Apply coupon | POST /cart/coupons | Validates and applies discount |
| Confirm order | POST /orders | Creates order, processes payment |
| View confirmation | GET /orders/{id} | Order details and tracking |
```

**Backward compatibility:**

If no ux-spec.md exists, the skill works normally. The UX integration step is optional and enhances endpoint design when available.

**Multiple projects:**

If multiple `.claude/design/*/ux-spec.md` files exist, ask the user which project to use or automatically select based on context from the request.

## Core Principles

### 1. Resource-Oriented Design
Design around resources (nouns), not actions (verbs).

```
✅ GET  /users/123/orders     → Get user's orders
✅ POST /orders               → Create order

❌ GET  /getUserOrders?id=123 → Action in URL
❌ POST /createOrder          → Verb in URL
```

### 2. Predictable Patterns
Consistent URL structure, response format, and behavior.

```
✅ All collections: GET /resources
✅ All items: GET /resources/{id}
✅ All creates: POST /resources
✅ All updates: PUT/PATCH /resources/{id}
✅ All deletes: DELETE /resources/{id}
```

### 3. Clear Contracts
Explicit request/response schemas, documented errors.

```
✅ Documented required fields
✅ Consistent error format
✅ Versioned endpoints
✅ OpenAPI specification
```

### 4. Developer Experience
Easy to understand, use, and debug.

```
✅ Meaningful error messages
✅ Helpful examples
✅ Logical defaults
✅ Self-documenting responses
```

## Quick Reference

### HTTP Methods

| Method | Purpose | Idempotent | Safe | Request Body |
|--------|---------|------------|------|--------------|
| GET | Read resource(s) | Yes | Yes | No |
| POST | Create resource | No | No | Yes |
| PUT | Replace resource | Yes | No | Yes |
| PATCH | Partial update | Yes* | No | Yes |
| DELETE | Remove resource | Yes | No | No |

### Common Status Codes

| Code | Meaning | Use Case |
|------|---------|----------|
| 200 | OK | Successful GET, PUT, PATCH |
| 201 | Created | Successful POST |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Validation error |
| 401 | Unauthorized | Missing/invalid auth |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource doesn't exist |
| 409 | Conflict | Duplicate, state conflict |
| 422 | Unprocessable | Semantic validation error |
| 429 | Too Many Requests | Rate limited |
| 500 | Server Error | Unexpected error |

### URL Structure

```
https://api.example.com/v1/users/123/orders?status=active&limit=10
│                       │  │     │   │      │
│                       │  │     │   │      └── Query parameters
│                       │  │     │   └── Nested resource
│                       │  │     └── Resource ID
│                       │  └── Resource collection
│                       └── API version
└── Base URL
```

## Standard Endpoints

### Collection Resource

```yaml
# List with pagination/filtering
GET /users?page=1&limit=20&status=active
Response: 200 OK
{
  "data": [...],
  "meta": { "total": 100, "page": 1, "limit": 20 }
}

# Create new
POST /users
Body: { "email": "...", "name": "..." }
Response: 201 Created
{ "id": "123", "email": "...", "name": "..." }
```

### Individual Resource

```yaml
# Get by ID
GET /users/123
Response: 200 OK
{ "id": "123", "email": "...", "name": "..." }

# Full update
PUT /users/123
Body: { "email": "...", "name": "..." }
Response: 200 OK

# Partial update
PATCH /users/123
Body: { "name": "New Name" }
Response: 200 OK

# Delete
DELETE /users/123
Response: 204 No Content
```

### Nested Resources

```yaml
# User's orders
GET /users/123/orders

# Create order for user
POST /users/123/orders

# Specific order
GET /users/123/orders/456
# Or if orders have global IDs:
GET /orders/456
```

## Standard Response Format

### Success Response

```json
{
  "data": {
    "id": "123",
    "type": "user",
    "attributes": {
      "email": "user@example.com",
      "name": "John Doe",
      "createdAt": "2024-01-15T10:30:00Z"
    },
    "relationships": {
      "orders": {
        "links": { "related": "/users/123/orders" }
      }
    }
  }
}
```

### Simpler Alternative

```json
{
  "id": "123",
  "email": "user@example.com",
  "name": "John Doe",
  "createdAt": "2024-01-15T10:30:00Z",
  "_links": {
    "self": "/users/123",
    "orders": "/users/123/orders"
  }
}
```

### Error Response

```json
{
  "error": {
    "status": 400,
    "code": "VALIDATION_ERROR",
    "message": "Invalid request data",
    "details": [
      {
        "field": "email",
        "message": "Must be a valid email address"
      },
      {
        "field": "password",
        "message": "Must be at least 8 characters"
      }
    ],
    "requestId": "req_abc123",
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```

## Design Checklist

### Preparation
- [ ] **Check for `.claude/design/*/ux-spec.md` and extract endpoint requirements**
- [ ] Map user flows to API endpoints
- [ ] Identify resources from UX nouns and collections
- [ ] Document edge cases from UX specification

### Resource Design
- [ ] Resources are nouns, not verbs
- [ ] Plural names for collections (`/users`, not `/user`)
- [ ] Consistent naming convention (kebab-case or snake_case)
- [ ] Logical nesting depth (max 2-3 levels)
- [ ] Clear relationship modeling

### Operations
- [ ] Correct HTTP methods for each operation
- [ ] Idempotent operations are actually idempotent
- [ ] Bulk operations considered where useful
- [ ] Actions use POST with clear naming

### Request/Response
- [ ] Consistent response envelope
- [ ] Meaningful field names
- [ ] ISO 8601 dates with timezone
- [ ] Pagination for lists
- [ ] Sparse fieldsets option (optional)

### Errors
- [ ] Consistent error format
- [ ] Appropriate status codes
- [ ] Helpful error messages
- [ ] Field-level validation details
- [ ] Request ID for debugging

### Documentation
- [ ] OpenAPI specification
- [ ] Request/response examples
- [ ] Authentication documented
- [ ] Rate limits documented
- [ ] Changelog maintained

### Security
- [ ] Authentication required
- [ ] Authorization checked
- [ ] Rate limiting configured
- [ ] Input validation
- [ ] No sensitive data in URLs

## Anti-Patterns

### ❌ Verbs in URLs
```
❌ POST /createUser
❌ GET /getUsers
❌ POST /users/123/delete
✅ POST /users
✅ GET /users
✅ DELETE /users/123
```

### ❌ Inconsistent Naming
```
❌ GET /users, GET /Order, GET /product-items
✅ GET /users, GET /orders, GET /product-items
```

### ❌ Overloaded POST
```
❌ POST /users { "action": "create" }
❌ POST /users { "action": "delete", "id": 123 }
✅ POST /users { ... }
✅ DELETE /users/123
```

### ❌ Wrong Status Codes
```
❌ 200 for created resource (should be 201)
❌ 200 for deleted resource (should be 204)
❌ 500 for validation error (should be 400/422)
❌ 404 for unauthorized (should be 401/403)
```

### ❌ Breaking Changes Without Versioning
```
❌ Renaming fields without version bump
❌ Removing endpoints without deprecation
❌ Changing response structure silently
✅ Use versioning: /v1/users, /v2/users
```

---

**References:**
- [references/endpoints.md](references/endpoints.md) — URL design, HTTP methods, resource modeling
- [references/requests-responses.md](references/requests-responses.md) — Request/response formats, headers, content types
- [references/status-codes.md](references/status-codes.md) — HTTP status codes, error handling patterns
- [references/pagination-filtering.md](references/pagination-filtering.md) — Pagination, filtering, sorting, searching
- [references/versioning.md](references/versioning.md) — API versioning strategies
- [references/openapi.md](references/openapi.md) — OpenAPI specification, documentation
- [references/security.md](references/security.md) — Authentication, authorization, rate limiting
- [references/ux-spec-integration.md](references/ux-spec-integration.md) — Integrating UX specifications with API design
