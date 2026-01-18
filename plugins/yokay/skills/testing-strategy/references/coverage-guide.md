# Coverage Guide

Focus on meaningful coverage, not just percentages.

## Coverage Metrics Explained

### Line Coverage

Percentage of code lines executed during tests.

```typescript
function greet(name: string, formal: boolean) {  // Line 1
  if (formal) {                                   // Line 2
    return `Good day, ${name}`;                   // Line 3
  }                                               // Line 4
  return `Hey, ${name}!`;                         // Line 5
}                                                 // Line 6

// Test
it('greets informally', () => {
  expect(greet('John', false)).toBe('Hey, John!');
});

// Coverage: 4/6 lines = 66% (lines 1, 2, 5, 6)
// Line 3 never executed
```

### Branch Coverage

Percentage of conditional branches taken.

```typescript
function calculatePrice(qty: number, isPremium: boolean): number {
  let price = qty * 10;             // Branch decision points:
  
  if (qty > 100) {                  // Branch 1: qty > 100
    price *= 0.9;                   // Branch 1a: true
  }                                 // Branch 1b: false (implicit)
  
  if (isPremium) {                  // Branch 2: isPremium
    price *= 0.95;                  // Branch 2a: true
  }                                 // Branch 2b: false (implicit)
  
  return price;
}

// Tests for full branch coverage
it('covers qty <= 100, not premium', () => {
  expect(calculatePrice(50, false)).toBe(500);  // 1b, 2b
});

it('covers qty > 100, premium', () => {
  expect(calculatePrice(150, true)).toBe(1282.5);  // 1a, 2a
});
// 4/4 branches = 100%
```

### Function Coverage

Percentage of functions called.

### Statement Coverage

Similar to line coverage but counts statements (multiple per line possible).

## The Coverage Trap

### High Coverage ≠ Quality Tests

```typescript
// 100% coverage, but tests nothing useful
function divide(a: number, b: number): number {
  return a / b;
}

it('covers divide', () => {
  const result = divide(10, 2);
  expect(result).toBeDefined(); // Weak assertion
});

// Misses: divide(10, 0), divide(NaN, 2), edge cases
```

### Meaningful vs. Meaningless Coverage

```typescript
// ❌ Meaningless: covers code, tests nothing
it('renders without crashing', () => {
  render(<ComplexForm />);
  // No assertions
});

// ✅ Meaningful: covers behavior users care about
it('shows validation error for invalid email', async () => {
  render(<ComplexForm />);
  await userEvent.type(screen.getByLabelText('Email'), 'invalid');
  await userEvent.click(screen.getByRole('button', { name: 'Submit' }));
  expect(screen.getByText('Invalid email format')).toBeInTheDocument();
});
```

## Recommended Coverage Targets

### By Code Type

| Code Type | Target | Rationale |
|-----------|--------|-----------|
| **Business logic** | 85-95% | Core value, high risk |
| **API handlers** | 80-90% | User-facing, error-prone |
| **UI components** | 70-80% | Visual states, interactions |
| **Utilities** | 90%+ | Widely used, pure functions |
| **Integration points** | 60-70% | Hard to unit test |
| **Config/Setup** | 0-30% | Often trivial |

### By Project Type

| Project Type | Line | Branch | Notes |
|--------------|------|--------|-------|
| **Library/SDK** | 90%+ | 85%+ | Public API surface critical |
| **API service** | 80%+ | 75%+ | Focus on handlers, validation |
| **Web app** | 70%+ | 65%+ | Balance UI and logic |
| **CLI tool** | 75%+ | 70%+ | Command paths important |
| **Internal tool** | 60%+ | 55%+ | Move fast, fix quick |

### Minimum Viable Coverage

For any project, ensure coverage of:

1. **Critical paths**: Auth, payments, data mutations = 100%
2. **Error handlers**: At least one test per error type
3. **Public API**: Every public function/endpoint
4. **Edge cases**: null, empty, boundary values

## Configuring Coverage

### Vitest Coverage

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8', // or 'istanbul'
      reporter: ['text', 'json', 'html', 'lcov'],
      include: ['src/**/*.{ts,tsx}'],
      exclude: [
        'src/**/*.d.ts',
        'src/**/*.test.{ts,tsx}',
        'src/**/*.stories.tsx',
        'src/types/**',
        'src/mocks/**',
        'src/**/index.ts', // Re-export files
      ],
      thresholds: {
        global: {
          branches: 75,
          functions: 80,
          lines: 80,
          statements: 80,
        },
        // Per-file thresholds
        'src/services/**': {
          branches: 85,
          functions: 90,
          lines: 90,
        },
        'src/components/**': {
          branches: 65,
          lines: 70,
        },
      },
    },
  },
});
```

### Jest Coverage

```javascript
// jest.config.js
module.exports = {
  collectCoverageFrom: [
    'src/**/*.{ts,tsx}',
    '!src/**/*.d.ts',
    '!src/**/*.stories.tsx',
  ],
  coverageThreshold: {
    global: {
      branches: 75,
      functions: 80,
      lines: 80,
      statements: 80,
    },
  },
  coverageReporters: ['text', 'lcov', 'json-summary'],
};
```

## Coverage Reports

### Reading the Report

```
File                | % Stmts | % Branch | % Funcs | % Lines | Uncovered Line #s
--------------------|---------|----------|---------|---------|------------------
All files           |   82.35 |    71.43 |   85.71 |   82.35 |
 src/services       |   95.24 |    87.5  |   100   |   95.24 |
  userService.ts    |   95.24 |    87.5  |   100   |   95.24 | 45-47
 src/components     |   68.42 |    55.56 |   71.43 |   68.42 |
  UserForm.tsx      |   65.22 |    50    |   66.67 |   65.22 | 23-28,42-45,67
  UserList.tsx      |   73.68 |    66.67 |   80    |   73.68 | 89-92
