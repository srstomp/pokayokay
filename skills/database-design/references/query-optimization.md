# Query Optimization

Identifying and fixing slow queries.

## Identifying Slow Queries

### PostgreSQL: Enable Logging

```sql
-- Log queries slower than 100ms
ALTER SYSTEM SET log_min_duration_statement = 100;
SELECT pg_reload_conf();

-- Check slow query log
-- Location: /var/log/postgresql/postgresql-*.log
```

### PostgreSQL: pg_stat_statements

```sql
-- Enable extension
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Top queries by total time
SELECT
  substring(query, 1, 100) AS short_query,
  calls,
  round(total_exec_time::numeric, 2) AS total_time_ms,
  round(mean_exec_time::numeric, 2) AS avg_time_ms,
  rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;

-- Most called queries
SELECT
  substring(query, 1, 100) AS short_query,
  calls,
  round(mean_exec_time::numeric, 2) AS avg_time_ms
FROM pg_stat_statements
ORDER BY calls DESC
LIMIT 20;
```

---

## EXPLAIN Fundamentals

### Basic EXPLAIN

```sql
-- Estimated plan only
EXPLAIN SELECT * FROM users WHERE email = 'test@example.com';

-- With actual execution
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'test@example.com';

-- With buffer info
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM users WHERE email = 'test@example.com';

-- Full details
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM users WHERE email = 'test@example.com';
```

### Reading EXPLAIN Output

```
Index Scan using idx_users_email on users  (cost=0.42..8.44 rows=1 width=100) (actual time=0.015..0.016 rows=1 loops=1)
  Index Cond: (email = 'test@example.com'::text)
  Buffers: shared hit=4
Planning Time: 0.085 ms
Execution Time: 0.031 ms
```

| Metric | Meaning |
|--------|---------|
| `cost=0.42..8.44` | Estimated startup..total cost (arbitrary units) |
| `rows=1` | Estimated rows returned |
| `width=100` | Average row size in bytes |
| `actual time=0.015..0.016` | Actual startup..total time in ms |
| `rows=1` | Actual rows returned |
| `loops=1` | Times this node executed |
| `Buffers: shared hit=4` | Pages read from cache |

### Scan Types (Good to Bad)

| Scan Type | Description | Speed |
|-----------|-------------|-------|
| Index Only Scan | Index satisfies query completely | 🟢 Best |
| Index Scan | Index + fetch from table | 🟢 Good |
| Bitmap Index Scan | Build bitmap, then heap scan | 🟡 Moderate |
| Seq Scan | Full table scan | 🔴 Worst for large tables |

---

## Common Problems & Solutions

### 1. Missing Index

**Symptom:**
```
Seq Scan on users  (cost=0.00..50000.00 rows=1 width=100)
  Filter: (email = 'test@example.com'::text)
  Rows Removed by Filter: 999999
```

**Solution:**
```sql
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
```

---

### 2. Index Not Used

**Symptom:** Index exists but Seq Scan used.

**Causes & Solutions:**

```sql
-- 1. Function on indexed column
-- Bad: index on email, but LOWER() prevents use
SELECT * FROM users WHERE LOWER(email) = LOWER('Test@Example.com');

-- Fix: Create expression index
CREATE INDEX idx_users_email_lower ON users(LOWER(email));

-- 2. Wrong data type
-- Bad: email is VARCHAR but parameter is TEXT
SELECT * FROM users WHERE email = $1::text;

-- Fix: Match types
SELECT * FROM users WHERE email = $1::varchar;

-- 3. OR condition
-- Bad: OR can prevent index use
SELECT * FROM users WHERE email = 'a@b.com' OR name = 'John';

-- Fix: Use UNION
SELECT * FROM users WHERE email = 'a@b.com'
UNION
SELECT * FROM users WHERE name = 'John';

-- 4. Leading wildcard
-- Bad: Leading % can't use B-tree index
SELECT * FROM users WHERE email LIKE '%@example.com';

-- Fix: Use pg_trgm or reverse index
CREATE INDEX idx_users_email_reverse ON users(reverse(email));
SELECT * FROM users WHERE reverse(email) LIKE reverse('%@example.com');
```

