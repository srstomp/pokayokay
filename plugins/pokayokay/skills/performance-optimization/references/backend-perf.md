# Backend Performance

Detailed guide to backend optimization: database queries, caching, and async patterns.

## Database Query Optimization

### Index Strategy

**Index types and use cases:**

| Index Type | Use Case | Example |
|------------|----------|---------|
| B-tree (default) | Equality, range queries | `WHERE status = 'active'` |
| Hash | Equality only | `WHERE id = 123` (PostgreSQL) |
| GIN | Full-text, JSONB, arrays | `WHERE tags @> '{urgent}'` |
| GiST | Geometric, range types | Spatial queries |
| BRIN | Large sequential data | Time-series tables |

**Composite index column order:**

```sql
-- Query: WHERE tenant_id = ? AND created_at > ? ORDER BY created_at
-- ✅ Good: Most selective first, matches query order
CREATE INDEX idx_orders_tenant_created 
  ON orders(tenant_id, created_at);

-- ❌ Bad: Wrong order
CREATE INDEX idx_orders_created_tenant 
  ON orders(created_at, tenant_id);
```

**Covering indexes:**

```sql
-- Query frequently needs these columns
SELECT id, status, total FROM orders WHERE user_id = ?;

-- Covering index (PostgreSQL INCLUDE)
CREATE INDEX idx_orders_user_covering 
  ON orders(user_id) 
  INCLUDE (id, status, total);

-- Index-only scan: no table access needed
```

### Query Analysis

**EXPLAIN ANALYZE workflow:**

```sql
-- PostgreSQL
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) 
SELECT * FROM orders WHERE user_id = 123;

-- Key things to look for:
-- 1. Seq Scan on large tables → Need index
-- 2. High "actual time" → Slow operation
-- 3. "Rows Removed by Filter" high → Index not selective
-- 4. Nested Loop with many iterations → N+1 pattern
```

**Reading EXPLAIN output:**

```sql
-- Example output
Seq Scan on orders  (cost=0.00..15406.00 rows=1 width=52)
                     (actual time=0.018..89.432 rows=5 loops=1)
  Filter: (user_id = 123)
  Rows Removed by Filter: 499995
  Buffers: shared hit=5406

-- Analysis:
-- - Seq Scan: Full table scan (bad for large tables)
-- - 499995 rows removed: Very unselective
-- - Solution: CREATE INDEX idx_orders_user ON orders(user_id)
```

### N+1 Query Detection

**Common N+1 patterns:**

```typescript
// ❌ N+1 pattern (1 + N queries)
const posts = await db.posts.findMany({ take: 10 });
for (const post of posts) {
  post.author = await db.users.findUnique({ 
    where: { id: post.authorId } 
  });
}

// ✅ Eager loading (2 queries)
const posts = await db.posts.findMany({
  take: 10,
  include: { author: true }
});

// ✅ Batch loading with DataLoader
const userLoader = new DataLoader(async (userIds) => {
  const users = await db.users.findMany({
    where: { id: { in: userIds } }
  });
  return userIds.map(id => users.find(u => u.id === id));
});

// Automatically batches within same tick
const posts = await db.posts.findMany({ take: 10 });
const postsWithAuthors = await Promise.all(
  posts.map(async post => ({
    ...post,
    author: await userLoader.load(post.authorId)
  }))
);
```

**Detection logging:**

```typescript
// Prisma query logging
const prisma = new PrismaClient({
  log: [
    { level: 'query', emit: 'event' }
  ],
});

let queryCount = 0;
prisma.$on('query', (e) => {
  queryCount++;
  if (queryCount > 10) {
    console.warn(`Potential N+1: ${queryCount} queries in request`);
  }
});

// Reset per request
app.use((req, res, next) => {
  queryCount = 0;
  next();
});
```

### Query Optimization Patterns

**Pagination:**

