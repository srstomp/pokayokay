# PostgreSQL

PostgreSQL-specific features, extensions, and optimization.

## Data Types

### Common Types

| Type | Use Case | Example |
|------|----------|---------|
| `UUID` | Primary keys, identifiers | `gen_random_uuid()` |
| `TIMESTAMPTZ` | Timestamps (always with TZ) | `NOW()` |
| `JSONB` | Flexible/dynamic data | `'{"key": "value"}'::jsonb` |
| `TEXT` | Variable-length strings | Unlimited |
| `VARCHAR(n)` | Strings with max length | Email, names |
| `INTEGER` | Whole numbers | Counters, IDs |
| `BIGINT` | Large whole numbers | Analytics, large IDs |
| `DECIMAL(p,s)` | Exact decimals | Money: `DECIMAL(10,2)` |
| `BOOLEAN` | True/false | Flags |
| `ARRAY` | Lists of values | Tags, permissions |

### UUID Generation

```sql
-- PostgreSQL 13+: Built-in
SELECT gen_random_uuid();

-- UUID v7 (time-ordered) - requires extension or function
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Custom UUID v7 function
CREATE OR REPLACE FUNCTION uuid_generate_v7()
RETURNS uuid AS $$
DECLARE
  unix_ts_ms bytea;
  uuid_bytes bytea;
BEGIN
  unix_ts_ms = substring(int8send(floor(extract(epoch from clock_timestamp()) * 1000)::bigint) from 3);
  uuid_bytes = unix_ts_ms || gen_random_bytes(10);
  uuid_bytes = set_byte(uuid_bytes, 6, (b'0111' || get_byte(uuid_bytes, 6)::bit(4))::bit(8)::int);
  uuid_bytes = set_byte(uuid_bytes, 8, (b'10' || get_byte(uuid_bytes, 8)::bit(6))::bit(8)::int);
  return encode(uuid_bytes, 'hex')::uuid;
END
$$ LANGUAGE plpgsql VOLATILE;
```

### JSONB Operations

```sql
-- Create with JSONB
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  attributes JSONB NOT NULL DEFAULT '{}'
);

-- Insert
INSERT INTO products (name, attributes)
VALUES ('Widget', '{"color": "red", "size": "large", "tags": ["sale", "featured"]}');

-- Query: Get key
SELECT attributes->>'color' AS color FROM products;

-- Query: Contains
SELECT * FROM products WHERE attributes @> '{"color": "red"}';

-- Query: Has key
SELECT * FROM products WHERE attributes ? 'size';

-- Query: Array element
SELECT * FROM products WHERE attributes->'tags' ? 'sale';

-- Update: Set key
UPDATE products SET attributes = attributes || '{"price": 99.99}';

-- Update: Remove key
UPDATE products SET attributes = attributes - 'color';

-- Update: Set nested
UPDATE products SET attributes = jsonb_set(attributes, '{specs,weight}', '"10kg"');

-- Index for JSONB queries
CREATE INDEX idx_products_attrs ON products USING gin(attributes);
CREATE INDEX idx_products_color ON products((attributes->>'color'));
```

### Array Operations

```sql
-- Create with array
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  tags TEXT[] NOT NULL DEFAULT '{}'
);

-- Insert
INSERT INTO posts (title, tags) VALUES ('Hello', ARRAY['tech', 'news']);

-- Query: Contains element
SELECT * FROM posts WHERE 'tech' = ANY(tags);

-- Query: Contains all
SELECT * FROM posts WHERE tags @> ARRAY['tech', 'news'];

-- Query: Overlaps (any match)
SELECT * FROM posts WHERE tags && ARRAY['tech', 'ai'];

-- Update: Append
UPDATE posts SET tags = array_append(tags, 'featured');

-- Update: Remove
UPDATE posts SET tags = array_remove(tags, 'tech');

-- Index
CREATE INDEX idx_posts_tags ON posts USING gin(tags);
```

---

## Constraints

