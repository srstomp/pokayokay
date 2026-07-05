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

1. Read the actual code changes (`git diff {BASE_COMMIT}` plus `git status --porcelain` — the diff against the base commit includes uncommitted working-tree edits, which post-fixer runs always have since the fixer does not commit)
2. Check each acceptance criterion against the code (not the summary)
3. Look for missing requirements
4. Look for scope creep (unrequested additions)
5. Return PASS or FAIL (BLOCKED only under your enumerated cannot-review conditions), ending with the terminal `VERDICT:` line

**Base Commit**: {BASE_COMMIT}

> `{BASE_COMMIT}` was recorded by the coordinator immediately before the implementer was dispatched — it is your primary diff baseline. If it is missing, fall back per your agent definition (merge-base with the default branch, then `HEAD~1`) and state which baseline you used.

**Working Directory**: {WORKING_DIRECTORY}

---

## Reminders

- **Adversarial**: Don't trust the implementer's report
- **Evidence-based**: Cite files and lines for each criterion
- **Scope discipline**: Extra work is also a failure
- **Verdict**: PASS or FAIL; BLOCKED only under the enumerated cannot-review conditions (zero changes, no acceptance criteria, nonexistent commit)
- **Terminal line**: End your reply with a final line exactly `VERDICT: PASS`, `VERDICT: FAIL`, or `VERDICT: BLOCKED`
