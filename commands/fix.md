---
description: Diagnose and fix a bug with structured workflow
argument-hint: <bug-description-or-task-id>
---

# Bug Fix Workflow

Fix bug: `$ARGUMENTS`

## Bug Fix Philosophy

1. **Reproduce first**: Confirm the bug exists and understand conditions
2. **Diagnose root cause**: Don't just fix symptoms
3. **Fix with minimal change**: Avoid scope creep
4. **Verify the fix**: Confirm bug is resolved
5. **Add regression test**: Prevent recurrence

## Steps

### 1. Create or Get Bug Task
If `$ARGUMENTS` is a task ID:
```bash
npx @stevestomp/ohno-cli get <task-id>
```

If `$ARGUMENTS` is a description:
```bash
npx @stevestomp/ohno-cli create "Bug: $ARGUMENTS" -t bug
npx @stevestomp/ohno-cli start <task-id>
```

### 2. Reproduce the Bug
Before fixing, confirm:
- [ ] Bug can be reproduced
- [ ] Reproduction steps documented
- [ ] Affected code/component identified

If cannot reproduce:
- Ask for more information
- Check if already fixed
- Document as "cannot reproduce"

### 3. Diagnose Root Cause
Investigate:
- Read error messages/stack traces
- Add logging to trace execution
- Check recent changes (`git log`)
- Review related tests

Document findings:
```markdown
## Root Cause
[Explanation of why the bug occurs]
```

### 4. Plan the Fix
Before coding:
- Identify files to change
- Consider side effects
- Plan regression test

### 5. Implement Fix
- Make minimal necessary changes
- Add inline comments explaining fix if non-obvious
- Commit with message: `fix: [description]`

### 6. Add Regression Test
- Write test that would have caught the bug
- Verify test fails without fix
- Verify test passes with fix

### 7. Verify Fix
- Confirm original reproduction steps no longer show bug
- Run related tests
- Check for regressions

### 8. Complete Task
```bash
npx @stevestomp/ohno-cli done <task-id> --notes "Root cause: X. Fixed by: Y. Test: Z"
```

## Output

```markdown
## Bug Fix Complete

**Bug**: [task-id] - [description]
**Root Cause**: [explanation]
**Fix**: [summary of changes]
**Test Added**: [test file/name]
**Files Changed**: [list]

Commit: [hash] fix: [message]
```

## Anti-Patterns to Avoid

1. **Fixing without reproducing**: May fix wrong thing
2. **Symptom fixing**: Address root cause, not just visible issue
3. **Scope creep**: "While I'm here..." - create separate task
4. **No test**: Bug may recur without regression test

## Related Commands

- `/pokayokay:quick` - Simpler ad-hoc work
- `/pokayokay:hotfix` - Production emergencies
- `/pokayokay:work` - Continue with other tasks

## Examples

```
/pokayokay:fix Login fails when email has plus sign
/pokayokay:fix Dashboard crashes on empty data
/pokayokay:fix T045
```
