# Memory Orchestration Design

**Date**: 2026-02-16
**Status**: Approved
**Scope**: Approach A — Rule Engine + Memory Curation

## Context

Claude Code has native memory features that pokayokay wasn't leveraging:
- **Auto memory** (`~/.claude/projects/<project>/memory/`) — Claude's self-authored notes, 200-line MEMORY.md loaded per session
- **`.claude/rules/*.md`** — Modular, path-scoped rules with glob frontmatter
- **CLAUDE.md imports** via `@path/to/file` syntax

pokayokay had a three-layer memory model (ohno ephemeral state, chain state file, memory directory) but was:
- Writing memory files Claude doesn't automatically load (recurring-failures.md, chain-learnings.md)
- Not producing `.claude/rules/` at all
- Not curating MEMORY.md (200-line budget unenforced)
- Not reading memory back to inform skill routing

## Approaches Considered

### Approach A: Rule Engine + Memory Curation (Chosen)

Graduate confirmed patterns to `.claude/rules/`, curate MEMORY.md, improve skill routing with memory reads. ~5-7 tasks, builds on existing hooks.

### Approach B: Full Memory Lifecycle (Deferred)

Everything in A plus pre-session memory injection, decision promotion (ohno → auto memory), memory decay agent, cross-session pattern detection. ~10-14 tasks.

**Why A over B**: A is B's prerequisite — every B feature assumes rule graduation and MEMORY.md curation exist. B's unique additions are speculative:
- Pre-session injection has nothing to inject until A produces curated content
- Decision promotion needs heuristics ("which decisions are durable?") that require data from A in production
- Memory decay agent adds maintenance cost; A's rotation caps may suffice
- Cross-session pattern detection is a small addition (~1 function in bridge.py), doesn't need full B scope

Decision promotion was identified as the most valuable B feature to pull into A later.

### Approach C: Intelligence Loop (Deferred)

Everything in A + B plus memory-informed agent dispatch, cross-project user-level rules, active memory queries during execution, memory quality scoring. ~20+ tasks.

**Why not C**: Premature. No data yet on which memory entries get used. Cross-project rules need careful scoping. Memory quality scoring requires instrumentation overhead.

## Design

### 1. Rule Graduation Pipeline

**New hook action: `graduate-rules.sh`**
- Triggered from bridge.py after `write_recurring_failure_to_memory()` hits threshold (3+ occurrences)
- Input: failure category, pattern description, affected file paths
- Output: creates/updates `.claude/rules/pokayokay/<category>.md`

**Rule file format** (native Claude Code path-scoped rules):
```markdown
---
paths:
  - "plugins/pokayokay/hooks/**/*"
---

# Hook Development Rules

- Always run integration tests after modifying hook actions
- bridge.py changes require testing both chain and non-chain scenarios
```

**Directory structure**:
```
.claude/rules/
└── pokayokay/           # pokayokay-managed rules (generated)
    ├── hooks.md          # Path-scoped to hooks/
    ├── skills.md         # Path-scoped to skills/
    ├── agents.md         # Path-scoped to agents/
    └── testing.md        # Project-wide (no paths: frontmatter)
```

**Graduation logic**:
1. bridge.py already tracks failures by category with counts in `pokayokay-review-failures.json`
2. When count >= 3, call `graduate-rules.sh` with category + details
3. Script checks if rule file exists → append if yes, create if no
4. Rule files are checked into git (shared with team)

Existing `recurring-failures.md` stays as the raw log. Rules are the curated, actionable output.

### 2. MEMORY.md Curation

**New hook action: `curate-memory.sh`**
- Triggered on SessionEnd, after chain-learnings are written
- Enforces section structure, per-section line budgets, overflow to topic files

**MEMORY.md template** (pokayokay-owned sections):
```markdown
# Memory

## Completed Work
<!-- pokayokay: managed by session-chain hooks -->
- [epic/story]: [brief] (date, status)

## Key Decisions
<!-- pokayokay: promoted from session handoffs -->
- [decision]: [rationale] — affects [what]

## Architecture Notes
<!-- pokayokay: stable project structure -->
- [key fact]

## Active Patterns
<!-- pokayokay: graduated to .claude/rules/ when confirmed -->
- [pattern]: see .claude/rules/pokayokay/[file].md

## Recent Bug Fixes
<!-- pokayokay: rotated, max 5 entries -->
- [fix]: (date)

## Topic Index
<!-- pokayokay: links to detail files -->
- See `memory/chain-learnings.md` for session history
- See `memory/spike-results.md` for spike outcomes
- See `memory/recurring-failures.md` for failure patterns
```

**Per-section line budgets** (total ~130, leaving ~70 for Claude's auto-memory):
- Completed Work: 20 lines
- Key Decisions: 40 lines
- Architecture Notes: 30 lines
- Active Patterns: 15 lines
- Recent Bug Fixes: 15 lines
- Topic Index: 10 lines

**Overflow handling**: When a section exceeds its limit, oldest entries move to corresponding topic file (e.g., Key Decisions overflow → `memory/decisions-archive.md`).

**Coexistence principle**: `<!-- pokayokay: -->` comments mark pokayokay-managed sections. Content outside those sections is Claude's auto-memory territory and left untouched.

### 3. Memory-Informed Skill Routing

**Modify existing: `suggest-skills.sh`** (no new hook)

**Memory sources consulted**:

| Source | Signal | Effect |
|--------|--------|--------|
| `memory/spike-results.md` | GO/NO-GO decisions | Suppress spike suggestion if question already answered; surface prior conclusion |
| `memory/recurring-failures.md` | Failure patterns by category | Boost skills that address the failure pattern |
| `.claude/rules/pokayokay/*.md` | Graduated rules | Mention relevant path-scoped rules in suggestion output |
| `memory/chain-learnings.md` | Recent session outcomes | Flag risk if same skill failed for same story last session |

### 4. Changelog

The discussion, approaches considered, and rationale are documented in CHANGELOG.md under the release that implements this design.

## Principles

1. **Orchestrate, don't replace** — manage the structure of Claude Code's native features, don't build parallel systems
2. **pokayokay owns structure, Claude fills content** — MEMORY.md sections are managed by hooks; Claude's auto-memory writes are preserved
3. **Path-scoped rules via native frontmatter** — leverage Claude Code's `paths:` glob support
4. **No new agents** — all memory management runs in existing hooks
5. **Graduate, don't duplicate** — recurring-failures.md is the raw log, `.claude/rules/` is the curated output
