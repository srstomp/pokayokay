---
name: error-handling
agents: [yokay-implementer, yokay-fixer, yokay-task-reviewer]
description: Use when designing error hierarchies, implementing React error boundaries, adding retry logic or fallbacks, creating API error responses, integrating error tracking (Sentry), or improving user-facing error communication.
---

# Error Handling

Design resilient applications through intentional error handling strategies. Errors are data, not just exceptions — design them intentionally.

## Quick Decision Guide

| Situation | Pattern | Reference |
|-----------|---------|-----------|
| Typed error categories | Custom error classes | [error-patterns.md](references/error-patterns.md) |
| Explicit handling (no throws) | Result/Either type | [error-patterns.md](references/error-patterns.md) |
| React component crash | Error boundary | [react-errors.md](references/react-errors.md) |
| API error response | Structured API errors | [api-errors.md](references/api-errors.md) |
| Network calls that fail | Retry with backoff | [recovery-patterns.md](references/recovery-patterns.md) |
| Unreliable downstream service | Circuit breaker | [recovery-patterns.md](references/recovery-patterns.md) |

## Key Principles

- **Debuggable**: Rich context, stack traces, correlation IDs
- **Recoverable**: Retry logic, fallbacks, circuit breakers
- **User-friendly**: Clear messages, recovery guidance, no leaked internals
- **Consistent**: Same error shape across all API endpoints

## Quick Start Checklist

1. Define base AppError class with code and context
2. Create domain-specific error subclasses
3. Implement consistent API error response shape
4. Add error boundaries at app, route, and component levels
5. Set up error tracking (Sentry) with scrubbing

## References

| Reference | Description |
|-----------|-------------|
| [error-patterns.md](references/error-patterns.md) | Custom errors, Result types, error hierarchies |
| [react-errors.md](references/react-errors.md) | Error boundaries, Suspense, React error handling |
| [api-errors.md](references/api-errors.md) | HTTP errors, response shapes, status codes |
| [recovery-patterns.md](references/recovery-patterns.md) | Retry, circuit breaker, fallbacks, degradation |
| [overview.md](references/overview.md) | Error types, Result pattern, user messages, tracking, anti-patterns |
| [anti-rationalization.md](references/anti-rationalization.md) | Iron Law, common rationalizations, red flag STOP list for error handling discipline |
| [tdd-patterns.md](references/tdd-patterns.md) | Test-first patterns for error paths, retry logic, boundaries |
| [review-checklist.md](references/review-checklist.md) | Error handling review checklist (classes, messages, recovery, tracking) |
