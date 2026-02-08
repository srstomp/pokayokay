# Test Database Management

Database helpers, cleanup strategies, configuration, and data generation utilities.

## Database Helper

```typescript
// tests/helpers/db.ts
import { Pool, PoolClient } from 'pg';

const pool = new Pool({
  connectionString: process.env.TEST_DATABASE_URL,
});

export const db = {
  pool,

  async query<T>(sql: string, params?: unknown[]): Promise<{ rows: T[] }> {
    return pool.query(sql, params);
  },

  async connect(): Promise<void> {
    // Verify connection
    const client = await pool.connect();
    client.release();
  },

  async close(): Promise<void> {
    await pool.end();
  },

  async migrate(): Promise<void> {
    // Run migrations
    // Using your migration tool
  },

  async truncateAll(): Promise<void> {
    const tables = await pool.query(`
      SELECT tablename FROM pg_tables
      WHERE schemaname = 'public'
      AND tablename != 'migrations'
    `);

    for (const { tablename } of tables.rows) {
      await pool.query(`TRUNCATE TABLE "${tablename}" CASCADE`);
    }
  },

  async clear(table: string): Promise<void> {
    await pool.query(`TRUNCATE TABLE "${table}" CASCADE`);
  },

  async seed(): Promise<void> {
    // Load seed data
    await this.clear('users');
    await this.clear('products');

    // Insert seed data
  },
};
```

## Transaction Wrapper

```typescript
// tests/helpers/db.ts
export async function withTransaction<T>(
  fn: (client: PoolClient) => Promise<T>
): Promise<T> {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

// Rollback after each test (faster than truncate)
export async function withRollback<T>(
  fn: (client: PoolClient) => Promise<T>
): Promise<T> {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    const result = await fn(client);
    return result;
  } finally {
    await client.query('ROLLBACK');
    client.release();
  }
}
```

## Per-Test Isolation

```typescript
// tests/setup.ts - Strategy 1: Truncate
import { beforeEach, afterAll } from 'vitest';
import { db } from './helpers/db';

beforeEach(async () => {
  await db.truncateAll();
});

afterAll(async () => {
  await db.close();
});
```

```typescript
// tests/setup.ts - Strategy 2: Transaction rollback (faster)
import { beforeEach, afterEach, afterAll } from 'vitest';
import { db, PoolClient } from './helpers/db';

let testClient: PoolClient;

beforeEach(async () => {
  testClient = await db.pool.connect();
  await testClient.query('BEGIN');
  // Override db to use this client
});

afterEach(async () => {
  await testClient.query('ROLLBACK');
  testClient.release();
});
```

## Seeding Reference Data

```typescript
// tests/helpers/seeds.ts
import { db } from './db';

export async function seedCategories(): Promise<void> {
  await db.query(`
    INSERT INTO categories (id, name, slug) VALUES
    ('cat-1', 'Electronics', 'electronics'),
    ('cat-2', 'Clothing', 'clothing'),
    ('cat-3', 'Books', 'books')
    ON CONFLICT (id) DO NOTHING
  `);
}

export async function seedRoles(): Promise<void> {
  await db.query(`
    INSERT INTO roles (id, name, permissions) VALUES
    ('role-admin', 'admin', '{"all": true}'),
    ('role-user', 'user', '{"read": true, "write": true}'),
    ('role-guest', 'guest', '{"read": true}')
    ON CONFLICT (id) DO NOTHING
  `);
}

export async function seedAll(): Promise<void> {
  await seedRoles();
  await seedCategories();
}
```

```typescript
// tests/setup.ts
import { beforeAll, beforeEach } from 'vitest';
import { db } from './helpers/db';
import { seedAll } from './helpers/seeds';

beforeAll(async () => {
  await db.connect();
  await db.migrate();
  await seedAll(); // Reference data seeded once
});

beforeEach(async () => {
  // Only truncate test-specific tables
  await db.clear('users');
  await db.clear('orders');
  await db.clear('order_items');
  // Don't clear categories, roles
});
```

---

## Test Database Configuration

### Environment Variables

```bash
# .env.test
DATABASE_URL=postgresql://test:test@localhost:5432/myapp_test
JWT_SECRET=test-secret
NODE_ENV=test
```

### Docker Compose for Test DB

```yaml
# docker-compose.test.yml
version: '3.8'

services:
  test-db:
    image: postgres:15
    environment:
      POSTGRES_USER: test
      POSTGRES_PASSWORD: test
      POSTGRES_DB: myapp_test
    ports:
      - "5433:5432"
    tmpfs:
      - /var/lib/postgresql/data  # In-memory for speed
```

```bash
# Start test database
docker-compose -f docker-compose.test.yml up -d

# Run tests
npm test

# Stop
docker-compose -f docker-compose.test.yml down
```

### In-Memory SQLite (Alternative)

