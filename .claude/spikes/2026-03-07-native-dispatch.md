# Spike: Native Dispatch via context: fork

**Decision**: MORE-INFO
**Date**: 2026-03-07
**Time spent**: 30min

## Question

Can pokayokay use Claude Code's native `context: fork` + `agent` frontmatter to replace manual Task tool dispatch for standalone agent skills?

## Findings

### 1. Plugin cache blocks in-session testing

Plugin skills load from `/Users/steve/.claude/plugins/cache/pokayokay/pokayokay/0.16.0/skills/`, not from the development directory. Source file modifications are ignored until the plugin is reinstalled. Live reload only works for `--add-dir` skills.

**Impact**: Cannot validate `context: fork` behavior without either:
- Reinstalling the plugin and starting a new session
- Using `claude --plugin-dir ./plugins/pokayokay` for dev mode loading

### 2. `${CLAUDE_SKILL_DIR}` resolves correctly

The "Base directory for this skill" line confirms `${CLAUDE_SKILL_DIR}` resolves to the skill's directory. For cached plugins: `/Users/steve/.claude/plugins/cache/pokayokay/pokayokay/0.16.0/skills/feature-audit`. For dev mode: would be the source path.

**Usable for**: Referencing bundled scripts, templates, or reference files within a skill. However, referencing *other* plugin directories (like `agents/templates/`) would require `${CLAUDE_SKILL_DIR}/../../agents/templates/` — fragile path traversal.

### 3. `!`command`` — not tested

Dynamic injection requires preprocessing at skill load time. Cannot test without plugin reinstall. The docs don't explicitly exclude plugin skills, so it likely works.

### 4. `context: fork` + `agent` — theoretical analysis

From the docs:
- `context: fork` runs the skill content as the task prompt in a forked subagent
- `agent` specifies which agent definition to use (built-in or custom from `.claude/agents/`)
- The forked agent gets CLAUDE.md but NOT conversation history

**Open questions**:
- Does `agent: yokay-auditor` resolve to `plugins/pokayokay/agents/yokay-auditor.md`?
- Does the `skill:` field in commands interact with `context: fork` on the referenced skill?
- Does the forked agent have access to MCP servers (ohno)?

### 5. Key architectural concern: command vs skill interaction

pokayokay separates commands (workflow steps) from skills (domain knowledge). The command `audit.md` has `skill: feature-audit` which loads the skill content. If `context: fork` is on the skill, what happens?

Option A: The entire skill runs in a fork, command instructions in main context
Option B: Both command and skill run in the fork
Option C: `context: fork` is ignored when loaded via `skill:` reference

This interaction is undocumented and needs empirical testing.

## Follow-up Required

### Test Plan (for fresh session)

```bash
# 1. Start dev mode session
claude --plugin-dir ./plugins/pokayokay

# 2. Test context: fork (modify feature-audit/SKILL.md first)
/pokayokay:audit

# 3. Observe: did it fork? Did yokay-auditor agent load? MCP access?

# 4. Test dynamic injection (add !`command` to a skill)
# 5. Test ${CLAUDE_SKILL_DIR} variable resolution
```

### Specific test modifications

Add to `plugins/pokayokay/skills/feature-audit/SKILL.md` frontmatter:
```yaml
context: fork
agent: yokay-auditor
```

Add to skill body:
```markdown
Skill directory: ${CLAUDE_SKILL_DIR}
Project status: !`npx @stevestomp/ohno-cli status 2>/dev/null || echo "ohno unavailable"`
```

## Recommendation

**MORE-INFO** — The spike couldn't complete due to the plugin cache architecture. The three features are plausible based on docs but need empirical validation in a fresh `--plugin-dir` session.

**Safe to adopt now** (from Tasks 1-2, already committed):
- `disable-model-invocation: true` — confirmed working, no cache issue
- `allowed-tools` — confirmed working, no cache issue

**Needs fresh session testing**:
- `context: fork` + `agent` for native dispatch
- `!`command`` for dynamic injection
- `${CLAUDE_SKILL_DIR}` for template references (confirmed resolving, but usefulness limited by cache paths)
