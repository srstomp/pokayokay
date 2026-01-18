# Index Design

When and how to add indexes for query optimization.

## Index Fundamentals

### What Indexes Do

```
Without index:  Sequential scan → O(n)
With index:     Index scan → O(log n) or O(1)

Trade-off:
- Faster reads
- Slower writes (index maintenance)
- More disk space
```

### When to Index

```
✅ DO Index:
- Primary keys (automatic)
- Foreign keys (NOT automatic in most DBs)
- Columns in WHERE clauses (high selectivity)
- Columns in ORDER BY
- Columns in JOIN conditions
- Unique constraints

❌ DON'T Index:
- Low-cardinality columns alone (boolean, status)
- Columns rarely used in queries
- Small tables (full scan is faster)
- Columns with frequent updates
- Every column "just in case"
```

---

## Index Types (PostgreSQL)

### B-tree (Default)

```sql
-- Best for: equality, range queries, sorting
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_orders_date ON orders(created_at);

-- Supports operators: <, <=, =, >=, >, BETWEEN, IN, IS NULL
SELECT * FROM users WHERE email = 'test@example.com';
SELECT * FROM orders WHERE created_at > '2024-01-01';
```

### Hash

```sql
-- Best for: equality only (no range queries)
CREATE INDEX idx_sessions_token ON sessions USING hash(token);

-- Only supports: =
SELECT * FROM sessions WHERE token = 'abc123';
```

### GIN (Generalized Inverted Index)

```sql
-- Best for: arrays, JSONB, full-text search
CREATE INDEX idx_posts_tags ON posts USING gin(tags);
CREATE INDEX idx_products_attrs ON products USING gin(attributes);
CREATE INDEX idx_articles_search ON articles USING gin(to_tsvector('english', title || ' ' || body));

-- Array queries
SELECT * FROM posts WHERE tags @> ARRAY['tech'];

-- JSONB queries
SELECT * FROM products WHERE attributes @> '{"color": "red"}';

-- Full-text search
SELECT * FROM articles WHERE to_tsvector('english', title || ' ' || body) @@ to_tsquery('database');
```

### GiST (Generalized Search Tree)

```sql
-- Best for: geometric data, range types, full-text
CREATE INDEX idx_locations_point ON locations USING gist(coordinates);
CREATE INDEX idx_events_during ON events USING gist(during);  -- tstzrange

-- Range queries
SELECT * FROM events WHERE during && '[2024-01-01, 2024-01-31]'::tstzrange;

-- Geometric queries
SELECT * FROM locations WHERE coordinates <-> point(40.7, -74.0) < 10;
```

### BRIN (Block Range Index)

```sql
-- Best for: large, naturally ordered tables (time-series)
CREATE INDEX idx_logs_created ON logs USING brin(created_at);

-- Very small index for huge tables where data is physically ordered
-- E.g., append-only log tables
```

---

## Composite Indexes

### Column Order Matters

```sql
-- Index on (a, b, c) can be used for:
-- - WHERE a = ?
-- - WHERE a = ? AND b = ?
-- - WHERE a = ? AND b = ? AND c = ?
-- - WHERE a = ? ORDER BY b
-- 
-- CANNOT be used efficiently for:
-- - WHERE b = ?  (skips first column)
-- - WHERE c = ?  (skips first columns)
-- - WHERE a = ? AND c = ?  (gap in columns)

CREATE INDEX idx_orders_user_status_date ON orders(user_id, status, created_at);

-- Good queries:
SELECT * FROM orders WHERE user_id = ? AND status = 'active';
SELECT * FROM orders WHERE user_id = ? ORDER BY created_at;

-- Bad queries (won't use this index efficiently):
SELECT * FROM orders WHERE status = 'active';  -- Create separate index
```

### Leftmost Prefix Rule

```
Index (a, b, c) serves queries on:
✅ (a)
✅ (a, b)
✅ (a, b, c)
❌ (b)
❌ (c)
❌ (b, c)
❌ (a, c)  -- can use for 'a', but not full index
```

