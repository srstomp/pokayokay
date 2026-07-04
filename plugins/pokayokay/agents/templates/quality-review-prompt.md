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

### Pre-Validated Approach

{APPROACH}

> If the approach above is `None — design review was skipped`, mark the design compliance check `N/A` — do not fabricate a verdict.

---

## Your Assignment

Review the implementation for:
1. **Code structure** — readability, organization, appropriate abstractions
2. **Test quality** — meaningful tests, edge case coverage
3. **Edge cases** — error handling, boundary conditions
4. **Conventions** — project patterns, naming, file placement
5. **Design compliance** — did the implementation follow the pre-validated approach above? (`N/A` if none)

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

---

<!-- Template Notes for Coordinator:

Variables:
- {TASK_ID}, {TASK_TITLE}: From ohno task
- {FILES_CHANGED}: From implementer handoff / git diff --name-only
- {COMMIT_INFO}: Implementer's commit (hash + message)
- {COMMIT_HASH}: Bare commit hash for the git diff verification commands
- {APPROACH}: The design reviewer's approved approach (work.md Step 3.7).
  Fill with "None — design review was skipped" when the gate was skipped
  (/fix and /hotfix pipelines never run design review).
- {WORKING_DIRECTORY}: Task's worktree path or project root
-->