---

### 3. N+1 Query Problem

**Symptom:** Many similar queries in logs.

```sql
-- 1 query for users
SELECT * FROM users WHERE status = 'active';
-- N queries for each user's posts
SELECT * FROM posts WHERE user_id = 1;
SELECT * FROM posts WHERE user_id = 2;
SELECT * FROM posts WHERE user_id = 3;
-- ...100 more
```

**Solution:** Use JOIN or subquery

```sql
-- Single query with JOIN
SELECT u.*, p.*
FROM users u
LEFT JOIN posts p ON p.user_id = u.id
WHERE u.status = 'active';

-- Or fetch IDs then bulk load
SELECT * FROM posts WHERE user_id IN (1, 2, 3, ...);
```

---

### 4. Large Offset Pagination

**Symptom:** Slow as page number increases.

```sql
-- Slow at page 500
SELECT * FROM products ORDER BY id LIMIT 20 OFFSET 10000;
```

**Explanation:** OFFSET still scans all skipped rows.

**Solution:** Use keyset/cursor pagination

```sql
-- Fast: Resume from last seen ID
SELECT * FROM products
WHERE id > $last_seen_id
ORDER BY id
LIMIT 20;
```

---

### 5. Expensive COUNT

**Symptom:** COUNT(*) is slow on large tables.

```sql
-- Slow: Full table scan
SELECT COUNT(*) FROM orders WHERE status = 'pending';
```

**Solutions:**

```sql
-- 1. Partial index for common filters
CREATE INDEX idx_orders_pending ON orders(id) WHERE status = 'pending';

-- 2. Approximate count (very fast)
SELECT reltuples::bigint AS estimate
FROM pg_class
WHERE relname = 'orders';

-- 3. Counter cache (application level)
-- Maintain a separate counts table updated by triggers

-- 4. HyperLogLog for unique counts (pg extension)
CREATE EXTENSION IF NOT EXISTS hll;
```

---

### 6. Inefficient JOIN Order

**Symptom:** Large intermediate results.

```sql
-- Bad: Joining large table first
SELECT * FROM orders o
JOIN users u ON u.id = o.user_id
JOIN products p ON p.id = o.product_id
WHERE p.category_id = 5;
```

**Solution:** Let planner decide or hint

```sql
-- Usually optimizer handles this, but:
-- 1. Update statistics
ANALYZE orders;
ANALYZE users;
ANALYZE products;

-- 2. Check join_collapse_limit
SHOW join_collapse_limit;  -- Default 8

-- 3. Rewrite with CTE (forces order)
WITH filtered_products AS (
  SELECT id FROM products WHERE category_id = 5
)
SELECT o.* FROM orders o
JOIN filtered_products p ON p.id = o.product_id
JOIN users u ON u.id = o.user_id;
```

---

### 7. Correlated Subquery

**Symptom:** Subquery runs for each row.

```sql
-- Bad: Subquery runs for each order
SELECT o.*,
  (SELECT COUNT(*) FROM order_items WHERE order_id = o.id) AS item_count
FROM orders o;
```

**Solution:** Use JOIN or window function

```sql
-- Better: Single aggregation
SELECT o.*, COALESCE(i.item_count, 0) AS item_count
FROM orders o
LEFT JOIN (
  SELECT order_id, COUNT(*) AS item_count
  FROM order_items
  GROUP BY order_id
) i ON i.order_id = o.id;
```

---

### 8. Unnecessary Columns

**Symptom:** Fetching unused data.

```sql
-- Bad: Fetching all columns including large TEXT/JSONB
SELECT * FROM posts WHERE author_id = 5;
```

**Solution:** Select only needed columns

```sql
-- Good: Only needed columns
SELECT id, title, created_at FROM posts WHERE author_id = 5;
```

---

## Query Patterns

### Batch Updates