### Index for Sorting

```sql
-- Include ORDER BY columns in index
CREATE INDEX idx_users_created_desc ON users(created_at DESC);

-- Composite for filter + sort
CREATE INDEX idx_orders_user_date ON orders(user_id, created_at DESC);

-- Query uses index for both filter and sort:
SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC;
```

---

## Partial Indexes

Index only rows matching a condition.

```sql
-- Only index active users
CREATE INDEX idx_users_email_active ON users(email)
  WHERE status = 'active';

-- Only index non-deleted
CREATE INDEX idx_orders_user_active ON orders(user_id)
  WHERE deleted_at IS NULL;

-- Only index recent data
CREATE INDEX idx_logs_recent ON logs(created_at)
  WHERE created_at > '2024-01-01';

-- Benefits:
-- - Smaller index size
-- - Faster updates for excluded rows
-- - Better cache efficiency
```

---

## Covering Indexes (Index-Only Scans)

Include all columns needed by query to avoid table access.

```sql
-- Query needs: id, email, name
SELECT id, email, name FROM users WHERE email = ?;

-- Covering index (PostgreSQL INCLUDE)
CREATE INDEX idx_users_email_covering ON users(email) INCLUDE (id, name);

-- Or composite index
CREATE INDEX idx_users_email_id_name ON users(email, id, name);

-- Query can be satisfied entirely from index (index-only scan)
```

---

## Expression Indexes

Index computed values.

```sql
-- Index lowercase email for case-insensitive search
CREATE INDEX idx_users_email_lower ON users(LOWER(email));

-- Query must use same expression
SELECT * FROM users WHERE LOWER(email) = LOWER('Test@Example.com');

-- Index extracted JSON field
CREATE INDEX idx_products_brand ON products((attributes->>'brand'));

-- Query
SELECT * FROM products WHERE attributes->>'brand' = 'Apple';

-- Index year from date
CREATE INDEX idx_orders_year ON orders(EXTRACT(YEAR FROM created_at));
```

---

## Unique Indexes

```sql
-- Single column
CREATE UNIQUE INDEX idx_users_email ON users(email);

-- Composite (combination must be unique)
CREATE UNIQUE INDEX idx_org_members ON organization_members(org_id, user_id);

-- Partial unique (unique only among non-deleted)
CREATE UNIQUE INDEX idx_users_email_active ON users(email)
  WHERE deleted_at IS NULL;
```

---

## Index Analysis

### Check Existing Indexes

```sql
-- List all indexes on a table
SELECT
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'users';

-- Index size
SELECT
  indexrelname AS index_name,
  pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE relname = 'users'
ORDER BY pg_relation_size(indexrelid) DESC;
```

### Index Usage Statistics

```sql
-- Which indexes are being used?
SELECT
  indexrelname AS index_name,
  idx_scan AS times_used,
  idx_tup_read AS tuples_read,
  idx_tup_fetch AS tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;

-- Unused indexes (candidates for removal)
SELECT
  indexrelname AS index_name,
  pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
  AND indexrelname NOT LIKE 'pg_%'
ORDER BY pg_relation_size(indexrelid) DESC;
```

### Missing Index Detection

```sql
-- Tables with high sequential scans
SELECT
  relname AS table_name,
  seq_scan,
  seq_tup_read,
  idx_scan,
  idx_tup_fetch
FROM pg_stat_user_tables
WHERE seq_scan > 1000
ORDER BY seq_tup_read DESC;
```

---

## EXPLAIN Analysis

### Reading EXPLAIN Output

```sql
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'test@example.com';

-- Output interpretation:
-- Seq Scan: Full table scan (no index used)
-- Index Scan: Using index, then fetching from table
-- Index Only Scan: Using index only (covering index)
-- Bitmap Index Scan: Building bitmap from index
-- Bitmap Heap Scan: Using bitmap to fetch from table
```

