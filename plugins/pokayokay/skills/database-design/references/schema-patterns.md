# Schema Patterns

Common database schema patterns for typical application needs.

## User Management

### Basic User Schema

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) NOT NULL UNIQUE,
  email_verified_at TIMESTAMPTZ,
  password_hash VARCHAR(255),  -- NULL for OAuth-only users
  name VARCHAR(255),
  avatar_url TEXT,
  
  -- Status
  status VARCHAR(20) NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'suspended', 'deleted')),
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,  -- soft delete
  
  -- Optimistic locking
  version INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX idx_users_email ON users(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_status ON users(status) WHERE deleted_at IS NULL;
```

### User with Profile (1:1)

```sql
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  
  -- Extended profile data
  bio TEXT,
  location VARCHAR(255),
  website VARCHAR(255),
  timezone VARCHAR(50) DEFAULT 'UTC',
  locale VARCHAR(10) DEFAULT 'en',
  
  -- Preferences (JSONB for flexibility)
  preferences JSONB NOT NULL DEFAULT '{}',
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### Authentication Methods

```sql
-- Support multiple auth methods per user
CREATE TABLE user_authentications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  provider VARCHAR(50) NOT NULL,  -- 'email', 'google', 'github', etc.
  provider_user_id VARCHAR(255),  -- NULL for email auth
  
  -- For email auth
  password_hash VARCHAR(255),
  
  -- OAuth tokens (encrypted at rest)
  access_token TEXT,
  refresh_token TEXT,
  expires_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(provider, provider_user_id),
  UNIQUE(user_id, provider)
);

CREATE INDEX idx_user_auth_provider ON user_authentications(provider, provider_user_id);
```

---

## Multi-Tenancy

### Shared Database, Tenant Column

Simplest approach. All tables have tenant_id.

```sql
CREATE TABLE tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(100) NOT NULL UNIQUE,
  settings JSONB NOT NULL DEFAULT '{}',
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  email VARCHAR(255) NOT NULL,
  -- ...
  
  UNIQUE(tenant_id, email)  -- Email unique per tenant
);

-- Row Level Security (PostgreSQL)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON users
  USING (tenant_id = current_setting('app.current_tenant_id')::UUID);
```

### Organization/Workspace Pattern

Users can belong to multiple organizations.

```sql
CREATE TABLE organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(100) NOT NULL UNIQUE,
  owner_id UUID NOT NULL REFERENCES users(id),
  
  -- Billing
  plan VARCHAR(50) NOT NULL DEFAULT 'free',
  subscription_id VARCHAR(255),
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE organization_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  role VARCHAR(50) NOT NULL DEFAULT 'member'
    CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
  
  invited_by UUID REFERENCES users(id),
  invited_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  accepted_at TIMESTAMPTZ,
  
  UNIQUE(organization_id, user_id)
);

CREATE INDEX idx_org_members_user ON organization_members(user_id);
CREATE INDEX idx_org_members_org ON organization_members(organization_id);
```

---

## Polymorphic Associations

When a table needs to reference multiple other tables.

### Approach 1: Multiple Nullable FKs

Simple but doesn't scale.

```sql
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  body TEXT NOT NULL,
  author_id UUID NOT NULL REFERENCES users(id),
  
  -- Only one of these will be set
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  article_id UUID REFERENCES articles(id) ON DELETE CASCADE,
  video_id UUID REFERENCES videos(id) ON DELETE CASCADE,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Ensure exactly one parent
  CHECK (
    (post_id IS NOT NULL)::int +
    (article_id IS NOT NULL)::int +
    (video_id IS NOT NULL)::int = 1
  )
);
```

### Approach 2: Discriminated Union

More flexible, works with any number of types.

```sql
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  body TEXT NOT NULL,
  author_id UUID NOT NULL REFERENCES users(id),
  
  -- Polymorphic reference
  commentable_type VARCHAR(50) NOT NULL,
  commentable_id UUID NOT NULL,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CHECK (commentable_type IN ('Post', 'Article', 'Video'))
);

CREATE INDEX idx_comments_target ON comments(commentable_type, commentable_id);
```

### Approach 3: Separate Junction Tables

Best referential integrity, more tables.

```sql
CREATE TABLE post_comments (
  comment_id UUID PRIMARY KEY REFERENCES comments(id) ON DELETE CASCADE,
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE
);

CREATE TABLE article_comments (
  comment_id UUID PRIMARY KEY REFERENCES comments(id) ON DELETE CASCADE,
  article_id UUID NOT NULL REFERENCES articles(id) ON DELETE CASCADE
);
```

---

## Hierarchical Data

### Adjacency List (Simple)

```sql
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  parent_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_categories_parent ON categories(parent_id);

-- Get children (one level)
SELECT * FROM categories WHERE parent_id = $1;

-- Get all descendants (recursive CTE)
WITH RECURSIVE descendants AS (
  SELECT * FROM categories WHERE id = $1
  UNION ALL
  SELECT c.* FROM categories c
  JOIN descendants d ON c.parent_id = d.id
)
SELECT * FROM descendants;
```

### Materialized Path

Good for read-heavy, breadcrumb displays.

```sql
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  parent_id UUID REFERENCES categories(id),
  
  -- Path: '/root-id/parent-id/this-id/'
  path TEXT NOT NULL,
  depth INTEGER NOT NULL DEFAULT 0,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_categories_path ON categories USING gist (path gist_trgm_ops);

-- Get all descendants
SELECT * FROM categories WHERE path LIKE $1 || '%';

-- Get ancestors
SELECT * FROM categories 
WHERE $1 LIKE path || '%' AND id != $2
ORDER BY depth;
```

### Nested Sets

Best for read-heavy, complex queries. Hard to maintain.

```sql
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  
  lft INTEGER NOT NULL,
  rgt INTEGER NOT NULL,
  depth INTEGER NOT NULL DEFAULT 0,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_categories_nested ON categories(lft, rgt);

-- Get all descendants
SELECT * FROM categories
WHERE lft > $parent_lft AND rgt < $parent_rgt
ORDER BY lft;

-- Get path to root
SELECT * FROM categories
WHERE lft < $node_lft AND rgt > $node_rgt
ORDER BY lft;
```

---

## Tagging

### Simple Tags Table

```sql
CREATE TABLE tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL UNIQUE,
  slug VARCHAR(100) NOT NULL UNIQUE,
  color VARCHAR(7),  -- hex color
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE post_tags (
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  
  PRIMARY KEY (post_id, tag_id)
);

CREATE INDEX idx_post_tags_tag ON post_tags(tag_id);

-- Find posts with specific tags
SELECT DISTINCT p.* FROM posts p
JOIN post_tags pt ON p.id = pt.post_id
WHERE pt.tag_id IN ($tag_ids);

-- Find posts with ALL specified tags
SELECT p.* FROM posts p
JOIN post_tags pt ON p.id = pt.post_id
WHERE pt.tag_id IN ($tag_ids)
GROUP BY p.id
HAVING COUNT(DISTINCT pt.tag_id) = $tag_count;
```

### PostgreSQL Array Approach

```sql
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  tags TEXT[] NOT NULL DEFAULT '{}',
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_posts_tags ON posts USING gin(tags);

-- Find posts with any of the tags
SELECT * FROM posts WHERE tags && ARRAY['tech', 'ai'];

-- Find posts with all tags
SELECT * FROM posts WHERE tags @> ARRAY['tech', 'ai'];
```

---

## Audit Trail

### Full History Table

```sql
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- What changed
  table_name VARCHAR(100) NOT NULL,
  record_id UUID NOT NULL,
  action VARCHAR(20) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
  
  -- Change details
  old_data JSONB,
  new_data JSONB,
  changed_fields TEXT[],
  
  -- Who and when
  user_id UUID REFERENCES users(id),
  ip_address INET,
  user_agent TEXT,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_table_record ON audit_logs(table_name, record_id);
CREATE INDEX idx_audit_created ON audit_logs(created_at);
CREATE INDEX idx_audit_user ON audit_logs(user_id);

-- Trigger function (PostgreSQL)
CREATE OR REPLACE FUNCTION audit_trigger_fn()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_logs (table_name, record_id, action, old_data, new_data)
  VALUES (
    TG_TABLE_NAME,
    COALESCE(NEW.id, OLD.id),
    TG_OP,
    CASE WHEN TG_OP != 'INSERT' THEN to_jsonb(OLD) END,
    CASE WHEN TG_OP != 'DELETE' THEN to_jsonb(NEW) END
  );
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Apply to table
CREATE TRIGGER audit_users
  AFTER INSERT OR UPDATE OR DELETE ON users
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
```

---

## Event Sourcing

### Event Store Pattern

```sql
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Aggregate identification
  aggregate_type VARCHAR(100) NOT NULL,
  aggregate_id UUID NOT NULL,
  
  -- Event details
  event_type VARCHAR(100) NOT NULL,
  event_data JSONB NOT NULL,
  metadata JSONB DEFAULT '{}',
  
  -- Ordering
  version INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(aggregate_type, aggregate_id, version)
);

CREATE INDEX idx_events_aggregate ON events(aggregate_type, aggregate_id, version);
CREATE INDEX idx_events_type ON events(event_type);
CREATE INDEX idx_events_created ON events(created_at);

-- Snapshots for performance
CREATE TABLE snapshots (
  aggregate_type VARCHAR(100) NOT NULL,
  aggregate_id UUID NOT NULL,
  version INTEGER NOT NULL,
  state JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  PRIMARY KEY (aggregate_type, aggregate_id)
);
```

---

## File Storage

### File Metadata Pattern

```sql
CREATE TABLE files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- File info
  filename VARCHAR(255) NOT NULL,
  original_filename VARCHAR(255) NOT NULL,
  mime_type VARCHAR(100) NOT NULL,
  size_bytes BIGINT NOT NULL,
  checksum VARCHAR(64),  -- SHA-256
  
  -- Storage location
  storage_provider VARCHAR(50) NOT NULL DEFAULT 's3',
  storage_path TEXT NOT NULL,
  storage_bucket VARCHAR(255),
  
  -- Access
  is_public BOOLEAN NOT NULL DEFAULT FALSE,
  expires_at TIMESTAMPTZ,
  
  -- Ownership
  uploaded_by UUID REFERENCES users(id),
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Polymorphic attachment
CREATE TABLE attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  file_id UUID NOT NULL REFERENCES files(id) ON DELETE CASCADE,
  
  attachable_type VARCHAR(50) NOT NULL,
  attachable_id UUID NOT NULL,
  
  purpose VARCHAR(50),  -- 'avatar', 'cover', 'document', etc.
  position INTEGER DEFAULT 0,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(file_id, attachable_type, attachable_id)
);

CREATE INDEX idx_attachments_target ON attachments(attachable_type, attachable_id);
```

---

## Queue/Jobs

### Simple Job Queue

```sql
CREATE TABLE jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Job identification
  queue VARCHAR(100) NOT NULL DEFAULT 'default',
  job_type VARCHAR(100) NOT NULL,
  
  -- Payload
  payload JSONB NOT NULL,
  
  -- Scheduling
  scheduled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  priority INTEGER NOT NULL DEFAULT 0,
  
  -- Execution
  attempts INTEGER NOT NULL DEFAULT 0,
  max_attempts INTEGER NOT NULL DEFAULT 3,
  last_error TEXT,
  
  -- Status
  status VARCHAR(20) NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
  
  -- Timestamps
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_jobs_queue_status ON jobs(queue, status, scheduled_at)
  WHERE status = 'pending';
CREATE INDEX idx_jobs_type ON jobs(job_type);

-- Fetch next job (with locking)
UPDATE jobs
SET status = 'processing', started_at = NOW(), attempts = attempts + 1
WHERE id = (
  SELECT id FROM jobs
  WHERE queue = $1 AND status = 'pending' AND scheduled_at <= NOW()
  ORDER BY priority DESC, scheduled_at ASC
  FOR UPDATE SKIP LOCKED
  LIMIT 1
)
RETURNING *;
```
