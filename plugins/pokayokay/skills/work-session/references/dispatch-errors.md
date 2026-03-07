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

**Task tool unavailable**: Coordinator implements directly (fallback mode).

**Subagent returns error**: Analyze error cause, fix prerequisites, re-dispatch with corrections.
