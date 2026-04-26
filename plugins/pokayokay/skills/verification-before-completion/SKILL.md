---
name: verification-before-completion
description: Use before claiming work is done, fixed, passing, ready to commit, ready to PR, or ready to mark complete. Requires fresh verification evidence and explicit command output before success claims.
---

# Verification Before Completion

Evidence comes before completion claims. Do not say work is done, fixed,
passing, ready, or complete until a fresh verification command proves it.

## Gate

Before any success claim:

1. Identify the command or checklist that proves the claim.
2. Run the full command now, not from memory.
3. Read the output and exit code.
4. If it fails, report the real state and next action.
5. If it passes, cite the command and result in the report.

## Required Evidence

| Claim | Evidence required |
|-------|-------------------|
| Tests pass | Fresh test command with exit 0 |
| Build passes | Fresh build/type-check command with exit 0 |
| Bug fixed | Reproduction/regression test now passes |
| Requirements met | Checklist mapped to files, tests, or behavior |
| Agent completed | VCS diff reviewed plus verification command |
| Ready to commit/PR | Tests/build relevant to changed surface plus self-review |

## Regression Tests

For bug fixes, a regression test must prove the original symptom:

1. Write or identify the test that fails without the fix.
2. Verify the failure is for the expected reason.
3. Apply the fix.
4. Verify the test passes.

If the project cannot support an automated regression test, document the manual
reproduction steps and why automation was not feasible.

## Output Pattern

```markdown
## Verification

- Command: `npm test -- path/to/test`
- Result: PASS, 12/12 tests, exit 0
- Scope checked: regression test for duplicate email handling
```

Avoid words like "should", "probably", or "looks good" when reporting status.
Use observed results.
