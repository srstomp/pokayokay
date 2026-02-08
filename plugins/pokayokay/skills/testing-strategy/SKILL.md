---
name: testing-strategy
agents: [yokay-test-runner]
description: Use when designing test architecture, building API test suites, validating API contracts, setting up component or E2E testing, managing test data, debugging flaky tests, reviewing coverage strategy, or organizing test files. Covers test pyramid, mocking (MSW), frontend (React Testing Library, Playwright), and CI integration.
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
| [test-architecture-structure.md](references/test-architecture-structure.md) | Project structures, shared utilities, test configuration |
| [test-architecture-isolation.md](references/test-architecture-isolation.md) | Playwright config, database isolation, performance optimization |
| [test-design-techniques.md](references/test-design-techniques.md) | Equivalence partitioning, boundary values, decision tables, state transitions |
| [test-design-error-and-advanced.md](references/test-design-error-and-advanced.md) | Error handling tests, property-based testing, parameterization, regression |
| [frontend-react-testing.md](references/frontend-react-testing.md) | React Testing Library, queries, user events, hooks, forms |
| [frontend-vue-a11y-visual.md](references/frontend-vue-a11y-visual.md) | Vue Test Utils, accessibility, visual/Storybook testing, anti-patterns |
| [e2e-playwright.md](references/e2e-playwright.md) | Playwright POM, fixtures, auth state, API mocking, visual comparison |
| [e2e-cypress-and-stability.md](references/e2e-cypress-and-stability.md) | Cypress patterns, flaky test prevention, test data, debugging |
| [mocking-fundamentals.md](references/mocking-fundamentals.md) | Mock decision tree, stubs/mocks/spies/fakes, MSW setup and usage |
| [mocking-modules-and-patterns.md](references/mocking-modules-and-patterns.md) | Module mocking, time mocking, anti-patterns, dependency injection |
| [coverage-guide.md](references/coverage-guide.md) | Coverage metrics, meaningful thresholds, CI integration |
| [api-test-frameworks-setup.md](references/api-test-frameworks-setup.md) | Vitest and Jest setup, configuration, running tests |
| [api-test-supertest-and-helpers.md](references/api-test-supertest-and-helpers.md) | Supertest usage, request helpers, custom matchers, snapshots, debugging |
| [api-integration-patterns.md](references/api-integration-patterns.md) | CRUD endpoint tests, relationship tests |
| [api-auth-patterns.md](references/api-auth-patterns.md) | Login/logout, protected routes, authorization, auth helpers |
| [api-e2e-and-edge-cases.md](references/api-e2e-and-edge-cases.md) | Multi-step workflow tests, error responses, edge cases |
| [api-test-data-factories.md](references/api-test-data-factories.md) | Factory patterns, builders, fixtures |
| [api-test-data-database.md](references/api-test-data-database.md) | Database helpers, cleanup strategies, data generation |
| [api-contract-openapi.md](references/api-contract-openapi.md) | OpenAPI/AJV schema validation, contract tests |
| [api-contract-zod-advanced.md](references/api-contract-zod-advanced.md) | Zod validation, response shape testing, breaking change detection |
| [api-test-ci-pipelines.md](references/api-test-ci-pipelines.md) | CI pipeline strategy, GitHub Actions, parallel execution |
| [api-test-ci-environments.md](references/api-test-ci-environments.md) | Environment config, test reporting, database services, E2E environments |
| [anti-rationalization.md](references/anti-rationalization.md) | Iron Law, common rationalizations, red flag STOP list for TDD discipline |
