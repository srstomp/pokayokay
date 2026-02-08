---
name: api-integration
description: Use when consuming external APIs, integrating third-party services, generating type-safe API clients, implementing authentication flows, or working with OpenAPI/Swagger, GraphQL, or REST specs. TypeScript-primary with language-agnostic patterns.
---

# API Integration

Build robust, type-safe API clients from specs and documentation.

## Key Principles

- **Type everything** — Runtime-validated types for all requests and responses
- **Fail explicitly** — No silent failures; throw typed errors with context
- **Auth is first-class** — Handle auth in the client layer, not scattered in calls
- **Retry intelligently** — Only idempotent methods, only transient failures, with backoff
- **Isolate the boundary** — Transform API shapes at the integration layer, not in app code

## When NOT to Use

- **Designing your own APIs** — Use `api-design` for building endpoints others will consume
- **Writing API test suites** — Use `testing-strategy` for test architecture, contract tests, mocking
- **Building SDKs for your API** — Use `sdk-development` for packaging your own API as a client library

## Quick Start Checklist

1. Obtain API credentials and locate documentation (spec, docs, or examples)
2. Analyze inputs: extract base URL, auth scheme, endpoints, error formats
3. Choose architecture: typed wrapper (1-5 endpoints), service class (5-20), or generated client (20+)
4. Implement types, client, auth handling, and error classification
5. Add retry logic for transient failures and rate limit handling
6. Write tests with mocked responses and error scenarios

## References

| Reference | Description |
|-----------|-------------|
| [openapi-consumption.md](references/openapi-consumption.md) | Parsing specs, type generation, codegen tools |
| [client-architecture.md](references/client-architecture.md) | Client patterns, service layers, request handling |
| [error-handling.md](references/error-handling.md) | Error types, retry logic, circuit breakers |
| [authentication.md](references/authentication.md) | OAuth, API keys, JWT, token refresh |
| [testing.md](references/testing.md) | Mocking, integration tests, contract testing |
