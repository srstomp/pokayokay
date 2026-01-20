# E2E Testing

End-to-end testing patterns with Playwright and Cypress.

## Playwright Patterns

### Page Object Model

```typescript
// pages/LoginPage.ts
import { Page, Locator } from '@playwright/test';

export class LoginPage {
  readonly page: Page;
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;
  readonly errorMessage: Locator;

  constructor(page: Page) {
    this.page = page;
    this.emailInput = page.getByLabel('Email');
    this.passwordInput = page.getByLabel('Password');
    this.submitButton = page.getByRole('button', { name: 'Sign in' });
    this.errorMessage = page.getByRole('alert');
  }

  async goto() {
    await this.page.goto('/login');
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }

  async expectError(message: string) {
    await expect(this.errorMessage).toContainText(message);
  }
}

// Usage in tests
test('login with valid credentials', async ({ page }) => {
  const loginPage = new LoginPage(page);
  await loginPage.goto();
  await loginPage.login('user@example.com', 'password123');
  await expect(page).toHaveURL('/dashboard');
});
```

### Fixtures and Setup

```typescript
// fixtures/auth.ts
import { test as base } from '@playwright/test';
import { LoginPage } from '../pages/LoginPage';
import { DashboardPage } from '../pages/DashboardPage';

type Fixtures = {
  loginPage: LoginPage;
  dashboardPage: DashboardPage;
};

export const test = base.extend<Fixtures>({
  loginPage: async ({ page }, use) => {
    await use(new LoginPage(page));
  },
  dashboardPage: async ({ page }, use) => {
    await use(new DashboardPage(page));
  },
});

export { expect } from '@playwright/test';

// Usage
test('navigates to settings', async ({ dashboardPage }) => {
  await dashboardPage.goto();
  await dashboardPage.openSettings();
  await expect(dashboardPage.settingsPanel).toBeVisible();
});
```

### Authentication State

```typescript
// tests/auth.setup.ts
import { test as setup, expect } from '@playwright/test';

const authFile = 'playwright/.auth/user.json';

setup('authenticate', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('Email').fill(process.env.TEST_USER_EMAIL!);
  await page.getByLabel('Password').fill(process.env.TEST_USER_PASSWORD!);
  await page.getByRole('button', { name: 'Sign in' }).click();

  // Wait for auth to complete
  await expect(page).toHaveURL('/dashboard');

  // Save storage state
  await page.context().storageState({ path: authFile });
});

// playwright.config.ts
export default defineConfig({
  projects: [
    { name: 'setup', testMatch: /.*\.setup\.ts/ },
    {
      name: 'chromium',
      use: { storageState: authFile },
      dependencies: ['setup'],
    },
  ],
});
```

### API Mocking

```typescript
test('shows products from API', async ({ page }) => {
  // Mock the API response
  await page.route('**/api/products', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify([
        { id: '1', name: 'Product 1', price: 29.99 },
        { id: '2', name: 'Product 2', price: 49.99 },
      ]),
    });
  });

  await page.goto('/products');
  await expect(page.getByText('Product 1')).toBeVisible();
  await expect(page.getByText('Product 2')).toBeVisible();
});

// Simulate network errors
test('handles API failure', async ({ page }) => {
  await page.route('**/api/products', (route) => route.abort('failed'));

  await page.goto('/products');
  await expect(page.getByText('Failed to load products')).toBeVisible();
});
```

### Visual Comparison

```typescript
test('homepage visual regression', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveScreenshot('homepage.png');
});

test('button states', async ({ page }) => {
  await page.goto('/buttons');

  // Capture specific element
  const button = page.getByRole('button', { name: 'Submit' });
  await expect(button).toHaveScreenshot('button-default.png');

  await button.hover();
  await expect(button).toHaveScreenshot('button-hover.png');
});

// With threshold
test('allows slight differences', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveScreenshot('homepage.png', {
    maxDiffPixelRatio: 0.01, // Allow 1% difference
  });
});
```

### Waiting Strategies

```typescript
// Wait for network idle
await page.goto('/dashboard', { waitUntil: 'networkidle' });

// Wait for specific request
const responsePromise = page.waitForResponse('**/api/users');
await page.click('button');
const response = await responsePromise;

// Wait for element state
await page.getByRole('button').waitFor({ state: 'visible' });
await page.getByRole('dialog').waitFor({ state: 'hidden' });

// Custom wait condition
await page.waitForFunction(() => {
  return document.querySelector('.loaded')?.textContent === 'Ready';
});

// Wait for navigation
await Promise.all([
  page.waitForURL('/dashboard'),
  page.click('a[href="/dashboard"]'),
]);
```

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
// ❌ Flaky: Fixed timeout
await page.waitForTimeout(2000);

// ✅ Stable: Wait for condition
await page.waitForSelector('.loaded');
await expect(page.getByText('Ready')).toBeVisible();

// ❌ Flaky: Assuming instant state change
await page.click('button');
expect(await page.textContent('.result')).toBe('Done');

// ✅ Stable: Wait for state change
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
