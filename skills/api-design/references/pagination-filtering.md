# Pagination and Filtering

Pagination, filtering, sorting, and searching patterns.

## Pagination

### Offset-Based Pagination

Simple, familiar, but has issues with large datasets.

```yaml
# Request
GET /users?page=2&limit=20
# Or
GET /users?offset=20&limit=20

# Response
{
  "data": [...],
  "meta": {
    "total": 500,
    "page": 2,
    "perPage": 20,
    "totalPages": 25
  },
  "links": {
    "first": "/users?page=1&limit=20",
    "prev": "/users?page=1&limit=20",
    "self": "/users?page=2&limit=20",
    "next": "/users?page=3&limit=20",
    "last": "/users?page=25&limit=20"
  }
}
```

**Pros:**
- Simple to implement
- Allows jumping to any page
- Shows total count

**Cons:**
- Inconsistent with real-time data (items shift)
- Slow on large datasets (OFFSET is O(n))
- Count queries can be expensive

### Cursor-Based Pagination

Better for large datasets and real-time data.

```yaml
# Request
GET /users?limit=20
GET /users?cursor=eyJpZCI6MTIzfQ&limit=20

# Response
{
  "data": [...],
  "meta": {
    "hasMore": true
  },
  "links": {
    "next": "/users?cursor=eyJpZCI6MTQzfQ&limit=20"
  },
  "cursors": {
    "next": "eyJpZCI6MTQzfQ",
    "prev": "eyJpZCI6MTIzfQ"
  }
}
```

**Cursor encoding:**
```javascript
// Cursor = base64 encoded JSON
const cursor = btoa(JSON.stringify({ id: 143, createdAt: "2024-01-15" }));
// "eyJpZCI6MTQzLCJjcmVhdGVkQXQiOiIyMDI0LTAxLTE1In0="

// Server decodes and uses for WHERE clause
const { id, createdAt } = JSON.parse(atob(cursor));
// WHERE (created_at, id) > (createdAt, id)
```

**Pros:**
- Consistent with changing data
- Efficient for large datasets
- No skipped/duplicated items

**Cons:**
- Can't jump to arbitrary page
- No total count (usually)
- More complex to implement

### Keyset Pagination

Cursor-based using the last item's values directly.

```yaml
# Request (after seeing item with id=143, created_at=2024-01-15)
GET /users?after_id=143&after_created_at=2024-01-15T10:00:00Z&limit=20

# Response
{
  "data": [...],
  "meta": {
    "hasMore": true,
    "lastId": 163,
    "lastCreatedAt": "2024-01-15T12:00:00Z"
  }
}
```

### Which Pagination to Use?

| Use Case | Recommended |
|----------|-------------|
| Small dataset (<10k) | Offset |
| Large dataset | Cursor |
| Real-time feeds | Cursor |
| Admin dashboards | Offset (with caching) |
| Mobile infinite scroll | Cursor |
| Search results | Offset (familiar UX) |

---

## Filtering

### Simple Equality Filters

```yaml
# Single value
GET /users?status=active
GET /users?role=admin

# Multiple values (OR)
GET /users?status=active,pending
GET /users?status[]=active&status[]=pending

# Multiple fields (AND)
GET /users?status=active&role=admin
```

### Comparison Operators

```yaml
# Using operator suffixes
GET /products?price_gte=100&price_lte=500
GET /orders?created_at_gte=2024-01-01

# Using brackets
GET /products?price[gte]=100&price[lte]=500
GET /orders?created_at[gte]=2024-01-01

# Operator reference
_eq   : equal (default)
_ne   : not equal
_gt   : greater than
_gte  : greater than or equal
_lt   : less than
_lte  : less than or equal
_in   : in list
_nin  : not in list
_like : pattern match
```

### Nested Field Filters

```yaml
# Dot notation
GET /users?profile.country=US
GET /orders?customer.email=john@example.com

# Bracket notation
GET /users?profile[country]=US
```

### Null Checking

```yaml
# Is null
GET /users?deleted_at=null
GET /users?avatar_url[eq]=null

# Is not null
GET /users?avatar_url[ne]=null
GET /users?has_avatar=true
```

### Filter Response

```yaml
# Include applied filters in response
{
  "data": [...],
  "meta": {
    "total": 45,
    "filters": {
      "status": "active",
      "role": "admin"
    }
  }
}
```

---

## Sorting

### Single Field Sort

```yaml
# Ascending (default)
GET /users?sort=created_at
GET /users?sort=+created_at

# Descending
GET /users?sort=-created_at
GET /users?sort=created_at:desc
GET /users?order_by=created_at&order=desc
```

### Multiple Field Sort

```yaml
# Comma-separated
GET /users?sort=-created_at,name
GET /users?sort=status:desc,name:asc

# Multiple params
GET /users?sort[]=-created_at&sort[]=name
```

### Sortable Fields

Document and validate allowed sort fields:

```yaml
# OpenAPI
paths:
  /users:
    get:
      parameters:
        - name: sort
          in: query
          schema:
            type: string
            enum: [created_at, -created_at, name, -name, email, -email]
```

