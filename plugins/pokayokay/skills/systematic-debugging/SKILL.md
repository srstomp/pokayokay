---
name: systematic-debugging
description: Use when diagnosing bugs, failing tests, build failures, unexpected behavior, flaky tests, regressions, or production incidents. Requires reproduction, root cause evidence, one-hypothesis fixes, and regression verification before editing.
---

# Systematic Debugging

Fix root causes, not symptoms. Do not edit code until you have reproduced the
issue or gathered enough evidence to explain why reproduction is impossible.

## Process

### 1. Reproduce

- Capture the exact command, input, or user steps.
- Read the full error message and stack trace.
- Confirm whether the issue is deterministic or intermittent.
- Record expected behavior versus actual behavior.

If the issue cannot be reproduced, gather logs or traces and report the missing
data instead of guessing.

### 2. Trace Root Cause

- Check recent changes that touch the failing path.
- Compare broken code with a nearby working example.
- Trace bad data backward from the failure site to the source.
- In multi-component systems, add temporary diagnostics at boundaries to find
  which layer changes the data or state.

Write the hypothesis as: "I think X is the root cause because Y evidence."

### 3. Test One Hypothesis

- Change one variable at a time.
- Prefer the smallest diagnostic or failing test that proves the hypothesis.
- If the hypothesis fails, remove incidental diagnostic changes and form a new
  hypothesis from the new evidence.
- After three failed fix attempts, stop and question whether the architecture or
  task framing is wrong.

### 4. Fix And Verify

- Add a regression test before the fix whenever feasible.
- Make the minimal code change that addresses the root cause.
- Run the regression test and relevant existing tests.
- Use `verification-before-completion` before reporting success.

## Anti-Patterns

- Patching the line where the error surfaced without tracing the source.
- Changing tests to match broken behavior.
- Bundling cleanup or refactors into a bug fix.
- Trying multiple fixes at once.
- Declaring "fixed" after code changes without rerunning the failing scenario.

## Report Template

```markdown
## Debugging Report

### Reproduction
- Command/steps:
- Expected:
- Actual:

### Root Cause
- Hypothesis:
- Evidence:

### Fix
- Files:
- Why this is minimal:

### Verification
- Command:
- Result:
```
