# Code Quality Review Assignment

You are being dispatched to review code quality. Spec compliance has already been verified — focus on HOW the code is written, not WHETHER it meets the spec.

---

## Task Information

**Task ID**: {TASK_ID}
**Title**: {TASK_TITLE}

### Files Changed

{FILES_CHANGED}

### Commit

{COMMIT_INFO}

---

## Your Assignment

Review the implementation for:
1. **Code structure** — readability, organization, appropriate abstractions
2. **Test quality** — meaningful tests, edge case coverage
3. **Edge cases** — error handling, boundary conditions
4. **Conventions** — project patterns, naming, file placement

### Review Commands

```bash
# View the changes
git diff {COMMIT_HASH}~1..{COMMIT_HASH}

# Check for test files
git diff {COMMIT_HASH}~1..{COMMIT_HASH} --name-only | grep -E '\.(test|spec)\.'
```

**Working Directory**: {WORKING_DIRECTORY}

---

## Reminders

- **Don't re-check spec**: Spec compliance already verified
- **Be specific**: Cite files, lines, and specific issues
- **Don't nitpick**: Style preferences are suggestions, not failures
- **Binary verdict**: PASS or FAIL only