```sql
-- ❌ Slow: OFFSET scans all previous rows
SELECT * FROM posts ORDER BY created_at DESC LIMIT 20 OFFSET 10000;

-- ✅ Fast: Cursor-based (keyset) pagination
SELECT * FROM posts 
WHERE created_at < '2024-01-15T10:30:00Z'
ORDER BY created_at DESC 
LIMIT 20;

-- ✅ For unique ordering, use composite cursor
SELECT * FROM posts 
WHERE (created_at, id) < ('2024-01-15T10:30:00Z', 12345)
ORDER BY created_at DESC, id DESC 
LIMIT 20;
```

**Batch operations:**

```typescript
// ❌ Slow: Individual inserts
for (const item of items) {
  await db.items.create({ data: item });
}

// ✅ Fast: Batch insert
await db.items.createMany({ data: items });

// ✅ With conflict handling (upsert)
await db.$executeRaw`
  INSERT INTO items (id, name, value)
  VALUES ${Prisma.join(
    items.map(i => Prisma.sql`(${i.id}, ${i.name}, ${i.value})`)
  )}
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    value = EXCLUDED.value
`;
```

**Select only needed columns:**

```typescript
// ❌ Selects all columns
const users = await db.users.findMany();

// ✅ Select specific columns
const users = await db.users.findMany({
  select: { id: true, name: true, email: true }
});
```

## Caching Strategies

### Cache Patterns

**Cache-Aside (Lazy Loading):**

```typescript
async function getUser(userId: string) {
  // 1. Check cache
  const cached = await redis.get(`user:${userId}`);
  if (cached) return JSON.parse(cached);
  
  // 2. Load from database
  const user = await db.users.findUnique({ where: { id: userId } });
  
  // 3. Store in cache
  if (user) {
    await redis.set(`user:${userId}`, JSON.stringify(user), 'EX', 3600);
  }
  
  return user;
}
```

**Write-Through:**

```typescript
async function updateUser(userId: string, data: Partial<User>) {
  // 1. Update database
  const user = await db.users.update({
    where: { id: userId },
    data
  });
  
  // 2. Update cache immediately
  await redis.set(`user:${userId}`, JSON.stringify(user), 'EX', 3600);
  
  return user;
}
```

**Write-Behind (Async):**

```typescript
async function updateUserAsync(userId: string, data: Partial<User>) {
  // 1. Update cache immediately
  const cached = await redis.get(`user:${userId}`);
  const updated = { ...JSON.parse(cached), ...data };
  await redis.set(`user:${userId}`, JSON.stringify(updated), 'EX', 3600);
  
  // 2. Queue database write
  await queue.add('user:update', { userId, data });
  
  return updated;
}
```

### Cache Invalidation

**TTL-based:**

```typescript
// Simple time-based expiration
await redis.set('key', value, 'EX', 300); // 5 minutes

// Different TTLs by data type
const TTL = {
  USER_PROFILE: 3600,       // 1 hour (changes rarely)
  USER_SESSION: 86400,      // 24 hours
  SEARCH_RESULTS: 300,      // 5 minutes (volatile)
  STATIC_CONFIG: 86400 * 7  // 1 week
};
```

**Event-based invalidation:**

```typescript
// Invalidate on update
async function updateProduct(productId: string, data) {
  await db.products.update({ where: { id: productId }, data });
  
  // Invalidate related caches
  await redis.del(`product:${productId}`);
  await redis.del(`category:${data.categoryId}:products`);
  await redis.del('featured-products');
}

// Pattern-based invalidation
async function invalidateUserCaches(userId: string) {
  const keys = await redis.keys(`user:${userId}:*`);
  if (keys.length > 0) {
    await redis.del(...keys);
  }
}
```

**Cache stampede prevention:**

