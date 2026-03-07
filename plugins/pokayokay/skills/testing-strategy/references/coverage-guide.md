# Coverage Guide

Focus on meaningful coverage, not just percentages. Coverage is a guide, not a goal.

## Recommended Targets

### By Code Type

| Code Type | Target | Rationale |
|-----------|--------|-----------|
| **Business logic** | 85-95% | Core value, high risk |
| **API handlers** | 80-90% | User-facing, error-prone |
| **UI components** | 70-80% | Visual states, interactions |
| **Utilities** | 90%+ | Widely used, pure functions |
| **Integration points** | 60-70% | Hard to unit test |
| **Config/Setup** | 0-30% | Often trivial |

### By Project Type

| Project Type | Line | Branch | Notes |
|--------------|------|--------|-------|
| **Library/SDK** | 90%+ | 85%+ | Public API surface critical |
| **API service** | 80%+ | 75%+ | Focus on handlers, validation |
| **Web app** | 70%+ | 65%+ | Balance UI and logic |
| **CLI tool** | 75%+ | 70%+ | Command paths important |
| **Internal tool** | 60%+ | 55%+ | Move fast, fix quick |

### Minimum Viable Coverage

For any project, ensure coverage of:

1. **Critical paths**: Auth, payments, data mutations = 100%
2. **Error handlers**: At least one test per error type
3. **Public API**: Every public function/endpoint
4. **Edge cases**: null, empty, boundary values

## Key Principles

- Branch coverage > line coverage (ensures conditionals are tested)
- Test behavior, not lines (coverage from assertions, not execution)
- Incrementally improve (start with critical code, expand over time)
- Mutation testing validates quality (high coverage with low mutation score = weak tests)
