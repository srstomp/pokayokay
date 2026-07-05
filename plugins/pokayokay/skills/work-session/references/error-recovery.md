# Error Recovery

Recovery playbook for coordinator-level failures during a work session.

## Dispatch Failures

A subagent dispatch that errors or times out, returns an empty or verdict-less
report, returns only questions, or claims success without a commit is handled
by the Dispatch Failure Protocol in [dispatch-errors.md](dispatch-errors.md).
Hard rule: a task NEVER remains `in_progress` after its dispatch concludes —
it ends the cycle `done`, `blocked`, or back to `todo`.

## Handoff Store Failures

Implementer and fixer agents wrap their `set-handoff` CLI call in a failure
guard: when the store write fails, the agent reports `HANDOFF STORE FAILED`
and includes the full handoff details in its inline report instead. Use that
inline report as the handoff source when filling review templates (instead of
`get_task_handoff`), and log the store failure via `add_task_activity`.

## Unparseable Review Verdict

Reviewers must end with a terminal `VERDICT: PASS | FAIL | BLOCKED` line. When
a review report has no such line (bridge.py surfaces a "could not be parsed"
warning), do NOT infer the verdict from prose. Re-dispatch the reviewer ONCE
per dispatch-failure class (b) — instructing it to end with the required
`VERDICT:` line — then `set_blocker` the task if the report is still
unparseable.

## Chain-State Desync

When `.pokayokay/pokayokay-chain-state.json` disagrees with ohno (stale counts
after a crash, tasks listed in `failed_tasks` that are actually done):

1. Treat ohno as the source of truth for task status
2. Re-derive `failed_tasks` / `conflict_tasks` from `get_blocked_tasks` and session context
3. Rewrite the chain-state file with corrected values before session end
4. Stale sessions with `in_progress` tasks are recovered automatically by `hooks/actions/recover.sh` (WIP saved, crash note folded in) — do not re-run recovery manually

## Build Failures

```markdown
## Build Failed

**Error**: TypeScript compilation error in Dashboard.tsx
**Line 47**: Property 'user' does not exist on type '{}'

### Recovery Plan
1. Check recent changes (git diff)
2. Identify breaking change
3. Fix type error
4. Verify build passes
5. Block task if needed: `npx @stevestomp/ohno-cli block <id> "Build failure"`
6. Continue or escalate

Proceeding with recovery...
```

## Blocked Tasks

```bash
# Block a task
npx @stevestomp/ohno-cli block task-abc123 "Waiting for API spec"

# View blocked tasks
npx @stevestomp/ohno-cli tasks --status blocked

# Resolve blocker
npx @stevestomp/ohno-cli unblock task-abc123
```
