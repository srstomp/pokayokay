# Spike: Native Dispatch via context: fork

**Decision**: NO-GO
**Date**: 2026-03-07
**Time spent**: 1h (30min analysis + 2 user test attempts)

## Question

Can pokayokay use Claude Code's native `context: fork` + `agent` frontmatter to replace manual Task tool dispatch for standalone agent skills?

## Answer

No. `context: fork` with custom plugin agents causes the session to hang indefinitely. Tested twice by the user in `--plugin-dir` mode — one session ran for 6+ hours doing nothing.

## Findings

### 1. context: fork hangs with plugin agents (BLOCKING)

When `context: fork` + `agent: yokay-auditor` is added to a plugin skill, invoking the skill causes the session to hang. The forked subagent never completes or returns results. This was reproduced twice.

Likely causes:
- Custom plugin agents may not resolve correctly in the forked context
- The `skill:` reference in commands may create a circular loading issue with `context: fork`
- The forked agent may lack access to required MCP servers and hang waiting

**Conclusion**: `context: fork` is not viable for pokayokay's plugin agent dispatch. Keep current manual dispatch via Task tool.

### 2. Plugin cache blocks in-session testing

Plugin skills load from the cache (`~/.claude/plugins/cache/`), not the development directory. Changes require either `--plugin-dir` or plugin reinstall.

### 3. ${CLAUDE_SKILL_DIR} resolves correctly

Confirmed working. Resolves to the skill's directory (cache or source depending on load method).

### 4. Dynamic injection (!`command`) — not tested

Blocked by the hanging issue. Lower priority now that native dispatch is ruled out.

## Recommendation

**NO-GO on `context: fork`** for pokayokay. The current architecture (coordinator dispatches agents via Task tool with filled prompt templates) is proven and reliable. Do not invest further in native dispatch.

**Still viable to adopt**:
- `disable-model-invocation: true` — already adopted, working
- `allowed-tools` — already adopted, working
- `${CLAUDE_SKILL_DIR}` — works but limited value (cache paths, fragile traversal)

**Deprioritized** (Tasks 4-5 from plan):
- Native dispatch migration — cancelled (NO-GO)
- Dynamic injection — low priority, current ohno MCP calls work fine