```typescript
// Mutex lock pattern
async function getCachedData(key: string, loadFn: () => Promise<any>) {
  const cached = await redis.get(key);
  if (cached) return JSON.parse(cached);
  
  // Try to acquire lock
  const lockKey = `lock:${key}`;
  const acquired = await redis.set(lockKey, '1', 'NX', 'EX', 10);
  
  if (acquired) {
    try {
      const data = await loadFn();
      await redis.set(key, JSON.stringify(data), 'EX', 3600);
      return data;
    } finally {
      await redis.del(lockKey);
    }
  } else {
    // Wait and retry
    await sleep(100);
    return getCachedData(key, loadFn);
  }
}

// Stale-while-revalidate
async function getWithSWR(key: string, loadFn: () => Promise<any>) {
  const [data, ttl] = await redis.multi()
    .get(key)
    .ttl(key)
    .exec();
  
  if (data) {
    // Refresh in background if nearing expiration
    if (ttl < 60) {
      loadFn().then(fresh => 
        redis.set(key, JSON.stringify(fresh), 'EX', 3600)
      );
    }
    return JSON.parse(data);
  }
  
  const fresh = await loadFn();
  await redis.set(key, JSON.stringify(fresh), 'EX', 3600);
  return fresh;
}
```

### Caching Layers

**Multi-level caching:**

```typescript
// L1: In-memory (fastest, limited size)
const memoryCache = new Map<string, { value: any; expires: number }>();

// L2: Redis (fast, shared across instances)
const redis = new Redis();

// L3: Database (slowest, source of truth)
const db = new PrismaClient();

async function get(key: string) {
  // Check L1
  const l1 = memoryCache.get(key);
  if (l1 && l1.expires > Date.now()) {
    return l1.value;
  }
  
  // Check L2
  const l2 = await redis.get(key);
  if (l2) {
    const value = JSON.parse(l2);
    memoryCache.set(key, { value, expires: Date.now() + 60000 });
    return value;
  }
  
  // Load from L3
  const value = await loadFromDB(key);
  
  // Populate caches
  await redis.set(key, JSON.stringify(value), 'EX', 3600);
  memoryCache.set(key, { value, expires: Date.now() + 60000 });
  
  return value;
}
```

### Redis Patterns

**Hash for structured data:**

```typescript
// Store user as hash (efficient partial updates)
await redis.hset('user:123', {
  name: 'John',
  email: 'john@example.com',
  role: 'admin'
});

// Get specific fields
const { name, role } = await redis.hgetall('user:123');

// Update single field
await redis.hset('user:123', 'role', 'user');
```

**Sorted sets for rankings:**

```typescript
// Leaderboard
await redis.zadd('leaderboard', score, `user:${userId}`);

// Top 10
const top10 = await redis.zrevrange('leaderboard', 0, 9, 'WITHSCORES');

// User rank
const rank = await redis.zrevrank('leaderboard', `user:${userId}`);
```

**Rate limiting:**

```typescript
async function rateLimit(key: string, limit: number, window: number) {
  const current = await redis.incr(key);
  
  if (current === 1) {
    await redis.expire(key, window);
  }
  
  return current <= limit;
}

// Usage
if (!await rateLimit(`api:${userId}`, 100, 60)) {
  throw new Error('Rate limit exceeded');
}
```

## Async Patterns

### Connection Pooling

**Database connection pool:**

```typescript
// Prisma (automatic pooling)
const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL + '?connection_limit=10&pool_timeout=30'
    }
  }
});

// pg-pool
import { Pool } from 'pg';

const pool = new Pool({
  max: 20,                // Max connections
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

const result = await pool.query('SELECT * FROM users WHERE id = $1', [userId]);
```

**Redis connection pool:**

```typescript
import Redis from 'ioredis';

const redis = new Redis({
  maxRetriesPerRequest: 3,
  enableReadyCheck: true,
  lazyConnect: true,
});

// Cluster mode
const cluster = new Redis.Cluster([
  { host: 'node1', port: 6379 },
  { host: 'node2', port: 6379 },
]);
```

### Parallel Execution

**Promise.all for independent operations:**

```typescript
// ❌ Sequential (slow)
const user = await getUser(userId);
const orders = await getOrders(userId);
const notifications = await getNotifications(userId);

// ✅ Parallel (fast)
const [user, orders, notifications] = await Promise.all([
  getUser(userId),
  getOrders(userId),
  getNotifications(userId)
]);
```

