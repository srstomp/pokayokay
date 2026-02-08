# Cypress Patterns and E2E Test Stability

Cypress testing patterns, flaky test prevention, test data management, and debugging.

## Cypress Patterns

### Custom Commands

```typescript
// cypress/support/commands.ts
Cypress.Commands.add('login', (email: string, password: string) => {
  cy.session([email, password], () => {
    cy.visit('/login');
    cy.get('[data-cy=email]').type(email);
    cy.get('[data-cy=password]').type(password);
    cy.get('[data-cy=submit]').click();
    cy.url().should('include', '/dashboard');
  });
});

Cypress.Commands.add('getByTestId', (testId: string) => {
  return cy.get(`[data-cy=${testId}]`);
});

// Type definitions
declare global {
  namespace Cypress {
    interface Chainable {
      login(email: string, password: string): Chainable<void>;
      getByTestId(testId: string): Chainable<JQuery<HTMLElement>>;
    }
  }
}

// Usage
it('shows user dashboard', () => {
  cy.login('user@example.com', 'password');
  cy.visit('/dashboard');
  cy.getByTestId('welcome-message').should('contain', 'Welcome');
});
```

### API Interception

```typescript
describe('Products', () => {
  it('displays products from API', () => {
    cy.intercept('GET', '/api/products', {
      statusCode: 200,
      body: [
        { id: '1', name: 'Product 1', price: 29.99 },
        { id: '2', name: 'Product 2', price: 49.99 },
      ],
    }).as('getProducts');

    cy.visit('/products');
    cy.wait('@getProducts');

    cy.contains('Product 1').should('be.visible');
    cy.contains('Product 2').should('be.visible');
  });

  it('handles API errors', () => {
    cy.intercept('GET', '/api/products', {
      statusCode: 500,
      body: { error: 'Server error' },
    }).as('getProducts');

    cy.visit('/products');
    cy.wait('@getProducts');

    cy.contains('Failed to load products').should('be.visible');
  });

  // Delay response
  it('shows loading state', () => {
    cy.intercept('GET', '/api/products', {
      statusCode: 200,
      body: [],
      delay: 1000,
    }).as('getProducts');

    cy.visit('/products');
    cy.contains('Loading...').should('be.visible');
    cy.wait('@getProducts');
    cy.contains('Loading...').should('not.exist');
  });
});
```

### Fixtures

```typescript
// cypress/fixtures/user.json
{
  "id": "1",
  "email": "test@example.com",
  "name": "Test User"
}

// Using fixtures
it('displays user profile', () => {
  cy.fixture('user').then((user) => {
    cy.intercept('GET', '/api/user', user).as('getUser');
  });

  cy.visit('/profile');
  cy.wait('@getUser');
  cy.contains('Test User').should('be.visible');
});

// Modifying fixture data
it('displays user with custom name', () => {
  cy.fixture('user').then((user) => {
    cy.intercept('GET', '/api/user', { ...user, name: 'Custom Name' });
  });
});
```

---

## Flaky Test Prevention

### Root Causes and Solutions

| Cause | Solution |
|-------|----------|
| Timing issues | Use explicit waits for conditions, not time |
| Animation interference | Disable animations or wait for completion |
| Shared state | Isolate tests, clean up between runs |
| Network variance | Mock external APIs |
| Date/time dependencies | Mock date functions |
| Random data | Seed random generators |
| Parallel interference | Run conflicting tests serially |

### Timing Best Practices

```typescript
// Flaky: Fixed timeout
await page.waitForTimeout(2000);

// Stable: Wait for condition
await page.waitForSelector('.loaded');
await expect(page.getByText('Ready')).toBeVisible();

// Flaky: Assuming instant state change
await page.click('button');
expect(await page.textContent('.result')).toBe('Done');

// Stable: Wait for state change
await page.click('button');
await expect(page.getByText('Done')).toBeVisible();
```

### Animation Handling

```typescript
// Playwright: Disable animations
const page = await browser.newPage({
  reducedMotion: 'reduce',
});

// Or via CSS
await page.addStyleTag({
  content: `
    *, *::before, *::after {
      animation-duration: 0s !important;
      transition-duration: 0s !important;
    }
  `,
});

// Cypress
// cypress.config.ts
export default defineConfig({
  e2e: {
    testIsolation: true,
    animationDistanceThreshold: 0,
  },
});
```

### Network Stability

```typescript
// Mock all external APIs
test.beforeEach(async ({ page }) => {
  // Block external requests
  await page.route('**/*', (route) => {
    if (!route.request().url().includes('localhost')) {
      return route.abort();
    }
    return route.continue();
  });
});

// Wait for network idle
await page.goto('/page', { waitUntil: 'networkidle' });

// Wait for specific API
const apiResponse = page.waitForResponse('**/api/data');
await page.click('button');
await apiResponse;
```

### Date/Time Mocking

