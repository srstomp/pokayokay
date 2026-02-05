---
name: architecture-review
description: Review project architecture, identify structural issues, and plan refactoring. Analyzes directory structure, module boundaries, dependencies, and code organization. Provides systematic approaches for cleanup, restructuring, and migration. Primary focus on TypeScript/JavaScript projects with patterns applicable to other languages. Use this skill when auditing codebases, planning refactors, or improving project organization.
---

# Architecture Review

Analyze, audit, and improve project structure.

## Key Principles

- **Measure before changing** — Map structure and identify concrete issues before proposing changes
- **Clear boundaries** — Layers (UI, logic, data) separated with consistent dependency direction
- **Colocation** — Related code together; easy to find, change, and delete features
- **Incremental migration** — Refactor in phases, validate each step with tests

## Quick Assessment

- No circular dependencies
- Consistent directory naming and grouping (by feature or by type)
- Single responsibility per file/module, reasonable file sizes (<500 lines)
- External dependencies isolated, shared code properly extracted
- New developers can navigate and find code for any feature easily

## Quick Start Checklist

1. Map current structure: directory tree, dependency graph, module boundaries
2. Identify issues: circular deps, god modules, leaky abstractions, deep nesting
3. Classify severity: critical (blocks dev), high (maintenance burden), medium/low (friction)
4. Propose target structure with migration plan
5. Execute incrementally, validating with tests after each move

## References

| Reference | Description |
|-----------|-------------|
| [analysis-techniques.md](references/analysis-techniques.md) | Dependency graphs, complexity metrics, code analysis |
| [refactoring-patterns.md](references/refactoring-patterns.md) | Safe refactoring techniques, migration strategies |
| [structural-patterns.md](references/structural-patterns.md) | Directory structures for different project types |
| [dependency-management.md](references/dependency-management.md) | Circular deps, coupling, module boundaries |
| [cleanup-strategies.md](references/cleanup-strategies.md) | Dead code removal, consolidation, naming conventions |
