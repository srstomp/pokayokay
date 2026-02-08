# Module Mocking and Advanced Patterns

Module mocking, time mocking, anti-patterns, and dependency injection for testability.

## Module Mocking

### Mocking Modules

```typescript
// Mock entire module
vi.mock('./analytics', () => ({
  track: vi.fn(),
  identify: vi.fn(),
}));

// Mock with factory
vi.mock('./config', () => ({
  default: {
    apiUrl: 'http://test.local',
    debug: true,
  },
}));

// Partial mock
vi.mock('./utils', async () => {
  const actual = await vi.importActual('./utils');
  return {
    ...actual,
    fetchData: vi.fn().mockResolvedValue({ data: 'mocked' }),
  };
});
```

### Mocking ES Modules

```typescript
// Named exports
vi.mock('./service', () => ({
  getUser: vi.fn().mockResolvedValue({ id: '1' }),
  createUser: vi.fn().mockResolvedValue({ id: '2' }),
}));

// Default export
vi.mock('./client', () => ({
  default: vi.fn().mockReturnValue({
    get: vi.fn().mockResolvedValue({ data: [] }),
    post: vi.fn().mockResolvedValue({ data: { id: '1' } }),
  }),
}));
```

### Resetting Mocks

```typescript
beforeEach(() => {
  // Clear mock call history
  vi.clearAllMocks();

  // Reset to original implementation
  vi.resetAllMocks();

  // Restore original modules
  vi.restoreAllMocks();
});

// Or per-mock
const myMock = vi.fn();
myMock.mockClear();    // Clear calls
myMock.mockReset();    // Clear calls + implementation
myMock.mockRestore();  // Restore original
```

---

## Time Mocking

```typescript
import { vi, beforeEach, afterEach } from 'vitest';

describe('Time-dependent tests', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2024-01-15T10:00:00Z'));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('shows correct date', () => {
    render(<DateDisplay />);
    expect(screen.getByText('January 15, 2024')).toBeInTheDocument();
  });

  it('handles timeout', async () => {
    const callback = vi.fn();
    setTimeout(callback, 1000);

    expect(callback).not.toHaveBeenCalled();

    vi.advanceTimersByTime(1000);

    expect(callback).toHaveBeenCalled();
  });

  it('handles interval', () => {
    const callback = vi.fn();
    setInterval(callback, 100);

    vi.advanceTimersByTime(350);

    expect(callback).toHaveBeenCalledTimes(3);
  });
});
```

---

## Anti-Patterns

### Over-Mocking

```typescript
// Mocking too much - test is meaningless
it('processes order', async () => {
  vi.mock('./validateOrder');
  vi.mock('./calculateTax');
  vi.mock('./applyDiscount');
  vi.mock('./chargePayment');
  vi.mock('./sendConfirmation');

  await processOrder(order);
  // What did we actually test?
});

// Mock only external boundaries
it('processes order', async () => {
  // Only mock external services
  server.use(
    http.post('/api/payments', () => HttpResponse.json({ success: true }))
  );
  vi.mock('./email', () => ({
    sendEmail: vi.fn().mockResolvedValue(true),
  }));

  const result = await processOrder(order);

  expect(result.status).toBe('completed');
  expect(result.total).toBe(expectedTotal);
});
```

### Mocking What You Own

```typescript
// Mocking internal module
vi.mock('./orderCalculator');
const result = processOrder(order);
expect(mockCalculator).toHaveBeenCalled();

// Test the actual behavior
const result = processOrder(order);
expect(result.total).toBe(100);
expect(result.tax).toBe(8);
```

### Brittle Mock Assertions

```typescript
// Testing exact call signature (brittle)
expect(mockApi.post).toHaveBeenCalledWith(
  '/api/orders',
  {
    userId: '123',
    items: [{ id: '1', quantity: 1 }],
    metadata: { source: 'web', timestamp: '2024-01-15T10:00:00Z' },
  },
  { headers: { 'Content-Type': 'application/json' } }
);

// Test what matters
expect(mockApi.post).toHaveBeenCalledWith(
  '/api/orders',
  expect.objectContaining({
    userId: '123',
    items: expect.arrayContaining([
      expect.objectContaining({ id: '1' }),
    ]),
  }),
  expect.anything()
);
```

### Mock Leakage

```typescript
// Mock leaks between tests
vi.mock('./api');

describe('Feature A', () => {
  it('uses mocked API', () => {
    // Works
  });
});

describe('Feature B', () => {
  it('expects real API', () => {
    // Fails because mock leaked
  });
});

// Clean up properly
beforeEach(() => {
  vi.resetModules();
  vi.clearAllMocks();
});
```

---

## Dependency Injection for Testability

```typescript
// Hard to test - direct dependency
class OrderService {
  async processOrder(order: Order) {
    const paymentResult = await StripeClient.charge(order.total);
    await EmailService.send(order.email, 'Confirmation');
    return { success: true };
  }
}

// Easy to test - injected dependencies
interface PaymentGateway {
  charge(amount: number): Promise<PaymentResult>;
}

interface EmailSender {
  send(to: string, subject: string): Promise<void>;
}

class OrderService {
  constructor(
    private payment: PaymentGateway,
    private email: EmailSender
  ) {}

  async processOrder(order: Order) {
    const paymentResult = await this.payment.charge(order.total);
    await this.email.send(order.email, 'Confirmation');
    return { success: true };
  }
}

// Test with fakes
it('processes order successfully', async () => {
  const fakePayment = { charge: vi.fn().mockResolvedValue({ success: true }) };
  const fakeEmail = { send: vi.fn().mockResolvedValue(undefined) };

  const service = new OrderService(fakePayment, fakeEmail);
  const result = await service.processOrder(order);

  expect(result.success).toBe(true);
  expect(fakePayment.charge).toHaveBeenCalledWith(order.total);
});
```