**Promise.allSettled for fault tolerance:**

```typescript
// Don't fail if one service is down
const results = await Promise.allSettled([
  fetchFromServiceA(),
  fetchFromServiceB(),
  fetchFromServiceC()
]);

const successful = results
  .filter(r => r.status === 'fulfilled')
  .map(r => r.value);
```

**Controlled concurrency:**

```typescript
import pLimit from 'p-limit';

const limit = pLimit(5); // Max 5 concurrent

const results = await Promise.all(
  items.map(item => 
    limit(() => processItem(item))
  )
);

// Or with p-map
import pMap from 'p-map';

const results = await pMap(items, processItem, { concurrency: 5 });
```

### Background Processing

**Job queues (BullMQ):**

```typescript
import { Queue, Worker } from 'bullmq';

// Producer
const queue = new Queue('emails', { connection: redis });

await queue.add('welcome', { 
  userId: '123',
  template: 'welcome'
}, {
  attempts: 3,
  backoff: { type: 'exponential', delay: 1000 }
});

// Consumer
const worker = new Worker('emails', async (job) => {
  await sendEmail(job.data);
}, { 
  connection: redis,
  concurrency: 10
});

worker.on('completed', (job) => {
  console.log(`Job ${job.id} completed`);
});

worker.on('failed', (job, err) => {
  console.error(`Job ${job.id} failed:`, err);
});
```

**Scheduled jobs:**

```typescript
// Recurring job
await queue.add('cleanup', {}, {
  repeat: {
    pattern: '0 2 * * *' // 2 AM daily
  }
});

// Delayed job
await queue.add('reminder', { userId }, {
  delay: 24 * 60 * 60 * 1000 // 24 hours
});
```

### Streaming

**Cursor-based streaming:**

```typescript
// Stream large results instead of loading all
async function* streamUsers() {
  let cursor = null;
  
  while (true) {
    const users = await db.users.findMany({
      take: 100,
      cursor: cursor ? { id: cursor } : undefined,
      skip: cursor ? 1 : 0
    });
    
    if (users.length === 0) break;
    
    for (const user of users) {
      yield user;
    }
    
    cursor = users[users.length - 1].id;
  }
}

// Usage
for await (const user of streamUsers()) {
  await processUser(user);
}
```

**HTTP streaming:**

```typescript
// Express streaming response
app.get('/export', async (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.write('[');
  
  let first = true;
  for await (const item of streamItems()) {
    if (!first) res.write(',');
    res.write(JSON.stringify(item));
    first = false;
  }
  
  res.write(']');
  res.end();
});
```

## API Response Optimization

### Response compression:**

```typescript
import compression from 'compression';

app.use(compression({
  level: 6,  // Compression level (1-9)
  threshold: 1024,  // Only compress > 1KB
  filter: (req, res) => {
    // Skip already compressed
    if (res.getHeader('Content-Encoding')) return false;
    return compression.filter(req, res);
  }
}));
```

### Payload optimization:**

```typescript
// Sparse fieldsets (GraphQL-like)
app.get('/users/:id', async (req, res) => {
  const fields = req.query.fields?.split(',') || ['id', 'name', 'email'];
  
  const user = await db.users.findUnique({
    where: { id: req.params.id },
    select: Object.fromEntries(fields.map(f => [f, true]))
  });
  
  res.json(user);
});

// Envelope stripping
// ❌ { data: { user: { ... } }, meta: { ... } }
// ✅ { ... } (user data directly)
```

### Conditional requests:**

```typescript
app.get('/resource/:id', async (req, res) => {
  const resource = await getResource(req.params.id);
  const etag = generateEtag(resource);
  
  // Check If-None-Match
  if (req.headers['if-none-match'] === etag) {
    return res.status(304).end();
  }
  
  res.setHeader('ETag', etag);
  res.setHeader('Cache-Control', 'private, max-age=60');
  res.json(resource);
});
```
