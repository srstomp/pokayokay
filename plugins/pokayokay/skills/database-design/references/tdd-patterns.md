# TDD Patterns: Database Design

## Test-First Workflow for Migrations

1. Write test for the migration (both up AND down)
2. Run test — confirm it fails (table/column doesn't exist)
3. Write the migration
4. Run test — confirm up works
5. Run down migration, confirm it reverses cleanly
6. Run up again — confirm idempotent behavior

## What to Test

| Test Case | Pattern | Example |
|-----------|---------|---------|
| Schema creation | Migration up | Table exists with correct columns |
| Schema rollback | Migration down | Table/column removed cleanly |
| Constraints | Violation test | Unique constraint rejects duplicates |
| Foreign keys | Cascade/restrict | Delete parent, check child behavior |
| Indexes | Query plan | EXPLAIN shows index scan, not seq scan |
| Seed data | Factory/fixture | Test data seeds correctly |
| Query performance | Benchmark | Query under threshold with N rows |

## Migration Test Template

```typescript
describe('migration: add-users-table', () => {
  it('creates users table with correct schema', async () => {
    await migrate.up();
    const columns = await db.raw("SELECT column_name FROM information_schema.columns WHERE table_name = 'users'");
    expect(columns.rows.map(r => r.column_name)).toContain('email');
  });

  it('rolls back cleanly', async () => {
    await migrate.up();
    await migrate.down();
    const tables = await db.raw("SELECT tablename FROM pg_tables WHERE schemaname = 'public'");
    expect(tables.rows.map(r => r.tablename)).not.toContain('users');
  });
});
```

## Test Data: Use Factories, Not Raw SQL

```typescript
// Good: Factory
const user = await UserFactory.create({ role: 'admin' });

// Bad: Raw SQL in tests
await db.raw("INSERT INTO users (name, role) VALUES ('test', 'admin')");
```

Factories are maintainable, type-safe, and survive schema changes.

## Constraint Violation Tests

```typescript
it('rejects duplicate email', async () => {
  await UserFactory.create({ email: 'test@example.com' });
  await expect(
    UserFactory.create({ email: 'test@example.com' })
  ).rejects.toThrow(/unique/i);
});
```
