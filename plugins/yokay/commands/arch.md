---
description: Review architecture and plan refactoring
argument-hint: <area-to-review>
skill: architecture-review
---

# Architecture Review Workflow

Review architecture of: `$ARGUMENTS`

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
- **CI/CD concerns** → Also load `ci-cd-expert` skill
- **Observability gaps** → Also load `observability` skill
- **Security concerns** → Also load `security-audit` skill

## Spike Trigger

If architecture decision has high uncertainty:
```bash
npx @stevestomp/ohno-cli create "Spike: [architecture question]" -t spike
```
Then use `/pokayokay:work` to investigate before deciding.
