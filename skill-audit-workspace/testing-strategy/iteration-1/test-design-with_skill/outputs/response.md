# Testing Strategy for Payment Processing Service

## Overview

You have a payment processing service with three critical subsystems: Stripe webhook handlers, idempotency logic, and retry mechanisms. Starting from 0% coverage, the strategy below prioritizes what to test first, how to organize tests, and which techniques apply to each area.

---

## Test Pyramid for This Service

| Level | Share | What It Covers Here |
|-------|-------|---------------------|
| **Unit** | ~65% | Idempotency key generation, amount calculations, retry backoff logic, webhook signature verification, state machine transitions, input validation |
| **Integration** | ~25% | Webhook endpoint handling, payment flow with mocked Stripe, database idempotency record lifecycle, retry queue processing |
| **Contract** | Part of unit | Stripe webhook payload schemas (Zod), your API response shapes |
| **E2E** | ~10% | Full checkout-to-webhook flow, double-charge prevention across the whole stack |

---

## Priority Order: What to Test First

Payment processing is a critical path. The coverage guide is explicit: **critical paths (auth, payments, data mutations) need 100% coverage**. Work in this order:

### Phase 1: Idempotency Logic (Unit Tests)

This is the highest-risk pure logic in the service. Bugs here mean double charges.

```typescript
describe('IdempotencyService', () => {
  // State transition testing: idempotency records move through states
  //   pending -> completed
  //   pending -> failed
  //   completed -> (no further transitions)
  describe('state transitions', () => {
    it('transitions from pending to completed on success', () => {
      const record = createIdempotencyRecord({ status: 'pending' });
      record.complete({ chargeId: 'ch_123' });
      expect(record.status).toBe('completed');
      expect(record.response.chargeId).toBe('ch_123');
    });

    it('transitions from pending to failed on error', () => {
      const record = createIdempotencyRecord({ status: 'pending' });
      record.fail(new Error('Card declined'));
      expect(record.status).toBe('failed');
    });

    it('cannot transition from completed to any other state', () => {
      const record = createIdempotencyRecord({ status: 'completed' });
      expect(() => record.fail(new Error('late error'))).toThrow('Invalid transition');
    });

    it('returns cached response for duplicate requests', () => {
      const record = createIdempotencyRecord({
        status: 'completed',
        response: { chargeId: 'ch_123', amount: 5000 },
      });
      expect(record.getCachedResponse()).toEqual({ chargeId: 'ch_123', amount: 5000 });
    });
  });

  // Boundary value analysis on idempotency key
  describe('key validation', () => {
    it('accepts valid UUID keys', () => {
      expect(validateIdempotencyKey('550e8400-e29b-41d4-a716-446655440000')).toBe(true);
    });

    it('rejects empty key', () => {
      expect(validateIdempotencyKey('')).toBe(false);
    });

    it('rejects key exceeding max length', () => {
      expect(validateIdempotencyKey('x'.repeat(256))).toBe(false);
    });

    it('accepts key at max length boundary', () => {
      expect(validateIdempotencyKey('x'.repeat(255))).toBe(true);
    });
  });

  // Decision table: what to do for each idempotency state
  describe('request deduplication', () => {
    const scenarios = [
      { existingStatus: null, expectedAction: 'process_new' },
      { existingStatus: 'pending', expectedAction: 'wait_and_return' },
      { existingStatus: 'completed', expectedAction: 'return_cached' },
      { existingStatus: 'failed', expectedAction: 'retry_allowed' },
    ];

    test.each(scenarios)(
      'returns $expectedAction when existing status is $existingStatus',
      ({ existingStatus, expectedAction }) => {
        const action = determineAction(existingStatus);
        expect(action).toBe(expectedAction);
      }
    );
  });
});
```

### Phase 2: Retry Mechanism (Unit Tests)

Retry logic has subtle bugs around exponential backoff, max attempts, and jitter. Use property-based testing here.

