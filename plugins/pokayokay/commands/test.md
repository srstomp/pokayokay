---
description: Design testing strategy or write tests
argument-hint: <testing-task> [--audit]
skill: testing-strategy
---

# Testing Strategy Workflow

Design or implement tests for: `$ARGUMENTS`

## Mode Detection

Parse `$ARGUMENTS` to determine mode:
- **`--audit` flag present** → Coverage audit mode (creates tasks for gaps)
- **No flag** → Design/implement mode (default behavior)

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

## Audit Mode (`--audit` flag)

When `--audit` is specified, switch to coverage gap analysis mode:

### Audit Steps

1. **Run Coverage Analysis**
```bash
# Example commands
npm run test -- --coverage
npx vitest --coverage
pytest --cov
```

2. **Identify Coverage Gaps**
Analyze coverage report to find:
- Untested critical paths (auth, payments, core business logic)
- Files/functions below coverage threshold
- Missing E2E tests for user flows
- Untested error handling paths

3. **Classify Gaps by Risk**

| Risk Level | Description | Priority |
|------------|-------------|----------|
| Critical | Auth, payments, data integrity | P1 |
| High | Core business logic, API endpoints | P2 |
| Medium | UI components, utilities | P3 |
| Low | Config, constants, types | Skip |

4. **Create Tasks for Gaps**

**Automatically create ohno tasks** using MCP tools for identified gaps:

```
create_task({
  title: "Test: [what needs testing]",
  description: "[Gap description]\n\nFiles: [file paths]\nCurrent coverage: [X]%\nTarget: [Y]%\nSuggested tests: [list]",
  task_type: "test",
  estimate_hours: [1-4 based on scope]
})
```

**Example task creation:**
- Untested auth middleware → `create_task("Test: Add unit tests for auth middleware", type: test)` P1
- Missing API tests → `create_task("Test: Add integration tests for /api/users endpoints", type: test)` P2
- No E2E for checkout → `create_task("Test: Add E2E test for checkout flow", type: test)` P1

5. **Report Summary**
```
Coverage Audit Results:
- Current coverage: [X]%
- Target coverage: [Y]%
- Gap: [Z]%

Created [N] test tasks:
- [task-id]: Test: [name] (P1/P2/P3)
- ...

Recommended priority: [first task to tackle]
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

- `/pokayokay:work` - Implement tests
- `/pokayokay:cicd` - Add tests to pipeline
- `/pokayokay:api` - API testing patterns

## Skill Integration

When testing involves:
- **API tests** → Also load `api-design` skill
- **Accessibility tests** → Also load `accessibility-auditor` skill
- **Security tests** → Also load `security-audit` skill