### Check Constraints

```sql
-- Simple check
CREATE TABLE products (
  price DECIMAL(10,2) CHECK (price >= 0),
  quantity INTEGER CHECK (quantity >= 0)
);

-- Named constraint
ALTER TABLE products ADD CONSTRAINT chk_price_positive
  CHECK (price >= 0);

-- Multi-column check
ALTER TABLE events ADD CONSTRAINT chk_dates_valid
  CHECK (end_date >= start_date);

-- Enum-like constraint
ALTER TABLE orders ADD CONSTRAINT chk_status_valid
  CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'));
```

### Exclusion Constraints

Prevent overlapping values (great for scheduling).

```sql
-- Prevent overlapping bookings
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE room_bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL,
  during TSTZRANGE NOT NULL,
  
  EXCLUDE USING gist (room_id WITH =, during WITH &&)
);

-- Insert will fail if overlaps
INSERT INTO room_bookings (room_id, during)
VALUES ('room-1', '[2024-01-15 10:00, 2024-01-15 12:00)');
```

---

## Row Level Security (RLS)

Automatic row filtering based on context.

```sql
-- Enable RLS
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Policy: Users see only their documents
CREATE POLICY user_documents ON documents
  FOR ALL
  USING (user_id = current_setting('app.current_user_id')::uuid);

-- Policy: Admins see all
CREATE POLICY admin_documents ON documents
  FOR ALL
  TO admin_role
  USING (true);

-- Set context in application
SET app.current_user_id = 'user-uuid-here';

-- Now queries automatically filter
SELECT * FROM documents;  -- Only returns user's documents
```

### Multi-Tenant RLS

```sql
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON orders
  FOR ALL
  USING (tenant_id = current_setting('app.tenant_id')::uuid);

-- Application sets tenant on each request
SET app.tenant_id = 'tenant-uuid';
```

---

## Triggers

### Updated At Trigger

```sql
-- Function to update timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to table
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
```

### Audit Trigger

```sql
CREATE OR REPLACE FUNCTION audit_changes()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_log (
    table_name,
    record_id,
    action,
    old_data,
    new_data,
    changed_at
  ) VALUES (
    TG_TABLE_NAME,
    COALESCE(NEW.id, OLD.id),
    TG_OP,
    CASE WHEN TG_OP != 'INSERT' THEN to_jsonb(OLD) END,
    CASE WHEN TG_OP != 'DELETE' THEN to_jsonb(NEW) END,
    NOW()
  );
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_users
  AFTER INSERT OR UPDATE OR DELETE ON users
  FOR EACH ROW EXECUTE FUNCTION audit_changes();
```

### Counter Cache Trigger

```sql
CREATE OR REPLACE FUNCTION update_comment_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE posts SET comment_count = comment_count + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE posts SET comment_count = comment_count - 1 WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_post_comment_count
  AFTER INSERT OR DELETE ON comments
  FOR EACH ROW EXECUTE FUNCTION update_comment_count();
```

---

## Useful Extensions

### Essential Extensions

```sql
-- UUID generation (pre PG 13)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Cryptographic functions
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Fuzzy string matching
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- B-tree GiST support (for exclusion constraints)
CREATE EXTENSION IF NOT EXISTS btree_gist;
```

### Full-Text Search

```sql
-- Add search vector column
ALTER TABLE articles ADD COLUMN search_vector tsvector;

-- Populate
UPDATE articles SET search_vector = 
  to_tsvector('english', coalesce(title, '') || ' ' || coalesce(body, ''));

-- Index
CREATE INDEX idx_articles_search ON articles USING gin(search_vector);

-- Keep updated with trigger
CREATE TRIGGER articles_search_update
  BEFORE INSERT OR UPDATE ON articles
  FOR EACH ROW EXECUTE FUNCTION
  tsvector_update_trigger(search_vector, 'pg_catalog.english', title, body);

-- Search
SELECT * FROM articles
WHERE search_vector @@ to_tsquery('english', 'database & design');

-- Ranked results
SELECT *, ts_rank(search_vector, query) AS rank
FROM articles, to_tsquery('english', 'database & design') query
WHERE search_vector @@ query
ORDER BY rank DESC;
```