```typescript
describe('RetryPolicy', () => {
  // Boundary values on attempt counts
  describe('attempt limits', () => {
    it('allows retry when attempts < maxRetries', () => {
      const policy = createRetryPolicy({ maxRetries: 3 });
      expect(policy.shouldRetry(2)).toBe(true);
    });

    it('denies retry when attempts = maxRetries', () => {
      const policy = createRetryPolicy({ maxRetries: 3 });
      expect(policy.shouldRetry(3)).toBe(false);
    });

    it('denies retry when attempts > maxRetries', () => {
      const policy = createRetryPolicy({ maxRetries: 3 });
      expect(policy.shouldRetry(4)).toBe(false);
    });
  });

  // Decision table: which errors are retryable
  describe('retryable error classification', () => {
    const cases = [
      { error: 'rate_limit', retryable: true },
      { error: 'network_error', retryable: true },
      { error: 'timeout', retryable: true },
      { error: 'card_declined', retryable: false },
      { error: 'invalid_request', retryable: false },
      { error: 'authentication_error', retryable: false },
    ];

    test.each(cases)(
      '$error is retryable: $retryable',
      ({ error, retryable }) => {
        expect(isRetryableError(error)).toBe(retryable);
      }
    );
  });

  // Property-based testing: backoff invariants
  describe('exponential backoff', () => {
    it('delay always increases with attempt number', () => {
      fc.assert(
        fc.property(
          fc.integer({ min: 1, max: 10 }),
          (attempt) => {
            const delay1 = calculateBackoff(attempt);
            const delay2 = calculateBackoff(attempt + 1);
            expect(delay2).toBeGreaterThan(delay1);
          }
        )
      );
    });

    it('delay never exceeds max backoff', () => {
      fc.assert(
        fc.property(
          fc.integer({ min: 1, max: 100 }),
          (attempt) => {
            const delay = calculateBackoff(attempt);
            expect(delay).toBeLessThanOrEqual(MAX_BACKOFF_MS);
          }
        )
      );
    });

    it('delay is always positive', () => {
      fc.assert(
        fc.property(
          fc.integer({ min: 0, max: 100 }),
          (attempt) => {
            expect(calculateBackoff(attempt)).toBeGreaterThan(0);
          }
        )
      );
    });
  });

  // Time-dependent: mock timers for retry scheduling
  describe('retry scheduling', () => {
    beforeEach(() => vi.useFakeTimers());
    afterEach(() => vi.useRealTimers());

    it('waits correct delay before retrying', async () => {
      const operation = vi.fn()
        .mockRejectedValueOnce(new Error('rate_limit'))
        .mockResolvedValue({ success: true });

      const promise = retryWithBackoff(operation, { maxRetries: 3 });

      vi.advanceTimersByTime(1000); // First retry delay
      await vi.runAllTimersAsync();

      const result = await promise;
      expect(result).toEqual({ success: true });
      expect(operation).toHaveBeenCalledTimes(2);
    });
  });
});
```

### Phase 3: Webhook Handlers (Integration Tests)

Webhooks are the integration boundary with Stripe. Mock Stripe at the network level, but test your handler logic end-to-end including database writes.

```typescript
describe('Stripe Webhook Handler', () => {
  beforeEach(async () => {
    await db.truncateAll();
  });

  // Signature verification (unit-level but critical)
  describe('signature verification', () => {
    it('accepts valid signature', async () => {
      const payload = JSON.stringify({ type: 'payment_intent.succeeded', data: {} });
      const signature = generateStripeSignature(payload, WEBHOOK_SECRET);

      const response = await request(app)
        .post('/webhooks/stripe')
        .set('stripe-signature', signature)
        .send(payload)
        .expect(200);
    });

    it('rejects invalid signature', async () => {
      await request(app)
        .post('/webhooks/stripe')
        .set('stripe-signature', 'invalid_sig')
        .send('{}')
        .expect(400);
    });

    it('rejects missing signature header', async () => {
      await request(app)
        .post('/webhooks/stripe')
        .send('{}')
        .expect(400);
    });

    it('rejects expired timestamp in signature', async () => {
      const payload = JSON.stringify({ type: 'payment_intent.succeeded' });
      const expiredSignature = generateStripeSignature(payload, WEBHOOK_SECRET, {
        timestamp: Math.floor(Date.now() / 1000) - 600, // 10 minutes ago
      });

      await request(app)
        .post('/webhooks/stripe')
        .set('stripe-signature', expiredSignature)
        .send(payload)
        .expect(400);
    });
  });

  // State machine: payment lifecycle through webhooks
  describe('payment_intent events', () => {
    it('records successful payment on payment_intent.succeeded', async () => {
      const order = await createOrder({ status: 'pending', stripePaymentIntentId: 'pi_123' });

      await sendWebhook('payment_intent.succeeded', {
        id: 'pi_123',
        amount: 5000,
        currency: 'usd',
      });

      const updatedOrder = await getOrder(order.id);
      expect(updatedOrder.status).toBe('paid');
      expect(updatedOrder.paidAt).toBeDefined();
    });

    it('marks order as failed on payment_intent.payment_failed', async () => {
      const order = await createOrder({ status: 'pending', stripePaymentIntentId: 'pi_456' });

      await sendWebhook('payment_intent.payment_failed', {
        id: 'pi_456',
        last_payment_error: { message: 'Card declined' },
      });

      const updatedOrder = await getOrder(order.id);
      expect(updatedOrder.status).toBe('payment_failed');
    });

    it('handles unknown payment intent gracefully', async () => {
      const response = await sendWebhook('payment_intent.succeeded', {
        id: 'pi_unknown',
        amount: 5000,
      });

      // Should acknowledge (200) but log warning, not crash
      expect(response.status).toBe(200);
    });
  });

  // Idempotency at the webhook level
  describe('webhook idempotency', () => {
    it('processes same event only once', async () => {
      const order = await createOrder({ status: 'pending', stripePaymentIntentId: 'pi_789' });

      await sendWebhook('payment_intent.succeeded', { id: 'pi_789' }, {
        eventId: 'evt_duplicate_test',
      });
      await sendWebhook('payment_intent.succeeded', { id: 'pi_789' }, {
        eventId: 'evt_duplicate_test',
      });

      // Verify only one payment record was created
      const payments = await getPaymentsForOrder(order.id);
      expect(payments).toHaveLength(1);
    });
  });
});
```

