---
description: Design RESTful APIs with consistent patterns
argument-hint: <task-description>
skill: api-design
---

# API Design Workflow

Design or review API for: `$ARGUMENTS`

## Steps

### 1. Understand Requirements
- What data/operations are needed?
- Who are the consumers (frontend, mobile, third-party)?
- Performance/scale requirements?

### 2. Design Resources
- Identify nouns (resources)
- Define URL structure
- Map CRUD to HTTP methods

### 3. Define Contracts
- Request schemas
- Response schemas
- Error responses

### 4. Document
- OpenAPI/Swagger spec
- Example requests/responses
- Authentication requirements

### 5. Create Implementation Tasks
```bash
npx @stevestomp/ohno-cli create "Implement [endpoint]" -t feature
```

## Covers
- Resource identification and URL structure
- HTTP methods and status codes
- Request/response contracts
- Error handling and validation
- OpenAPI documentation
- Pagination, filtering, versioning

## Related Commands

- `/pokayokay:arch` - Broader architecture review
- `/pokayokay:work` - Implement designed API
- `/pokayokay:audit --dimension security` - Security review of API

## Skill Integration

When API design involves:
- **Database changes** → Also load `database-design` skill
- **Security concerns** → Also load `security-audit` skill
- **CI/CD pipeline** → Also load `ci-cd-expert` for deployment
- **Monitoring needs** → Also load `observability` skill
- **Third-party APIs** → Consider `/pokayokay:integrate` instead