### pg_trgm for Fuzzy Matching

```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Index for LIKE/ILIKE queries
CREATE INDEX idx_users_name_trgm ON users USING gin(name gin_trgm_ops);

-- Fuzzy search
SELECT * FROM users WHERE name % 'jhon';  -- Finds "john"

-- Similarity score
SELECT name, similarity(name, 'jhon') AS sim
FROM users
WHERE name % 'jhon'
ORDER BY sim DESC;
```

---

## Performance

### Connection Pooling

Always use a connection pooler in production.

```
Application → PgBouncer → PostgreSQL
             (pooler)

Benefits:
- Reduced connection overhead
- Better resource utilization
- Connection limiting
```

### Query Optimization

```sql
-- Analyze query plan
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM orders WHERE user_id = ?;

-- Force index usage (rarely needed)
SET enable_seqscan = off;

-- Update statistics
ANALYZE orders;

-- Vacuum to reclaim space
VACUUM ANALYZE orders;
```

### Partitioning

For very large tables (millions of rows).

```sql
-- Range partitioning by date
CREATE TABLE events (
  id UUID DEFAULT gen_random_uuid(),
  event_type VARCHAR(100) NOT NULL,
  data JSONB,
  created_at TIMESTAMPTZ NOT NULL
) PARTITION BY RANGE (created_at);

-- Create partitions
CREATE TABLE events_2024_01 PARTITION OF events
  FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE events_2024_02 PARTITION OF events
  FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

-- Queries automatically route to relevant partitions
SELECT * FROM events WHERE created_at >= '2024-01-15';
```

### Materialized Views

Pre-computed results for expensive queries.

```sql
CREATE MATERIALIZED VIEW monthly_stats AS
SELECT
  date_trunc('month', created_at) AS month,
  COUNT(*) AS total_orders,
  SUM(total) AS revenue
FROM orders
GROUP BY date_trunc('month', created_at);

-- Index the materialized view
CREATE UNIQUE INDEX idx_monthly_stats ON monthly_stats(month);

-- Refresh (blocks reads during refresh)
REFRESH MATERIALIZED VIEW monthly_stats;

-- Refresh concurrently (requires unique index)
REFRESH MATERIALIZED VIEW CONCURRENTLY monthly_stats;
```

---

## Useful Queries

### Table Sizes

```sql
SELECT
  relname AS table_name,
  pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
  pg_size_pretty(pg_relation_size(relid)) AS data_size,
  pg_size_pretty(pg_indexes_size(relid)) AS index_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;
```

### Active Queries

```sql
SELECT
  pid,
  now() - pg_stat_activity.query_start AS duration,
  query,
  state
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes'
  AND state != 'idle'
ORDER BY duration DESC;
```

### Kill Long-Running Query

```sql
-- Cancel query (graceful)
SELECT pg_cancel_backend(pid);

-- Terminate connection (forceful)
SELECT pg_terminate_backend(pid);
```

### Table Bloat

```sql
SELECT
  schemaname,
  relname,
  n_live_tup,
  n_dead_tup,
  round(100.0 * n_dead_tup / nullif(n_live_tup + n_dead_tup, 0), 2) AS dead_pct
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC;
```

### Missing Foreign Key Indexes

```sql
SELECT
  conrelid::regclass AS table_name,
  conname AS fk_name,
  a.attname AS column_name
FROM pg_constraint c
JOIN pg_attribute a ON a.attnum = ANY(c.conkey) AND a.attrelid = c.conrelid
WHERE c.contype = 'f'
AND NOT EXISTS (
  SELECT 1 FROM pg_index i
  WHERE i.indrelid = c.conrelid
  AND a.attnum = ANY(i.indkey)
);
```
