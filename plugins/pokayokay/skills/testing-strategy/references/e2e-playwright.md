# E2E Testing with Playwright

Playwright patterns including Page Object Model, fixtures, auth state, API mocking, and visual comparison.

## Page Object Model

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

## Fixtures and Setup

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

## Authentication State

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

## API Mocking

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

## Visual Comparison

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

## Waiting Strategies

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
