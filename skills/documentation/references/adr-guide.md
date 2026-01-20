# Architecture Decision Records (ADR) Guide

Document significant architectural decisions for future reference.

## What is an ADR?

An Architecture Decision Record captures:
- **Context** — The situation and constraints
- **Decision** — What was chosen
- **Consequences** — The outcomes and tradeoffs

ADRs create a decision log that helps future team members understand why the system is built the way it is.

## When to Write an ADR

### Write an ADR When

- Choosing between significant alternatives (databases, frameworks, patterns)
- Making decisions that would be expensive to reverse
- Establishing patterns or conventions the team should follow
- Deciding NOT to do something (important to document why)
- Future developers will ask "why did we do this?"

### Skip ADR When

- Decision is easily reversible
- Standard/obvious choice for the situation
- Already documented elsewhere (RFC, design doc)
- Personal preference with no significant impact

## ADR Format

### Standard Format

```markdown
# ADR-NNN: Title

## Status

Proposed | Accepted | Deprecated | Superseded by ADR-XXX

## Date

YYYY-MM-DD

## Context

What is the issue that we're seeing that is motivating this decision?
What are the forces at play (technical, political, social)?
What constraints exist?

## Decision

What is the change that we're proposing and/or doing?
State the decision in full sentences, with active voice.

## Consequences

What becomes easier or harder because of this decision?

### Positive
- Benefit 1
- Benefit 2

### Negative
- Tradeoff 1
- Tradeoff 2

### Neutral
- Side effect that's neither good nor bad

## Alternatives Considered

### Alternative 1: Name
Description and why it was rejected.

### Alternative 2: Name
Description and why it was rejected.
```

### Lightweight Format

For smaller decisions:

```markdown
# ADR-NNN: Title

**Status**: Accepted | **Date**: YYYY-MM-DD

## Context
Brief description of the problem.

## Decision
What we decided.

## Consequences
Key outcomes.
```

## ADR Examples

### Example: Database Selection

```markdown
# ADR-001: Use PostgreSQL for Primary Database

## Status
Accepted

## Date
2024-01-15

## Context

We need a database for our new order management system. Requirements:
- Handle 10K orders/day with growth to 100K
- Complex queries across orders, customers, inventory
- Strong consistency for financial data
- Team familiar with SQL

Options considered: PostgreSQL, MySQL, MongoDB, DynamoDB.

## Decision

Use PostgreSQL as the primary database.

## Consequences

### Positive
- ACID compliance for financial integrity
- Rich query capabilities for reporting
- Mature ecosystem, extensive documentation
- Team expertise exists

### Negative
- Vertical scaling limitations
- Manual sharding if we exceed single-node capacity
- Requires DBA expertise for optimization

### Neutral
- Will need connection pooling (PgBouncer)
- Regular maintenance (vacuum, reindex) required

## Alternatives Considered

### MySQL
Similar capabilities but PostgreSQL has better JSON support and
more advanced features we anticipate needing.

### MongoDB
Good for document storage but we need strong relational queries
and ACID transactions across collections.

### DynamoDB
Excellent scale but query patterns too restrictive for our
complex reporting needs. Higher ongoing costs.
```

### Example: API Strategy

```markdown
# ADR-002: REST over GraphQL for Public API

## Status
Accepted

## Date
2024-01-20

## Context

Building a public API for third-party integrations.

Considerations:
- Partners have varying technical sophistication
- Need extensive documentation and examples
- Must support caching for performance
- Team has REST experience, limited GraphQL

## Decision

Implement a REST API following OpenAPI 3.0 specification.

## Consequences

### Positive
- Lower learning curve for partners
- HTTP caching works out of the box
- Extensive tooling for docs, SDKs, testing
- Team can ship faster with existing expertise

### Negative
- Over-fetching/under-fetching in some use cases
- Multiple roundtrips for complex data requirements
- API versioning overhead

### Neutral
- GraphQL could be added later for specific use cases
```

### Example: Deprecation Decision

