# Code Quality Review Assignment

You are being dispatched to review code quality. Spec compliance has already been verified — focus on HOW the code is written, not WHETHER it meets the spec.

---

## Task Information

**Task ID**: {TASK_ID}
**Title**: {TASK_TITLE}

### Acceptance Criteria

{ACCEPTANCE_CRITERIA}

> For the Test-AC Mapping check only — do NOT re-verify spec compliance against these.

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
# View the changes (the diff against the base commit includes uncommitted
# working-tree edits — post-fixer runs always have them)
git diff {BASE_COMMIT}
git status --porcelain

# Check for test files
git diff {BASE_COMMIT} --name-only | grep -E '\.(test|spec)\.'
```

**Base Commit**: {BASE_COMMIT}

> `{BASE_COMMIT}` was recorded by the coordinator immediately before the implementer was dispatched — it is your primary diff baseline. If it is missing, fall back per your agent definition (merge-base with the default branch, then `HEAD~1`) and state which baseline you used.

**Working Directory**: {WORKING_DIRECTORY}

---

## Reminders

- **Don't re-check spec**: Spec compliance already verified
- **Be specific**: Cite files, lines, and specific issues
- **Don't nitpick**: Style preferences are suggestions, not failures
- **Verdict**: PASS or FAIL; BLOCKED only under the enumerated cannot-review conditions (zero changes, no acceptance criteria, nonexistent commit, declared checks fail to launch)
- **Terminal line**: End your reply with a final line exactly `VERDICT: PASS`, `VERDICT: FAIL`, or `VERDICT: BLOCKED`

---

<!-- Template Notes for Coordinator:

Variables:
- {TASK_ID}, {TASK_TITLE}: From ohno task
- {ACCEPTANCE_CRITERIA}: From ohno task (post-brainstorm) — input for the
  Test-AC Mapping check; without it the reviewer's cannot-review trigger (b)
  would fire on every quality review
- {FILES_CHANGED}: From implementer handoff / git diff --name-only
- {COMMIT_INFO}: Implementer's commit (hash + message)
- {BASE_COMMIT}: Recorded by the coordinator at implementer dispatch
  (work.md Step 4) — primary diff baseline, includes working-tree edits
- {APPROACH}: The design reviewer's approved approach (work.md Step 3.7).
  Fill with "None — design review was skipped" when the gate was skipped
  (/fix and /hotfix pipelines never run design review).
- {WORKING_DIRECTORY}: Task's worktree path or project root
-->
