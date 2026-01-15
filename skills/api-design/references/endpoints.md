# Endpoints

URL design, HTTP methods, and resource modeling.

## URL Structure

### Base URL

```
https://api.example.com/v1
│       │              │
│       │              └── Version prefix
│       └── API subdomain (recommended)
└── HTTPS always
```

**Options:**
```
https://api.example.com/v1      # Subdomain (recommended)
https://example.com/api/v1      # Path-based
https://api.example.com         # No version in URL (use headers)
```

### Resource Paths

```
/users                          # Collection
/users/123                      # Specific item
/users/123/orders               # Nested collection
/users/123/orders/456           # Nested item
/users/123/profile              # Singleton (1:1 relation)
```

### Naming Conventions

```
✅ Plural nouns for collections
   /users, /orders, /products

✅ Lowercase with hyphens (kebab-case)
   /order-items, /user-profiles

✅ Or lowercase with underscores (snake_case)
   /order_items, /user_profiles

❌ Never mix conventions
   /order-items, /user_profiles  # Inconsistent!

❌ No verbs in resource names
   /getUsers, /createOrder
```

### Resource Hierarchy

```
# Good: Logical nesting (max 2-3 levels)
/users/123/orders
/orders/456/items

# Avoid: Deep nesting
/users/123/orders/456/items/789/reviews  # Too deep!

# Better: Flatten with query or direct access
/reviews?order_item_id=789
/order-items/789/reviews
```

---

## HTTP Methods

### GET - Read

```yaml
# List collection
GET /users
GET /users?status=active&limit=10
Response: 200 OK

# Get single resource
GET /users/123
Response: 200 OK | 404 Not Found

# Get nested resource
GET /users/123/orders
Response: 200 OK

# Get singleton
GET /users/123/profile
Response: 200 OK | 404 Not Found
```

**Rules:**
- Never modify data
- Always safe and idempotent
- No request body
- Cacheable

### POST - Create

```yaml
# Create in collection
POST /users
Body: { "email": "new@example.com", "name": "New User" }
Response: 201 Created
Headers: Location: /users/124

# Create nested resource
POST /users/123/orders
Body: { "product_id": "456", "quantity": 2 }
Response: 201 Created

# Trigger action (when no other method fits)
POST /users/123/send-verification
Body: {} or { "method": "email" }
Response: 202 Accepted | 204 No Content
```

**Rules:**
- Creates new resource
- Not idempotent (multiple calls create multiple resources)
- Returns created resource (recommended)
- Returns `Location` header with new resource URL

### PUT - Replace

```yaml
# Replace entire resource
PUT /users/123
Body: { "email": "updated@example.com", "name": "Updated Name", "role": "admin" }
Response: 200 OK

# Create if not exists (optional, controversial)
PUT /users/123
Response: 201 Created (if didn't exist) | 200 OK (if updated)
```

**Rules:**
- Replaces entire resource
- Must include all required fields
- Idempotent (same request = same result)
- Resource ID in URL, not body

### PATCH - Partial Update

```yaml
# Update specific fields
PATCH /users/123
Body: { "name": "New Name" }
Response: 200 OK

# JSON Patch format (RFC 6902)
PATCH /users/123
Content-Type: application/json-patch+json
Body: [
  { "op": "replace", "path": "/name", "value": "New Name" },
  { "op": "add", "path": "/tags/-", "value": "premium" }
]
Response: 200 OK

# JSON Merge Patch (RFC 7396) - simpler
PATCH /users/123
Content-Type: application/merge-patch+json
Body: { "name": "New Name", "tags": null }  # null removes field
Response: 200 OK
```

**Rules:**
- Updates only provided fields
- Idempotent when implemented correctly
- Less common: atomic field operations

### DELETE - Remove

```yaml
# Delete resource
DELETE /users/123
Response: 204 No Content | 200 OK (with body)

# Idempotent: deleting non-existent
DELETE /users/999
Response: 204 No Content | 404 Not Found  # Both are valid approaches

# Soft delete (if supported)
DELETE /users/123
Response: 200 OK { "id": "123", "deletedAt": "..." }
```

**Rules:**
- Removes resource
- Idempotent (deleting twice = same result)
- Usually no request body
- 204 (no body) or 200 (with confirmation)

---

## Resource Modeling

### Identify Resources

```
Business entities → API resources

User          → /users
Product       → /products
Order         → /orders
Order Item    → /orders/{id}/items or /order-items
Review        → /reviews or /products/{id}/reviews
```

### Model Relationships

#### One-to-Many

```yaml
# User has many orders
GET /users/123/orders        # Orders for user
POST /users/123/orders       # Create order for user

# Alternative: query parameter
GET /orders?user_id=123
```

#### Many-to-Many

```yaml
# Users and roles (many-to-many)
GET /users/123/roles         # User's roles
POST /users/123/roles        # Add role to user
Body: { "role_id": "456" }
DELETE /users/123/roles/456  # Remove role

# Or via junction resource
GET /user-roles?user_id=123
POST /user-roles
Body: { "user_id": "123", "role_id": "456" }
```

#### One-to-One

```yaml
# User has one profile (singleton)
GET /users/123/profile       # Get profile (not /profiles)
PUT /users/123/profile       # Create or update
PATCH /users/123/profile     # Partial update
DELETE /users/123/profile    # Remove profile
```

### Resource vs. Attribute

```yaml
# As nested resource (if complex, has own lifecycle)
GET /users/123/address
PUT /users/123/address

# As attribute (if simple, always with parent)
GET /users/123
Response: { "id": "123", "address": { "street": "...", "city": "..." } }

PATCH /users/123
Body: { "address": { "city": "New City" } }
```

---

## Actions and Non-CRUD Operations

### Resource Actions

When an operation doesn't map to CRUD, use POST with action name:

