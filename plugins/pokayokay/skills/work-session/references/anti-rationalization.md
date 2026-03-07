# Anti-Rationalization: Testing Discipline

## Iron Law

**NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST.**

This is non-negotiable. Write the test. Watch it fail. Then implement. Every time.

---

## Why This Works

Authority + commitment language doubles LLM compliance on discipline tasks (33% to 72%). Pre-rebutting common excuses prevents rationalization before it starts.

---

## Common Rationalizations

| Rationalization | Reality |
|----------------|---------|
| "Too simple to test" | Simple code breaks. The test takes 30 seconds to write. Write it. |
| "I'll add tests after" | You won't. And tests written after prove nothing — they're written to pass, not to catch bugs. |
| "The framework handles it" | Framework bugs exist. Framework behavior changes between versions. Test YOUR logic. |
| "The test would just duplicate the implementation" | Then your test is wrong. Test behavior and outcomes, not implementation details. |
| "This is just a refactor, existing tests cover it" | Run them. If they pass, great. If not, you just proved why tests matter. |
| "It's a one-line change" | One-line changes cause production outages. The smaller the change, the faster the test. |
| "We're under time pressure" | Skipping tests creates MORE time pressure later. Bugs found in production cost 10x more. |
| "This is throwaway/prototype code" | There is no throwaway code. Today's prototype is tomorrow's production system. |
| "The type system catches this" | Types catch type errors. They don't catch logic errors, race conditions, or edge cases. |
| "I tested it manually" | Manual testing is not repeatable, not documented, and not run in CI. Write the automated test. |
| "This is just configuration" | Configuration errors cause outages. Test that your config produces the expected behavior. |
| "The integration test covers this" | Integration tests are slow and broad. Unit tests are fast and precise. You need both. |

---

## Red Flags — STOP

When you detect ANY of these phrases in your reasoning, STOP IMMEDIATELY. You are rationalizing.

### Phrases That Must Halt Implementation

1. **"I'll add tests later"** — STOP. Write the test NOW.
2. **"This doesn't need a test"** — STOP. Everything needs a test. Find the behavior to verify.
3. **"The test would just duplicate the implementation"** — STOP. Rewrite the test to check outcomes, not internals.
4. **"Too simple to test"** — STOP. Simple = fast to test. Do it.
5. **"Tests are passing so I'll skip writing new ones"** — STOP. Existing tests don't cover new code.
6. **"Let me implement first, then test"** — STOP. That's not TDD. Reverse the order.
7. **"The existing test suite is sufficient"** — STOP. Verify this claim. Check coverage of YOUR changes.
8. **"This is just glue code"** — STOP. Glue code has the most integration bugs. Test it.
9. **"I'll test the happy path only"** — STOP. Error paths cause production incidents. Test them.
10. **"Testing this would require too much setup"** — STOP. Complex setup = design smell. Simplify the interface, then test.
11. **"It works on my machine"** — STOP. Write the test that proves it works everywhere.
12. **"The PR reviewer will catch any issues"** — STOP. Reviewers catch style issues. Tests catch bugs.

### What To Do When You STOP

1. Write a failing test for the behavior you're about to implement
2. Run the test — confirm it fails for the right reason
3. Implement the minimum code to make it pass
4. Refactor if needed (tests still pass)
5. Move to the next behavior

---

## Verification Checklist

Before reporting a task as complete, verify ALL of these:

- [ ] Every new function/method has at least one test
- [ ] Tests were written BEFORE implementation (TDD)
- [ ] Tests cover both happy path AND error paths
- [ ] Tests verify behavior, not implementation details
- [ ] Tests are independent — no shared mutable state between tests
- [ ] Test names describe the expected behavior
- [ ] No `skip`, `todo`, or `pending` test markers added
- [ ] Coverage of changed files is at or above project threshold