### Default Sort

Always have a stable default sort (include ID for consistency):

```sql
-- Default: newest first, then by ID for stability
ORDER BY created_at DESC, id DESC
```

---

## Searching

### Simple Search

```yaml
# Full-text search
GET /users?q=john
GET /users?search=john doe

# Field-specific search
GET /users?email=*@example.com
GET /products?name=*widget*
```

### Advanced Search

```yaml
# POST for complex queries
POST /users/search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "name": "john" } }
      ],
      "filter": [
        { "term": { "status": "active" } },
        { "range": { "age": { "gte": 18 } } }
      ]
    }
  },
  "sort": [{ "created_at": "desc" }],
  "from": 0,
  "size": 20
}
```

### Search Response

```yaml
{
  "data": [...],
  "meta": {
    "total": 150,
    "query": "john",
    "took": 45,  # milliseconds
    "highlights": {
      "123": {
        "name": "<em>John</em> Doe"
      }
    }
  }
}
```

---

## Field Selection

### Sparse Fieldsets

Request only needed fields:

```yaml
# Include specific fields
GET /users?fields=id,name,email
GET /users?fields[user]=id,name,email

# Exclude fields
GET /users?exclude=password,internal_notes

# Nested fields
GET /orders?fields=id,total,customer.name,items.product.name
```

### Response

```json
// GET /users?fields=id,name
[
  { "id": "1", "name": "John" },
  { "id": "2", "name": "Jane" }
]
```

---

## Including Related Resources

### Include Parameter

```yaml
GET /orders/123?include=customer,items
GET /orders/123?include=customer,items.product

# Response
{
  "id": "123",
  "total": 99.99,
  "customer": {
    "id": "456",
    "name": "John Doe"
  },
  "items": [
    {
      "id": "789",
      "quantity": 2,
      "product": {
        "id": "prod_1",
        "name": "Widget",
        "price": 49.99
      }
    }
  ]
}
```

### Expand Parameter (Alternative)

```yaml
GET /orders/123?expand=customer
GET /orders?expand=customer,items.product
```

### JSON:API Style

```json
{
  "data": {
    "id": "123",
    "type": "order",
    "attributes": { "total": 99.99 },
    "relationships": {
      "customer": { "data": { "type": "user", "id": "456" } }
    }
  },
  "included": [
    {
      "id": "456",
      "type": "user",
      "attributes": { "name": "John Doe" }
    }
  ]
}
```

---

## Combined Example

### Complex Query

```yaml
GET /orders
  ?status=completed
  &customer.type=premium
  &total_gte=100
  &created_at_gte=2024-01-01
  &sort=-created_at
  &fields=id,total,customer.name
  &include=items
  &page=1
  &limit=20
```

### Response

```json
{
  "data": [
    {
      "id": "ord_123",
      "total": 250.00,
      "customer": {
        "name": "John Doe"
      },
      "items": [
        { "id": "item_1", "product": "Widget", "quantity": 5 }
      ]
    }
  ],
  "meta": {
    "total": 45,
    "page": 1,
    "perPage": 20,
    "totalPages": 3,
    "filters": {
      "status": "completed",
      "customer.type": "premium",
      "total_gte": 100,
      "created_at_gte": "2024-01-01"
    },
    "sort": "-created_at"
  },
  "links": {
    "self": "/orders?...",
    "next": "/orders?...&page=2"
  }
}
```

---

## Best Practices

### Defaults

```yaml
# Always have sensible defaults
limit: 20 (max: 100)
page: 1
sort: -created_at

# Document defaults in API docs
```

### Limits

```yaml
# Enforce maximum limits
GET /users?limit=1000
→ Returns max 100, with warning header

# Response header
X-Max-Limit: 100
```

### Performance Considerations

```yaml
# Expensive operations
- Counting total (especially with filters)
- Deep pagination (page > 100)
- Complex sorts on non-indexed fields
- Including too many relations

# Solutions
- Use cursor pagination for large sets
- Return estimate instead of exact count
- Limit includable relations
- Cache count queries
```

### Consistent Parameter Names

Pick one convention and stick with it:

```yaml
# Pagination
page/per_page OR offset/limit OR cursor/limit

# Sorting
sort OR order_by OR sortBy

# Filtering
field=value OR filter[field]=value

# Searching
q OR search OR query
```

---

## Query String Length

For very complex queries that exceed URL length limits:

```yaml
# POST to search endpoint
POST /orders/search
Content-Type: application/json
{
  "filters": {
    "status": ["completed", "shipped"],
    "customer": {
      "type": "premium",
      "country": ["US", "CA", "GB"]
    },
    "total": { "gte": 100, "lte": 1000 },
    "created_at": { "gte": "2024-01-01" }
  },
  "sort": ["-created_at", "id"],
  "fields": ["id", "total", "customer.name"],
  "include": ["items", "items.product"],
  "pagination": {
    "page": 1,
    "limit": 20
  }
}
```
