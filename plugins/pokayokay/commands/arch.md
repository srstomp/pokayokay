---
description: Review architecture and plan refactoring
argument-hint: <area-to-review> [--audit]
skill: architecture-review
---

# Architecture Review Workflow

Review architecture of: `$ARGUMENTS`

## Mode Detection

Parse `$ARGUMENTS` to determine mode:
- **`--audit` flag present** → Architecture audit mode (creates tasks for issues)
- **No flag** → Review/planning mode (default behavior)

## Steps

### 1. Analyze Structure
- Directory organization
- Module boundaries
- Layer separation

### 2. Map Dependencies
- Import relationships
- Circular dependencies
- External dependencies

### 3. Evaluate Patterns
- Consistency across codebase
- Adherence to conventions
- Code organization

### 4. Identify Issues
Severity levels:
- **Critical**: Blocking or causing bugs
- **Major**: Technical debt accumulating
- **Minor**: Style/consistency issues
- **Info**: Suggestions for improvement

### 5. Plan Refactoring
- Prioritize by impact
- Define migration path
- Estimate effort

### 6. Create Tasks
```bash
npx @stevestomp/ohno-cli create "Refactor [area]" -t chore
```

## Audit Mode (`--audit` flag)

When `--audit` is specified, switch to architecture audit mode that automatically creates tasks:

### Audit Steps

1. **Scan Architecture**
Analyze codebase for:
- Circular dependencies
- Layer violations (UI importing from data layer directly)
- God classes/modules (too many responsibilities)
- Orphaned code (unreachable/dead code)
- Security architecture issues

2. **Classify Issues**

| Issue Type | Description | Priority | Task Type |
|------------|-------------|----------|-----------|
| Security flaw | Auth bypass, insecure patterns | P0 | bug |
| Circular dependency | Blocking clean builds/tests | P1 | chore |
| Layer violation | Breaks separation of concerns | P1 | chore |
| Feature blocker | Architecture blocking feature dev | P1 | chore |
| God module | >500 lines, many responsibilities | P2 | chore |
| Dead code | Unreachable, unused exports | P3 | chore |
| Inconsistency | Naming, patterns, conventions | P3 | chore |

3. **Calculate Impact**
For each issue, assess:
- **Blast radius**: How many modules affected?
- **Change risk**: How risky is the fix?
- **Blocking**: Is this blocking other work?

4. **Create Tasks for Issues**

**Automatically create ohno tasks** using MCP tools:

```
create_task({
  title: "Arch: [issue description]",
  description: "[Description]\n\nAffected: [modules/files]\nBlast radius: [high/medium/low]\nMigration approach: [suggested fix]\nRisk: [assessment]",
  task_type: "bug" | "chore",
  estimate_hours: [2-8 based on blast radius]
})
```

**Example task creation:**
- Security: Auth middleware bypassable → `create_task("Arch: Fix auth middleware bypass vulnerability", type: bug)` P0
- Circular dep in core modules → `create_task("Arch: Break circular dependency between user and order modules", type: chore)` P1
- God class UserService → `create_task("Arch: Split UserService into focused services", type: chore)` P2
- Dead code in utils → `create_task("Arch: Remove dead code in utils/legacy", type: chore)` P3

5. **Report Summary**
```
Architecture Audit Results:

| Category | Count | Severity |
|----------|-------|----------|
| Security flaws | [N] | Critical |
| Circular deps | [N] | High |
| Layer violations | [N] | High |
| God modules | [N] | Medium |
| Dead code | [N] | Low |

Created [N] architecture tasks:
- [task-id]: Arch: [name] (P0/P1/P2/P3)
- ...

Recommended refactoring order: [prioritized list]
Tech debt score: [X]/100
```

## Output
Architecture audit with:
- Current state assessment
- Issues by severity
- Recommended changes
- Refactoring plan

## Covers
- Directory structure analysis
- Module boundaries and dependencies
- Code organization patterns
- Circular dependency detection
- Refactoring planning
- Migration strategies

## Related Commands

- `/pokayokay:api` - API-specific architecture
- `/pokayokay:audit --dimension security` - Security architecture review
- `/pokayokay:plan` - Incorporate architecture into planning
- `/pokayokay:work` - Implement refactoring

## Skill Integration

When architecture review involves:
- **Database structure** → Also load `database-design` skill
- **CI/CD concerns** → Also load `ci-cd` skill
- **Observability gaps** → Also load `observability` skill
- **Security concerns** → Also load `security-audit` skill

## Spike Trigger

If architecture decision has high uncertainty:
```bash
npx @stevestomp/ohno-cli create "Spike: [architecture question]" -t spike
```
Then use `/pokayokay:work` to investigate before deciding.
