# Prisma Patterns

Prisma schema design, migrations, and best practices.

## Schema Basics

### Model Definition

```prisma
model User {
  id        String   @id @default(uuid())
  email     String   @unique
  name      String?
  password  String?
  
  // Relations
  posts     Post[]
  profile   Profile?
  
  // Timestamps
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")
  
  // Table mapping
  @@map("users")
}
```

### Common Field Types

```prisma
model Example {
  // IDs
  id        String   @id @default(uuid())         // UUID
  id        Int      @id @default(autoincrement()) // Auto-increment
  id        String   @id @default(cuid())         // CUID
  
  // Strings
  email     String   @unique
  name      String?                               // Nullable
  bio       String   @db.Text                     // Long text
  
  // Numbers
  count     Int      @default(0)
  price     Decimal  @db.Decimal(10, 2)
  amount    Float
  bigNum    BigInt
  
  // Boolean
  isActive  Boolean  @default(true)
  
  // DateTime
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  deletedAt DateTime?                             // Soft delete
  
  // JSON
  metadata  Json     @default("{}")
  
  // Enum
  status    Status   @default(PENDING)
}

enum Status {
  PENDING
  ACTIVE
  COMPLETED
  CANCELLED
}
```

---

## Relationships

### One-to-One

```prisma
model User {
  id      String   @id @default(uuid())
  profile Profile?
}

model Profile {
  id     String @id @default(uuid())
  bio    String?
  
  userId String @unique @map("user_id")
  user   User   @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  @@map("profiles")
}
```

### One-to-Many

```prisma
model User {
  id     String  @id @default(uuid())
  posts  Post[]
}

model Post {
  id       String @id @default(uuid())
  title    String
  
  authorId String @map("author_id")
  author   User   @relation(fields: [authorId], references: [id], onDelete: Cascade)
  
  @@index([authorId])
  @@map("posts")
}
```

### Many-to-Many (Implicit)

```prisma
model Post {
  id         String     @id @default(uuid())
  title      String
  categories Category[]
}

model Category {
  id    String @id @default(uuid())
  name  String @unique
  posts Post[]
}

// Creates implicit _CategoryToPost table
```

### Many-to-Many (Explicit)

Use when you need additional fields on the join.

```prisma
model User {
  id          String           @id @default(uuid())
  memberships OrganizationMember[]
}

model Organization {
  id      String               @id @default(uuid())
  name    String
  members OrganizationMember[]
}

model OrganizationMember {
  id             String       @id @default(uuid())
  role           MemberRole   @default(MEMBER)
  joinedAt       DateTime     @default(now()) @map("joined_at")
  
  userId         String       @map("user_id")
  user           User         @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  organizationId String       @map("organization_id")
  organization   Organization @relation(fields: [organizationId], references: [id], onDelete: Cascade)
  
  @@unique([userId, organizationId])
  @@index([organizationId])
  @@map("organization_members")
}

enum MemberRole {
  OWNER
  ADMIN
  MEMBER
  VIEWER
}
```

### Self-Referential

```prisma
model Category {
  id       String     @id @default(uuid())
  name     String
  
  parentId String?    @map("parent_id")
  parent   Category?  @relation("CategoryHierarchy", fields: [parentId], references: [id])
  children Category[] @relation("CategoryHierarchy")
  
  @@index([parentId])
  @@map("categories")
}
```

---

## Indexes

```prisma
model User {
  id        String   @id @default(uuid())
  email     String   @unique                    // Unique constraint = index
  name      String
  status    String
  createdAt DateTime @default(now())
  
  // Single column index
  @@index([status])
  
  // Composite index
  @@index([status, createdAt(sort: Desc)])
  
  // Named index
  @@index([name], name: "idx_users_name")
  
  @@map("users")
}
```

### Full-Text Index (PostgreSQL)

```prisma
model Post {
  id      String @id @default(uuid())
  title   String
  content String

  @@index([title, content], type: Gin)
}
```

