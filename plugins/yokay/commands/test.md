---
description: Design testing strategy or write tests
argument-hint: <testing-task>
skill: testing-strategy
---

# Testing Strategy Workflow

Design or implement tests for: `$ARGUMENTS`

## Agent Delegation

When running tests (not designing strategy), **delegate test execution to the `yokay-test-runner` agent** for isolated output. This keeps verbose test output separate from the main conversation.

```
Use the yokay-test-runner agent to run the test suite.
Return only failures and summary to this conversation.
```

The agent will:
1. Detect test framework (Jest, Vitest, pytest, etc.)
2. Run test suite
3. Return only failures with context, not all passing tests

Use delegation for:
- Running full test suites
- Verifying fixes
- Pre-commit test runs

Run inline for:
- Writing new tests
- Debugging specific test failures
- Test strategy design

## Steps

### 1. Identify Test Context
Detect from project:
- **Framework**: React, Vue, Node, etc.
- **Test runner**: Vitest, Jest, Mocha
- **E2E tool**: Playwright, Cypress
- **Coverage**: Current coverage targets

### 2. Identify Task Type
From `$ARGUMENTS`, determine the goal:
- **Strategy**: Design test approach for feature/project
- **Unit tests**: Write isolated component/function tests
- **Integration tests**: Test component interactions
- **E2E tests**: Write end-to-end user flow tests
- **Debug**: Fix flaky or failing tests

### 3. Apply Test Pyramid
- **Many** unit tests (fast, isolated)
- **Some** integration tests (component interaction)
- **Few** E2E tests (critical user paths)

### 4. Execute Task

**For Strategy:**
- Recommend test types for the feature
- Define coverage targets
- Identify critical paths
- Plan test data strategy

**For Implementation:**
- Write tests following AAA pattern (Arrange, Act, Assert)
- Use appropriate mocking
- Ensure tests are deterministic
- Add to CI pipeline

**For Debugging:**
- Identify flakiness source
- Add proper waits/retries
- Isolate test dependencies
- Fix timing issues

### 5. Create Implementation Tasks
```bash
npx @stevestomp/ohno-cli create "Test: [specific tests]" -t chore
```

## Covers
- Test pyramid design
- Unit test patterns
- Integration testing
- E2E test design
- Mocking strategies
- Test data management
- Coverage analysis

## Related Commands

- `/yokay:work` - Implement tests
- `/yokay:cicd` - Add tests to pipeline
- `/yokay:api` - API testing patterns

## Skill Integration

When testing involves:
- **API tests** → Also load `api-design` skill
- **Accessibility tests** → Also load `accessibility-auditor` skill
- **Security tests** → Also load `security-audit` skill
