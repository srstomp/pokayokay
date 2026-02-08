# Review Checklist: Error Handling

## Error Classes

- [ ] Custom AppError base class with code, message, and context
- [ ] Domain-specific subclasses (ValidationError, NotFoundError, AuthError)
- [ ] Error codes are documented and consistent
- [ ] No generic `throw new Error('...')` for domain errors

## Error Handling

- [ ] Every try block has a meaningful catch (no empty catches)
- [ ] Caught errors are re-thrown or returned as Result (never swallowed)
- [ ] Async operations have explicit error handling (.catch or try/catch)
- [ ] Errors caught at the right level (where context is available)

## Error Messages

- [ ] Messages explain what failed and why
- [ ] Messages include recovery guidance for the user
- [ ] No stack traces, internal paths, or sensitive data in user-facing messages
- [ ] Error messages are actionable (not just "something went wrong")

## API Error Responses

- [ ] Consistent error response shape across all endpoints
- [ ] HTTP status codes match error semantics (400 vs 401 vs 403 vs 404 vs 500)
- [ ] Validation errors include field-level details
- [ ] Error responses include correlation/request ID for debugging

## Recovery Patterns

- [ ] Network calls have retry logic with exponential backoff
- [ ] Circuit breaker for unreliable downstream services
- [ ] Graceful degradation where possible (cache fallback, default values)
- [ ] Timeout configured for all external calls

## Error Tracking

- [ ] Errors reported to tracking service (Sentry or equivalent)
- [ ] Sensitive data scrubbed before reporting
- [ ] Error grouping configured (by error type, not message)
- [ ] Alert thresholds set for critical error rates
