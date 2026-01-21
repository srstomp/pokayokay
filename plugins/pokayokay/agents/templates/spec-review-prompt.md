# Spec Compliance Review Assignment

You are being dispatched by the coordinator to review an implementation for spec compliance.

---

## Task Information

**Task ID**: {TASK_ID}
**Title**: {TASK_TITLE}

### Original Description

{TASK_DESCRIPTION}

### Acceptance Criteria

{ACCEPTANCE_CRITERIA}

---

## Implementation Summary

### What Was Implemented

{IMPLEMENTATION_SUMMARY}

### Files Changed

{FILES_CHANGED}

### Commit

{COMMIT_INFO}

---

## Your Assignment

Verify that the implementation matches the task specification:

1. **Check each acceptance criterion** - Is it fully met?
2. **Look for gaps** - Is anything from the spec missing?
3. **Check for scope creep** - Was anything extra added?
4. **Verify understanding** - Was the spec interpreted correctly?

### Review Commands

```bash
# View the changes
git diff {COMMIT_HASH}~1..{COMMIT_HASH}

# Read specific files
# Use Read tool for each changed file
```

---

## Expected Output

Return one of:

### PASS
```markdown
## Spec Review: PASS

**Task**: {TASK_TITLE}
**Verdict**: PASS - Implementation matches specification

### Criteria Verification
[Table showing each criterion as met]

### Summary
[Brief confirmation]
```

### FAIL
```markdown
## Spec Review: FAIL

**Task**: {TASK_TITLE}
**Verdict**: FAIL - Implementation does not match specification

### Issues Found
[Specific gaps, misunderstandings, or scope creep]

### Required Fixes
[Numbered list of what needs to change]
```

---

## Reminders

- **Binary verdict**: PASS or FAIL only
- **Be specific**: Cite exact criteria and gaps
- **Spec only**: Don't evaluate code quality (that's next)
- **Extra work is failure**: Scope creep means FAIL
