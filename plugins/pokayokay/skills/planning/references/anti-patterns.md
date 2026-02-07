# Anti-Patterns

## Analysis Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Accepting vague requirements | Builds wrong thing | Flag ambiguities, ask questions |
| Scope creep in breakdown | Adds unspecified work | Stick to documented requirements |
| Ignoring constraints | Infeasible plan | Check tech stack, timeline, budget |
| Missing dependencies | Blocked work | Map all external dependencies |
| No skill assignment | Work not routed | Assign skills to every feature |

## Task Breakdown Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Tasks > 8 hours | Too vague to estimate | Split into smaller tasks |
| No acceptance criteria | Unclear "done" | Define measurable criteria |
| Missing task types | Can't assign properly | Tag: frontend, backend, design, etc. |
| Circular dependencies | Deadlock | Identify and break cycles |
| Everything P0 | No prioritization | Force-rank priorities |

## Output Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Output to random location | Skills can't find | Always use `.claude/` |
| No PROJECT.md | No shared context | Always generate PROJECT.md |
| No skill assignments | Manual routing needed | Assign skills during analysis |
| Missing features.json | No machine-readable list | Always generate features.json |
