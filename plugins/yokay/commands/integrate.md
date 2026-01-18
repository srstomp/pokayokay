---
description: Integrate with external APIs
argument-hint: <api-to-integrate>
skill: api-integration
---

# API Integration Workflow

Integrate with: `$ARGUMENTS`

## Steps

### 1. Gather API Information
From `$ARGUMENTS`, identify:
- API documentation URL
- Authentication method (API key, OAuth, etc.)
- Rate limits
- Available endpoints

### 2. Analyze Integration Requirements
- Which endpoints do we need?
- What data transformations required?
- Error handling requirements
- Caching strategy

### 3. Design Integration

**Client Architecture:**
```typescript
// api/[service]/client.ts
export class ServiceClient {
  constructor(config: ServiceConfig) {}

  // Typed methods for each endpoint
  async getResource(id: string): Promise<Resource> {}
  async createResource(data: CreateData): Promise<Resource> {}
}
```

**Key Components:**
- Typed client wrapper
- Request/response interceptors
- Error handling with retries
- Rate limit handling
- Response caching (if appropriate)

### 4. Handle Authentication

**API Key:**
```typescript
headers: {
  'Authorization': `Bearer ${process.env.SERVICE_API_KEY}`
}
```

**OAuth 2.0:**
- Token storage
- Refresh token flow
- Token expiration handling

### 5. Implement Error Handling
```typescript
class ServiceError extends Error {
  constructor(
    message: string,
    public code: string,
    public status: number
  ) {
    super(message);
  }
}
```

### 6. Add Observability
- Log all external API calls
- Track latency metrics
- Alert on error rates

### 7. Create Implementation Tasks
```bash
npx @stevestomp/ohno-cli create "Integration: [service] [endpoint]" -t feature
```

## Covers
- API client design
- Authentication patterns
- Error handling
- Rate limit management
- Response caching
- Type safety
- Testing strategies

## Related Commands

- `/yokay:api` - Design internal API for integration
- `/yokay:test` - Test integration
- `/yokay:security` - Review API security
- `/yokay:observe` - Monitor integration
- `/yokay:work` - Implement integration

## Skill Integration

When integration work involves:
- **API design** → Also load `api-design` skill
- **Security review** → Also load `security-audit` skill
- **Monitoring** → Also load `observability` skill
- **Testing** → Also load `testing-strategy` skill
