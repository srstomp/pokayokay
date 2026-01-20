# API Versioning

Versioning strategies and migration patterns.

## Why Version?

APIs evolve. Versioning lets you:
- Make breaking changes without breaking clients
- Support multiple versions during migration
- Communicate changes clearly
- Deprecate old versions gracefully

---

## Versioning Strategies

### URL Path Versioning

Version in the URL path.

```
https://api.example.com/v1/users
https://api.example.com/v2/users
```

**Pros:**
- Very explicit and visible
- Easy to test in browser
- Clear routing
- Cacheable per version

**Cons:**
- URL changes between versions
- Can't version individual resources
- Clutters URL structure

**Implementation:**
```javascript
// Express
app.use('/v1', v1Router);
app.use('/v2', v2Router);

// Or with version middleware
app.use('/api/:version', (req, res, next) => {
  req.apiVersion = req.params.version;
  next();
});
```

### Header Versioning

Version in request header.

```http
GET /users HTTP/1.1
Host: api.example.com
Accept: application/json
API-Version: 2024-01-15
```

**Pros:**
- Clean URLs
- Can version per-request
- More RESTful (URL = resource)

**Cons:**
- Hidden, harder to test
- Can't test in browser easily
- Must document header requirement

**Implementation:**
```javascript
app.use((req, res, next) => {
  req.apiVersion = req.get('API-Version') || '2024-01-15';
  next();
});
```

### Accept Header Versioning

Version via content negotiation.

```http
GET /users HTTP/1.1
Accept: application/vnd.myapi.v2+json
```

**Pros:**
- Follows HTTP content negotiation
- Semantically correct
- Flexible format specification

**Cons:**
- Complex Accept headers
- Less discoverable
- Harder for non-technical users

**Implementation:**
```javascript
app.use((req, res, next) => {
  const accept = req.get('Accept') || '';
  const match = accept.match(/application\/vnd\.myapi\.(v\d+)\+json/);
  req.apiVersion = match ? match[1] : 'v1';
  next();
});
```

### Query Parameter Versioning

Version as query parameter.

```
https://api.example.com/users?version=2
https://api.example.com/users?api-version=2024-01-15
```

**Pros:**
- Easy to test
- Optional parameter
- Works everywhere

**Cons:**
- Pollutes query string
- Easy to forget
- Can conflict with resource params

### Which Strategy to Choose?

| Factor | URL Path | Header | Accept | Query |
|--------|----------|--------|--------|-------|
| Visibility | High | Low | Low | Medium |
| Testability | Easy | Hard | Hard | Easy |
| RESTfulness | Low | High | High | Low |
| Caching | Easy | Complex | Complex | Easy |
| Adoption | Most common | Growing | Rare | Occasional |

**Recommendation:** URL path versioning for most APIs. It's explicit, easy to understand, and widely adopted.

---

## Version Numbering

### Integer Versions

Simple major version only.

```
/v1/users
/v2/users
/v3/users
```

**When to increment:**
- Breaking changes only
- Typically rare (yearly or less)

### Date-Based Versions

Use release date.

```
API-Version: 2024-01-15
API-Version: 2024-06-01
```

**Pros:**
- Clear timeline
- No "what's in v2" questions
- Encourages regular releases

**Used by:** Stripe, Twilio

### Semantic Versioning

Full semver (rare for APIs).

```
/v1.2.3/users
```

**Rarely used** because:
- Minor/patch changes shouldn't require version in URL
- Too granular for clients to track

---

## What's a Breaking Change?

### Breaking Changes (Require New Version)

```yaml
# Removing endpoint
DELETE /v1/legacy-endpoint  # Was available, now gone

# Removing field from response
# v1: { "id": "123", "name": "John", "email": "..." }
# v2: { "id": "123", "name": "John" }  # email removed

# Renaming field
# v1: { "user_name": "john" }
# v2: { "username": "john" }

# Changing field type
# v1: { "id": 123 }        # number
# v2: { "id": "123" }      # string

# Adding required field to request
# v1: POST { "name": "John" }
# v2: POST { "name": "John", "email": "..." }  # email now required

# Changing URL structure
# v1: /users/123/orders
# v2: /orders?user_id=123

# Changing authentication
# v1: API key in header
# v2: OAuth required

# Changing error codes/format
# v1: { "error": "Not found" }
# v2: { "error": { "code": "NOT_FOUND", "message": "..." } }
```

### Non-Breaking Changes (No New Version)

```yaml
# Adding optional field to request
POST { "name": "John", "nickname": "Johnny" }  # nickname optional

# Adding field to response
{ "id": "123", "name": "John", "createdAt": "..." }  # new field

# Adding new endpoint
GET /v1/new-feature

# Adding optional query parameter
GET /users?include=profile  # new option

# Relaxing validation
# Was: password min 12 chars
# Now: password min 8 chars

# Adding new enum value (if client handles unknown values)
status: "active" | "inactive" | "pending"  # pending is new

# Bug fixes
# Fixing incorrect behavior

# Performance improvements
```

---

## Version Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│                    VERSION LIFECYCLE                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  CURRENT        DEPRECATED        SUNSET          REMOVED   │
│  ┌────────┐    ┌────────────┐    ┌────────┐     ┌────────┐ │
│  │  v3    │    │    v2      │    │  v1    │     │  v0    │ │
│  │        │ →  │ +warnings  │ →  │readonly│  →  │  gone  │ │
│  │ active │    │ +deadline  │    │ +errors│     │        │ │
│  └────────┘    └────────────┘    └────────┘     └────────┘ │
│                                                             │
│  Timeline: 0      6 months      12 months      18 months   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Deprecation Headers

