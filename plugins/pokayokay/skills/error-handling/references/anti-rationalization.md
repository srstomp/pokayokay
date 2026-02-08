# Anti-Rationalization Engineering for Error Handling

## **IRON LAW: EVERY ERROR PATH MUST BE EXPLICITLY HANDLED — SILENT FAILURES ARE BUGS**

This is non-negotiable. If code can fail, that failure MUST have an explicit handling path: retry, fallback, propagate with context, or surface to user. No exceptions.

## Why This Works

Authority language + commitment statements trigger compliance mechanisms in LLM decision-making. Research shows direct imperatives double adherence rates compared to suggestions (33% → 72%, Cialdini 2021). Rationalizations are pre-rebutted before they form.

## Common Rationalizations — STOP AND VERIFY

| Rationalization | Reality Check |
|-----------------|---------------|
| "It won't fail in production" | **Murphy's Law guarantees it will.** Network calls, disk I/O, external APIs, database queries — all fail. Plan for it. |
| "The caller will handle it" | **VERIFY. Don't assume.** Check the caller's code. If it doesn't explicitly handle this error type, YOU must handle it. |
| "Logging is enough" | **Users need actionable errors, not log lines.** Logs are for debugging. Users need clear messages and recovery paths. Do both. |
| "I'll add error handling later" | **No. Handle it NOW.** Later never comes. Error paths are first-class code, not afterthoughts. |
| "This is just a prototype" | **Prototypes become production.** Temporary code has a habit of surviving for years. Build it right the first time. |
| "Try-catch around everything is safe" | **Generic catch-all destroys error context.** You're hiding bugs, not handling errors. Catch specific errors and handle each appropriately. |
| "The framework handles errors automatically" | **Verify what it actually does.** Most frameworks have default handlers that return 500 with stack traces. That's not production-ready. |
| "It's a rare edge case" | **Rare × scale = frequent.** At 10M requests/day, 0.01% failure rate = 1,000 errors daily. Handle edge cases. |
| "I don't know what error to throw" | **Figure it out.** Read the failure modes. Design error types for your domain. If you're unsure, create a ValidationError or OperationFailedError with context. |
| "Error handling makes the code ugly" | **Unhandled errors make production ugly.** Use Result types, early returns, or extract to functions. Readable error handling is possible and required. |
| "The database driver already retries" | **Verify the retry behavior.** Most drivers retry connection errors, not query errors. Deadlocks, constraint violations, timeouts often don't auto-retry. Check the docs. |
| "Just return null on error" | **Null tells you nothing.** Was it not found? Permission denied? Network timeout? Return a Result type or throw a specific error. Make failures informative. |

## Red Flags — STOP LIST

When you see these patterns, STOP immediately and fix before proceeding:

### STOP: Catch and Ignore
```javascript
try {
  await riskyOperation();
} catch (error) {
  // Empty catch block
}
```
**Fix:** Handle the error or propagate it with context. Silent failures are undebuggable.

### STOP: TODO Comments on Error Handling
```javascript
catch (error) {
  // TODO: handle this properly
  console.log(error);
}
```
**Fix:** Handle it NOW. No TODOs on error paths. This code may ship.

### STOP: Console.log Without Action
```javascript
catch (error) {
  console.log(error);
  // No throw, no retry, no user message
}
```
**Fix:** Logging alone is NOT error handling. Log AND take action: retry, fallback, or surface to user.

### STOP: Generic Error Messages
```javascript
throw new Error("Something went wrong");
```
**Fix:** Be specific. What went wrong? Include context: `new ValidationError("Email format invalid", { field: "email", value })`

### STOP: Swallowing Type Information
```javascript
catch (error) {
  throw new Error(error.message); // Lost stack trace and error type
}
```
**Fix:** Preserve the cause chain: `throw new AppError("Operation failed", "OP_ERROR", {}, error)`

### STOP: Naked Promises
```javascript
fetchData().then(process); // Unhandled rejection
```
**Fix:** Always add `.catch()` or use `await` in try-catch. Unhandled rejections crash Node.js.

### STOP: Error Leak to User
```javascript
res.status(500).json({ error: error.stack });
```
**Fix:** Never expose stack traces, file paths, or internal errors to users. Return structured error codes and user-friendly messages.

### STOP: No Recovery Guidance
```json
{ "error": "Payment failed" }
```
**Fix:** Tell users what to do next: `{ "error": "Payment failed: insufficient funds", "action": "Add funds or use a different card" }`

### STOP: Retry Without Backoff
```javascript
for (let i = 0; i < 3; i++) {
  try { return await fetch(url); }
  catch { /* immediate retry */ }
}
```
**Fix:** Add exponential backoff: `await sleep(2 ** i * 100)`. Immediate retries hammer failing services.

### STOP: Catching Without Specificity
```javascript
catch (error) {
  return fallback(); // Wrong for auth errors, timeouts, validation, etc
}
```
**Fix:** Match error types to recovery strategies. ValidationError → return 400. TimeoutError → retry. AuthError → return 401. Don't conflate.

## Implementation Checklist

Before marking error handling complete, verify EVERY item:

- [ ] All async operations have explicit error handlers
- [ ] Error types are specific (ValidationError, NotFoundError, etc), not generic Error
- [ ] User-facing errors have clear messages and recovery guidance
- [ ] Internal errors are logged with context (request ID, user ID, operation)
- [ ] Network calls have retry logic with exponential backoff
- [ ] Database operations handle constraint violations, deadlocks, timeouts
- [ ] API endpoints return consistent error shape: `{ error: { code, message, requestId } }`
- [ ] Error boundaries exist at React app, route, and critical component levels
- [ ] Error tracking (Sentry) is configured and scrubs sensitive data
- [ ] Stack traces and internal details are NEVER exposed to end users
- [ ] No catch blocks are empty or only contain console.log
- [ ] No TODO comments exist on error handling paths
- [ ] Result types are used for expected failures (validation, not found)
- [ ] Throws are reserved for unexpected failures (system errors, programmer errors)

## Non-Compliance Consequences

Skipping error handling creates:
- **Production incidents**: Silent failures cascade into data corruption
- **Poor user experience**: Cryptic errors with no recovery path
- **Debugging hell**: No context when things break
- **Security vulnerabilities**: Stack traces leak implementation details
- **Lost revenue**: Failed operations with no retry = lost transactions

Handle errors explicitly. Every single time.
