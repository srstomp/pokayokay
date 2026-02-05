---
name: api-design
description: Design RESTful APIs with consistent patterns, clear conventions, and comprehensive documentation. Covers endpoint design, HTTP methods, status codes, request/response formats, pagination, filtering, versioning, authentication, and OpenAPI specifications. Use this skill when designing new APIs, reviewing API designs, or establishing API standards for a project or organization.
---

# API Design

Design clear, consistent, and developer-friendly REST APIs.

## Core Principles

- **Resource-oriented** — Design around nouns (resources), not verbs (actions)
- **Predictable patterns** — Consistent URL structure, response format, and behavior
- **Clear contracts** — Explicit schemas, documented errors, versioned endpoints
- **Developer experience** — Meaningful errors, helpful examples, logical defaults

## Quick Start Checklist

1. Identify resources and their relationships
2. Define CRUD operations + custom actions with correct HTTP methods
3. Design request/response schemas with consistent envelope
4. Plan error format with status codes, error codes, and field-level details
5. Write OpenAPI specification with examples
6. Review for consistency, security, and usability

## Design Quick Reference

| Method | Purpose | Idempotent | Body |
|--------|---------|------------|------|
| GET | Read | Yes | No |
| POST | Create | No | Yes |
| PUT | Replace | Yes | Yes |
| PATCH | Partial update | Yes* | Yes |
| DELETE | Remove | Yes | No |

## References

| Reference | Description |
|-----------|-------------|
| [endpoints.md](references/endpoints.md) | URL design, HTTP methods, resource modeling |
| [requests-responses.md](references/requests-responses.md) | Request/response formats, headers, content types |
| [status-codes.md](references/status-codes.md) | HTTP status codes, error handling patterns |
| [pagination-filtering.md](references/pagination-filtering.md) | Pagination, filtering, sorting, searching |
| [versioning.md](references/versioning.md) | API versioning strategies |
| [openapi.md](references/openapi.md) | OpenAPI specification, documentation |
| [security.md](references/security.md) | Authentication, authorization, rate limiting |