```typescript
// tests/helpers/db-sqlite.ts
import Database from 'better-sqlite3';

let db: Database.Database;

export function getDb(): Database.Database {
  if (!db) {
    db = new Database(':memory:');
    runMigrations(db);
  }
  return db;
}

export function resetDb(): void {
  db?.close();
  db = new Database(':memory:');
  runMigrations(db);
}

function runMigrations(db: Database.Database): void {
  db.exec(`
    CREATE TABLE users (
      id TEXT PRIMARY KEY,
      email TEXT UNIQUE NOT NULL,
      name TEXT,
      password TEXT,
      role TEXT DEFAULT 'user',
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE products (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      price REAL NOT NULL,
      stock INTEGER DEFAULT 0
    );
  `);
}
```

---

## Cleanup Strategies

### Truncate Tables

```typescript
// Pros: Clean slate, simple
// Cons: Slower, resets sequences

async function truncateAll(): Promise<void> {
  await db.query(`
    TRUNCATE TABLE users, orders, order_items, products CASCADE
  `);
}
```

### Delete with WHERE

```typescript
// Pros: Can be selective
// Cons: May leave orphans

async function cleanupTestData(): Promise<void> {
  // Delete test data by convention (e.g., test emails)
  await db.query(`DELETE FROM users WHERE email LIKE '%@test.com'`);
}
```

### Transaction Rollback

```typescript
// Pros: Fastest, cleanest
// Cons: More complex setup

let savepoint: string;

beforeEach(async () => {
  savepoint = `sp_${Date.now()}`;
  await db.query(`SAVEPOINT ${savepoint}`);
});

afterEach(async () => {
  await db.query(`ROLLBACK TO SAVEPOINT ${savepoint}`);
});
```

### Cleanup by Test ID

```typescript
// Tag all test data with unique test ID
let testId: string;

beforeEach(() => {
  testId = `test_${Date.now()}_${Math.random().toString(36).slice(2)}`;
});

afterEach(async () => {
  await db.query(`DELETE FROM users WHERE test_id = $1`, [testId]);
  await db.query(`DELETE FROM orders WHERE test_id = $1`, [testId]);
});

// Factory includes test_id
async function createUser(input: CreateUserInput): Promise<User> {
  return db.query(
    `INSERT INTO users (email, name, test_id) VALUES ($1, $2, $3) RETURNING *`,
    [input.email, input.name, testId]
  );
}
```

---

## Data Generation Utilities

### Faker Integration

```typescript
// tests/helpers/fake.ts
import { faker } from '@faker-js/faker';

export const fake = {
  user: () => ({
    email: faker.internet.email(),
    name: faker.person.fullName(),
    password: faker.internet.password({ length: 12 }),
  }),

  product: () => ({
    name: faker.commerce.productName(),
    description: faker.commerce.productDescription(),
    price: parseFloat(faker.commerce.price({ min: 10, max: 1000 })),
    stock: faker.number.int({ min: 0, max: 100 }),
  }),

  address: () => ({
    street: faker.location.streetAddress(),
    city: faker.location.city(),
    state: faker.location.state(),
    zip: faker.location.zipCode(),
    country: faker.location.country(),
  }),

  creditCard: () => ({
    number: faker.finance.creditCardNumber(),
    expiry: faker.date.future().toISOString().slice(0, 7),
    cvv: faker.finance.creditCardCVV(),
  }),
};

// Usage
const user = await createUser(fake.user());
```

### Deterministic Data (for snapshots)

```typescript
import { faker } from '@faker-js/faker';

// Set seed for reproducible data
faker.seed(12345);

// Now faker will generate same values every time
const user1 = fake.user(); // Always same
const user2 = fake.user(); // Always same

// Reset for different sequence
faker.seed(67890);
```

### Sequence Generators

```typescript
// tests/helpers/sequences.ts
const sequences: Record<string, number> = {};

export function nextSeq(name: string): number {
  sequences[name] = (sequences[name] ?? 0) + 1;
  return sequences[name];
}

export function resetSeq(name?: string): void {
  if (name) {
    sequences[name] = 0;
  } else {
    Object.keys(sequences).forEach(key => {
      sequences[key] = 0;
    });
  }
}

// Usage
const email = `user${nextSeq('user')}@test.com`; // user1@test.com
const email2 = `user${nextSeq('user')}@test.com`; // user2@test.com

// In setup
beforeEach(() => {
  resetSeq();
});
```

---

## Test Data Best Practices

### DO

```typescript
// Use factories for test-specific data
const user = await createUser({ role: 'admin' });

// Create only what you need
const order = await createOrder({ userId: user.id });

// Use meaningful test data
const product = await createProduct({
  name: 'Premium Widget',
  price: 299.99,
});

// Clean up after tests
afterEach(async () => {
  await db.truncateAll();
});

// Isolate tests
it('test 1', async () => {
  const user = await createUser(); // Own user
});

it('test 2', async () => {
  const user = await createUser(); // Own user
});
```

### DON'T

```typescript
// Share mutable data between tests
let sharedUser: User;
beforeAll(async () => {
  sharedUser = await createUser();
});

// Depend on specific IDs
expect(user.id).toBe('123'); // Fragile

// Use production data
const users = await db.query('SELECT * FROM production_users');

// Hardcode dates
const user = await createUser({
  createdAt: '2024-01-15T10:00:00Z', // Will break
});

// Leave test data behind
it('creates user', async () => {
  await createUser(); // Never cleaned up
});
```
