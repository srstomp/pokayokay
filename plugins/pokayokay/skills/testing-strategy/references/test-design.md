# Test Design

Systematic approaches to designing effective test cases.

## Equivalence Partitioning

Divide inputs into groups where all values in a partition should behave identically.

### Principle

Test one value from each partition rather than exhaustively testing all values.

```typescript
// Function: validateAge(age: number) -> boolean
// Partitions:
//   Invalid (negative): age < 0
//   Invalid (too young): 0 <= age < 18
//   Valid: 18 <= age <= 120
//   Invalid (too old): age > 120

describe('validateAge', () => {
  // One test per partition
  it('rejects negative age', () => {
    expect(validateAge(-5)).toBe(false);
  });

  it('rejects age under 18', () => {
    expect(validateAge(10)).toBe(false);
  });

  it('accepts valid age', () => {
    expect(validateAge(25)).toBe(true);
  });

  it('rejects age over 120', () => {
    expect(validateAge(150)).toBe(false);
  });
});
```

### Common Partitions

| Input Type | Typical Partitions |
|------------|-------------------|
| Numbers | Negative, zero, positive, very large |
| Strings | Empty, whitespace, short, typical, max length |
| Arrays | Empty, single item, multiple items, at capacity |
| Objects | Null, empty object, partial, complete |
| Dates | Past, present, future, invalid format |
| Enums | Each valid value, invalid value |

## Boundary Value Analysis

Bugs cluster at boundaries. Test values at, just below, and just above boundaries.

### Pattern

For each boundary, test: boundary - 1, boundary, boundary + 1

```typescript
// Password length: 8-20 characters
// Boundaries: 8 (min), 20 (max)

describe('validatePassword', () => {
  // Lower boundary
  it('rejects 7 characters', () => {
    expect(validatePassword('1234567')).toBe(false);
  });

  it('accepts 8 characters', () => {
    expect(validatePassword('12345678')).toBe(true);
  });

  it('accepts 9 characters', () => {
    expect(validatePassword('123456789')).toBe(true);
  });

  // Upper boundary
  it('accepts 19 characters', () => {
    expect(validatePassword('1234567890123456789')).toBe(true);
  });

  it('accepts 20 characters', () => {
    expect(validatePassword('12345678901234567890')).toBe(true);
  });

  it('rejects 21 characters', () => {
    expect(validatePassword('123456789012345678901')).toBe(false);
  });
});
```

### Special Boundaries

```typescript
// Numeric boundaries
const testCases = [
  { input: Number.MIN_SAFE_INTEGER, expected: 'handled' },
  { input: Number.MAX_SAFE_INTEGER, expected: 'handled' },
  { input: 0, expected: 'zero case' },
  { input: -0, expected: 'negative zero' },
  { input: Infinity, expected: 'infinity handled' },
  { input: NaN, expected: 'NaN handled' },
];

// Array boundaries
describe('getItem', () => {
  const arr = ['a', 'b', 'c'];

  it('returns first item at index 0', () => {
    expect(getItem(arr, 0)).toBe('a');
  });

  it('returns last item at index length-1', () => {
    expect(getItem(arr, 2)).toBe('c');
  });

  it('returns undefined at index -1', () => {
    expect(getItem(arr, -1)).toBeUndefined();
  });

  it('returns undefined at index length', () => {
    expect(getItem(arr, 3)).toBeUndefined();
  });
});
```

## Decision Table Testing

Map combinations of conditions to expected outcomes.

### Example: Discount Calculation

| Condition | Rule 1 | Rule 2 | Rule 3 | Rule 4 |
|-----------|--------|--------|--------|--------|
| Premium member | Yes | Yes | No | No |
| Order > $100 | Yes | No | Yes | No |
| **Action** |
| Discount % | 20% | 10% | 5% | 0% |

