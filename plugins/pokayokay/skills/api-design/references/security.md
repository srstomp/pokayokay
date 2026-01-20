# Security

Authentication, authorization, and rate limiting.

## Authentication Methods

### API Keys

Simple key-based authentication.

```http
# Header (recommended)
GET /users HTTP/1.1
X-API-Key: sk_live_abc123xyz

# Query parameter (less secure)
GET /users?api_key=sk_live_abc123xyz
```

**Key Format:**
```
sk_live_abc123xyz   # Live/production
sk_test_abc123xyz   # Test/sandbox
pk_live_abc123xyz   # Publishable (client-side)
```

**Pros:**
- Simple to implement
- Easy for developers
- No expiration handling

**Cons:**
- No built-in expiration
- Hard to rotate
- Can't carry user identity

**Best for:** Server-to-server, simple integrations

### Bearer Tokens (JWT)

Token-based authentication with JSON Web Tokens.

```http
GET /users HTTP/1.1
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

**JWT Structure:**
```javascript
// Header
{
  "alg": "RS256",
  "typ": "JWT"
}

// Payload
{
  "sub": "user_123",           // Subject (user ID)
  "iss": "https://api.example.com",  // Issuer
  "aud": "https://api.example.com",  // Audience
  "exp": 1705835000,           // Expiration
  "iat": 1705831400,           // Issued at
  "scope": "read:users write:users"
}

// Signature
RSASHA256(base64(header) + "." + base64(payload), privateKey)
```

**Token Response:**
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "rt_abc123xyz",
  "scope": "read:users write:users"
}
```

**Pros:**
- Stateless verification
- Carries claims (user info, permissions)
- Expiration built-in

**Cons:**
- Can't revoke individual tokens (without blacklist)
- Token size can be large
- Must handle expiration/refresh

### OAuth 2.0

Industry-standard authorization framework.

```yaml
# Authorization Code Flow (web apps)
1. Redirect to authorization server
   GET /authorize?
     response_type=code&
     client_id=CLIENT_ID&
     redirect_uri=CALLBACK_URL&
     scope=read:users&
     state=RANDOM_STATE

2. User authenticates and consents

3. Callback with authorization code
   GET /callback?code=AUTH_CODE&state=RANDOM_STATE

4. Exchange code for tokens
   POST /token
   Content-Type: application/x-www-form-urlencoded
   
   grant_type=authorization_code&
   code=AUTH_CODE&
   redirect_uri=CALLBACK_URL&
   client_id=CLIENT_ID&
   client_secret=CLIENT_SECRET

5. Use access token
   GET /api/users
   Authorization: Bearer ACCESS_TOKEN
```

**Grant Types:**

| Grant Type | Use Case |
|------------|----------|
| Authorization Code | Web apps with backend |
| Authorization Code + PKCE | SPAs, mobile apps |
| Client Credentials | Server-to-server |
| Refresh Token | Get new access token |

**Scopes:**
```
read:users      Read user data
write:users     Create/update users
delete:users    Delete users
admin           Full administrative access
```

### Basic Authentication

HTTP Basic Auth (simple but limited).

```http
GET /users HTTP/1.1
Authorization: Basic dXNlcm5hbWU6cGFzc3dvcmQ=
# Base64 encoded "username:password"
```

**Only use for:**
- Internal APIs
- Development/testing
- When combined with HTTPS

---

## Authorization

### Role-Based Access Control (RBAC)

```yaml
# Define roles
roles:
  admin:
    - users:read
    - users:write
    - users:delete
    - orders:*
  manager:
    - users:read
    - orders:read
    - orders:write
  user:
    - users:read:own
    - orders:read:own
    - orders:write:own
```

**Check in API:**
```javascript
function requirePermission(permission) {
  return (req, res, next) => {
    const userPermissions = getUserPermissions(req.user);
    
    if (!userPermissions.includes(permission)) {
      return res.status(403).json({
        error: {
          code: 'FORBIDDEN',
          message: `Permission "${permission}" required`,
        },
      });
    }
    
    next();
  };
}

// Usage
app.delete('/users/:id', 
  authenticate,
  requirePermission('users:delete'),
  deleteUser
);
```

### Attribute-Based Access Control (ABAC)

