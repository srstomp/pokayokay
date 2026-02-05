# Error Recovery

## Build Failures

```markdown
## Build Failed

**Error**: TypeScript compilation error in Dashboard.tsx
**Line 47**: Property 'user' does not exist on type '{}'

### Recovery Plan
1. Check recent changes (git diff)
2. Identify breaking change
3. Fix type error
4. Verify build passes
5. Block task if needed: `ohno block <id> "Build failure"`
6. Continue or escalate

Proceeding with recovery...
```

## Blocked Tasks

```bash
# Block a task
ohno block task-abc123 "Waiting for API spec"

# View blocked tasks
ohno tasks --status blocked

# Resolve blocker
ohno unblock task-abc123
```
