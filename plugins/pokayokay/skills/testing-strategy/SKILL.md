---
name: testing-strategy
agents: [yokay-test-runner]
description: Use when designing test architecture, setting up coverage thresholds, or organizing test files for a project. Dispatches yokay-test-runner for test execution.
---

# Testing Strategy

Test architecture decisions and coverage strategy for project setup.

## Test Pyramid

| Level | Speed | Cost | Confidence | Share |
|-------|-------|------|------------|-------|
| **Unit** | ~1ms | Low | Narrow | 65-80% |
| **Integration** | ~100ms | Medium | Medium | 15-25% |
| **Contract** | ~10ms | Low | API shape | Part of unit |
| **E2E** | ~1s+ | High | Broad | 5-10% |

## Key Principles

- Test behavior, not implementation
- Follow the testing pyramid
- Use meaningful coverage metrics — branch coverage over line coverage
- Prevent flaky tests — no arbitrary waits, no test interdependence

## When NOT to Use

- For TDD discipline during implementation — see work-session anti-rationalization reference
- For security testing — see security-audit skill
- For performance testing — see performance-optimization skill

## References

| Reference | Description |
|-----------|-------------|
| [coverage-guide.md](references/coverage-guide.md) | Coverage targets by code type and project type |