```typescript
// Playwright
test('shows correct date', async ({ page }) => {
  await page.addInitScript(() => {
    const fakeDate = new Date('2024-01-15T10:00:00Z');
    Date = class extends Date {
      constructor(...args: any[]) {
        if (args.length === 0) {
          return new (Function.prototype.bind.apply(
            fakeDate.constructor as any,
            [null] as any
          ))();
        }
        super(...args);
      }
      static now() {
        return fakeDate.getTime();
      }
    } as DateConstructor;
  });

  await page.goto('/');
  await expect(page.getByText('January 15, 2024')).toBeVisible();
});

// Cypress
cy.clock(new Date('2024-01-15').getTime());
cy.visit('/');
cy.contains('January 15, 2024').should('be.visible');
```

### Test Isolation

```typescript
// Playwright
test.describe('User tests', () => {
  test.beforeEach(async ({ request }) => {
    // Reset database state
    await request.post('/api/test/reset');
  });

  test('creates user', async ({ page }) => {
    // ...
  });
});

// Cypress
beforeEach(() => {
  cy.request('POST', '/api/test/reset');
});
```

### Retry Strategies

```typescript
// playwright.config.ts
export default defineConfig({
  retries: process.env.CI ? 2 : 0,
  use: {
    trace: 'on-first-retry', // Capture trace on failure
    video: 'on-first-retry',
  },
});

// Test-specific retry
test('flaky test', async ({ page }) => {
  test.info().annotations.push({ type: 'flaky', description: 'Network timing' });
  // ... test code
}, { retries: 3 });

// Cypress
// cypress.config.ts
export default defineConfig({
  retries: {
    runMode: 2,
    openMode: 0,
  },
});
```

---

## Test Data Management

### Database Seeding

```typescript
// Playwright
test.beforeAll(async ({ request }) => {
  // Seed test data
  await request.post('/api/test/seed', {
    data: {
      users: [{ email: 'test@example.com', password: 'hashed' }],
      products: [{ id: '1', name: 'Test Product', price: 29.99 }],
    },
  });
});

test.afterAll(async ({ request }) => {
  await request.post('/api/test/cleanup');
});
```

### Factory Pattern

```typescript
// test-data/factories.ts
import { faker } from '@faker-js/faker';

export const factories = {
  user: (overrides = {}) => ({
    email: faker.internet.email(),
    name: faker.person.fullName(),
    ...overrides,
  }),

  product: (overrides = {}) => ({
    name: faker.commerce.productName(),
    price: parseFloat(faker.commerce.price()),
    ...overrides,
  }),

  order: (userId: string, productIds: string[], overrides = {}) => ({
    userId,
    items: productIds.map((id) => ({ productId: id, quantity: 1 })),
    status: 'pending',
    ...overrides,
  }),
};

// Usage in tests
test('checkout flow', async ({ page, request }) => {
  const user = factories.user();
  const product = factories.product({ price: 99.99 });

  await request.post('/api/test/seed', {
    data: { users: [user], products: [product] },
  });

  // ... test checkout
});
```

### Cleanup Strategies

```typescript
// Transaction rollback (best for database tests)
test.beforeEach(async ({ request }) => {
  await request.post('/api/test/begin-transaction');
});

test.afterEach(async ({ request }) => {
  await request.post('/api/test/rollback-transaction');
});

// Explicit cleanup
test.afterEach(async ({ request }) => {
  await request.delete('/api/test/users');
  await request.delete('/api/test/products');
});

// Namespace isolation
test('creates order', async ({ page, request }) => {
  const testId = `test-${Date.now()}`;
  const user = factories.user({ email: `${testId}@test.com` });

  // Use namespaced data
  await request.post('/api/test/seed', { data: { users: [user] } });

  // Cleanup by namespace
  test.afterEach(async () => {
    await request.delete(`/api/test/cleanup/${testId}`);
  });
});
```

---

## Debugging Failed Tests

### Trace and Screenshots

```typescript
// playwright.config.ts
export default defineConfig({
  use: {
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
});

// View trace
// npx playwright show-trace trace.zip
```

### Console and Network Logs

```typescript
test('debug failing test', async ({ page }) => {
  // Log console messages
  page.on('console', (msg) => console.log('PAGE LOG:', msg.text()));

  // Log network requests
  page.on('request', (req) => console.log('REQUEST:', req.url()));
  page.on('response', (res) => console.log('RESPONSE:', res.status(), res.url()));

  await page.goto('/');
});
```

### Step-by-Step Debugging

```typescript
// Playwright
test('step by step', async ({ page }) => {
  await test.step('Navigate to login', async () => {
    await page.goto('/login');
  });

  await test.step('Fill credentials', async () => {
    await page.fill('[name=email]', 'test@example.com');
    await page.fill('[name=password]', 'password');
  });

  await test.step('Submit and verify', async () => {
    await page.click('button[type=submit]');
    await expect(page).toHaveURL('/dashboard');
  });
});
```

### Headed Mode

```bash
# Run with visible browser
npx playwright test --headed

# Debug mode (pauses on failure)
npx playwright test --debug

# Cypress
npx cypress open
```