```http
# Deprecated version
HTTP/1.1 200 OK
Deprecation: true
Sunset: Sat, 01 Jun 2025 00:00:00 GMT
Link: <https://docs.api.com/migration/v2-to-v3>; rel="deprecation"

# Response body warning
{
  "data": {...},
  "warnings": [
    {
      "code": "DEPRECATED_VERSION",
      "message": "API v2 is deprecated. Please migrate to v3 by June 2025.",
      "link": "https://docs.api.com/migration/v2-to-v3"
    }
  ]
}
```

### Sunset Response

```http
# After sunset date
HTTP/1.1 410 Gone
{
  "error": {
    "code": "VERSION_SUNSET",
    "message": "API v1 is no longer available. Please use v3.",
    "documentation": "https://docs.api.com/migration/v1-to-v3"
  }
}
```

---

## Migration Strategies

### Parallel Running

Run both versions simultaneously.

```
v1 → Database ← v2
```

**Implementation:**
```javascript
// Both versions use same data
// Controllers handle version-specific logic

// v1 controller
function getUserV1(id) {
  const user = await db.getUser(id);
  return {
    user_name: user.username,  // Old field name
    email: user.email,
  };
}

// v2 controller
function getUserV2(id) {
  const user = await db.getUser(id);
  return {
    username: user.username,   // New field name
    email: user.email,
    createdAt: user.createdAt, // New field
  };
}
```

### Transformation Layer

Single source, transform at edges.

```javascript
// Internal representation
const internalUser = {
  username: 'john',
  email: 'john@example.com',
  createdAt: new Date(),
};

// Version transformers
const transformers = {
  v1: (user) => ({
    user_name: user.username,
    email: user.email,
  }),
  v2: (user) => ({
    username: user.username,
    email: user.email,
    createdAt: user.createdAt.toISOString(),
  }),
};

// Middleware applies version transform
app.use((req, res, next) => {
  const originalJson = res.json.bind(res);
  res.json = (data) => {
    const transformer = transformers[req.apiVersion];
    return originalJson(transformer ? transformer(data) : data);
  };
  next();
});
```

### Feature Flags

Control features per version.

```javascript
const versionFeatures = {
  v1: {
    includeCreatedAt: false,
    useNewErrorFormat: false,
    allowBulkOperations: false,
  },
  v2: {
    includeCreatedAt: true,
    useNewErrorFormat: true,
    allowBulkOperations: true,
  },
};

function getUser(id, version) {
  const user = await db.getUser(id);
  const features = versionFeatures[version];
  
  const response = {
    id: user.id,
    username: user.username,
  };
  
  if (features.includeCreatedAt) {
    response.createdAt = user.createdAt;
  }
  
  return response;
}
```

---

## Version Documentation

### Changelog

```markdown
# API Changelog

## v3 (2024-06-01)

### Breaking Changes
- Renamed `user_name` to `username` in all responses
- Removed deprecated `/legacy/users` endpoint
- Changed error response format (see migration guide)

### New Features
- Added bulk operations for all resources
- Added `createdAt` field to all responses
- Added cursor-based pagination

### Migration Guide
See [v2 to v3 Migration Guide](/docs/migration/v2-to-v3)

## v2 (2023-01-15)

### Breaking Changes
- Authentication now requires OAuth 2.0
- Removed API key authentication

### New Features
- Added rate limiting headers
- Added webhook support
```

### Version Matrix

```markdown
| Version | Status | Sunset Date | Notes |
|---------|--------|-------------|-------|
| v3 | Current | - | Latest version |
| v2 | Deprecated | 2025-06-01 | Migrate to v3 |
| v1 | Sunset | 2024-01-01 | No longer available |
```

---

## Best Practices

### 1. Minimize Breaking Changes

```yaml
# Instead of removing field
✅ Add new field, deprecate old, remove later
- v1: { "user_name": "john" }
- v2: { "user_name": "john", "username": "john" }  # Both
- v3: { "username": "john" }  # Old removed

# Instead of changing type
✅ Add new field with new type
- v1: { "id": 123 }
- v2: { "id": 123, "uuid": "abc-123" }
- v3: { "uuid": "abc-123" }
```

### 2. Version From Day One

```yaml
# Start with versioned URLs
✅ /v1/users  # From the start
❌ /users     # Then later /v1/users
```

### 3. Communicate Early and Often

```yaml
# Announce deprecation with plenty of notice
- 6+ months before sunset
- Email to API users
- Dashboard warnings
- Response headers
```

### 4. Provide Migration Tools

```yaml
# Help users migrate
- Detailed migration guides
- Code examples in multiple languages
- Comparison of old vs new
- Test environments for new version
```

### 5. Support Multiple Versions (Temporarily)

```yaml
# Reasonable overlap period
- Current version: full support
- Previous version: 12-18 months support
- Older versions: sunset
```

### 6. Version Entire API, Not Resources

```yaml
# Consistent versioning
✅ /v1/users, /v1/orders  # All v1
✅ /v2/users, /v2/orders  # All v2
❌ /v1/users, /v2/orders  # Mixed versions
```
