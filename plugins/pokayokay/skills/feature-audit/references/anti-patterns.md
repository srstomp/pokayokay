# Anti-Patterns

## Audit Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Trusting tasks.db status | "Done" ≠ user-facing | Always verify in codebase |
| Only checking file existence | File may be empty/stub | Check for real implementation |
| Ignoring navigation | Feature unreachable | Verify menu/nav links |
| Skipping mobile | Desktop-only isn't complete | Check responsive/native |
| No documentation check | Users can't discover | Verify help/docs exist |

## Remediation Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Generic tasks | "Add frontend" too vague | Specific: "Create /analytics route" |
| Missing dependencies | Frontend before backend | Check implementation order |
| Overloading | 50 tasks at once | Prioritize by P-level |
| No estimates | Can't plan | Add hour estimates |
