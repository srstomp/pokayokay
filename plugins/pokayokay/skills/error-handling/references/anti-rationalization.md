# Anti-Rationalization: Error Handling Discipline

## Iron Law

**EVERY ERROR PATH MUST BE EXPLICITLY HANDLED — SILENT FAILURES ARE BUGS.**

If code can fail, handle the failure. No exceptions. No excuses.

---

## Why This Works

Authority + commitment language doubles LLM compliance on discipline tasks (33% to 72%). Pre-rebutting common excuses prevents rationalization before it starts.

---

## Common Rationalizations

| Rationalization | Reality |
|----------------|---------|
| "It won't fail in production" | It will. Murphy's law. Handle it NOW. |
| "The caller handles it" | Verify. Don't assume. Read the caller's code. If they don't handle it, nobody does. |
| "Logging is enough" | Users need actionable errors, not log lines. Logs are for debugging. Error handling is for users. |
| "This error can't actually happen" | It can. Edge cases, network failures, disk full, race conditions. Handle it. |
| "The try/catch at the top catches everything" | Catch-all handlers lose context. Handle errors where you have the context to provide meaningful recovery. |
| "I'll add error handling in a follow-up" | You won't. Error handling added after the fact misses edge cases. Handle errors during implementation. |
| "The library throws, so we don't need to" | Library errors are generic. Your users need domain-specific error messages and recovery paths. |
| "It's an internal function, callers know the contract" | Internal contracts break. New developers don't know them. Make errors explicit. |
| "Returning null/undefined is fine here" | Null propagation causes crashes far from the source. Return a Result type or throw a typed error. |
| "The validation layer catches bad input" | Validation catches known-bad input. Error handling catches unexpected failures AFTER validation. |
| "We can just restart the service" | Restarts lose in-flight work, frustrate users, and mask the real problem. Handle the error properly. |
| "This only fails during development" | If it fails during development, it fails in production. The difference is you won't be watching. |

---

## Red Flags — STOP

When you detect ANY of these patterns in code or reasoning, STOP IMMEDIATELY.

### Code Patterns That Must Be Fixed

1. **`catch (e) {}`** — Empty catch block. STOP. Handle the error or re-throw with context.
2. **`catch (e) { console.log(e) }`** — Log-and-swallow. STOP. Log AND re-throw, or return an error result.
3. **`// TODO: handle error`** — Deferred handling. STOP. Handle it NOW. There is no later.
4. **`catch (e) { return null }`** — Error-to-null conversion. STOP. The caller won't know something failed.
5. **`catch (e) { return false }`** — Error-to-boolean conversion. STOP. Callers need error details, not a boolean.
6. **`.catch(() => {})`** — Swallowed promise rejection. STOP. Unhandled rejections crash Node.js processes.
7. **`try { ... } catch { ... }` without error parameter** — Discarded error info. STOP. You need the error for debugging.
8. **`if (result) { ... }` with no else** — Missing error branch. STOP. What happens when result is falsy?
9. **`async function` without try/catch or .catch** — Unhandled async error. STOP. Async errors vanish silently without handling.
10. **Generic `Error("Something went wrong")`** — Useless error message. STOP. Include what failed, why, and what to do about it.

### Reasoning Phrases That Must Halt Implementation

1. **"We can handle this error later"** — STOP. Handle it now.
2. **"This path is unreachable"** — STOP. Prove it with an assertion. If it IS reached, you'll know immediately.
3. **"The error message doesn't matter"** — STOP. Error messages are the first thing users and debuggers see.
4. **"Just wrap it in a try/catch"** — STOP. Catch SPECIFIC errors. Generic catches hide bugs.

### What To Do When You STOP

1. Identify the specific failure mode
2. Determine the appropriate response: retry, fallback, propagate, or fail with context
3. Write a typed error with actionable message (what failed, why, how to fix)
4. Handle the error at the right level (where you have context to do something useful)
5. Add a test that triggers the error path and verifies the handling

---

## Verification Checklist

Before reporting a task as complete, verify ALL of these:

- [ ] Every `try` block has a meaningful `catch` — no empty catches
- [ ] Every async operation has error handling (try/catch or .catch)
- [ ] Error messages include: what failed, why, and recovery guidance
- [ ] No `console.log(error)` without re-throwing or returning an error result
- [ ] No `// TODO: handle error` comments — all errors handled now
- [ ] Error paths have tests that trigger and verify them
- [ ] Custom error classes used for domain errors (not generic Error)
- [ ] HTTP endpoints return consistent error response shapes
- [ ] No null/undefined returns where an error should be thrown or Result returned
- [ ] Error boundaries in place for React components (if applicable)
