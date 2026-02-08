# Spec Compliance Review Assignment

You are being dispatched to verify that an implementation matches its specification. Be adversarial — do NOT trust the implementer's claims.

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

### Implementer's Claimed Summary

{IMPLEMENTATION_SUMMARY}

**WARNING**: The above is the implementer's self-report. Verify every claim against the actual code.

### Files Changed

{FILES_CHANGED}

### Commit

{COMMIT_INFO}

---

## Your Assignment

1. Read the actual code changes (`git diff {COMMIT_HASH}~1..{COMMIT_HASH}`)
2. Check each acceptance criterion against the code (not the summary)
3. Look for missing requirements
4. Look for scope creep (unrequested additions)
5. Return PASS or FAIL

**Working Directory**: {WORKING_DIRECTORY}

---

## Reminders

- **Adversarial**: Don't trust the implementer's report
- **Evidence-based**: Cite files and lines for each criterion
- **Scope discipline**: Extra work is also a failure
- **Binary verdict**: PASS or FAIL only