```sql
-- Bad: Individual updates
UPDATE items SET status = 'processed' WHERE id = 1;
UPDATE items SET status = 'processed' WHERE id = 2;
-- ...

-- Good: Batch update
UPDATE items SET status = 'processed'
WHERE id IN (1, 2, 3, ...);

-- Better: With batching for very large sets
UPDATE items SET status = 'processed'
WHERE id IN (
  SELECT id FROM items
  WHERE status = 'pending'
  LIMIT 1000
);
```

### Upsert (INSERT ... ON CONFLICT)

```sql
-- Insert or update
INSERT INTO user_stats (user_id, login_count, last_login)
VALUES ($1, 1, NOW())
ON CONFLICT (user_id) DO UPDATE SET
  login_count = user_stats.login_count + 1,
  last_login = NOW();
```

### Conditional Aggregation

```sql
-- Count by status in single query
SELECT
  COUNT(*) AS total,
  COUNT(*) FILTER (WHERE status = 'active') AS active,
  COUNT(*) FILTER (WHERE status = 'pending') AS pending,
  COUNT(*) FILTER (WHERE status = 'completed') AS completed
FROM orders;
```

### Avoiding SELECT DISTINCT

```sql
-- Bad: DISTINCT on large result
SELECT DISTINCT category_id FROM products;

-- Better: Use EXISTS or GROUP BY
SELECT category_id FROM products GROUP BY category_id;

-- Or if checking existence
SELECT id FROM categories c
WHERE EXISTS (SELECT 1 FROM products p WHERE p.category_id = c.id);
```

---

## Index Usage Verification

```sql
-- Check if your query uses indexes
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE user_id = 123 AND status = 'active';

-- Good signs:
-- - Index Scan or Index Only Scan
-- - Low "Buffers: shared hit" count
-- - Actual rows close to estimated rows

-- Bad signs:
-- - Seq Scan on large table
-- - High "Rows Removed by Filter"
-- - Buffers: shared read (disk reads)
```

---

## Statistics

### Update Statistics

```sql
-- Update single table
ANALYZE orders;

-- Update entire database
ANALYZE;

-- Check last analyze time
SELECT
  relname,
  last_analyze,
  last_autoanalyze
FROM pg_stat_user_tables
ORDER BY last_analyze DESC NULLS LAST;
```

### Check Statistics Quality

```sql
-- Compare estimated vs actual rows
EXPLAIN ANALYZE SELECT * FROM orders WHERE status = 'pending';

-- If estimated rows is far from actual:
-- 1. Run ANALYZE
-- 2. Increase statistics target for that column
ALTER TABLE orders ALTER COLUMN status SET STATISTICS 1000;
ANALYZE orders;
```

---

## Monitoring Queries

### Active Queries

```sql
SELECT
  pid,
  now() - pg_stat_activity.query_start AS duration,
  state,
  query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY duration DESC;
```

### Blocked Queries

```sql
SELECT
  blocked.pid AS blocked_pid,
  blocked.query AS blocked_query,
  blocking.pid AS blocking_pid,
  blocking.query AS blocking_query
FROM pg_stat_activity blocked
JOIN pg_stat_activity blocking ON blocking.pid = ANY(pg_blocking_pids(blocked.pid))
WHERE blocked.pid != blocking.pid;
```

### Query Termination

```sql
-- Cancel query (graceful)
SELECT pg_cancel_backend(pid);

-- Terminate connection (forceful)
SELECT pg_terminate_backend(pid);
```

---

## Optimization Checklist

```
□ Run EXPLAIN ANALYZE on slow query
□ Check for Seq Scan on large tables
□ Verify indexes exist for WHERE/JOIN columns
□ Check for type mismatches in comparisons
□ Look for N+1 patterns in application logs
□ Consider pagination strategy for large offsets
□ Update statistics (ANALYZE) if estimates are off
□ Check for unnecessary columns in SELECT
□ Review JOIN order for large tables
□ Consider partial indexes for common filters
```
