# Migration Strategies

Safe database migration techniques for production systems.

## Zero-Downtime Migration Principles

```
1. All changes must be backward compatible
2. Deploy code that works with BOTH old and new schema
3. Make schema change
4. Deploy code that uses new schema
5. Clean up old code paths
```

---

## Adding Columns

### Safe: Nullable Column

```sql
-- Step 1: Add nullable column
ALTER TABLE users ADD COLUMN middle_name VARCHAR(255);

-- Step 2: Deploy code that writes to new column
-- Step 3: Backfill existing rows
UPDATE users SET middle_name = '' WHERE middle_name IS NULL;

-- Step 4: Add NOT NULL constraint (if needed)
ALTER TABLE users ALTER COLUMN middle_name SET NOT NULL;
```

### Dangerous: NOT NULL with Default

```sql
-- ⚠️ LOCKS TABLE on large tables in older PostgreSQL
ALTER TABLE users ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'active';

-- ✅ Safe alternative (PostgreSQL 11+)
-- In PG 11+, this is safe because default is stored in catalog
ALTER TABLE users ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'active';

-- ✅ Safe for all versions
ALTER TABLE users ADD COLUMN status VARCHAR(20);
UPDATE users SET status = 'active' WHERE status IS NULL;  -- in batches
ALTER TABLE users ALTER COLUMN status SET NOT NULL;
ALTER TABLE users ALTER COLUMN status SET DEFAULT 'active';
```

### Batch Backfill Pattern

```sql
-- Backfill in batches to avoid long transactions
DO $$
DECLARE
  batch_size INT := 10000;
  affected INT;
BEGIN
  LOOP
    UPDATE users
    SET status = 'active'
    WHERE id IN (
      SELECT id FROM users
      WHERE status IS NULL
      LIMIT batch_size
      FOR UPDATE SKIP LOCKED
    );
    
    GET DIAGNOSTICS affected = ROW_COUNT;
    
    IF affected = 0 THEN
      EXIT;
    END IF;
    
    -- Allow other transactions to proceed
    COMMIT;
    PERFORM pg_sleep(0.1);
  END LOOP;
END $$;
```

---

## Removing Columns

### Safe Removal Process

```
Step 1: Stop reading from column in application code
Step 2: Deploy
Step 3: Stop writing to column
Step 4: Deploy
Step 5: Remove column from database
```

```sql
-- Step 5: Actually remove
ALTER TABLE users DROP COLUMN legacy_field;
```

### Remove with Safety Check

```sql
-- Check column is not being used
SELECT COUNT(*) FROM users WHERE legacy_field IS NOT NULL;

-- If safe, remove
ALTER TABLE users DROP COLUMN legacy_field;
```

---

## Renaming Columns

Never rename directly. Use expand-contract pattern.

```sql
-- Step 1: Add new column
ALTER TABLE users ADD COLUMN full_name VARCHAR(255);

-- Step 2: Backfill
UPDATE users SET full_name = name;

-- Step 3: Deploy code that writes to BOTH columns
-- Step 4: Deploy code that reads from new column
-- Step 5: Stop writing to old column
-- Step 6: Remove old column
ALTER TABLE users DROP COLUMN name;
```

### Using View for Transition

```sql
-- Create view that exposes old name
CREATE VIEW users_compat AS
SELECT id, full_name AS name, full_name, email
FROM users;
```

---

## Changing Column Types

### Safe: Compatible Type Changes

```sql
-- VARCHAR to TEXT (safe)
ALTER TABLE users ALTER COLUMN bio TYPE TEXT;

-- Smaller VARCHAR (unsafe if data exceeds)
-- First check:
SELECT MAX(LENGTH(name)) FROM users;
-- Then change:
ALTER TABLE users ALTER COLUMN name TYPE VARCHAR(100);
```

### Safe: Integer to Bigint

```sql
-- PostgreSQL handles this safely
ALTER TABLE metrics ALTER COLUMN count TYPE BIGINT;
```

### Complex Type Changes

