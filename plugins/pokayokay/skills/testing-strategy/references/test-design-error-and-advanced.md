# Error Handling and Advanced Test Design

Error handling testing, property-based testing, parameterization, and regression test design.

## Error Handling Testing

### Error Categories

```typescript
describe('UserService.createUser', () => {
  // Validation errors
  describe('validation errors', () => {
    it('throws for empty email', async () => {
      await expect(userService.createUser({ email: '' }))
        .rejects.toThrow('Email is required');
    });

    it('throws for invalid email format', async () => {
      await expect(userService.createUser({ email: 'invalid' }))
        .rejects.toThrow('Invalid email format');
    });
  });

  // Business logic errors
  describe('business errors', () => {
    it('throws for duplicate email', async () => {
      await userService.createUser({ email: 'exists@example.com' });

      await expect(userService.createUser({ email: 'exists@example.com' }))
        .rejects.toThrow('Email already registered');
    });
  });

  // External dependency errors
  describe('dependency errors', () => {
    it('handles database connection failure', async () => {
      mockDb.connect.mockRejectedValue(new Error('Connection failed'));

      await expect(userService.createUser(validUser))
        .rejects.toThrow('Unable to create user');
    });

    it('handles email service failure gracefully', async () => {
      mockEmailService.send.mockRejectedValue(new Error('SMTP error'));

      // Should still create user, just not send email
      const user = await userService.createUser(validUser);
      expect(user).toBeDefined();
    });
  });

  // Network errors
  describe('network errors', () => {
    it('handles timeout', async () => {
      mockApi.fetch.mockImplementation(() =>
        new Promise((_, reject) =>
          setTimeout(() => reject(new Error('Timeout')), 100)
        )
      );

      await expect(userService.createUser(validUser))
        .rejects.toThrow('Request timed out');
    });
  });
});
```

### Error Message Quality

```typescript
describe('error messages', () => {
  it('provides actionable error for invalid input', async () => {
    const error = await userService.createUser({ email: 'bad' })
      .catch(e => e);

    expect(error).toMatchObject({
      code: 'VALIDATION_ERROR',
      message: 'Invalid email format',
      field: 'email',
      suggestion: 'Email must be in format: user@domain.com',
    });
  });

  it('includes request ID for debugging', async () => {
    mockDb.query.mockRejectedValue(new Error('DB error'));

    const error = await userService.createUser(validUser)
      .catch(e => e);

    expect(error.requestId).toMatch(/^[a-f0-9-]{36}$/);
  });
});
```

---

## Property-Based Testing

Test invariants that should hold for all inputs.

```typescript
import fc from 'fast-check';

describe('sort', () => {
  it('always returns array of same length', () => {
    fc.assert(
      fc.property(fc.array(fc.integer()), (arr) => {
        expect(sort(arr).length).toBe(arr.length);
      })
    );
  });

  it('returns sorted array', () => {
    fc.assert(
      fc.property(fc.array(fc.integer()), (arr) => {
        const sorted = sort(arr);
        for (let i = 1; i < sorted.length; i++) {
          expect(sorted[i]).toBeGreaterThanOrEqual(sorted[i - 1]);
        }
      })
    );
  });

  it('contains same elements as input', () => {
    fc.assert(
      fc.property(fc.array(fc.integer()), (arr) => {
        const sorted = sort(arr);
        expect([...sorted].sort()).toEqual([...arr].sort());
      })
    );
  });

  it('is idempotent', () => {
    fc.assert(
      fc.property(fc.array(fc.integer()), (arr) => {
        expect(sort(sort(arr))).toEqual(sort(arr));
      })
    );
  });
});
```

### Custom Arbitraries

```typescript
// Custom user generator
const userArbitrary = fc.record({
  email: fc.emailAddress(),
  name: fc.string({ minLength: 1, maxLength: 100 }),
  age: fc.integer({ min: 0, max: 150 }),
});

// Custom date in range
const dateInRange = (start: Date, end: Date) =>
  fc.date({ min: start, max: end });

// Nested structures
const orderArbitrary = fc.record({
  id: fc.uuid(),
  userId: fc.uuid(),
  items: fc.array(
    fc.record({
      productId: fc.uuid(),
      quantity: fc.integer({ min: 1, max: 100 }),
      price: fc.float({ min: 0.01, max: 10000, noNaN: true }),
    }),
    { minLength: 1, maxLength: 20 }
  ),
});

describe('Order', () => {
  it('calculates total correctly', () => {
    fc.assert(
      fc.property(orderArbitrary, (order) => {
        const expectedTotal = order.items.reduce(
          (sum, item) => sum + item.quantity * item.price,
          0
        );
        expect(calculateTotal(order)).toBeCloseTo(expectedTotal, 2);
      })
    );
  });
});
```

---

## Test Parameterization

### Table-Driven Tests

```typescript
describe('formatCurrency', () => {
  const testCases = [
    { input: 0, expected: '$0.00' },
    { input: 1, expected: '$1.00' },
    { input: 1.5, expected: '$1.50' },
    { input: 1.555, expected: '$1.56' }, // Rounds up
    { input: 1000, expected: '$1,000.00' },
    { input: -50, expected: '-$50.00' },
  ];

  test.each(testCases)(
    'formats $input as $expected',
    ({ input, expected }) => {
      expect(formatCurrency(input)).toBe(expected);
    }
  );
});
```

### Complex Parameterization

```typescript
describe('calculateTax', () => {
  const scenarios = [
    {
      name: 'standard rate for regular items',
      item: { category: 'electronics', price: 100 },
      region: 'CA',
      expected: { tax: 7.25, total: 107.25 },
    },
    {
      name: 'reduced rate for groceries',
      item: { category: 'groceries', price: 100 },
      region: 'CA',
      expected: { tax: 0, total: 100 },
    },
    {
      name: 'different rate for NY',
      item: { category: 'electronics', price: 100 },
      region: 'NY',
      expected: { tax: 8, total: 108 },
    },
  ];

  describe.each(scenarios)('$name', ({ item, region, expected }) => {
    it(`calculates tax of ${expected.tax}`, () => {
      const result = calculateTax(item, region);
      expect(result.tax).toBe(expected.tax);
    });

    it(`calculates total of ${expected.total}`, () => {
      const result = calculateTax(item, region);
      expect(result.total).toBe(expected.total);
    });
  });
});
```

---

## Regression Test Design

### Bug-Driven Tests

```typescript
// When fixing a bug, write a failing test first
describe('calculateDiscount (regression tests)', () => {
  // BUG-123: Discount was applied twice for premium members
  it('applies discount only once for premium members', () => {
    const order = { total: 100, isPremium: true };
    const result = calculateDiscount(order);
    expect(result.discount).toBe(10); // Not 20
  });

  // BUG-456: Floating point error in total calculation
  it('handles floating point correctly', () => {
    const order = { total: 0.1 + 0.2, isPremium: false };
    const result = calculateDiscount(order);
    expect(result.total).toBeCloseTo(0.3, 10);
  });

  // BUG-789: Null premium status caused crash
  it('handles null premium status', () => {
    const order = { total: 100, isPremium: null };
    expect(() => calculateDiscount(order)).not.toThrow();
  });
});
```

### Critical Path Coverage

```typescript
describe('Checkout (critical path)', () => {
  // These tests must never be skipped or deleted
  it('completes purchase with valid payment', async () => {
    // Full happy path
  });

  it('prevents double-charging on retry', async () => {
    // Idempotency check
  });

  it('rolls back on payment failure', async () => {
    // Transaction safety
  });

  it('handles concurrent checkouts correctly', async () => {
    // Race condition prevention
  });
});
```