### Phase 4: Payment Amount Calculations (Unit Tests)

Financial calculations demand precision. Use boundary value analysis and parameterized tests.

```typescript
describe('Payment Calculations', () => {
  // Parameterized: currency formatting for Stripe (cents)
  describe('amount to Stripe cents conversion', () => {
    const cases = [
      { dollars: 0, expected: 0 },
      { dollars: 0.01, expected: 1 },
      { dollars: 1.00, expected: 100 },
      { dollars: 99.99, expected: 9999 },
      { dollars: 0.1 + 0.2, expected: 30 }, // Floating point edge case
      { dollars: 999999.99, expected: 99999999 },
    ];

    test.each(cases)(
      'converts $dollars to $expected cents',
      ({ dollars, expected }) => {
        expect(toCents(dollars)).toBe(expected);
      }
    );
  });

  // Property-based: round-trip conversion
  describe('round-trip conversion', () => {
    it('converts dollars to cents and back without loss', () => {
      fc.assert(
        fc.property(
          fc.integer({ min: 0, max: 99999999 }),
          (cents) => {
            expect(toCents(toDollars(cents))).toBe(cents);
          }
        )
      );
    });
  });

  // Boundary: minimum and maximum charge amounts
  describe('charge amount validation', () => {
    it('rejects amount below Stripe minimum (50 cents)', () => {
      expect(() => validateChargeAmount(49)).toThrow('Amount below minimum');
    });

    it('accepts amount at Stripe minimum (50 cents)', () => {
      expect(() => validateChargeAmount(50)).not.toThrow();
    });

    it('accepts amount at upper bound (99999999 cents)', () => {
      expect(() => validateChargeAmount(99999999)).not.toThrow();
    });

    it('rejects negative amounts', () => {
      expect(() => validateChargeAmount(-100)).toThrow('Amount must be positive');
    });

    it('rejects zero amount', () => {
      expect(() => validateChargeAmount(0)).toThrow('Amount must be positive');
    });
  });
});
```

### Phase 5: Contract Tests (Zod Schemas)

Define and validate the shape of your API responses and Stripe webhook payloads.

```typescript
// schemas/payment.ts
import { z } from 'zod';

export const CreatePaymentIntentResponseSchema = z.object({
  id: z.string(),
  clientSecret: z.string(),
  amount: z.number().int().positive(),
  currency: z.string().length(3),
  status: z.enum(['requires_payment_method', 'requires_confirmation', 'succeeded', 'canceled']),
});

export const WebhookEventSchema = z.object({
  id: z.string().startsWith('evt_'),
  type: z.string(),
  data: z.object({
    object: z.record(z.unknown()),
  }),
  created: z.number().int(),
});

export const PaymentErrorResponseSchema = z.object({
  status: z.number().int(),
  error: z.string(),
  message: z.string(),
  code: z.string().optional(),
});
```

