---
description: Design database schemas and migrations
argument-hint: <database-task>
skill: database-design
---

# Database Design Workflow

Design or review database for: `$ARGUMENTS`

## Steps

### 1. Identify Database Context
Detect from project:
- **ORM**: Prisma, Drizzle, TypeORM, Sequelize
- **Database**: PostgreSQL, MySQL, SQLite, MongoDB
- **Existing schema**: Check for migration files

### 2. Identify Task Type
From `$ARGUMENTS`, determine the goal:
- **Schema design**: New tables, relationships, constraints
- **Migration**: Plan safe schema changes
- **Optimization**: Index design, query analysis
- **Review**: Audit for anti-patterns

### 3. Execute Task

**For Schema Design:**
- Identify entities and relationships
- Define constraints (PK, FK, unique, check)
- Plan indexes for query patterns
- Consider normalization level

**For Migrations:**
- Plan backward-compatible changes
- Design rollback strategy
- Handle data migrations
- Test on staging first

**For Optimization:**
- Analyze slow queries with EXPLAIN
- Recommend indexes
- Identify N+1 patterns
- Suggest denormalization if needed

### 4. Generate Artifacts
- Schema diagram (Mermaid ERD)
- Migration files (Prisma/Drizzle format)
- Index recommendations
- Query improvements

### 5. Create Implementation Tasks
```bash
npx @stevestomp/ohno-cli create "DB: [specific change]" -t feature
```

## Covers
- Entity relationship modeling
- Index strategy
- Migration planning
- Query optimization
- Constraint design
- Data integrity

## Related Commands

- `/pokayokay:api` - Design API for database entities
- `/pokayokay:work` - Implement schema changes
- `/pokayokay:test` - Database testing strategy

## Skill Integration

When database work involves:
- **API changes** → Also load `api-design` skill
- **Data security** → Also load `security-audit` skill
- **Query monitoring** → Also load `observability` skill