```yaml
# Send email
POST /users/123/send-verification-email
Response: 202 Accepted

# Archive (state change)
POST /orders/456/archive
Response: 200 OK

# Cancel with reason
POST /orders/456/cancel
Body: { "reason": "Customer request" }
Response: 200 OK

# Bulk action
POST /orders/bulk-archive
Body: { "ids": ["123", "456", "789"] }
Response: 200 OK
```

### Controller Resources

For operations that don't fit a resource:

```yaml
# Search (complex query)
POST /search
Body: { "query": "...", "filters": {...} }
Response: 200 OK

# Convert (stateless operation)
POST /convert/currency
Body: { "from": "USD", "to": "EUR", "amount": 100 }
Response: 200 OK { "result": 92.50 }

# Validate (without saving)
POST /validate/email
Body: { "email": "test@example.com" }
Response: 200 OK { "valid": true, "disposable": false }
```

---

## Bulk Operations

### Bulk Create

```yaml
POST /users/bulk
Body: {
  "items": [
    { "email": "user1@example.com", "name": "User 1" },
    { "email": "user2@example.com", "name": "User 2" }
  ]
}
Response: 201 Created
{
  "created": [
    { "id": "1", "email": "user1@example.com" },
    { "id": "2", "email": "user2@example.com" }
  ],
  "failed": []
}
```

### Bulk Update

```yaml
PATCH /users/bulk
Body: {
  "items": [
    { "id": "1", "name": "Updated 1" },
    { "id": "2", "name": "Updated 2" }
  ]
}
Response: 200 OK

# Or: update by filter
PATCH /users?status=inactive
Body: { "status": "archived" }
Response: 200 OK { "updated": 45 }
```

### Bulk Delete

```yaml
DELETE /users/bulk
Body: { "ids": ["1", "2", "3"] }
Response: 204 No Content

# Or via query (careful with this!)
DELETE /users?status=inactive
Response: 200 OK { "deleted": 45 }
```

### Partial Success Handling

```yaml
POST /users/bulk
Response: 207 Multi-Status
{
  "results": [
    { "status": 201, "data": { "id": "1", ... } },
    { "status": 400, "error": { "message": "Invalid email" } },
    { "status": 201, "data": { "id": "3", ... } }
  ],
  "summary": { "succeeded": 2, "failed": 1 }
}
```

---

## URL Design Patterns

### Query Parameters

```yaml
# Filtering
GET /users?status=active&role=admin

# Pagination
GET /users?page=2&limit=20
GET /users?cursor=abc123&limit=20

# Sorting
GET /users?sort=created_at:desc
GET /users?sort=-created_at  # Prefix convention

# Field selection
GET /users?fields=id,name,email

# Including relations
GET /users?include=orders,profile

# Search
GET /users?q=john
GET /users?search=john@example
```

### Path vs Query Parameters

```yaml
# Path: required identifiers
GET /users/123           # User ID is required
GET /orders/456/items    # Order ID is required

# Query: optional filters/modifiers
GET /users?role=admin    # Role is optional filter
GET /orders?status=open  # Status is optional filter
```

### Avoid Query String Overload

```yaml
# ❌ Too much in query string
GET /reports?type=sales&start=2024-01-01&end=2024-12-31&group=monthly&metrics=revenue,orders&breakdown=region,category

# ✅ Use POST for complex queries
POST /reports/generate
Body: {
  "type": "sales",
  "dateRange": { "start": "2024-01-01", "end": "2024-12-31" },
  "groupBy": "monthly",
  "metrics": ["revenue", "orders"],
  "breakdown": ["region", "category"]
}
```

---

## Endpoint Naming Examples

### E-commerce API

```yaml
# Products
GET    /products
GET    /products/{id}
POST   /products
PUT    /products/{id}
DELETE /products/{id}
GET    /products/{id}/reviews
POST   /products/{id}/reviews

# Categories
GET    /categories
GET    /categories/{id}
GET    /categories/{id}/products

# Cart
GET    /cart                    # Current user's cart
POST   /cart/items              # Add item
PATCH  /cart/items/{id}         # Update quantity
DELETE /cart/items/{id}         # Remove item
DELETE /cart                    # Clear cart

# Orders
GET    /orders
GET    /orders/{id}
POST   /orders                  # Create from cart
POST   /orders/{id}/cancel
GET    /orders/{id}/tracking

# User
GET    /users/me                # Current user
PATCH  /users/me
GET    /users/me/orders
GET    /users/me/addresses
```

### SaaS API

```yaml
# Organizations (multi-tenant)
GET    /organizations
GET    /organizations/{id}
POST   /organizations
PATCH  /organizations/{id}

# Members
GET    /organizations/{id}/members
POST   /organizations/{id}/members/invite
DELETE /organizations/{id}/members/{user_id}
PATCH  /organizations/{id}/members/{user_id}  # Update role

# Projects
GET    /projects
GET    /projects/{id}
POST   /projects
PATCH  /projects/{id}
DELETE /projects/{id}
POST   /projects/{id}/archive

# Resources scoped to project
GET    /projects/{id}/tasks
GET    /projects/{id}/files
GET    /projects/{id}/settings
```

### Social API

```yaml
# Users
GET    /users/{id}
GET    /users/{id}/posts
GET    /users/{id}/followers
GET    /users/{id}/following

# Posts
GET    /posts
GET    /posts/{id}
POST   /posts
PATCH  /posts/{id}
DELETE /posts/{id}
POST   /posts/{id}/like
DELETE /posts/{id}/like
GET    /posts/{id}/comments
POST   /posts/{id}/comments

# Feed
GET    /feed                    # Current user's feed
GET    /feed/trending

# Relationships
POST   /users/{id}/follow
DELETE /users/{id}/follow
```