```sql
-- String to Integer (requires conversion)
-- Step 1: Add new column
ALTER TABLE orders ADD COLUMN amount_cents INTEGER;

-- Step 2: Backfill with conversion
UPDATE orders SET amount_cents = (amount::numeric * 100)::integer;

-- Step 3: Verify
SELECT COUNT(*) FROM orders WHERE amount_cents IS NULL;

-- Step 4: Update code, then remove old column
ALTER TABLE orders DROP COLUMN amount;
ALTER TABLE orders RENAME COLUMN amount_cents TO amount;
```

---

## Adding Constraints

### NOT NULL Constraint

```sql
-- Step 1: Add constraint as NOT VALID (no full table scan)
ALTER TABLE users ADD CONSTRAINT users_email_not_null
  CHECK (email IS NOT NULL) NOT VALID;

-- Step 2: Validate in separate transaction (allows concurrent access)
ALTER TABLE users VALIDATE CONSTRAINT users_email_not_null;

-- Step 3: Convert to proper NOT NULL
ALTER TABLE users ALTER COLUMN email SET NOT NULL;
ALTER TABLE users DROP CONSTRAINT users_email_not_null;
```

### Foreign Key Constraint

```sql
-- Step 1: Add as NOT VALID
ALTER TABLE orders ADD CONSTRAINT orders_user_fk
  FOREIGN KEY (user_id) REFERENCES users(id) NOT VALID;

-- Step 2: Validate (scans table but doesn't lock)
ALTER TABLE orders VALIDATE CONSTRAINT orders_user_fk;
```

### Check Constraint

```sql
-- Step 1: Add as NOT VALID
ALTER TABLE products ADD CONSTRAINT products_price_positive
  CHECK (price >= 0) NOT VALID;

-- Step 2: Fix violating rows
UPDATE products SET price = 0 WHERE price < 0;

-- Step 3: Validate
ALTER TABLE products VALIDATE CONSTRAINT products_price_positive;
```

---

## Adding Indexes

### Safe Index Creation

```sql
-- ✅ CONCURRENTLY doesn't lock table
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);

-- ⚠️ Standard CREATE INDEX locks table
CREATE INDEX idx_users_email ON users(email);  -- DON'T DO THIS
```

### Monitoring Index Creation

```sql
-- Check progress (PostgreSQL 12+)
SELECT
  relname AS table_name,
  phase,
  blocks_total,
  blocks_done,
  tuples_total,
  tuples_done
FROM pg_stat_progress_create_index;
```

### Failed Concurrent Index

```sql
-- If CONCURRENTLY fails, it leaves invalid index
SELECT indexrelid::regclass, indisvalid
FROM pg_index
WHERE NOT indisvalid;

-- Drop invalid index and retry
DROP INDEX CONCURRENTLY idx_users_email;
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
```

---

## Table Restructuring

### Adding Primary Key

```sql
-- If table has no PK (avoid this situation)
-- Step 1: Add column
ALTER TABLE legacy_table ADD COLUMN id UUID DEFAULT gen_random_uuid();

-- Step 2: Backfill existing rows
UPDATE legacy_table SET id = gen_random_uuid() WHERE id IS NULL;

-- Step 3: Add constraint
ALTER TABLE legacy_table ADD CONSTRAINT legacy_table_pkey PRIMARY KEY (id);
```

### Splitting Table

```sql
-- Original monolithic table
-- users (id, email, password, profile_bio, profile_avatar, settings_json)

-- Step 1: Create new tables
CREATE TABLE user_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  bio TEXT,
  avatar_url TEXT
);

CREATE TABLE user_settings (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  settings JSONB NOT NULL DEFAULT '{}'
);

-- Step 2: Migrate data
INSERT INTO user_profiles (user_id, bio, avatar_url)
SELECT id, profile_bio, profile_avatar FROM users;

INSERT INTO user_settings (user_id, settings)
SELECT id, settings_json FROM users;

-- Step 3: Update application code
-- Step 4: Remove old columns
ALTER TABLE users 
  DROP COLUMN profile_bio,
  DROP COLUMN profile_avatar,
  DROP COLUMN settings_json;
```