```javascript
// Check based on resource attributes
function canAccessOrder(user, order) {
  // Admin can access all
  if (user.role === 'admin') return true;
  
  // User can access own orders
  if (order.userId === user.id) return true;
  
  // Manager can access orders from their team
  if (user.role === 'manager' && order.teamId === user.teamId) return true;
  
  return false;
}

app.get('/orders/:id', authenticate, async (req, res) => {
  const order = await getOrder(req.params.id);
  
  if (!canAccessOrder(req.user, order)) {
    return res.status(403).json({
      error: { code: 'FORBIDDEN', message: 'Access denied' }
    });
  }
  
  res.json(order);
});
```

### Resource Ownership

```javascript
// Middleware to check ownership
function requireOwnership(resourceGetter) {
  return async (req, res, next) => {
    const resource = await resourceGetter(req);
    
    if (!resource) {
      return res.status(404).json({
        error: { code: 'NOT_FOUND', message: 'Resource not found' }
      });
    }
    
    // Admin bypasses ownership check
    if (req.user.role === 'admin') {
      req.resource = resource;
      return next();
    }
    
    // Check ownership
    if (resource.userId !== req.user.id) {
      return res.status(403).json({
        error: { code: 'FORBIDDEN', message: 'Access denied' }
      });
    }
    
    req.resource = resource;
    next();
  };
}

// Usage
app.get('/orders/:id',
  authenticate,
  requireOwnership((req) => getOrder(req.params.id)),
  (req, res) => res.json(req.resource)
);
```

---

## Rate Limiting

### Response Headers

```http
HTTP/1.1 200 OK
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1705835000
X-RateLimit-Policy: 1000;w=3600
```

### Rate Limit Exceeded

```http
HTTP/1.1 429 Too Many Requests
Retry-After: 60
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1705835000

{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Rate limit exceeded. Try again in 60 seconds.",
    "retryAfter": 60
  }
}
```

### Rate Limit Strategies

```yaml
# Per API key
1000 requests per hour per API key

# Per endpoint
POST /users: 10 per minute
GET /users: 100 per minute

# Per user tier
Free: 100/hour
Pro: 1000/hour
Enterprise: 10000/hour

# Sliding window
100 requests per minute (rolling window)

# Token bucket
Refill 10 tokens/second, max 100 tokens
Each request costs 1 token
```

### Implementation Example

```javascript
const rateLimit = require('express-rate-limit');
const RedisStore = require('rate-limit-redis');

// Basic rate limiter
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    res.status(429).json({
      error: {
        code: 'RATE_LIMIT_EXCEEDED',
        message: 'Too many requests',
        retryAfter: Math.ceil(req.rateLimit.resetTime / 1000),
      },
    });
  },
});

// Different limits for different endpoints
const createLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  keyGenerator: (req) => req.user?.id || req.ip,
});

app.use('/api', limiter);
app.post('/api/users', createLimiter, createUser);
```

---

## Security Best Practices

### HTTPS Only

```yaml
# Enforce HTTPS
- Redirect HTTP to HTTPS
- Use HSTS header
- Never accept credentials over HTTP

# HSTS header
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
```

### Sensitive Data

```yaml
# Never in URLs
❌ GET /users?api_key=secret
❌ GET /auth/reset?token=secret

# Never in logs
✅ Mask API keys: sk_live_***abc
✅ Never log passwords or tokens

# Never in error messages
❌ "Invalid password 'abc123'"
✅ "Invalid credentials"
```

### Input Validation

```javascript
// Validate all inputs
const { z } = require('zod');

const CreateUserSchema = z.object({
  email: z.string().email().max(255),
  name: z.string().min(1).max(100),
  password: z.string().min(8).max(128),
});

app.post('/users', (req, res) => {
  const result = CreateUserSchema.safeParse(req.body);
  
  if (!result.success) {
    return res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        details: result.error.issues,
      },
    });
  }
  
  // Proceed with validated data
  createUser(result.data);
});
```

### CORS Configuration

```javascript
const cors = require('cors');

// Strict CORS
app.use(cors({
  origin: ['https://app.example.com', 'https://admin.example.com'],
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  maxAge: 86400,
}));

// For public APIs
app.use(cors({
  origin: '*',
  methods: ['GET'],
}));
```

### Security Headers

