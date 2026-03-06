# Testing Strategy: Payment Processing Service with Stripe Integration

## Overview

A payment processing service with webhook handlers, idempotency logic, and retry mechanisms has three distinct risk surfaces: external API integration (Stripe), data consistency (idempotency), and reliability (retries). The testing strategy below addresses all three with a layered approach, organized by priority.

---

## Test Pyramid Structure

### Layer 1: Unit Tests (highest priority, fastest feedback)

Unit tests should cover pure business logic in isolation. Mock all external boundaries (Stripe SDK, database, message queues).

**What to test:**

- **Idempotency key generation and validation** -- Verify keys are deterministic for the same input, unique across distinct inputs, and follow the expected format. Test edge cases: empty inputs, extremely long inputs, special characters.
- **Idempotency deduplication logic** -- Given a stored idempotency record, verify that a duplicate request returns the cached response without re-executing. Verify that a request with the same key but different parameters is rejected (not silently accepted).
- **Retry policy calculations** -- Verify backoff intervals (exponential, jitter), max retry counts, and which error types are retryable vs. terminal. Test boundary: what happens at max retries.
- **Webhook signature verification** -- Verify valid signatures pass, invalid signatures are rejected, expired timestamps are rejected, and replay attacks (old valid signatures) are caught.
- **Webhook event parsing** -- Verify each event type you handle is parsed correctly. Verify unknown event types are handled gracefully (logged and acknowledged, not crashed).
- **Payment state machine transitions** -- If you model payment states (pending, processing, succeeded, failed, refunded), verify every valid transition and that invalid transitions are rejected.
- **Amount and currency handling** -- Verify cent/unit conversions, rounding behavior, minimum/maximum amounts, and currency-specific rules (e.g., zero-decimal currencies like JPY).
- **Error classification** -- Verify that Stripe error codes are correctly classified into retryable (rate limit, network timeout) vs. terminal (card declined, invalid request).

**Estimated count:** 60-100 tests. These run in milliseconds.

### Layer 2: Integration Tests (second priority, moderate speed)

Integration tests verify that your code works correctly with real dependencies (database, cache) but still mock external APIs.

**What to test:**

- **Idempotency storage round-trips** -- Write an idempotency record to the real database, read it back, verify TTL/expiration behavior. Test concurrent writes with the same key (race condition).
- **Database transactions for payment creation** -- Verify that payment record creation and idempotency record creation happen atomically. Simulate a failure mid-transaction and verify rollback.
- **Retry queue mechanics** -- If using a job queue (Redis, SQS, database-backed), verify that failed payments are enqueued with correct delay, picked up on schedule, and removed after max retries.
- **Webhook event deduplication** -- Stripe can deliver the same webhook event multiple times. Verify your storage layer correctly deduplicates by event ID.
- **Concurrent payment processing** -- Two requests for the same idempotency key arrive simultaneously. Only one should execute; the other should wait or return the cached result. This requires real concurrency (threads or async) against a real database.

**Estimated count:** 20-40 tests. These run in seconds (database I/O).

### Layer 3: Contract Tests (third priority)

Contract tests verify that your code sends valid requests to Stripe and correctly handles Stripe's responses, without calling Stripe's live API.

**What to test:**

- **Request shape validation** -- Verify that PaymentIntent creation requests include all required fields, use correct types, and match Stripe's API schema for your pinned API version.
- **Response handling for every Stripe object you consume** -- Use recorded or fixture-based Stripe responses. Verify your code extracts the right fields from PaymentIntent, Charge, Refund, Dispute objects.
- **Webhook payload contracts** -- Verify your handler correctly processes the actual shape of each webhook event type (payment_intent.succeeded, charge.refunded, etc.). Use real example payloads from Stripe's documentation or test mode.
- **Error response handling** -- Verify your code handles every Stripe error type: card_error, rate_limit_error, api_error, authentication_error, invalid_request_error. Use fixture responses matching Stripe's actual error format.
- **API version compatibility** -- Pin your Stripe API version. Contract tests should use response fixtures matching that version, so you catch breakage when upgrading.

**Estimated count:** 15-30 tests.

### Layer 4: End-to-End Tests (fourth priority, slowest)

E2E tests verify complete flows against Stripe's test mode. These are slow, flaky-prone, and rate-limited, so keep the count minimal.

**What to test:**

- **Happy path: successful payment** -- Create a payment intent with a test card (4242...), confirm it, verify webhook delivery, verify your database state.
- **Declined payment** -- Use Stripe's decline test card, verify your system records the failure correctly.
- **Webhook delivery and processing** -- Use Stripe CLI (`stripe listen --forward-to`) to forward test webhooks to your local handler. Verify end-to-end event processing.
- **Retry recovery** -- Force a transient failure (e.g., kill your webhook endpoint mid-processing), verify Stripe retries, verify your idempotency logic prevents double-processing.
- **Refund flow** -- Process a payment, issue a refund, verify webhook events and database state.

**Estimated count:** 5-10 tests. Run these in CI on a schedule (nightly), not on every commit.

---

## Test Organization

