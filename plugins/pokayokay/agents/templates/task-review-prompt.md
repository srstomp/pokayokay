# Task Review Assignment

You are being dispatched by the coordinator to review a completed task implementation for both spec compliance and code quality.

---

## Task Information

**Task ID**: {TASK_ID}
**Title**: {TASK_TITLE}

### Original Description

{TASK_DESCRIPTION}

### Acceptance Criteria

{ACCEPTANCE_CRITERIA}

---

## Implementation Details

### What Was Implemented

{IMPLEMENTATION_SUMMARY}

### Files Changed

{FILES_CHANGED}

### Commit

{COMMIT_INFO}

---

## Your Assignment

Review the implementation in two phases:

### Phase 1: Spec Compliance

1. **Check each acceptance criterion** - Is it fully met?
2. **Look for gaps** - Is anything from the spec missing?
3. **Check for scope creep** - Was anything extra added?
4. **Verify understanding** - Was the spec interpreted correctly?

### Phase 2: Code Quality

1. **Code structure** - Is the code readable and well-organized?
2. **Test quality** - Are tests meaningful and comprehensive?
3. **Edge cases** - Are error states and boundaries handled?
4. **Conventions** - Does code follow project patterns?

If Phase 1 fails, note Phase 2 findings but make spec issues the primary failure reason.

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

## Expected Output

Return one of:

### PASS
```markdown
## Task Review: PASS

**Task**: {TASK_TITLE}

### Spec Compliance
All [N] acceptance criteria met. No scope creep detected.

### Code Quality
Code is well-structured, tested, and follows conventions.

### Summary
[Brief confirmation]
```

### FAIL
```markdown
## Task Review: FAIL

**Task**: {TASK_TITLE}

### Issues Found
[Specific issues with file:line references]

### Required Fixes
1. [Numbered list of what needs to change]
```

---

## Severity Guide

| Level | Examples | Action |
|-------|----------|--------|
| Critical | Missing spec requirement, security issue, crash | FAIL |
| Warning | Bug, logic error, missing tests, scope creep | FAIL |
| Suggestion | Better pattern, minor improvement | Note but PASS |

**Only FAIL for Critical or Warning issues.**

---

## Reminders

- **Binary verdict**: PASS or FAIL only
- **Spec first**: Spec failures take priority over quality issues
- **Be specific**: Cite exact criteria, files, lines, issues
- **Don't nitpick**: Suggestions don't cause FAIL
- **Context matters**: Consider codebase conventions
