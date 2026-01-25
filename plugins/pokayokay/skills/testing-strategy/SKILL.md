---
name: testing-strategy
description: Decide what tests to write and when. Choose between unit, integration, and E2E tests, determine coverage targets, and avoid testing anti-patterns. Use when planning test coverage or evaluating test quality.
---

# Testing Strategy

Workflow for deciding what tests to write and when. Use when planning test coverage, choosing between test types, or evaluating test quality.

## Five-Step Decision Process

### 1. Classify the Code → Choose Test Type

- **Pure function/utility** → Unit (`formatCurrency()`, validation)
- **UI component** → Component (React/Vue rendering + interactions)
- **Multi-module interaction** → Integration (service + DB + cache)
- **Cross-page user flow** → E2E (login → dashboard → checkout)

### 2. Apply Test Pyramid (65% Unit / 25% Integration / 10% E2E)

- Too many E2E → Slow suite, expensive maintenance
- Too many units → Missing integration issues
- No E2E → Critical paths not validated

### 3. Set Coverage Targets

- **Business logic:** 85-95% (skip framework internals, libraries)
- **Data layer:** 80-90% (skip pass-through functions, getters)
- **UI components:** 70-80% (skip type definitions, constants)
- **E2E flows:** Critical paths only (auth, checkout, core conversions)

### 4. Mock External Boundaries Only

Mock network, DB, file system, timers. Don't mock core logic. Rule: Mocking everything = testing nothing.

### 5. Validate Test Quality

- [ ] Tests behavior, not implementation
- [ ] Each test is independent
- [ ] No arbitrary waits (use `waitFor()`)
- [ ] Descriptive names (what/when, not how)

## Good vs Poor Examples

**Login Form**
- Poor: Unit test every method, E2E every validation → Slow, brittle
- Good: Component for behavior, integration for API, 1 E2E → Efficient

**Order Processing**
- Poor: Mock everything (inventory, payment, shipping) → Tests nothing
- Good: Unit test logic, integration with real DB + mocked payment → Real behavior

## Common Scenarios

- **API endpoint** → Unit (logic) + Integration (handler → DB)
- **UI component** → Component test + visual states
- **User flow** → Component tests + 1 E2E for critical path
- **Bug fix** → Reproduce with test, then fix (TDD)
- **Legacy code** → E2E safety net first, add units during refactor

## Anti-Patterns

| Problem | Fix |
|---------|-----|
| Testing implementation details | Test behavior, not internals |
| Test interdependence | Each test independent |
| Snapshot abuse | Snapshot specific outputs only |
| Mocking too much | Mock boundaries only |
| Arbitrary waits | Use `waitFor()`, `findBy*()` |

---

**References:** [test-architecture.md](references/test-architecture.md) • [frontend-testing.md](references/frontend-testing.md) • [e2e-testing.md](references/e2e-testing.md) • [test-design.md](references/test-design.md) • [mocking-strategies.md](references/mocking-strategies.md) • [coverage-guide.md](references/coverage-guide.md)