```typescript
describe('Payment API Contracts', () => {
  it('POST /payments/intents returns valid CreatePaymentIntentResponse', async () => {
    const response = await request(app)
      .post('/payments/intents')
      .set('Authorization', `Bearer ${token}`)
      .send({ amount: 5000, currency: 'usd' })
      .expect(201);

    expect(response.body).toMatchZodSchema(CreatePaymentIntentResponseSchema);
  });

  it('returns valid PaymentErrorResponse for invalid amount', async () => {
    const response = await request(app)
      .post('/payments/intents')
      .set('Authorization', `Bearer ${token}`)
      .send({ amount: -1, currency: 'usd' })
      .expect(400);

    expect(response.body).toMatchZodSchema(PaymentErrorResponseSchema);
  });
});
```

### Phase 6: E2E Flow Tests

These cover the full happy path and the most critical failure paths across the entire stack.

```typescript
describe('E2E: Payment Processing', () => {
  it('completes full payment flow: create intent -> confirm -> webhook -> order fulfilled', async () => {
    const user = await createUser();
    const token = await getAuthToken(user);
    const product = await createProduct({ price: 49.99 });

    // 1. Create order
    const orderRes = await request(app)
      .post('/orders')
      .set('Authorization', `Bearer ${token}`)
      .send({ items: [{ productId: product.id, quantity: 1 }] })
      .expect(201);

    expect(orderRes.body.status).toBe('pending');

    // 2. Create payment intent
    const paymentRes = await request(app)
      .post('/payments/intents')
      .set('Authorization', `Bearer ${token}`)
      .send({
        orderId: orderRes.body.id,
        amount: 4999,
        currency: 'usd',
        idempotencyKey: 'idem_test_001',
      })
      .expect(201);

    expect(paymentRes.body.clientSecret).toBeDefined();

    // 3. Simulate Stripe webhook (payment succeeded)
    await sendWebhook('payment_intent.succeeded', {
      id: paymentRes.body.stripePaymentIntentId,
      amount: 4999,
      currency: 'usd',
    });

    // 4. Verify order is now paid
    const finalOrder = await request(app)
      .get(`/orders/${orderRes.body.id}`)
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    expect(finalOrder.body.status).toBe('paid');
    expect(finalOrder.body.paidAt).toBeDefined();
  });

  it('prevents double-charging via idempotency key', async () => {
    const user = await createUser();
    const token = await getAuthToken(user);

    const idempotencyKey = 'idem_double_charge_test';

    // First request succeeds
    const res1 = await request(app)
      .post('/payments/intents')
      .set('Authorization', `Bearer ${token}`)
      .set('Idempotency-Key', idempotencyKey)
      .send({ amount: 5000, currency: 'usd' })
      .expect(201);

    // Second request with same key returns cached response
    const res2 = await request(app)
      .post('/payments/intents')
      .set('Authorization', `Bearer ${token}`)
      .set('Idempotency-Key', idempotencyKey)
      .send({ amount: 5000, currency: 'usd' })
      .expect(200); // 200, not 201 -- indicates cached

    expect(res2.body.id).toBe(res1.body.id);
  });

  it('handles payment failure and allows retry', async () => {
    const user = await createUser();
    const token = await getAuthToken(user);

    // Create payment that will fail
    const paymentRes = await request(app)
      .post('/payments/intents')
      .set('Authorization', `Bearer ${token}`)
      .send({ amount: 5000, currency: 'usd' })
      .expect(201);

    // Webhook: payment failed
    await sendWebhook('payment_intent.payment_failed', {
      id: paymentRes.body.stripePaymentIntentId,
      last_payment_error: { message: 'Card declined' },
    });

    // Retry with new idempotency key should be allowed
    const retryRes = await request(app)
      .post('/payments/intents')
      .set('Authorization', `Bearer ${token}`)
      .set('Idempotency-Key', 'idem_retry_001')
      .send({ amount: 5000, currency: 'usd' })
      .expect(201);

    expect(retryRes.body.id).not.toBe(paymentRes.body.id);
  });
});
```

---

## Test Organization

