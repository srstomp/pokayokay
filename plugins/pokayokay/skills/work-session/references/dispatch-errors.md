# Dispatch Error Handling

Recovery procedures when dispatch components fail.

## When ohno MCP Fails

1. **Retry once** — transient failures are common
2. **Check MCP connection** — `npx @stevestomp/ohno-cli status`
3. **Use CLI fallback** — `npx @stevestomp/ohno-cli task <task-id>`
4. **Proceed without ohno** — use coordinator notes, sync when available

## When Task Data is Incomplete

**Missing description**: Ask human, infer from title+context, or block pending clarification.

**Missing acceptance criteria**: Coordinator defines basic criteria before dispatch:
- Implementation matches task title/description
- Code follows existing patterns
- Tests verify core functionality
- No regressions introduced

## When Skill Routing Fails

**No matching skill**: Proceed with Claude's general capabilities. The implementer will use built-in knowledge without skill specialization.

**Skill file not found**: Check skill installation, use alternative skill, or proceed without.

## When Subagent Dispatch Fails

**Task tool unavailable**: Coordinator implements directly (fallback mode). On Codex this is the normal path — run the stage inline per the agent's definition.

### Dispatch Failure Protocol

Classify every failed or suspect dispatch into one of four classes and apply the mandated behavior:

| Class | Symptom | Mandated behavior |
|-------|---------|-------------------|
| **(a) Tool error / timeout** | Task tool returns an error or times out before a report arrives | Retry the dispatch ONCE. On second failure, `mcp__ohno__set_blocker(task_id, "agent dispatch failed: tool error/timeout")` and move to the next task. |
| **(b) Empty / no verdict token** | Report is empty, or contains no recognizable status token (`Status:`, `VERDICT:`, `PASS`, `FAIL`, `BLOCKED`) | Retry the dispatch ONCE, prefixing the prompt with: "Your previous dispatch produced no usable report; end with the required status line". On second failure, `mcp__ohno__set_blocker(task_id, "agent dispatch failed: no usable report")` and move on. |
| **(c) Questions only** | Report contains only questions (e.g. the brainstormer's `### Open Questions`) with no usable result | Answer from the task description, story context, and handoff notes, then re-dispatch with `## Answers to Your Questions` appended to the prompt. Mode-aware per [dispatch-preparation.md](dispatch-preparation.md) Step 2: in supervised/semi-auto, surface unanswerable questions at the human checkpoint; in auto/unattended, log them as assumptions and proceed. |
| **(d) Success claimed, no commit** | Report claims success but `git log --oneline -1` shows no new commit | Inspect the worktree (`git status`, `git log --oneline -5`) and re-dispatch with resume context built from the ACTUAL state (files present, last real commit, what remains). Never trust the claim over the repository. |

**Hard rule**: A task NEVER remains `in_progress` after its dispatch concludes —
it ends the cycle `done`, `blocked`, or back to `todo`.

This protocol complements (does not replace) the existing recovery paths:
crashed sessions with stale `in_progress` tasks are handled by
`hooks/actions/recover.sh` (WIP saved, crash note folded in), and interrupted
work resumes via `/work --continue` (work.md "Resume Check").
