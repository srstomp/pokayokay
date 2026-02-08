# Pre-Flight Checks

Validation run automatically at SessionStart when mode is `unattended`. Prevents wasted overnight sessions by catching environment issues upfront.

## Checks Performed

| Check | Level | What | Why |
|-------|-------|------|-----|
| Git clean | Blocking | No uncommitted changes | Avoids commit conflicts |
| ohno responsive | Blocking | CLI can list tasks | No task management = no work |
| Tasks available | Blocking | Ready count > 0 | Don't start if nothing to do |
| Disk space | Warning | >1GB free | Prevents mid-session failures |
| Worktree locks | Warning | No stale lock files | May cause worktree setup failures |
| Chain state | Blocking | Valid JSON if file exists | Corrupt state = broken chaining |

## Behavior

- **Blocking issues**: Session reports all issues and stops before work begins
- **Warnings**: Logged but session continues
- **All checks pass**: Session proceeds normally

## Hook Integration

Pre-flight runs via `bridge.py` → `pre-flight.sh` during SessionStart when `YOKAY_WORK_MODE=unattended`.

The coordinator sets this environment variable at session start based on the mode argument.

## Adding Custom Checks

Add checks to `hooks/actions/pre-flight.sh`. Follow the output format:
- `CHECK=name OK` for passing checks
- `ISSUE=name` + `DETAIL=description` for blocking issues
- `WARNING=name` + `DETAIL=description` for non-blocking warnings

Exit code: 0 = all pass, 1 = blocking issues found.