```markdown
# ADR-003: Deprecate Custom Auth in Favor of Auth0

## Status
Accepted

## Date
2024-02-01

## Context

Our custom authentication system has accumulated technical debt:
- 3 CVEs patched in last year
- Password reset flow is unreliable
- No MFA support
- Significant maintenance burden (20% of security team time)

## Decision

Migrate to Auth0 for all authentication.

Deprecation timeline:
- 2024-03: Auth0 available for new signups
- 2024-06: Existing users migrated
- 2024-09: Custom auth decommissioned

## Consequences

### Positive
- Reduced security risk
- MFA, SSO, passwordless available
- Frees security team for other work
- Better compliance posture

### Negative
- Vendor dependency and cost ($X/month at current scale)
- Migration effort estimated at 6 weeks
- Some custom flows need redesign

## Migration Plan

See [AUTH-MIGRATION.md](../docs/AUTH-MIGRATION.md) for details.
```

## ADR Lifecycle

### Status Transitions

```
Proposed → Accepted → [Deprecated | Superseded]
    ↓
  Rejected
```

### Superseding Decisions

When a new decision replaces an old one:

```markdown
# ADR-010: Use Prisma Instead of TypeORM

## Status
Accepted (supersedes ADR-003)

## Context
ADR-003 established TypeORM as our ORM. After 2 years of use,
we've encountered significant pain points...
```

Update the original ADR:

```markdown
# ADR-003: Use TypeORM for Database Access

## Status
Superseded by ADR-010
```

## ADR Organization

### Directory Structure

```
docs/
└── adr/
    ├── README.md           # Index of all ADRs
    ├── 0001-use-postgresql.md
    ├── 0002-rest-api.md
    ├── 0003-auth0-migration.md
    └── template.md         # Template for new ADRs
```

### Index File (README.md)

```markdown
# Architecture Decision Records

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [001](0001-use-postgresql.md) | Use PostgreSQL | Accepted | 2024-01-15 |
| [002](0002-rest-api.md) | REST API Strategy | Accepted | 2024-01-20 |
| [003](0003-auth0-migration.md) | Migrate to Auth0 | Accepted | 2024-02-01 |

## By Status

### Accepted
- ADR-001, ADR-002, ADR-003

### Proposed
- None

### Deprecated/Superseded
- None
```

### Numbering Convention

- Zero-padded for sorting: `0001`, `0042`, `0123`
- Never reuse numbers
- Gaps are okay (deleted/rejected ADRs)

## ADR Workflow

### 1. Propose

Create ADR in `Proposed` status. Share with team for feedback.

### 2. Discuss

Review in PR, architecture meeting, or async discussion.
Update based on feedback.

### 3. Decide

Update status to `Accepted` or `Rejected`.
If rejected, document why (valuable for future reference).

### 4. Implement

Reference ADR in implementation PRs:
```
Implements ADR-003: Auth0 Migration
```

### 5. Review

Periodically review ADRs:
- Are accepted decisions still valid?
- Should any be deprecated?
- Missing decisions that should be documented?

## Writing Tips

### Context Section

- State facts, not opinions
- Include constraints explicitly
- Mention relevant stakeholders
- Reference related documents

### Decision Section

- Use active voice ("We will use..." not "It was decided...")
- Be specific and unambiguous
- Include scope (what this applies to)

### Consequences Section

- Be honest about tradeoffs
- Don't hide negative consequences
- Include operational impact
- Consider future implications

### Keep It Focused

- One decision per ADR
- Avoid bundling related decisions
- Link to related ADRs instead

## Anti-Patterns

### ❌ Too Vague

```markdown
## Decision
We'll use a modern database solution.
```

### ✅ Specific

```markdown
## Decision
Use PostgreSQL 15 hosted on AWS RDS with Multi-AZ deployment.
```

### ❌ Missing Context

```markdown
## Decision
Use microservices architecture.

## Consequences
More flexibility.
```

### ✅ Full Context

```markdown
## Context
Our monolith deployment takes 45 minutes and requires full team
coordination. Teams are blocked waiting for each other. We need
independent deployability for the 4 product teams.

## Decision
Extract order-processing into a separate service as a pilot.

## Consequences
### Positive
- Order team can deploy independently
- Reduces deployment time to 10 minutes for that service

### Negative
- Added operational complexity (service discovery, distributed tracing)
- Need to handle network failures between services
```
