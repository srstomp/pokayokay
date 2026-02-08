# Review Checklist: API Design

## Endpoint Design

- [ ] Consistent URL naming convention (plural nouns, kebab-case)
- [ ] Correct HTTP methods (GET=read, POST=create, PUT=replace, PATCH=update, DELETE=remove)
- [ ] Appropriate status codes for each response path
- [ ] Consistent error response format across all endpoints

## Request Validation

- [ ] All required fields validated
- [ ] Input types checked (string, number, email format)
- [ ] Array/string length limits enforced
- [ ] Dangerous characters sanitized (XSS, SQL injection prevention)

## Response Shape

- [ ] Consistent envelope format (data, meta, errors)
- [ ] Pagination for list endpoints (page, limit, total)
- [ ] No internal IDs or sensitive data leaked
- [ ] Dates in ISO 8601 format

## Authentication & Authorization

- [ ] Auth required on all non-public endpoints
- [ ] Rate limiting on auth endpoints (login, register, password reset)
- [ ] Role/permission checks on protected resources
- [ ] Token expiry and refresh handled

## Performance

- [ ] N+1 query prevention (eager loading, dataloaders)
- [ ] Response size bounded (pagination, field selection)
- [ ] Appropriate caching headers (ETag, Cache-Control)
- [ ] Slow endpoint monitoring (>500ms threshold)

## Documentation

- [ ] OpenAPI spec exists and matches implementation
- [ ] Request/response examples provided
- [ ] Error codes documented with resolution guidance