```
src/
  services/
    payment/
      payment.service.ts
      payment.service.test.ts         # Unit: amount calculations, validation
    idempotency/
      idempotency.service.ts
      idempotency.service.test.ts     # Unit: state machine, key validation
    retry/
      retry.policy.ts
      retry.policy.test.ts            # Unit: backoff, attempt limits
    webhook/
      webhook.handler.ts

tests/
  setup/
    vitest.setup.ts                   # MSW server, DB cleanup
  helpers/
    db.ts                             # Database helper (truncate, clear, transaction)
    factories/
      payment.ts                      # createPaymentIntent, createPaymentRecord
      order.ts                        # createOrder, createOrderWithItems
      user.ts                         # createUser
      webhook.ts                      # createWebhookEvent, sendWebhook
      index.ts                        # Re-exports
    auth.ts                           # getAuthToken, loginAs
    stripe.ts                         # generateStripeSignature, mockStripeClient
    matchers/
      zod.ts                          # toMatchZodSchema custom matcher
  mocks/
    handlers.ts                       # MSW handlers for Stripe API
    server.ts                         # MSW server setup
  integration/
    webhook-handler.test.ts           # Webhook signature + DB writes
    payment-flow.test.ts              # Payment creation with mocked Stripe
    idempotency-db.test.ts            # Idempotency records in real DB
  contracts/
    payment-api.contract.test.ts      # Zod schema validation of API responses
    webhook-payload.contract.test.ts  # Validate incoming webhook shapes
  e2e/
    checkout-flow.test.ts             # Full create->pay->webhook->fulfilled
    double-charge.test.ts             # Idempotency E2E
    retry-flow.test.ts                # Failure + retry E2E

schemas/
  payment.ts                          # Zod schemas (shared by app + contract tests)

vitest.config.ts
```

---

## Mocking Strategy

Follow the mocking decision tree: **mock at the boundary, not inside your code**.

| Dependency | Mock Strategy | Why |
|------------|--------------|-----|
| **Stripe API** | MSW (network-level) | External service. Mock the HTTP boundary so your SDK calls still execute real code. |
| **Database** | Real DB in integration, fake repo in unit | Unit tests use in-memory fakes for speed. Integration tests use a real test database with transaction rollback. |
| **Time/Dates** | `vi.useFakeTimers()` | Retry backoff, idempotency key expiration, webhook timestamp verification all depend on time. |
| **Crypto/Random** | Mock for deterministic tests | Idempotency key generation, signature verification need reproducible values. |
| **Your own services** | Do NOT mock | Test real behavior. Mocking your own OrderService in PaymentService tests proves nothing. |

### MSW Handlers for Stripe

```typescript
// tests/mocks/handlers.ts
import { http, HttpResponse } from 'msw';

export const stripeHandlers = [
  http.post('https://api.stripe.com/v1/payment_intents', async ({ request }) => {
    const body = await request.text();
    const params = new URLSearchParams(body);

    return HttpResponse.json({
      id: `pi_test_${Date.now()}`,
      client_secret: `pi_test_secret_${Date.now()}`,
      amount: parseInt(params.get('amount') || '0'),
      currency: params.get('currency') || 'usd',
      status: 'requires_payment_method',
    });
  }),

  http.post('https://api.stripe.com/v1/payment_intents/:id/confirm', ({ params }) => {
    return HttpResponse.json({
      id: params.id,
      status: 'succeeded',
    });
  }),
];
```

### Dependency Injection for Testability

```typescript
// Instead of this:
class PaymentService {
  async createPayment(amount: number) {
    const intent = await stripe.paymentIntents.create({ amount, currency: 'usd' });
    return intent;
  }
}

// Do this:
interface PaymentGateway {
  createIntent(amount: number, currency: string): Promise<PaymentIntent>;
  confirmIntent(intentId: string): Promise<PaymentResult>;
}

class PaymentService {
  constructor(
    private gateway: PaymentGateway,
    private idempotencyStore: IdempotencyStore,
    private retryPolicy: RetryPolicy
  ) {}

  async createPayment(amount: number, idempotencyKey: string) {
    const existing = await this.idempotencyStore.find(idempotencyKey);
    if (existing?.status === 'completed') return existing.response;

    return this.retryPolicy.execute(() =>
      this.gateway.createIntent(amount, 'usd')
    );
  }
}
```

---

## Test Data Factories

