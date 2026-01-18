---
name: hooks
description: Automatic action execution at session lifecycle points. Hooks guarantee critical actions (sync, commit, test) run without relying on LLM memory. Integrated with project-harness for session orchestration.
---

# Hook System

Guaranteed action execution for reliable autonomous sessions.

## Quick Reference

| Hook | Trigger | Default Actions |
|------|---------|-----------------|
| pre-session | Session start | verify-clean |
| pre-task | Task start | check-blockers |
| post-task | Task complete | sync, commit |
| post-story | Story complete | test, audit |
| post-epic | Epic complete | full-audit |
| on-error | Error occurs | log, block, recover |
| pre-commit | Before commit | lint, typecheck |
| post-session | Session end | handoff, sync |

## Execution

Hooks execute automatically. Do not call manually.

### In Work Loop

```
# The work loop with hooks (simplified)
[pre-session hooks]

WHILE tasks remain:
  [pre-task hooks]

  # Do the work
  get_next_task()
  start_task()
  route_to_skill()
  implement()

  [post-task hooks]  <- sync + commit happen here

  checkpoint()

[post-session hooks]
```

### Hook Output Format

When hooks execute, log them:

```markdown
## Hooks: post-task

| Action | Status | Duration |
|--------|--------|----------|
| sync | ✓ | 0.3s |
| commit | ✓ | 0.5s |

All hooks passed.
```

If a hook fails:

```markdown
## Hooks: post-task

| Action | Status | Duration |
|--------|--------|----------|
| sync | ✓ | 0.3s |
| commit | ⚠️ nothing to commit | 0.1s |

Continuing despite warnings.
```

## Configuration

### Project Override

Create `.yokay/hooks.yaml` to customize:

```yaml
hooks:
  post-task:
    actions:
      - sync
      - commit
      - prisma-generate  # Custom action

  pre-commit:
    enabled: false  # Disable entirely
```

### Adding Custom Actions

Put scripts in `.yokay/hooks/`:

```bash
# .yokay/hooks/prisma-generate.sh
#!/bin/bash
if git diff --name-only | grep -q 'schema.prisma'; then
  npx prisma generate
fi
```

## Mode Behavior

| Hook | supervised | semi-auto | autonomous |
|------|------------|-----------|------------|
| post-task | sync | sync, commit | sync, commit, test |
| post-story | — | test, audit | test, audit |
| post-epic | audit | audit | audit, docs |

## Error Handling

Hooks are **fail-safe**:
- Failures log warnings
- Session continues
- Critical failures (can't sync) pause for human

## Anti-Patterns

| Don't | Do |
|-------|-----|
| Call hooks manually | Let them execute automatically |
| Skip hooks to save time | Trust the system |
| Ignore hook warnings | Review before continuing |