```typescript
describe('calculateDiscount', () => {
  it('gives 20% for premium member with order > $100', () => {
    const result = calculateDiscount({ isPremium: true, orderTotal: 150 });
    expect(result).toBe(0.20);
  });

  it('gives 10% for premium member with order <= $100', () => {
    const result = calculateDiscount({ isPremium: true, orderTotal: 50 });
    expect(result).toBe(0.10);
  });

  it('gives 5% for non-premium with order > $100', () => {
    const result = calculateDiscount({ isPremium: false, orderTotal: 150 });
    expect(result).toBe(0.05);
  });

  it('gives 0% for non-premium with order <= $100', () => {
    const result = calculateDiscount({ isPremium: false, orderTotal: 50 });
    expect(result).toBe(0);
  });
});
```

### Complex Decision Table

```typescript
// Shipping calculation
// | Country   | Weight  | Express | Price    |
// |-----------|---------|---------|----------|
// | Domestic  | < 1kg   | No      | $5       |
// | Domestic  | < 1kg   | Yes     | $15      |
// | Domestic  | >= 1kg  | No      | $10      |
// | Domestic  | >= 1kg  | Yes     | $25      |
// | Internat. | < 1kg   | No      | $20      |
// | Internat. | < 1kg   | Yes     | $50      |
// | Internat. | >= 1kg  | No      | $40      |
// | Internat. | >= 1kg  | Yes     | $80      |

const shippingTestCases = [
  { country: 'US', weight: 0.5, express: false, expected: 5 },
  { country: 'US', weight: 0.5, express: true, expected: 15 },
  { country: 'US', weight: 2, express: false, expected: 10 },
  { country: 'US', weight: 2, express: true, expected: 25 },
  { country: 'CA', weight: 0.5, express: false, expected: 20 },
  { country: 'CA', weight: 0.5, express: true, expected: 50 },
  { country: 'CA', weight: 2, express: false, expected: 40 },
  { country: 'CA', weight: 2, express: true, expected: 80 },
];

describe('calculateShipping', () => {
  test.each(shippingTestCases)(
    'calculates $expected for $country, ${weight}kg, express=$express',
    ({ country, weight, express, expected }) => {
      expect(calculateShipping({ country, weight, express })).toBe(expected);
    }
  );
});
```

## State Transition Testing

Test state machines and workflows by covering transitions.

### State Diagram to Tests

```
     ┌─────────┐
     │  Draft  │
     └────┬────┘
          │ submit
          ▼
     ┌─────────┐
     │ Pending │◄────────┐
     └────┬────┘         │
          │ approve/     │ revise
          │ reject       │
          ▼              │
     ┌─────────┐    ┌─────────┐
     │Approved │    │Rejected │
     └─────────┘    └────┬────┘
                        │
                        ▼
                   ┌─────────┐
                   │ Closed  │
                   └─────────┘
```

```typescript
describe('Document state machine', () => {
  describe('from Draft', () => {
    it('transitions to Pending on submit', () => {
      const doc = createDocument({ status: 'draft' });
      doc.submit();
      expect(doc.status).toBe('pending');
    });

    it('cannot approve from draft', () => {
      const doc = createDocument({ status: 'draft' });
      expect(() => doc.approve()).toThrow('Invalid transition');
    });
  });

  describe('from Pending', () => {
    it('transitions to Approved on approve', () => {
      const doc = createDocument({ status: 'pending' });
      doc.approve();
      expect(doc.status).toBe('approved');
    });

    it('transitions to Rejected on reject', () => {
      const doc = createDocument({ status: 'pending' });
      doc.reject();
      expect(doc.status).toBe('rejected');
    });
  });

  describe('from Rejected', () => {
    it('transitions to Pending on revise', () => {
      const doc = createDocument({ status: 'rejected' });
      doc.revise();
      expect(doc.status).toBe('pending');
    });

    it('transitions to Closed on close', () => {
      const doc = createDocument({ status: 'rejected' });
      doc.close();
      expect(doc.status).toBe('closed');
    });
  });

  describe('from Approved', () => {
    it('cannot transition further', () => {
      const doc = createDocument({ status: 'approved' });
      expect(() => doc.reject()).toThrow('Invalid transition');
      expect(() => doc.close()).toThrow('Invalid transition');
    });
  });
});
```

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