```typescript
// tests/helpers/factories/payment.ts
import { faker } from '@faker-js/faker';

let paymentCounter = 0;

export async function createPaymentRecord(overrides = {}) {
  paymentCounter++;
  return db.query(
    `INSERT INTO payments (id, order_id, stripe_payment_intent_id, amount, currency, status)
     VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
    [
      overrides.id ?? faker.string.uuid(),
      overrides.orderId ?? (await createOrder()).id,
      overrides.stripePaymentIntentId ?? `pi_test_${paymentCounter}`,
      overrides.amount ?? 5000,
      overrides.currency ?? 'usd',
      overrides.status ?? 'pending',
    ]
  );
}

export function buildWebhookEvent(type: string, data: Record<string, unknown>, options = {}) {
  return {
    id: options.eventId ?? `evt_test_${Date.now()}`,
    type,
    data: { object: data },
    created: Math.floor(Date.now() / 1000),
  };
}

export async function sendWebhook(type: string, data: Record<string, unknown>, options = {}) {
  const event = buildWebhookEvent(type, data, options);
  const payload = JSON.stringify(event);
  const signature = generateStripeSignature(payload, WEBHOOK_SECRET);

  return request(app)
    .post('/webhooks/stripe')
    .set('stripe-signature', signature)
    .set('Content-Type', 'application/json')
    .send(payload);
}
```

---

## Database Isolation Strategy

Use **transaction rollback** for integration tests (fastest) and **truncate** as fallback:

```typescript
// tests/setup/vitest.setup.ts
import { beforeAll, beforeEach, afterAll } from 'vitest';
import { db } from '../helpers/db';

beforeAll(async () => {
  await db.connect();
  await db.migrate();
});

beforeEach(async () => {
  await db.truncateAll(); // Clean slate per test
});

afterAll(async () => {
  await db.close();
});
```

---

## Coverage Targets

| Area | Target | Rationale |
|------|--------|-----------|
| `services/payment/` | 95% branch | Financial calculations. Bugs = money loss. |
| `services/idempotency/` | 95% branch | Double-charge prevention. Mission critical. |
| `services/retry/` | 90% branch | Backoff logic, attempt counting. |
| `services/webhook/` | 85% branch | Integration boundary, tested more via integration tests. |
| `routes/` (handlers) | 80% branch | Input validation, auth checks. |
| Overall | 85% line, 80% branch | API service targets per coverage guide. |

Set these in your Vitest config:

```typescript
// vitest.config.ts
coverage: {
  thresholds: {
    global: { branches: 80, functions: 85, lines: 85, statements: 85 },
    'src/services/payment/**': { branches: 95, lines: 95 },
    'src/services/idempotency/**': { branches: 95, lines: 95 },
    'src/services/retry/**': { branches: 90, lines: 90 },
  },
}
```

---

## CI Pipeline

```
Lint + Typecheck  (< 30s)
       |
  +---------+-----------+
  |         |           |
Unit     Contract    Integration
(< 1m)   (< 30s)    (< 3m, needs DB)
  |         |           |
  +---------+-----------+
            |
         E2E Tests
    (< 5m, staging env)
```

Run unit and contract tests on every PR. Integration tests after lint passes. E2E tests on merge to main.

---

## What NOT to Test

Per the skill's guidance:

- **Stripe SDK internals** -- do not test that `stripe.paymentIntents.create()` calls the right HTTP method. Stripe tests that.
- **Express/framework routing** -- do not test that `POST /webhooks/stripe` reaches your handler. Test what the handler does.
- **Trivial getters** -- `order.getId()` does not need a test.
- **Database driver behavior** -- do not test that Postgres handles `INSERT RETURNING *` correctly.

---

## Key Techniques Summary

| Technique | Where It Applies |
|-----------|-----------------|
| **State transition testing** | Idempotency record lifecycle, payment status machine, order status |
| **Boundary value analysis** | Amount limits (Stripe min/max), idempotency key length, retry attempt counts |
| **Decision table testing** | Error classification (retryable vs. terminal), webhook event routing |
| **Property-based testing** | Backoff invariants, amount conversion round-trips |
| **Parameterized tests** | Currency conversion, error codes, webhook event types |
| **Time mocking** | Retry delays, webhook signature expiration, idempotency key TTL |
| **MSW network mocking** | Stripe API interactions |
| **Dependency injection** | PaymentGateway interface, IdempotencyStore interface |
| **Contract testing (Zod)** | API response shapes, webhook payload validation |
| **Concurrent request testing** | Double-charge prevention under race conditions |
