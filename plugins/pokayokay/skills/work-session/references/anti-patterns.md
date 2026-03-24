# Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Horizontal layer tasks | Agent builds components referencing APIs that don't exist yet; nothing works until all tasks complete | Replan as vertical slices (one feature end-to-end per task) |
| File-existence-only tests | Agent asserts file exists but doesn't verify it renders/responds/connects | Require runtime verification (render, API response, DB query) |
| Skipping verification | Start on broken code | Always verify first |
| No git commits | Can't recover from errors | Commit every task |
| No kanban sync | Stale visual state | Run `ohno sync` after changes |
| Giant tasks | Lose progress on failure | Keep tasks ≤8 hours |
| Ignoring checkpoints | Lose human control | Respect mode settings |
| No session context | Next session confused | Use `ohno context` |
| Auto on new project | Bad patterns amplified | Start supervised |