```

**Interpret the numbers:**
- **Stmts**: Statement coverage
- **Branch**: Conditional branches covered
- **Funcs**: Functions executed
- **Lines**: Lines executed
- **Uncovered**: Specific lines not covered

### Actionable Analysis

```bash
# Find untested files
npx vitest --coverage --reporter=json | jq '.total.lines.pct < 50'

# Coverage diff on PR
npx vitest --coverage --changed

# Generate detailed HTML report
npx vitest --coverage --reporter=html
```

## Coverage Anti-Patterns

### Gaming the Metrics

```typescript
// ❌ Test written just for coverage
it('covers the function', () => {
  someFunction();
  // No assertions
});

// ❌ Assertion-free snapshot
it('renders', () => {
  expect(render(<Component />)).toMatchSnapshot();
});
```

### Ignoring Important Code

```typescript
// ❌ Excluding code that should be tested
/* istanbul ignore next */
function criticalFunction() {
  // This actually needs tests!
}
```

### Coverage as the Goal

```typescript
// ❌ Writing tests backwards from coverage report
// "Line 45-47 uncovered, let me hit those"

// ✅ Writing tests from requirements
// "Users should see an error when email is invalid"
```

## Improving Coverage Meaningfully

### 1. Identify Critical Gaps

```bash
# Find files with low coverage
npx vitest --coverage | grep -E "^\s+src.*\|\s+[0-5][0-9]\."

# Focus on business-critical files first
```

### 2. Add Tests for Behavior, Not Lines

```typescript
// Instead of: "need to cover lines 45-47"
// Ask: "what behavior is untested?"

// Lines 45-47 might be error handling
it('handles network failure gracefully', async () => {
  server.use(http.get('/api/data', () => HttpResponse.error()));
  render(<DataLoader />);
  await waitFor(() => {
    expect(screen.getByRole('alert')).toHaveTextContent('Connection failed');
  });
});
```

### 3. Test Edge Cases First

```typescript
describe('parseAmount', () => {
  // Happy path probably covered
  it('parses valid amount', () => {
    expect(parseAmount('$1,234.56')).toBe(1234.56);
  });

  // Edge cases often missed
  it('handles empty string', () => {
    expect(parseAmount('')).toBe(0);
  });

  it('handles negative', () => {
    expect(parseAmount('-$50.00')).toBe(-50);
  });

  it('handles no decimal', () => {
    expect(parseAmount('$100')).toBe(100);
  });

  it('handles invalid input', () => {
    expect(() => parseAmount('abc')).toThrow('Invalid amount');
  });
});
```

### 4. Use Mutation Testing

Mutation testing verifies test quality by introducing bugs and checking if tests catch them.

```bash
# Stryker mutation testing
npx stryker run

# Output shows mutation score (higher = better tests)
# Mutation score: 85%
# Survivors: 15 mutations not caught by tests
```

## Coverage in CI/CD

### GitHub Actions Example

```yaml
name: Test Coverage

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'

      - run: npm ci
      - run: npm run test:coverage

      # Fail if coverage drops
      - name: Check coverage thresholds
        run: |
          COVERAGE=$(cat coverage/coverage-summary.json | jq '.total.lines.pct')
          if (( $(echo "$COVERAGE < 80" | bc -l) )); then
            echo "Coverage $COVERAGE% is below 80% threshold"
            exit 1
          fi

      # Upload report
      - uses: codecov/codecov-action@v4
        with:
          files: ./coverage/lcov.info
          fail_ci_if_error: true
```

### PR Coverage Comments

```yaml
- name: Coverage Report
  uses: davelosert/vitest-coverage-report-action@v2
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    json-summary-path: ./coverage/coverage-summary.json
```

## Key Takeaways

1. **Coverage is a guide, not a goal** - Use it to find gaps, not to prove quality
2. **Branch coverage > line coverage** - Ensures conditionals are tested
3. **Critical paths need 100%** - Auth, payments, data mutations
4. **Tests should assert behavior** - Not just execute code
5. **Incrementally improve** - Start with critical code, expand over time
6. **Mutation testing validates quality** - High coverage with low mutation score = weak tests
