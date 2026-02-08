# Test Design Techniques

Equivalence partitioning, boundary value analysis, decision tables, and state transition testing.

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
