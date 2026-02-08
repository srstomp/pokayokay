# Test Data Factories and Fixtures

Factory patterns, builders, and fixture strategies for test data management.

## Test Data Strategies

| Strategy | Use Case | Pros | Cons |
|----------|----------|------|------|
| **Factories** | Dynamic test data | Flexible, readable | More code |
| **Fixtures** | Static reference data | Fast, predictable | Less flexible |
| **Seeds** | Baseline data | Consistent starting point | Can get stale |
| **Snapshots** | Prod-like data | Realistic | Privacy concerns |

**Recommendation**: Use factories as primary strategy, fixtures for reference data.

---

## Factories

### Basic Factory Pattern

```typescript
// tests/helpers/factories/user.ts
import { db } from '../db';
import { User } from '../../../src/types';

interface CreateUserInput {
  email?: string;
  name?: string;
  password?: string;
  role?: 'admin' | 'user' | 'guest';
  verified?: boolean;
}

let userCounter = 0;

export async function createUser(input: CreateUserInput = {}): Promise<User> {
  userCounter++;

  const userData = {
    email: input.email ?? `user${userCounter}@test.com`,
    name: input.name ?? `Test User ${userCounter}`,
    password: input.password ?? 'password123',
    role: input.role ?? 'user',
    verified: input.verified ?? true,
  };

  // Hash password if your app does this
  const hashedPassword = await hashPassword(userData.password);

  const user = await db.query<User>(
    `INSERT INTO users (email, name, password, role, verified)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [userData.email, userData.name, hashedPassword, userData.role, userData.verified]
  );

  return user.rows[0];
}

export async function createUsers(count: number, input: CreateUserInput = {}): Promise<User[]> {
  return Promise.all(
    Array.from({ length: count }, () => createUser(input))
  );
}
```

### Factory with Relationships

```typescript
// tests/helpers/factories/order.ts
import { createUser } from './user';
import { createProduct } from './product';
import { db } from '../db';

interface CreateOrderInput {
  userId?: string;
  items?: Array<{
    productId?: string;
    quantity?: number;
    price?: number;
  }>;
  status?: 'pending' | 'paid' | 'shipped' | 'delivered';
}

export async function createOrder(input: CreateOrderInput = {}): Promise<Order> {
  // Create user if not provided
  const userId = input.userId ?? (await createUser()).id;

  // Create order
  const order = await db.query<Order>(
    `INSERT INTO orders (user_id, status) VALUES ($1, $2) RETURNING *`,
    [userId, input.status ?? 'pending']
  );

  // Create order items
  const items = input.items ?? [{ quantity: 1 }];

  for (const item of items) {
    const productId = item.productId ?? (await createProduct()).id;
    const product = await db.query('SELECT price FROM products WHERE id = $1', [productId]);

    await db.query(
      `INSERT INTO order_items (order_id, product_id, quantity, price)
       VALUES ($1, $2, $3, $4)`,
      [order.rows[0].id, productId, item.quantity ?? 1, item.price ?? product.rows[0].price]
    );
  }

  // Return order with items
  return getOrderWithItems(order.rows[0].id);
}
```

### Factory Builder Pattern

```typescript
// tests/helpers/factories/builders/user-builder.ts
import { createUser } from '../user';

export class UserBuilder {
  private data: Partial<CreateUserInput> = {};

  withEmail(email: string): this {
    this.data.email = email;
    return this;
  }

  withName(name: string): this {
    this.data.name = name;
    return this;
  }

  asAdmin(): this {
    this.data.role = 'admin';
    return this;
  }

  asGuest(): this {
    this.data.role = 'guest';
    return this;
  }

  unverified(): this {
    this.data.verified = false;
    return this;
  }

  async build(): Promise<User> {
    return createUser(this.data);
  }
}

// Helper function
export function buildUser(): UserBuilder {
  return new UserBuilder();
}

// Usage
const admin = await buildUser()
  .withEmail('admin@test.com')
  .asAdmin()
  .build();

const unverifiedUser = await buildUser()
  .unverified()
  .build();
```

### Factory Index

```typescript
// tests/helpers/factories/index.ts
export { createUser, createUsers } from './user';
export { createProduct, createProducts } from './product';
export { createOrder } from './order';
export { createCategory } from './category';

// Builders
export { buildUser } from './builders/user-builder';
export { buildProduct } from './builders/product-builder';

// Convenience factories for common scenarios
export async function createUserWithOrders(orderCount: number = 1) {
  const user = await createUser();
  const orders = await Promise.all(
    Array.from({ length: orderCount }, () =>
      createOrder({ userId: user.id })
    )
  );
  return { user, orders };
}

export async function createProductWithInventory(stock: number = 10) {
  const product = await createProduct({ stock });
  return product;
}
```

---

## Fixtures

### JSON Fixtures

```typescript
// tests/fixtures/users.json
{
  "admin": {
    "email": "admin@example.com",
    "name": "Admin User",
    "role": "admin"
  },
  "regular": {
    "email": "user@example.com",
    "name": "Regular User",
    "role": "user"
  },
  "unverified": {
    "email": "unverified@example.com",
    "name": "Unverified User",
    "role": "user",
    "verified": false
  }
}
```

```typescript
// tests/helpers/fixtures.ts
import usersFixture from '../fixtures/users.json';
import productsFixture from '../fixtures/products.json';
import { createUser } from './factories';

type UserFixtureKey = keyof typeof usersFixture;

export async function loadUserFixture(key: UserFixtureKey): Promise<User> {
  const fixture = usersFixture[key];
  return createUser(fixture);
}

export async function loadAllUserFixtures(): Promise<Record<UserFixtureKey, User>> {
  const result: Record<string, User> = {};

  for (const [key, data] of Object.entries(usersFixture)) {
    result[key] = await createUser(data);
  }

  return result as Record<UserFixtureKey, User>;
}

// Usage
const admin = await loadUserFixture('admin');
const { admin, regular, unverified } = await loadAllUserFixtures();
```

### Typed Fixtures

```typescript
// tests/fixtures/index.ts
import { User, Product, Order } from '../../src/types';

export const userFixtures = {
  admin: {
    email: 'admin@example.com',
    name: 'Admin User',
    role: 'admin' as const,
    verified: true,
  },
  regular: {
    email: 'user@example.com',
    name: 'Regular User',
    role: 'user' as const,
    verified: true,
  },
} satisfies Record<string, Partial<User>>;

export const productFixtures = {
  basic: {
    name: 'Basic Product',
    price: 99.99,
    stock: 100,
  },
  outOfStock: {
    name: 'Out of Stock Product',
    price: 149.99,
    stock: 0,
  },
  expensive: {
    name: 'Expensive Product',
    price: 9999.99,
    stock: 5,
  },
} satisfies Record<string, Partial<Product>>;
```
