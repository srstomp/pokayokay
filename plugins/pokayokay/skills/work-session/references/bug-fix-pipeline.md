# Bug Fix Agent Pipeline

Shared pipeline for `/fix` and `/hotfix` commands. The coordinator has already completed diagnosis (reproduction, root cause analysis). This pipeline handles implementation, testing, and review via agents.

## Prerequisites

Before entering this pipeline, the coordinator MUST have:
- A task ID in ohno (status: `in_progress`)
- Root cause analysis documented
- Reproduction steps documented (for `/fix`) or impact analysis documented (for `/hotfix`)
- Files to change identified

## Pipeline Configuration

| Setting | `/fix` | `/hotfix` |
|---------|--------|-----------|
| Max fixer retries | 3 (default) | 2 |
| Max review cycles | 3 (default) | 1 |
| Quality review threshold | Warning+ (standard) | Critical only |
| Browser verification | Conditional (same as /work) | Skip |

These limits are passed to the fixer agent in the dispatch prompt (e.g., "Max attempts: 3"). The agent respects whatever limit the coordinator provides.

## Step 1: Build Acceptance Criteria

Construct acceptance criteria that ALWAYS includes these mandatory items:

```markdown
### Acceptance Criteria

- [ ] Bug described in root cause is fixed
- [ ] Regression test exists that reproduces the original bug (fails without fix, passes with fix)
- [ ] All existing tests pass
- [ ] Fix is minimal — no refactoring, no "while I'm here" changes
- [ ] Commit message follows: fix: [description]
```

Append any additional criteria from the ohno task description.

## Step 2: Build Implementer Context

Assemble the `{CONTEXT}` variable for the implementer template:

```markdown
## Bug Fix Context

### Root Cause
{ROOT_CAUSE from diagnostic steps}

### Reproduction Steps
{REPRODUCTION_STEPS from diagnostic steps}

### Files to Change
{FILES_IDENTIFIED from diagnostic steps}

### Fix Strategy
{PLANNED_APPROACH from diagnostic steps}

### MANDATORY: Regression Test
You MUST write a regression test that:
1. Reproduces the original bug condition
2. FAILS without the fix applied
3. PASSES with the fix applied
Place the test alongside existing tests for the affected module.
```

## Step 3: Dispatch Implementer

Use template: `agents/templates/implementer-prompt.md`
Agent: `yokay-implementer`

Fill template variables:
- `{TASK_ID}`: from ohno task
- `{TASK_TITLE}`: from ohno task
- `{TASK_DESCRIPTION}`: ohno description enriched with root cause analysis
- `{ACCEPTANCE_CRITERIA}`: from Step 1
- `{CONTEXT}`: from Step 2
- `{RELEVANT_SKILL}`: `error-handling`
- `{WORKING_DIRECTORY}`: project root or worktree
- `{RESUME_CONTEXT}`: empty

Dispatch:
```
Task tool:
  subagent_type: "pokayokay:yokay-implementer"
  description: "Fix: {task.title}"
  prompt: [filled implementer-prompt.md]
```

## Step 4: Auto-Fix Test Failures

After implementer completes, run the project's test suite.

**If tests pass**: proceed to Step 5.

**If tests fail** and fixer retries remain (see Configuration table):
```
Task tool:
  subagent_type: "pokayokay:yokay-fixer"
  description: "Fix test failure: {task.title}"
  prompt: [task details + full test output + "Max attempts: {config.max_fixer_retries}"]
```

**If fixer exhausts retries**:
- Set blocker: `set_blocker(task_id, "Test failures could not be auto-fixed after {N} attempts")`
- STOP pipeline. Return FAIL to calling command.

## Step 5: Verify Regression Test Exists

Before proceeding to review, verify the implementer wrote a regression test.

Check the list of changed files for test files (files matching `*.test.*`, `*.spec.*`, `*_test.*`, or files in `__tests__/`, `tests/`, `test/` directories).

**If test file found**: proceed to Step 6.

**If no test file found** and review cycles remain:
- Re-dispatch implementer with specific instruction:
  "Implementation is missing a MANDATORY regression test. Add a test that reproduces the original bug and verifies the fix. The test must fail without the fix and pass with it."
- This counts toward the review cycle limit.

**If no test file found** and review cycles exhausted:
- Set blocker: `set_blocker(task_id, "No regression test after {N} implementation cycles")`
- STOP pipeline. Return FAIL to calling command.

## Step 6: Task Review

Agent: `yokay-task-reviewer`
Template: `agents/templates/task-review-prompt.md`

Fill template with:
- `{TASK_DESCRIPTION}`: enriched description from Step 2
- `{ACCEPTANCE_CRITERIA}`: from Step 1 (bug fixed + regression test + all tests pass + minimal)
- `{IMPLEMENTATION_SUMMARY}`: from implementer's report
- `{FILES_CHANGED}`: from implementer's report
- `{COMMIT_INFO}`: from implementer's commit

**For `/hotfix` mode**, prepend this to the review prompt:
```markdown
## Review Mode: HOTFIX

Due to time pressure, only FAIL on CRITICAL issues:
- Security vulnerabilities
- Data loss risk
- Crash potential

WARNING and SUGGESTION issues should be noted but result in PASS.
```

**For `/fix` mode**: standard review (same thresholds as `/work`).

**PASS**: proceed to Step 7.
**FAIL**: re-dispatch implementer with issues (counts toward review cycle limit).

### Review Cycle Exhaustion

After max review cycles (see Configuration table):
- Set blocker: `set_blocker(task_id, "Review failed after {N} cycles: {last_failure_reason}")`
- STOP pipeline. Return FAIL to calling command.

## Step 7: Pipeline Complete

Return result to calling command:
- **PASS**: Implementation committed, regression test verified, both reviews passed.
- **FAIL**: Pipeline could not complete. Task blocked with reason in ohno.
