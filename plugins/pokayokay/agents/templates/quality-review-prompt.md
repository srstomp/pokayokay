# Quality Review Assignment

You are being dispatched by the coordinator to review implementation quality. Spec compliance has already passed.

---

## Task Information

**Task ID**: {TASK_ID}
**Title**: {TASK_TITLE}

---

## Implementation Details

### Files Changed

{FILES_CHANGED}

### Commit

{COMMIT_INFO}

---

## Your Assignment

Verify that the implementation meets quality standards:

1. **Code structure** - Is the code readable and well-organized?
2. **Test quality** - Are tests meaningful and comprehensive?
3. **Edge cases** - Are error states and boundaries handled?
4. **Conventions** - Does code follow project patterns?

### Review Commands

```bash
# View the changes
git diff {COMMIT_HASH}~1..{COMMIT_HASH}

# Check for test files
git diff {COMMIT_HASH}~1..{COMMIT_HASH} --name-only | grep -E '\.(test|spec)\.'

# Run tests to verify they pass
npm test -- --testPathPattern="[relevant pattern]"
```

---

## Quality Checklist

### Code Quality
- [ ] Functions are focused and readable
- [ ] No deep nesting or complex conditionals
- [ ] Appropriate error handling
- [ ] Clear naming conventions

### Test Quality
- [ ] Tests exist for new functionality
- [ ] Happy path covered
- [ ] Edge cases covered
- [ ] Tests have meaningful assertions

### Conventions
- [ ] Matches existing codebase patterns
- [ ] Correct file organization
- [ ] Consistent style

### Security (Always Critical)
- [ ] No hardcoded secrets
- [ ] Input validation present
- [ ] No injection vulnerabilities

---

## Expected Output

Return one of:

### PASS
```markdown
## Quality Review: PASS

**Task**: {TASK_TITLE}
**Verdict**: PASS - Implementation meets quality standards

### Code Quality
[Status table]

### Test Quality
[Status table]

### Summary
[Brief confirmation]
```

### FAIL
```markdown
## Quality Review: FAIL

**Task**: {TASK_TITLE}
**Verdict**: FAIL - Implementation has quality issues

### Issues Found
[Specific issues with file:line references]

### Required Fixes
[Numbered list of what needs to change]
```

---

## Severity Guide

| Level | Examples | Action |
|-------|----------|--------|
| Critical | Security issue, crash potential | FAIL |
| Warning | Bug, logic error, missing tests | FAIL |
| Suggestion | Better pattern, minor improvement | Note but PASS |

**Only FAIL for Critical or Warning issues.**

---

## Reminders

- **Binary verdict**: PASS or FAIL only
- **Be specific**: Cite exact files, lines, issues
- **Don't nitpick**: Suggestions don't cause FAIL
- **Context matters**: Consider codebase conventions
