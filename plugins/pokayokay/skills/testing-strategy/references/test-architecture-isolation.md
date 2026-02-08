# Test Isolation and Performance

Playwright configuration, database isolation, transaction rollback, module isolation, and performance optimization.

## Playwright Configuration

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html', { outputFolder: 'playwright-report' }],
    ['json', { outputFile: 'test-results.json' }],
    process.env.CI ? ['github'] : ['list'],
  ],

  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },

  projects: [
    // Setup project for authentication state
    {
      name: 'setup',
      testMatch: /.*\.setup\.ts/,
    },
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        storageState: 'playwright/.auth/user.json',
      },
      dependencies: ['setup'],
    },
    {
      name: 'firefox',
      use: {
        ...devices['Desktop Firefox'],
        storageState: 'playwright/.auth/user.json',
      },
      dependencies: ['setup'],
    },
    {
      name: 'webkit',
      use: {
        ...devices['Desktop Safari'],
        storageState: 'playwright/.auth/user.json',
      },
      dependencies: ['setup'],
    },
    // Mobile viewports
    {
      name: 'mobile-chrome',
      use: {
        ...devices['Pixel 5'],
        storageState: 'playwright/.auth/user.json',
      },
      dependencies: ['setup'],
    },
  ],

  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120 * 1000,
  },
});
```

---

## Test Isolation Patterns

### Database Isolation

```typescript
// tests/helpers/db.ts
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function clearDatabase() {
  const tableNames = await prisma.$queryRaw<
    Array<{ tablename: string }>
  >`SELECT tablename FROM pg_tables WHERE schemaname='public'`;

  for (const { tablename } of tableNames) {
    if (tablename !== '_prisma_migrations') {
      await prisma.$executeRawUnsafe(
        `TRUNCATE TABLE "public"."${tablename}" CASCADE;`
      );
    }
  }
}

export async function seedDatabase(data: SeedData) {
  await prisma.user.createMany({ data: data.users });
  await prisma.product.createMany({ data: data.products });
}

export { prisma };
```

### Transaction Rollback

```typescript
// tests/helpers/transactional.ts
import { prisma } from './db';

export function withTransaction<T>(
  fn: (tx: typeof prisma) => Promise<T>
): Promise<T> {
  return prisma.$transaction(async (tx) => {
    const result = await fn(tx);
    throw new Error('ROLLBACK'); // Force rollback
    return result;
  }).catch((e) => {
    if (e.message === 'ROLLBACK') return;
    throw e;
  });
}

// Usage in tests
it('creates order', async () => {
  await withTransaction(async (tx) => {
    const order = await tx.order.create({ data: orderData });
    expect(order.id).toBeDefined();
    // Transaction rolls back after test
  });
});
```

### Module Isolation

```typescript
// Reset module state between tests
beforeEach(() => {
  vi.resetModules();
});

// Or use isolated module imports
it('uses fresh module state', async () => {
  const { counter } = await import('./counter');
  counter.increment();
  expect(counter.value).toBe(1);
});
```

---

## Performance Optimization

### Parallel Execution

```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    pool: 'threads',        // or 'forks' for full isolation
    poolOptions: {
      threads: {
        singleThread: false,
        minThreads: 2,
        maxThreads: 8,
      },
    },
  },
});
```

### Test Sharding

```bash
# CI: Split tests across machines
vitest run --shard=1/3  # Machine 1
vitest run --shard=2/3  # Machine 2
vitest run --shard=3/3  # Machine 3

# Playwright sharding
npx playwright test --shard=1/3
```

### Selective Test Running

```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    // Only run tests affected by changed files
    changed: true,
    // Watch mode filter
    watchExclude: ['**/node_modules/**', '**/dist/**'],
  },
});
```

### Caching Strategies

```typescript
// Cache expensive setup
let cachedApp: Application;

beforeAll(async () => {
  if (!cachedApp) {
    cachedApp = await createApp();
  }
});

// Reuse query client in tests
const queryClient = new QueryClient({
  defaultOptions: {
    queries: { retry: false, staleTime: Infinity },
  },
});

beforeEach(() => {
  queryClient.clear();
});
```