```http
# Recommended headers
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Cache-Control: no-store
Pragma: no-cache
```

```javascript
const helmet = require('helmet');
app.use(helmet());
```

### Token Security

```yaml
# Access tokens
- Short-lived (15 min - 1 hour)
- JWT or opaque
- Include minimal claims

# Refresh tokens
- Long-lived (days - weeks)
- Stored securely (httpOnly cookie or secure storage)
- Rotate on use
- Revocable

# API keys
- Long-lived but rotatable
- Scoped to specific permissions
- Unique per integration
```

### Secure Token Refresh

```javascript
// Refresh token endpoint
app.post('/auth/refresh', async (req, res) => {
  const { refreshToken } = req.body;
  
  // Validate refresh token
  const tokenData = await validateRefreshToken(refreshToken);
  if (!tokenData) {
    return res.status(401).json({
      error: { code: 'INVALID_TOKEN', message: 'Invalid refresh token' }
    });
  }
  
  // Revoke old refresh token (rotation)
  await revokeRefreshToken(refreshToken);
  
  // Issue new tokens
  const accessToken = generateAccessToken(tokenData.userId);
  const newRefreshToken = await generateRefreshToken(tokenData.userId);
  
  res.json({
    access_token: accessToken,
    refresh_token: newRefreshToken,
    expires_in: 3600,
  });
});
```

---

## API Key Management

### Key Generation

```javascript
const crypto = require('crypto');

function generateApiKey(prefix = 'sk') {
  const key = crypto.randomBytes(24).toString('base64url');
  return `${prefix}_${key}`;
}

// sk_abc123xyz... (32+ characters)
```

### Key Storage

```javascript
// Never store plain API keys
// Store hash, return key only on creation

const bcrypt = require('bcrypt');

async function createApiKey(userId) {
  const key = generateApiKey('sk');
  const hash = await bcrypt.hash(key, 10);
  
  await db.apiKeys.create({
    userId,
    keyHash: hash,
    prefix: key.slice(0, 7),  // For identification
    lastUsed: null,
    createdAt: new Date(),
  });
  
  // Return plain key only once
  return { key, prefix: key.slice(0, 7) };
}

async function validateApiKey(key) {
  const prefix = key.slice(0, 7);
  const apiKey = await db.apiKeys.findByPrefix(prefix);
  
  if (!apiKey) return null;
  
  const valid = await bcrypt.compare(key, apiKey.keyHash);
  if (!valid) return null;
  
  // Update last used
  await db.apiKeys.updateLastUsed(apiKey.id);
  
  return apiKey;
}
```

### Key Rotation

```yaml
# Allow multiple active keys per user
# Overlap period for rotation

1. Create new key
2. Update integrations to use new key
3. Verify new key works
4. Revoke old key

# API endpoints
POST /api-keys           # Create new key
GET /api-keys            # List keys (prefix only)
DELETE /api-keys/{id}    # Revoke key
```

---

## Error Responses for Security

### Authentication Errors

```json
// 401 Unauthorized - Missing auth
{
  "error": {
    "status": 401,
    "code": "UNAUTHORIZED",
    "message": "Authentication required"
  }
}

// 401 Unauthorized - Invalid credentials
{
  "error": {
    "status": 401,
    "code": "INVALID_CREDENTIALS",
    "message": "Invalid email or password"
  }
}

// 401 Unauthorized - Expired token
{
  "error": {
    "status": 401,
    "code": "TOKEN_EXPIRED",
    "message": "Access token has expired"
  }
}
```

### Authorization Errors

```json
// 403 Forbidden - No permission
{
  "error": {
    "status": 403,
    "code": "FORBIDDEN",
    "message": "You don't have permission to access this resource"
  }
}

// 403 Forbidden - Specific permission missing
{
  "error": {
    "status": 403,
    "code": "INSUFFICIENT_PERMISSIONS",
    "message": "This action requires 'users:delete' permission"
  }
}
```

### Security Considerations

```yaml
# Don't reveal existence
❌ "User admin@example.com not found"
✅ "Invalid email or password"

# Don't reveal implementation
❌ "JWT signature verification failed"
✅ "Invalid token"

# Consistent timing
- Use constant-time comparison for secrets
- Same response time for valid/invalid credentials
```