---

## Database Mapping

### Column Names (snake_case)

```prisma
model User {
  id        String   @id @default(uuid())
  firstName String   @map("first_name")
  lastName  String   @map("last_name")
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")
  
  @@map("users")
}
```

### Database-Specific Types

```prisma
model Product {
  id       String  @id @default(uuid())
  name     String  @db.VarChar(255)
  price    Decimal @db.Decimal(10, 2)
  data     Json    @db.JsonB              // PostgreSQL JSONB
  bio      String  @db.Text
}
```

---

## Migrations

### Generate Migration

```bash
# Development: Create and apply
npx prisma migrate dev --name add_user_profile

# Create migration without applying
npx prisma migrate dev --create-only --name add_user_profile

# Review generated SQL in prisma/migrations/
```

### Production Deployment

```bash
# Apply pending migrations
npx prisma migrate deploy

# Check migration status
npx prisma migrate status
```

### Reset Database (Dev Only)

```bash
# Reset and reseed
npx prisma migrate reset
```

### Custom Migration SQL

Edit generated SQL before applying:

```sql
-- prisma/migrations/20240115_add_status/migration.sql

-- Generated:
ALTER TABLE "users" ADD COLUMN "status" TEXT;

-- Modified for safe deployment:
ALTER TABLE "users" ADD COLUMN "status" TEXT;
UPDATE "users" SET "status" = 'active' WHERE "status" IS NULL;
ALTER TABLE "users" ALTER COLUMN "status" SET NOT NULL;
ALTER TABLE "users" ALTER COLUMN "status" SET DEFAULT 'active';
```

---

## Query Patterns

### Basic CRUD

```typescript
// Create
const user = await prisma.user.create({
  data: {
    email: 'user@example.com',
    name: 'John Doe',
  },
});

// Read
const user = await prisma.user.findUnique({
  where: { email: 'user@example.com' },
});

const users = await prisma.user.findMany({
  where: { status: 'active' },
  orderBy: { createdAt: 'desc' },
  take: 10,
});

// Update
const user = await prisma.user.update({
  where: { id: userId },
  data: { name: 'Jane Doe' },
});

// Delete
await prisma.user.delete({
  where: { id: userId },
});
```

### Relations

```typescript
// Include relations
const user = await prisma.user.findUnique({
  where: { id: userId },
  include: {
    posts: true,
    profile: true,
  },
});

// Nested include
const user = await prisma.user.findUnique({
  where: { id: userId },
  include: {
    posts: {
      include: {
        comments: true,
      },
    },
  },
});

// Create with relations
const user = await prisma.user.create({
  data: {
    email: 'user@example.com',
    profile: {
      create: {
        bio: 'Hello world',
      },
    },
  },
});
```

### Filtering

```typescript
// Complex where
const users = await prisma.user.findMany({
  where: {
    AND: [
      { status: 'active' },
      {
        OR: [
          { role: 'admin' },
          { createdAt: { gte: new Date('2024-01-01') } },
        ],
      },
    ],
    email: {
      contains: '@example.com',
    },
    posts: {
      some: {
        published: true,
      },
    },
  },
});
```

### Pagination

```typescript
// Offset-based
const users = await prisma.user.findMany({
  skip: 20,
  take: 10,
  orderBy: { createdAt: 'desc' },
});

// Cursor-based
const users = await prisma.user.findMany({
  take: 10,
  cursor: { id: lastUserId },
  skip: 1, // Skip the cursor itself
  orderBy: { id: 'asc' },
});
```

### Transactions

```typescript
// Sequential transaction
const [user, post] = await prisma.$transaction([
  prisma.user.create({ data: { email: 'user@example.com' } }),
  prisma.post.create({ data: { title: 'Hello', authorId: '...' } }),
]);

// Interactive transaction
const result = await prisma.$transaction(async (tx) => {
  const user = await tx.user.create({
    data: { email: 'user@example.com' },
  });
  
  await tx.post.create({
    data: { title: 'First post', authorId: user.id },
  });
  
  return user;
});
```

