# Approval Policy

Pokayokay should reduce approval friction for low-risk workflow actions while
leaving meaningful risk with the human operator.

## Auto-Approve Candidates

These are safe for hook-level allow decisions when they stay inside the active
workspace:

- Read-only repository inspection: `git status`, `git diff`, `git log`, `git branch`, `git rev-parse`
- Code search and file inspection: `rg`, `ls`, `pwd`, targeted `sed -n`, and reads under `plugins/pokayokay/`
- Pokayokay test commands: `bash plugins/pokayokay/tests/...` and `node plugins/pokayokay/tests/...`
- ohno task bookkeeping: `npx @stevestomp/ohno-cli ...`
- The pokayokay bridge hook itself: `hooks/actions/bridge.py`

## Always Ask Or Deny

These should not be auto-approved by pokayokay:

- Destructive filesystem commands such as `rm -rf`
- History rewriting or discard commands such as `git reset --hard`, `git checkout --`, and broad `git clean`
- Publishing, deployment, and infrastructure mutation commands
- `git push`, PR merge/close commands, or release tagging
- Dependency installation unless the user or task explicitly requested it
- Commands touching secrets, credentials, environment files, or paths outside the workspace

## Runtime Notes

- Codex uses `PermissionRequest` hooks for approval decisions. The bridge only
  auto-decides obvious allow/deny cases; ambiguous commands fall back to the
  normal Codex approval prompt.
- Claude Code does not use Codex's `PermissionRequest` hook shape. Claude
  approval and permission behavior should stay in Claude settings and hook
  guardrails.
- Hook approvals are convenience, not security boundaries. Keep checks scoped
  and conservative.
