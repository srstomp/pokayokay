# Token And Context Budgeting

Use subagents when isolation, parallelism, or a specialized review is worth the
extra model work. Stay inline when the task is small and the result can be
verified with local commands.

## Runtime Facts

- Codex subagents run separate model/tool work and consume more tokens than a
  comparable single-agent run. Codex only spawns subagents when explicitly
  asked, and custom agents inherit model/reasoning settings when omitted.
- Claude Code subagents also use separate context windows, which preserves the
  main conversation but adds latency while the agent gathers its own context.
- Codex skills use progressive disclosure: only skill names/descriptions start
  in context; full `SKILL.md` content is read only when the skill is selected.
- Claude Code cost guidance recommends specific prompts, smaller focused tasks,
  clearing history between unrelated tasks, and compaction when context grows.

## Dispatch Budget Rules

| Situation | Cheapest good path | Why |
|-----------|--------------------|-----|
| Tiny one-off edit touching <=3 files | `/quick` inline | Avoids subagent startup/context duplication |
| Bug with unclear root cause | `/fix` + `systematic-debugging` | Debugging discipline prevents repeated failed fix loops |
| Broad codebase question | `yokay-explorer` / Codex `explorer` | Read-only focused context, cheaper model class where available |
| Implementation with clear AC | One implementer | Fresh context helps, but avoid extra reviewers until code exists |
| Complex task touching multiple modules | Design review, implementer, then reviewers | Upfront design review reduces expensive rework |
| Independent backlog batch | `/work -n 2` or `-n auto` | Parallelism costs more tokens; use only when wall-clock matters |
| Flaky test output or CI logs | Test runner or inline summarized logs | Do not paste full logs unless the failure requires it |

## Parallelism Limits

Parallel execution multiplies context and tool work. Prefer:

- `1` for default sessions and uncertain tasks.
- `2-3` for independent tasks with disjoint files.
- `auto` for long supervised/semi-auto sessions where pokayokay can adjust.
- Avoid `4-5` unless the backlog is independent and token budget is acceptable.

Do not parallelize tasks that share files, packages, migrations, schemas, or
review gates. The merge/review cost often erases any wall-clock gain.

## Handoff And Compaction

- Save decisions and WIP to ohno instead of keeping long narrative context in
  the live conversation.
- Prefer concise handoff notes: goal, current state, files touched, blockers,
  next command.
- Use session chaining before context pressure causes quality loss.
- Summarize long logs before dispatching reviewers; include only the failure,
  command, expected/actual behavior, and relevant file paths.

## Reporting

pokayokay writes subagent usage to `.pokayokay/pokayokay-token-usage.json` and
prints a session summary when available. Treat `?` token counts as unavailable
runtime telemetry, not zero usage.

Session reviews should look for:

- Expensive agents used for small tasks.
- Repeated fixer attempts that should have stopped for root-cause analysis.
- Parallel runs that caused conflicts or duplicate exploration.
- Skills loaded unnecessarily when `/quick` would have been enough.

## Documentation References

- Codex subagents: https://developers.openai.com/codex/subagents
- Codex skills: https://developers.openai.com/codex/skills
- Claude Code subagents: https://docs.anthropic.com/en/docs/claude-code/sub-agents
- Claude Code costs: https://docs.anthropic.com/en/docs/claude-code/costs
