---
name: api-testing
description: Test APIs with integration tests, contract tests, and E2E validation. Covers Jest, Vitest, and Supertest for Node.js/TypeScript APIs. Includes test data management, fixtures, factories, environment configuration, CI/CD integration, mocking external services, and contract testing with OpenAPI validation. Use this skill when building test suites for REST APIs, validating API contracts, or setting up API testing infrastructure.
---

# API Integration Testing

Build robust test suites for your APIs with integration, contract, and E2E tests.

## Testing Pyramid for APIs

| Level | What It Tests | Speed | Isolation |
|-------|---------------|-------|-----------|
| **Unit** | Handlers, validators, utils | Fast | High |
| **Integration** | API + database, services | Medium | Medium |
| **Contract** | API shape vs OpenAPI spec | Fast | High |
| **E2E** | Full stack, real DB | Slow | Low |

## Key Principles

- Test API behavior through HTTP requests, not internal function calls
- Use real database for integration tests (SQLite or test containers)
- Validate response shapes against OpenAPI spec with contract tests
- Isolate external services with MSW or similar mock servers

## Quick Start Checklist

1. Set up test framework (Vitest + Supertest recommended)
2. Configure test database (separate from dev)
3. Create test factories for data setup
4. Write integration tests for each endpoint (happy + error paths)
5. Add contract tests against OpenAPI spec
6. Configure CI pipeline for automated test runs

## References

| Reference | Description |
|-----------|-------------|
| [test-frameworks.md](references/test-frameworks.md) | Vitest, Jest, Supertest setup and configuration |
| [test-patterns.md](references/test-patterns.md) | Request testing, authentication, error validation |
| [test-data.md](references/test-data.md) | Factories, fixtures, database seeding |
| [contract-testing.md](references/contract-testing.md) | OpenAPI validation, schema testing |
| [ci-cd.md](references/ci-cd.md) | CI pipeline configuration, environment setup |
