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

## See Also
- Load `architecture-review` skill for detailed patterns
