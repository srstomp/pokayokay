---
name: testing-strategy
description: Comprehensive test architecture, coverage strategy, and test design. Covers test pyramid design, API integration testing (Supertest, contract tests, OpenAPI validation), frontend/component testing (React Testing Library, Vue Test Utils), E2E testing (Playwright, Cypress), visual regression, mocking strategies (MSW), test data management (factories, fixtures), CI/CD test pipelines, and flaky test prevention. Use this skill when designing test architecture, building API test suites, validating API contracts, setting up component or E2E testing, managing test data, debugging flaky tests, reviewing coverage strategy, or organizing test files.
---

# Testing Strategy

Comprehensive testing guidance for test architecture, coverage strategy, and test design.

## Test Pyramid

| Level | Speed | Cost | Confidence | Share |
|-------|-------|------|------------|-------|
| **Unit** | ~1ms | Low | Narrow | 65-80% |
| **Integration** | ~100ms | Medium | Medium | 15-25% |
| **Contract** | ~10ms | Low | API shape | Part of unit |
| **E2E** | ~1s+ | High | Broad | 5-10% |

## Key Principles

- Test behavior, not implementation — test what code does, not how
- Follow the testing pyramid — more unit tests, fewer E2E
- Use meaningful coverage metrics — branch coverage over line coverage
- Prevent flaky tests — no arbitrary waits, no test interdependence

## Quick Start Checklist

1. Choose test framework (Vitest recommended for new projects)
2. Design test folder structure mirroring source
3. Write unit tests for pure logic and utilities
4. Add integration tests for API endpoints and data flows
5. Add contract tests against OpenAPI spec (if applicable)
6. Add E2E tests for critical user journeys only
7. Set up CI to run tests on every PR

## What NOT to Test

- Framework internals (React rendering, Express routing)
- Third-party library behavior
- Trivial getters/setters with no logic
- Implementation details (private methods, internal state)

## References

| Reference | Description |
|-----------|-------------|
| [test-architecture.md](references/test-architecture.md) | Test pyramid, folder structure, naming conventions |
| [test-design.md](references/test-design.md) | Writing good tests, AAA pattern, assertion strategies |
| [frontend-testing.md](references/frontend-testing.md) | React Testing Library, component tests, visual regression |
| [e2e-testing.md](references/e2e-testing.md) | Playwright, Cypress, E2E patterns |
| [mocking-strategies.md](references/mocking-strategies.md) | MSW, test doubles, when to mock |
| [coverage-guide.md](references/coverage-guide.md) | Coverage metrics, meaningful thresholds, CI integration |
| [api-test-frameworks.md](references/api-test-frameworks.md) | Vitest, Jest, Supertest setup for API testing |
| [api-test-patterns.md](references/api-test-patterns.md) | Request testing, authentication, error validation |
| [api-test-data.md](references/api-test-data.md) | Factories, fixtures, database seeding |
| [api-contract-testing.md](references/api-contract-testing.md) | OpenAPI validation, schema testing |
| [api-test-ci-cd.md](references/api-test-ci-cd.md) | CI pipeline configuration for API tests |