### Key Metrics

```
cost=0.00..100.00    -- Estimated cost (startup..total)
rows=1000            -- Estimated rows returned
width=100            -- Average row size in bytes
actual time=0.1..1.5 -- Actual time (startup..total) in ms
rows=950             -- Actual rows returned
loops=1              -- Number of executions
```

### Example Analysis

```sql
-- Query
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM orders WHERE user_id = '123' AND status = 'active';

-- Good output (using index):
Index Scan using idx_orders_user_status on orders
  Index Cond: (user_id = '123' AND status = 'active')
  Buffers: shared hit=4
  Planning Time: 0.1 ms
  Execution Time: 0.05 ms

-- Bad output (sequential scan):
Seq Scan on orders
  Filter: (user_id = '123' AND status = 'active')
  Rows Removed by Filter: 9999
  Buffers: shared hit=500
  Planning Time: 0.1 ms
  Execution Time: 50.0 ms
```

---

## Common Index Patterns

### Foreign Key Index

```sql
-- Always index foreign keys
CREATE TABLE orders (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id),
  -- ...
);

-- Add index for FK (not automatic in PostgreSQL)
CREATE INDEX idx_orders_user_id ON orders(user_id);
```

### Status + Date Filtering

```sql
-- Common query pattern
SELECT * FROM orders
WHERE status = 'pending'
AND created_at > NOW() - INTERVAL '24 hours';

-- Composite index (status first for equality, then date for range)
CREATE INDEX idx_orders_status_created ON orders(status, created_at);
```

### Multi-Tenant Lookup

```sql
-- All queries filtered by tenant
SELECT * FROM items WHERE tenant_id = ? AND ...;

-- Always lead with tenant_id
CREATE INDEX idx_items_tenant_name ON items(tenant_id, name);
CREATE INDEX idx_items_tenant_created ON items(tenant_id, created_at DESC);
```

### Search + Sort

```sql
-- Query: filter + order + limit
SELECT * FROM products
WHERE category_id = ?
ORDER BY popularity DESC
LIMIT 20;

-- Index supports both filter and sort
CREATE INDEX idx_products_cat_pop ON products(category_id, popularity DESC);
```

---

## Index Maintenance

### Reindex Bloated Indexes

```sql
-- Reindex single index (locks table)
REINDEX INDEX idx_users_email;

-- Reindex concurrently (PostgreSQL 12+)
REINDEX INDEX CONCURRENTLY idx_users_email;

-- Reindex all indexes on table
REINDEX TABLE users;
REINDEX TABLE CONCURRENTLY users;
```

### Check Index Bloat

```sql
-- Estimate index bloat
SELECT
  indexrelname AS index_name,
  pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
  idx_scan AS scans
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY pg_relation_size(indexrelid) DESC;
```

---

## Anti-Patterns

### ❌ Index on Every Column

```sql
-- Don't do this
CREATE INDEX idx_users_id ON users(id);        -- Already PK
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_name ON users(name);
CREATE INDEX idx_users_created ON users(created_at);
CREATE INDEX idx_users_status ON users(status);  -- Low cardinality
-- Too many indexes slow down writes
```

### ❌ Duplicate Indexes

```sql
-- Redundant: (a) is already covered by (a, b)
CREATE INDEX idx_a ON table(a);
CREATE INDEX idx_a_b ON table(a, b);  -- This covers queries on (a)
```

### ❌ Index on Low Cardinality

```sql
-- Bad: Only 3 possible values
CREATE INDEX idx_users_status ON users(status);  -- active/suspended/deleted

-- Better: Partial index if querying specific value often
CREATE INDEX idx_users_active ON users(id) WHERE status = 'active';
```

### ❌ Over-Indexing JSONB

```sql
-- Don't index entire JSONB column
CREATE INDEX idx_data ON table USING gin(data);  -- Too broad

-- Better: Index specific paths you query
CREATE INDEX idx_data_type ON table USING gin((data->'type'));
```