```
tests/
  unit/
    idempotency/
      key-generation.test.ts
      deduplication.test.ts
      expiration.test.ts
    payments/
      state-machine.test.ts
      amount-handling.test.ts
      error-classification.test.ts
    webhooks/
      signature-verification.test.ts
      event-parsing.test.ts
    retry/
      backoff-calculation.test.ts
      retry-policy.test.ts
  integration/
    idempotency-storage.test.ts
    payment-transactions.test.ts
    retry-queue.test.ts
    concurrent-processing.test.ts
    webhook-deduplication.test.ts
  contract/
    stripe-requests.test.ts
    stripe-responses.test.ts
    webhook-payloads.test.ts
    error-responses.test.ts
  e2e/
    payment-happy-path.test.ts
    payment-declined.test.ts
    webhook-delivery.test.ts
    retry-recovery.test.ts
    refund-flow.test.ts
  fixtures/
    stripe/
      payment-intents/        # Recorded Stripe response fixtures
      webhook-events/         # Real webhook payloads by event type
      errors/                 # Error response fixtures by type
  helpers/
    stripe-mock.ts            # Shared Stripe mock/stub utilities
    db-setup.ts               # Test database lifecycle
    webhook-factory.ts        # Construct webhook events with valid signatures
```

---

## Prioritization Order (from 0% coverage)

Given zero coverage, work in this order to maximize risk reduction per hour invested:

### Phase 1: Foundation (days 1-3)

1. **Webhook signature verification** -- A bug here means accepting forged events or rejecting real ones. Both are critical. This is pure logic, fast to test.
2. **Idempotency deduplication logic** -- Double-charging customers is the highest-severity bug in a payment system. Unit test this thoroughly.
3. **Error classification (retryable vs. terminal)** -- Misclassifying a terminal error as retryable means infinite retries. Misclassifying a retryable error as terminal means lost revenue.
4. **Payment state machine transitions** -- Invalid state transitions cause data corruption. Enumerate every transition.

### Phase 2: Reliability (days 4-6)

5. **Retry backoff and limits** -- Verify the math. Verify the ceiling. Verify jitter randomness stays within bounds.
6. **Webhook event parsing for each handled event type** -- Use real Stripe payloads as fixtures.
7. **Idempotency storage integration tests** -- Race conditions and TTL behavior need a real database.
8. **Database transaction atomicity** -- Verify payment + idempotency records are atomic.

### Phase 3: Contracts (days 7-8)

9. **Stripe request/response contracts** -- Pin your API version, record fixtures, verify parsing.
10. **Concurrent idempotency integration test** -- The hardest test to write but catches the hardest bugs.

### Phase 4: Confidence (day 9+)

11. **E2E happy path against Stripe test mode** -- One test that proves the full system works.
12. **E2E failure and retry recovery** -- Proves resilience under real conditions.

---

## Key Testing Patterns for This Domain

### Idempotency Testing Pattern

Every idempotency test needs three scenarios:
1. **First request** -- Executes normally, stores result.
2. **Duplicate request (same key, same params)** -- Returns cached result, does NOT re-execute.
3. **Conflicting request (same key, different params)** -- Returns 409 or 422. Never silently processes different params under the same key.

### Webhook Testing Pattern

Use a factory that constructs properly-signed webhook payloads:

```
function buildWebhookEvent(type, data, options?) {
  // Construct the event object
  // Sign it with your test webhook secret
  // Return { body, headers } ready to send to your handler
}
```

This lets every webhook test focus on behavior rather than boilerplate signing.

### Retry Testing Pattern

Test retries by injecting failures at the boundary:

```
// Arrange: mock Stripe to fail twice, then succeed
mockStripe.onCall(0).reject(rateLimitError)
mockStripe.onCall(1).reject(networkError)
mockStripe.onCall(2).resolve(successResponse)

// Act: trigger payment processing

// Assert: verify 3 calls made, final result is success,
// delays between calls match backoff policy
```

### Concurrency Testing Pattern

For idempotency race conditions, launch N concurrent requests with the same key and verify:
- Exactly one execution occurred (check side effects / call count)
- All N requests received the same response
- No database constraint violations or deadlocks

---

## What NOT to Test

- **Stripe SDK internals** -- Do not test that `stripe.paymentIntents.create()` makes an HTTP call. That is Stripe's responsibility.
- **Framework routing** -- Do not test that POST /webhooks routes to your handler. Test the handler logic directly.
- **Database driver behavior** -- Do not test that INSERT inserts. Test your transaction boundaries and constraints.

---

## CI Configuration Recommendations

- **Unit + contract tests**: Run on every commit. Target < 30 seconds.
- **Integration tests**: Run on every PR. Target < 2 minutes. Use a containerized test database.
- **E2E tests**: Run nightly or on release branches. Require Stripe test API key in CI secrets. Set a generous timeout (5+ minutes) due to Stripe API latency.
- **Separate Stripe test API keys for CI** -- Never share keys between local dev and CI. Stripe rate limits per key.

---

## Coverage Targets

| Layer | Target | Rationale |
|-------|--------|-----------|
| Idempotency logic | 100% branch | Double-charge prevention is non-negotiable |
| Webhook signature verification | 100% branch | Security boundary |
| Payment state machine | 100% transition | Every valid and invalid transition |
| Retry logic | 95%+ | Edge cases in timing are hard to cover |
| Error classification | 100% of known Stripe error types | Missing a type means silent failure |
| Overall service | 80%+ line | Standard target after all layers are in place |

The 100% targets above are not aspirational -- they are achievable because the code under test is pure logic with clear inputs and outputs. The 80% overall target accounts for glue code, logging, and configuration that has diminishing returns to test.
