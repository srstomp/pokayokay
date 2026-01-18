# Test Architecture

Patterns for organizing tests, shared utilities, and configuration.

## Project Structures

### Monorepo Structure

```
packages/
├── web/
│   ├── src/
│   ├── tests/
│   │   ├── setup.ts
│   │   └── e2e/
│   ├── vitest.config.ts
│   └── playwright.config.ts
├── api/
│   ├── src/
│   ├── tests/
│   └── vitest.config.ts
└── shared/
    ├── src/
    └── tests/

tests/                      # Cross-package E2E
├── e2e/
│   ├── full-flow.spec.ts
│   └── fixtures/
└── playwright.config.ts
```

### Single App Structure

```
src/
├── components/
│   └── Button/
│       ├── Button.tsx
│       ├── Button.test.tsx     # Component tests
│       └── Button.stories.tsx  # Visual tests
├── features/
│   └── checkout/
│       ├── components/
│       │   └── Cart.test.tsx
│       ├── hooks/
│       │   └── useCart.test.ts
│       └── services/
│           └── cartService.test.ts
└── lib/
    └── utils/
        └── format.test.ts

tests/
├── setup/
│   ├── vitest.setup.ts      # Unit/component setup
│   └── playwright.setup.ts   # E2E setup
├── mocks/
│   ├── handlers.ts          # MSW handlers
│   └── fixtures/            # Shared test data
├── helpers/
│   ├── render.tsx           # Custom render
│   ├── factories.ts         # Data factories
│   └── assertions.ts        # Custom matchers
├── integration/
│   └── api-client.test.ts
└── e2e/
    ├── auth.spec.ts
    └── checkout.spec.ts

vitest.config.ts
playwright.config.ts
```

## Shared Test Utilities

### Custom Render Function

```typescript
// tests/helpers/render.tsx
import { render as rtlRender, RenderOptions } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ThemeProvider } from '@/providers/theme';
import { AuthProvider } from '@/providers/auth';

interface ExtendedRenderOptions extends RenderOptions {
  initialUser?: User | null;
  queryClient?: QueryClient;
}

export function render(
  ui: React.ReactElement,
  {
    initialUser = null,
    queryClient = new QueryClient({
      defaultOptions: { queries: { retry: false } },
    }),
    ...options
  }: ExtendedRenderOptions = {}
) {
  function Wrapper({ children }: { children: React.ReactNode }) {
    return (
      <QueryClientProvider client={queryClient}>
        <AuthProvider initialUser={initialUser}>
          <ThemeProvider>{children}</ThemeProvider>
        </AuthProvider>
      </QueryClientProvider>
    );
  }

  return {
    ...rtlRender(ui, { wrapper: Wrapper, ...options }),
    queryClient,
  };
}

export * from '@testing-library/react';
export { render };
```

### Data Factories

```typescript
// tests/helpers/factories.ts
import { faker } from '@faker-js/faker';
import type { User, Product, Order } from '@/types';

export function createUser(overrides: Partial<User> = {}): User {
  return {
    id: faker.string.uuid(),
    email: faker.internet.email(),
    name: faker.person.fullName(),
    role: 'user',
    createdAt: faker.date.past().toISOString(),
    ...overrides,
  };
}

export function createProduct(overrides: Partial<Product> = {}): Product {
  return {
    id: faker.string.uuid(),
    name: faker.commerce.productName(),
    price: parseFloat(faker.commerce.price()),
    description: faker.commerce.productDescription(),
    inStock: true,
    ...overrides,
  };
}

export function createOrder(overrides: Partial<Order> = {}): Order {
  return {
    id: faker.string.uuid(),
    userId: faker.string.uuid(),
    items: [
      { productId: faker.string.uuid(), quantity: 1, price: 29.99 },
    ],
    total: 29.99,
    status: 'pending',
    createdAt: faker.date.recent().toISOString(),
    ...overrides,
  };
}

// Factory with relationships
export function createOrderWithUser(
  orderOverrides: Partial<Order> = {},
  userOverrides: Partial<User> = {}
) {
  const user = createUser(userOverrides);
  const order = createOrder({ userId: user.id, ...orderOverrides });
  return { user, order };
}
```

### Custom Assertions

```typescript
// tests/helpers/assertions.ts
import { expect } from 'vitest';

expect.extend({
  toBeWithinRange(received: number, floor: number, ceiling: number) {
    const pass = received >= floor && received <= ceiling;
    return {
      pass,
      message: () =>
        pass
          ? `expected ${received} not to be within range ${floor} - ${ceiling}`
          : `expected ${received} to be within range ${floor} - ${ceiling}`,
    };
  },

  toHaveBeenCalledOnceWith(received: jest.Mock, ...args: unknown[]) {
    const pass = 
      received.mock.calls.length === 1 &&
      JSON.stringify(received.mock.calls[0]) === JSON.stringify(args);
    
    return {
      pass,
      message: () =>
        pass
          ? `expected mock not to have been called exactly once with ${JSON.stringify(args)}`
          : `expected mock to have been called exactly once with ${JSON.stringify(args)}, ` +
            `but was called ${received.mock.calls.length} times with ${JSON.stringify(received.mock.calls)}`,
    };
  },
});

// Type augmentation
declare module 'vitest' {
  interface Assertion<T> {
    toBeWithinRange(floor: number, ceiling: number): T;
    toHaveBeenCalledOnceWith(...args: unknown[]): T;
  }
}
```

## Test Configuration

### Vitest Configuration

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import tsconfigPaths from 'vite-tsconfig-paths';

export default defineConfig({
  plugins: [react(), tsconfigPaths()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./tests/setup/vitest.setup.ts'],
    include: ['src/**/*.test.{ts,tsx}', 'tests/**/*.test.{ts,tsx}'],
    exclude: ['tests/e2e/**'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      include: ['src/**/*.{ts,tsx}'],
      exclude: [
        'src/**/*.d.ts',
        'src/**/*.stories.tsx',
        'src/**/*.test.{ts,tsx}',
        'src/types/**',
      ],
      thresholds: {
        branches: 80,
        functions: 80,
        lines: 80,
        statements: 80,
      },
    },
    testTimeout: 10000,
    hookTimeout: 10000,
  },
});
```

### Vitest Setup File

```typescript
// tests/setup/vitest.setup.ts
import '@testing-library/jest-dom/vitest';
import { cleanup } from '@testing-library/react';
import { afterEach, beforeAll, afterAll, vi } from 'vitest';
import { server } from '../mocks/server';

// MSW setup
beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

// Cleanup after each test
afterEach(() => {
  cleanup();
});

// Mock problematic browser APIs
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
});

// Mock IntersectionObserver
class MockIntersectionObserver {
  observe = vi.fn();
  disconnect = vi.fn();
  unobserve = vi.fn();
}
Object.defineProperty(window, 'IntersectionObserver', {
  writable: true,
  value: MockIntersectionObserver,
});

// Mock ResizeObserver
class MockResizeObserver {
  observe = vi.fn();
  disconnect = vi.fn();
  unobserve = vi.fn();
}
Object.defineProperty(window, 'ResizeObserver', {
  writable: true,
  value: MockResizeObserver,
});
```

### Playwright Configuration

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
