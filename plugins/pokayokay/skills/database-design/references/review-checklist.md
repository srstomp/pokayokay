# Review Checklist: Database Design

## Schema Design

- [ ] Appropriate data types for each column (don't use VARCHAR for everything)
- [ ] Primary keys defined (prefer UUID over auto-increment for distributed systems)
- [ ] NOT NULL constraints on required fields
- [ ] DEFAULT values where appropriate
- [ ] Column naming consistent (snake_case, no abbreviations)

## Migrations

- [ ] Migration is reversible (down migration defined and tested)
- [ ] No data loss on rollback (or explicitly documented as destructive)
- [ ] Large table alterations use batched approach (avoid locking)
- [ ] Migration tested with realistic data volume

## Indexes

- [ ] Indexes on foreign key columns
- [ ] Indexes on columns used in WHERE clauses and ORDER BY
- [ ] Composite indexes ordered by selectivity (most selective first)
- [ ] No redundant indexes (subset of existing composite)
- [ ] EXPLAIN checked for critical queries

## Foreign Keys

- [ ] FK constraints defined for all relationships
- [ ] ON DELETE behavior specified (CASCADE, SET NULL, or RESTRICT)
- [ ] Circular references avoided
- [ ] Orphan prevention verified

## Query Patterns

- [ ] N+1 queries prevented (joins or eager loading)
- [ ] Pagination implemented for unbounded queries
- [ ] No SELECT * in production code (select specific columns)
- [ ] Transactions used for multi-table writes

## Data Integrity

- [ ] Unique constraints on business-unique fields (email, slug)
- [ ] Check constraints for value ranges/enums
- [ ] Timestamps (created_at, updated_at) on all tables
- [ ] Soft delete considered vs hard delete