---

## Soft Deletes

### Schema

```prisma
model User {
  id        String    @id @default(uuid())
  email     String    @unique
  deletedAt DateTime? @map("deleted_at")
  
  @@index([deletedAt])
  @@map("users")
}
```

### Extension for Automatic Filtering

```typescript
// prisma/extensions/softDelete.ts
import { Prisma } from '@prisma/client';

export const softDeleteExtension = Prisma.defineExtension({
  name: 'softDelete',
  query: {
    user: {
      findMany({ args, query }) {
        args.where = { ...args.where, deletedAt: null };
        return query(args);
      },
      findFirst({ args, query }) {
        args.where = { ...args.where, deletedAt: null };
        return query(args);
      },
    },
  },
});

// Usage
const prisma = new PrismaClient().$extends(softDeleteExtension);

// Soft delete
await prisma.user.update({
  where: { id: userId },
  data: { deletedAt: new Date() },
});
```

---

## Multi-Tenancy

### Schema with Tenant ID

```prisma
model Tenant {
  id    String @id @default(uuid())
  name  String
  users User[]
}

model User {
  id       String @id @default(uuid())
  email    String
  
  tenantId String @map("tenant_id")
  tenant   Tenant @relation(fields: [tenantId], references: [id])
  
  @@unique([tenantId, email])
  @@index([tenantId])
  @@map("users")
}
```

### Tenant-Scoped Queries

```typescript
// Middleware for tenant isolation
prisma.$use(async (params, next) => {
  if (params.model && ['User', 'Post'].includes(params.model)) {
    if (params.action === 'findMany' || params.action === 'findFirst') {
      params.args.where = {
        ...params.args.where,
        tenantId: getCurrentTenantId(),
      };
    }
    if (params.action === 'create') {
      params.args.data = {
        ...params.args.data,
        tenantId: getCurrentTenantId(),
      };
    }
  }
  return next(params);
});
```

---

## Performance Tips

### Select Only Needed Fields

```typescript
// Bad: Fetches all fields
const users = await prisma.user.findMany();

// Good: Fetches only needed fields
const users = await prisma.user.findMany({
  select: {
    id: true,
    email: true,
    name: true,
  },
});
```

### Avoid N+1 with Include

```typescript
// Bad: N+1 queries
const users = await prisma.user.findMany();
for (const user of users) {
  const posts = await prisma.post.findMany({
    where: { authorId: user.id },
  });
}

// Good: Single query with include
const users = await prisma.user.findMany({
  include: { posts: true },
});
```

### Batch Operations

```typescript
// Bad: Individual inserts
for (const data of items) {
  await prisma.item.create({ data });
}

// Good: Batch insert
await prisma.item.createMany({
  data: items,
  skipDuplicates: true,
});
```

### Raw Queries for Complex Operations

```typescript
// Complex aggregation
const stats = await prisma.$queryRaw`
  SELECT 
    date_trunc('month', created_at) AS month,
    COUNT(*) AS count,
    SUM(amount) AS total
  FROM orders
  WHERE created_at > ${startDate}
  GROUP BY date_trunc('month', created_at)
  ORDER BY month DESC
`;
```

---

## Seeding

```typescript
// prisma/seed.ts
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  // Clean existing data
  await prisma.user.deleteMany();
  
  // Seed users
  const user = await prisma.user.create({
    data: {
      email: 'admin@example.com',
      name: 'Admin User',
      profile: {
        create: {
          bio: 'System administrator',
        },
      },
    },
  });
  
  console.log('Seeded:', user);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
```

```json
// package.json
{
  "prisma": {
    "seed": "ts-node prisma/seed.ts"
  }
}
```

```bash
# Run seed
npx prisma db seed
```
