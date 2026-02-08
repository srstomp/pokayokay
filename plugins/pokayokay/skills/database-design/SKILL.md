---
name: database-design
description: Use when designing database schemas, reviewing data models, planning migrations, optimizing slow queries, or establishing database patterns. Covers relational (PostgreSQL, MySQL, SQLite), document (MongoDB), and ORM-integrated (Prisma, Drizzle, TypeORM) projects.
---

# Database Design

Design efficient, maintainable database schemas with safe migration strategies.

## Key Principles

- Start from requirements: identify entities, attributes, and relationships first
- Normalize for data integrity, denormalize selectively for read performance
- Design indexes based on actual query patterns, not guesses
- Migrations must be reversible and safe for zero-downtime deployments
- Choose the right ORM — Prisma for type safety, Drizzle for SQL-close, TypeORM for enterprise

## Quick Start Checklist

1. Identify entities and relationships from requirements
2. Design normalized schema (3NF minimum)
3. Add indexes for known query patterns
4. Plan migration strategy (up + down)
5. Choose ORM/query builder based on project needs
6. Set up seed data for development

## References

| Reference | Description |
|-----------|-------------|
| [schema-patterns.md](references/schema-patterns.md) | Normalization, relationships, naming conventions |
| [index-design.md](references/index-design.md) | Index types, composite indexes, partial indexes |
| [migration-strategies.md](references/migration-strategies.md) | Safe migrations, zero-downtime, rollback |
| [query-optimization.md](references/query-optimization.md) | EXPLAIN, N+1 queries, join strategies |
| [postgresql.md](references/postgresql.md) | PostgreSQL-specific features and patterns |
| [prisma-patterns.md](references/prisma-patterns.md) | Prisma schema, relations, transactions |
| [tdd-patterns.md](references/tdd-patterns.md) | Test-first patterns for migrations, constraints, factories |
| [review-checklist.md](references/review-checklist.md) | Database design review checklist (schema, indexes, integrity) |