---

## Rollback Strategies

### Pre-Migration Backup

```bash
# Full backup before migration
pg_dump -Fc -f backup_before_migration.dump dbname

# Restore if needed
pg_restore -d dbname backup_before_migration.dump
```

### Reversible Migrations

```sql
-- migration_001_up.sql
ALTER TABLE users ADD COLUMN nickname VARCHAR(100);

-- migration_001_down.sql
ALTER TABLE users DROP COLUMN nickname;
```

### Data-Preserving Rollback

```sql
-- Up: Rename column
ALTER TABLE users RENAME COLUMN name TO full_name;

-- Down: Rename back
ALTER TABLE users RENAME COLUMN full_name TO name;
```

### Non-Reversible Migrations

Document clearly when rollback is not possible:

```sql
-- ⚠️ NON-REVERSIBLE: Dropping data
-- Before running: Verify data is no longer needed
-- Backup: SELECT * FROM old_data INTO backup_old_data;
DROP TABLE old_data;
```

---

## Migration Testing

### Test on Production Copy

```bash
# Create test database from production backup
pg_restore -d test_db production_backup.dump

# Run migration
psql -d test_db -f migration.sql

# Verify
psql -d test_db -c "SELECT COUNT(*) FROM affected_table"
```

### Schema Comparison

```bash
# Export schemas
pg_dump --schema-only -d production > prod_schema.sql
pg_dump --schema-only -d staging > staging_schema.sql

# Compare
diff prod_schema.sql staging_schema.sql
```

### Migration Timing

```sql
-- Time migration on test data
\timing on
-- Run migration
\timing off
```

---

## ORM-Specific Migrations

### Prisma

```bash
# Generate migration without applying
npx prisma migrate dev --create-only

# Review generated SQL in prisma/migrations/

# Apply migration
npx prisma migrate dev

# Production deployment
npx prisma migrate deploy
```

```prisma
// schema.prisma changes are tracked
model User {
  id    String @id @default(uuid())
  email String @unique
  name  String?  // Added field
}
```

### Drizzle

```typescript
// drizzle/migrations/0001_add_name.ts
import { sql } from 'drizzle-orm';
import { pgTable, varchar } from 'drizzle-orm/pg-core';

export async function up(db) {
  await db.execute(sql`
    ALTER TABLE users ADD COLUMN name VARCHAR(255);
  `);
}

export async function down(db) {
  await db.execute(sql`
    ALTER TABLE users DROP COLUMN name;
  `);
}
```

```bash
# Generate migrations from schema changes
npx drizzle-kit generate:pg

# Apply migrations
npx drizzle-kit push:pg
```

---

## Migration Checklist

```
Pre-Migration:
□ Migration tested on copy of production data
□ Rollback plan documented
□ Estimated duration calculated
□ Maintenance window scheduled (if needed)
□ Team notified

During Migration:
□ Monitor database locks
□ Monitor replication lag
□ Monitor application errors
□ Ready to rollback

Post-Migration:
□ Verify data integrity
□ Check application functionality
□ Monitor performance
□ Update documentation
```

---

## Lock Monitoring

```sql
-- Check for locks during migration
SELECT
  pid,
  now() - pg_stat_activity.query_start AS duration,
  query,
  state
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '5 seconds'
  AND state != 'idle';

-- Check for blocked queries
SELECT
  blocked_locks.pid AS blocked_pid,
  blocking_locks.pid AS blocking_pid,
  blocked_activity.usename AS blocked_user,
  blocking_activity.usename AS blocking_user,
  blocked_activity.query AS blocked_statement,
  blocking_activity.query AS blocking_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity 
  ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks 
  ON blocking_locks.locktype = blocked_locks.locktype
  AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
  AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
  AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
  AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
  AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
  AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
  AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
  AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
  AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
  AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity 
  ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
```
