# Changelog

All notable changes to pokayokay are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.26.0] - 2026-07-04

### Added
- **Design-review pipeline stage in /work** — the `yokay-design-reviewer`
  stage is now wired into the /work pipeline ahead of implementation, with
  `NEEDS_REDESIGN` escalation handling when the implementer finds the
  pre-validated approach infeasible.
- **Test runner + CI** — `tests/run-tests.sh` runs the full shell test suite
  in one command, and a CI workflow runs it on every push.
- **Machine-parseable review verdicts** — reviewer agents now emit a
  `VERDICT:` terminal line, and bridge.py parses it robustly (including a
  `BLOCKED` verdict path) instead of relying on free-form prose.
- **Dispatch-failure protocol** — four failure classes with a retry-once
  policy and a `set_blocker` fallback when the retry also fails, plus a
  one-shot brainstormer dispatch (no open-ended re-brainstorm loops).
- **Structured parallel-conflict detection** — implementer handoffs report
  `packages_touched`, which the coordinator unions with the existing
  file-overlap heuristic when deciding what can run in parallel.
- **work.md structure tests** — new tests pin the progressive-disclosure
  extraction and the plugin-qualified dispatch-ID doc contract.

### Changed
- **Agent model policy alignment** — agents now follow explicit model tiers:
  `inherit` for reasoning-heavy agents, `sonnet` for standard pipeline work,
  `haiku` for fast read-only scans (explorer, test-runner).
- **Re-landed PR #8 skill overhaul** — restored the skill slimming work:
  domain reference files removed, `disable-model-invocation` on process
  skills, `allowed-tools` on read-only skills, CSO trigger-style descriptions
  and "When NOT to Use" sections.
- **Coordinator-supplied review baseline** — reviewers receive an explicit
  `BASE_COMMIT` from the coordinator and review the working tree against it
  (working-tree-inclusive diff), with closed `BLOCKED` triggers and
  mode-aware escalation instead of guessing a baseline.
- **work.md progressive disclosure** — chain-state details and kaizen
  review-failure handling extracted to `chain-state.md` and
  `kaizen-review-failures.md` references, and the duplicated brainstorm-gate
  text deduplicated, keeping work.md lean.
- **Spike skill canonicalization** — spike time-box values, report paths, and
  the decision enum are now canonical and consistent across the skill and its
  references.

### Fixed
- **Hook payload and routing repair** — bridge.py now parses MCP content-block
  responses (not just plain JSON), matches plugin-prefixed tool names
  (`mcp__plugin_pokayokay_ohno__*` alongside `mcp__ohno__*`), and normalizes
  Task tool output across both runtimes (Claude Code and Codex).
- **Unattended pipeline and session chaining** — repaired the unattended work
  mode path and session-chaining handoff so headless runs proceed and chain
  correctly across sessions.
- **Test suite repair** — fixed broken and stale shell tests so the whole
  suite passes again.
- **CLI codex and Windows fixes** — corrected Codex install handling and
  Windows path issues in the setup wizard.
- **Stale pre-ohno references removed** — remaining mentions of the old
  `tasks.db` / `features.json` state files and dead skill routes are gone;
  everything now points at ohno-backed task state.
- **session-review allowed-tools completed** — the session-review skill's
  `allowed-tools` list now includes every tool the workflow actually uses.

### Documentation
- **Hook documentation truth pass** — hook docs (CLAUDE.md flow diagram and
  hook references) corrected to match what bridge.py actually routes.

## [0.25.0] - 2026-06-10

### Added
- **Runtime notes for Codex** — the nine dispatch-referencing skills
  (work-session, spike, planning, security-audit, feature-audit,
  browser-verification, error-handling, testing-strategy, cloud-infrastructure)
  and the subagent-dispatch reference now document both runtimes: Task-tool
  dispatch with `subagent_type: "pokayokay:yokay-<name>"` on Claude Code, and
  inline execution of the agent's role (Behavioral Defaults, Critical Rules,
  Output Contract) on Codex, where subagent dispatch does not exist.
- **AGENTS.md** — accurate Codex guidance for this repository: the Codex
  surface (skills, ohno MCP, bridge.py hooks), correct install/dev commands,
  and how to run the work pipeline inline without subagent dispatch.

### Changed
- **Implementer model: sonnet → opus** — `yokay-implementer` now runs on Opus.
  Opus is markedly stronger at long-horizon agentic coding, and a single pass
  that survives review is cheaper than a Sonnet pass plus a fixer/review retry
  cycle. Explorer and test-runner stay on Haiku; other agents are unchanged.

### Fixed
- **Command frontmatter parsing** — `/work` and `/plan` had unquoted
  `argument-hint` values starting with `[`, which fail YAML parsing and
  silently dropped all frontmatter (including the `skill:` binding) at
  runtime. Values are now quoted.
- **Codex install path** — installing on Codex takes two steps:
  `codex plugin marketplace add .` from the repository checkout, then
  `codex plugin add pokayokay@pokayokay`. Docs previously stopped at the
  marketplace step, which registers the source without installing the plugin.
  The setup wizard now runs both steps, and install detection requires the
  `[plugins."pokayokay@..."]` record in `~/.codex/config.toml` rather than
  treating a marketplace entry alone as installed. Also clarifies that the npm
  package is the setup CLI rather than the Codex plugin payload.
- **Claude marketplace alias** — update install examples and setup code to use
  `pokayokay@pokayokay`, matching the configured marketplace alias.
- **Codex setup detection** — detect pokayokay through Codex's current
  `~/.codex/config.toml` marketplace entry while preserving the legacy
  `~/.agents/plugins/marketplace.json` fallback.

## [0.24.0] - 2026-04-26

### Added
- **Disciplined workflow gates** — verification-before-completion enforced in
  the implementer, fixer, brainstormer, and quality reviewer; new
  finishing-branch, systematic-debugging, and verification-before-completion
  gate sections; approval-policy and token-budgeting references for
  work-session.

### Fixed
- **Codex hook approval policy** — tightened `PermissionRequest` handling in
  bridge.py to auto-decide only obvious allow/deny cases, with runtime payload
  normalization tests and install edge-case fixes.

## [0.23.0] - 2026-04-26

### Added
- **Codex Runtime Support** — Pokayokay can now be installed/configured for Codex alongside existing Claude Code support
  - Added Codex plugin manifest (`plugins/pokayokay/.codex-plugin/plugin.json`), plugin-local ohno MCP config, and Codex hook config while preserving the existing Claude plugin manifest
  - Setup wizard (`npx pokayokay`) detects Claude Code, Codex, or both and configures the selected runtimes
  - Added Codex `config.toml` MCP helpers for `~/.codex/config.toml` with idempotent CRLF-tolerant upserts
  - Hook bridge now normalizes Claude-style and Codex-style hook payloads (top-level keys, tool aliases, and inner shell-command field aliases like `cmd` → `command`) before routing to existing handlers
  - Output extraction falls through to Codex's `tool_response.output` when Claude's `content` envelope is absent
  - Detect Codex installs via `~/.agents/plugins/marketplace.json` so doctor/setup do not falsely report Codex as not installed after a successful run
  - Added focused compatibility tests for Codex plugin files, CLI dual-runtime helpers (Codex MCP read/write/upsert, CRLF idempotence), and hook payload normalization (Claude + Codex shapes, Codex Bash payloads with `cmd` field)

### Changed
- **Runtime-agnostic state directory** — chain state, token usage, review failure tracking, and pokayokay config now read `.pokayokay/<file>` first and fall back to `.claude/<file>` for legacy Claude Code projects. New writes default to `.pokayokay/`; pre-existing files in `.claude/` are preserved in place. `delete_chain_state()` cleans up both locations.
- **Plugin install messaging** — Codex install reports "✓ Codex marketplace entry written" with the activation hint to run `codex plugin install pokayokay`, replacing the misleading "Plugin installed" line that was shown for marketplace-only writes.

### Fixed
- **Codex shell hooks silently no-op'd** — `normalize_hook_input` now mirrors Codex's `tool_input.cmd` (and `shell_command` / `command_line` aliases) to `tool_input.command` so pre-commit lint and WIP commit/test/error capture see Codex Bash calls.
- **`extract_output_text` short-circuit** — the previous default of `content = []` made the `output`/`text` fallback unreachable, hiding Codex's response shape.
- **`.pokayokay/` not gitignored** — added alongside `.claude/` so newly-created runtime state never lands in version control.
- **Marketplace entry path** — Codex marketplace entries now use an absolute path resolved through `locatePluginSource()` (cwd → CLI sibling fallback) and fail fast with an actionable "clone the repo and re-run" message instead of writing a broken relative path.
- **User-owned marketplace JSON preserved** — if `~/.agents/plugins/marketplace.json` is invalid JSON, it is copied to `marketplace.json.backup-<timestamp>` before being replaced with a fresh default.
- **Bash test trap hardening** — `bridge-runtime-normalization.test.sh` uses `trap 'rm -rf -- "$TEST_DIR"' EXIT` (single-quoted, double-quoted variable, `--` guard) to avoid word-splitting/leading-dash hazards.

## [0.22.0] - 2026-04-05

### Added
- **Pre-Implementation Design Review** — New `yokay-design-reviewer` agent validates implementation approach against codebase patterns and design skills before the implementer starts coding
  - Read-only, skill-aware agent that searches for and consults relevant design skills
  - New `design-review-prompt.md` dispatch template
  - Implementer receives pre-validated approach via `{APPROACH}` template variable
  - New `NEEDS_REDESIGN` escalation status when approach is infeasible
  - Quality reviewer expanded with design compliance post-check
  - Pipeline: Brainstorm? → **Design Review (new)** → Implementer → Spec Review → Quality Review (+design)
  - Agent count: 13 → 14
- **Agent Color Coding** — All 14 agents now have `color` frontmatter for UI identification
  - Magenta (creative): brainstormer, design-reviewer
  - Cyan (planning): planner, explorer
  - Green (execution): implementer, fixer, spike-runner, test-runner, browser-verifier
  - Yellow (validation): spec-reviewer, quality-reviewer, auditor
  - Blue (review): reviewer
  - Red (security): security-scanner
- **Talos Integration Fields** — Planner now outputs `packages_touched` and `strategy` per task
  - `packages_touched` enables conflict-aware parallel batching in Talos
  - `strategy` (tdd/direct) enables per-task override for mixed frontend/backend slices

## [0.19.0] - 2026-03-24

### Changed
- **Vertical Slice Task Decomposition** — Planner now requires every task to be a vertical slice (UI + API + DB for one feature), never horizontal layers (all components, then all APIs)
  - New Critical Rule in `yokay-planner`: "NEVER create horizontal-layer tasks"
  - New "Vertical Slice Rule" section with WRONG/RIGHT examples and exception for shared infrastructure
  - Dependency mapping rewritten: shared infrastructure → vertical slices (not layer → layer)
  - Task decomposition example replaced: 12-task horizontal auth → 4-task vertical auth
- **Runtime Verification** — Agents must verify runtime behavior, not just file existence
  - New Critical Rule in `yokay-implementer`: "NEVER write tests that only check file existence"
  - `yokay-spec-reviewer` gains "End-to-End Completeness" check (section 4)
  - `yokay-quality-reviewer` gains runtime behavior test quality check
- **Keyword-Based Skill Routing** — Replaced layer-based routing (`backend → api-design`) with content keyword routing across `work.md`, `subagent-dispatch.md`, and `skill-routing.md`

### Fixed
- **Stale task types in reference docs** — `database-schema.md` had `frontend/backend/database/design/devops/qa/documentation` task types; actual ohno schema uses `feature/bug/chore/spike/test`. Fixed reference to match reality.
- **Kanban template dropdown** — Filter options now match ohno's actual task types
- **Kanban setup example** — Example tasks rewritten as vertical slices

### Added
- Anti-pattern: "Horizontal layer tasks" added to both `planning/anti-patterns.md` and `work-session/anti-patterns.md`
- Anti-pattern: "File-existence-only tests" added to `work-session/anti-patterns.md`

### Docs
- Audited and fixed documentation accuracy across 15 files: corrected `--plugin-dir` paths, updated hook flow diagrams with 7 missing actions from v0.13-v0.16, fixed npm scope, removed stale fork-test artifacts from NO-GO `context:fork` spike

## [0.18.1] - 2026-03-18

### Removed
- **figma-plugin skill** — Zero entry points (no command, not in planner routing, no agent dispatch). Hyper-specialized domain with no usage path.
- **performance-optimization skill** — Zero entry points. Orphaned skill with generic principles Claude already knows.

### Fixed
- **Planner skill routing gaps** — Added `cloud-infrastructure` (cloud, aws, serverless, lambda, ecs, cdk) and `sdk-development` (sdk, package, extract, publish, npm) to planner's keyword routing table. Tasks with these keywords were previously unrouted.

## [0.18.0] - 2026-03-18

### Added
- **auto-improve** — Autonomous skill improvement system inspired by Karpathy's autoresearch
  - `eval.py`: Core eval runner with scenario-based skill quality measurement
  - `judge.py`: LLM-as-judge with binary criteria, chain-of-thought-before-verdict, anti-slop checks
  - `structural.py`: Automated structural checks (line counts, required sections, description format)
  - `runner.py`: Loop orchestrator with adaptive/breadth/deep scheduling, portfolio dashboard, git integration
  - Uses `claude -p` (print mode) for API access — no separate API key needed
- **Per-skill eval files** for 3 pilot skills (15 scenarios each):
  - `planning/eval.json` — Tests PRD analysis, P0-P3 classification, skill routing, ambiguity flagging
  - `work-session/eval.json` — Tests orchestration, worktrees, mode selection, parallel dispatch
  - `api-design/eval.json` — Tests domain knowledge (baseline regression, validates -7% hypothesis)
- `improvement-program.md` — Human steering file for the improvement loop
- `dashboard.json` + `patterns.json` — Portfolio state and cross-skill learning

## [0.17.0] - 2026-03-12

### Changed
- **Agent Behavioral Defaults** — All 13 agents now have explicit disposition constraints and hard rules, inspired by [agency-agents](https://github.com/msitarzewski/agency-agents) personality-as-constraint pattern
  - `## Behavioral Defaults` section (2-4 per agent): disposition constraints that shape how agents think, not what they know
  - `## Critical Rules` section (3-5 per agent): hard "never" constraints for common failure modes
  - `## Output Contract`: consistent heading across all agents (renamed from Output Format / Report Format / Spike Report Format)
- **Implementer TDD Compression** — Replaced 60-line step-by-step TDD workflow with red/green TDD shorthand (~10 lines), trusting model knowledge per [Simon Willison's agentic patterns](https://simonwillison.net/guides/agentic-engineering-patterns/red-green-tdd/)
- **Fixer Output Consolidation** — Merged dual output sections (Output Format + Return Minimal Output) into single Output Contract

### Highlights
- Spec reviewer: "Default to FAIL. The implementer must prove compliance, not you."
- Quality reviewer: "Default to PASS unless you'd flag it in a real code review. Don't manufacture issues."
- Implementer: "NEVER skip the red phase. If a test passes before implementation, the test is wrong."
- Fixer: "NEVER change more than one thing per attempt. Isolate your variables."

## [0.15.0] - 2026-02-26

### Changed
- **Graduated Pipeline** — `/quick` and `/fix` no longer use the full agent pipeline, reducing context consumption by 76-95%
  - `/quick` now works inline (no agent dispatch, no skill reference loading). ~200 lines context vs ~1,400 previously.
  - `/fix` now uses a light pipeline by default (implementer agent only, coordinator self-reviews). ~500 lines context vs ~1,400+ previously.
  - `/fix --thorough` engages the full agent pipeline (implementer + spec review + quality review) for complex bugs.
  - `/work` and `/hotfix` are unchanged (full pipeline).

## [0.13.0] - 2026-02-16

### Added
- **Memory Orchestration System** — pokayokay now manages Claude Code's native auto memory directory and `.claude/rules/`
  - **Rule graduation pipeline**: Recurring failure patterns (3+ occurrences) automatically become path-scoped `.claude/rules/pokayokay/*.md` files, natively loaded by Claude Code every session
  - **MEMORY.md curation**: Enforced section structure with per-section line budgets (200-line total), overflow to topic files, coexistence with Claude's auto memory
  - **Memory-informed skill routing**: `suggest-skills.sh` reads spike results, failure patterns, and graduated rules to improve recommendations

### Design Decisions
- **Orchestrate, don't replace** — pokayokay manages the structure of Claude Code's native memory features rather than building parallel systems
- **Approach A (Rule Engine + Curation) chosen over B (Full Lifecycle) and C (Intelligence Loop)** — A is B's prerequisite; B's unique features (pre-session injection, memory decay agent, decision promotion) are speculative until A provides data on which memory entries actually get used. Decision promotion (ohno → auto memory) identified as the most valuable B feature to pull forward later.
- **Path-scoped rules via native frontmatter** — leverages Claude Code's `paths:` glob support rather than custom scoping logic
- **pokayokay owns MEMORY.md structure, Claude fills content** — sections marked with `<!-- pokayokay: -->` comments are managed by hooks; everything else is Claude's auto memory territory
- **No new agents** — all memory management runs in existing hooks (SessionEnd, post-review), avoiding the overhead of a yokay-memory-curator agent

## [0.12.0] - 2026-02-09

### Added
- **Chain Completion Audit**: When all tasks in a chain finish, `yokay-auditor` runs a completeness audit against the concept doc/PRD before declaring the chain done. Failed audits create remediation tasks and continue the chain.
- **Test Infrastructure Auto-Detection**: Planner now detects missing test infrastructure (no test config, test files, or test directories) and creates a "Setup test infrastructure" task as the first task, blocking all feature/bug tasks.
- **Infrastructure-First Ordering**: New reference section in task-breakdown.md documenting infrastructure tasks (test setup, DB schema, auth) that must precede implementation.

### Fixed
- **Design Task Routing in Unattended Mode**: Design tasks no longer stall unattended chains. Added "unattended" to auto-resolve path when design plugin is missing, and replaced "stop processing" with continue-loop behavior so the work loop continues after design commands complete.

## [0.11.0] - 2026-02-08

### Added
- **Cloud Infrastructure Skill**: AWS-primary cloud provisioning skill with 8 reference files covering service selection, CDK patterns, serverless, containers, IAM/security, storage/CDN, databases, and cost optimization
- **Anti-Rationalization Engineering**: Iron Laws, rationalization pre-rebuttals, and Red Flag STOP patterns added to testing-strategy, error-handling, architecture-review, and cloud-infrastructure skills
- **Pre-flight Validation**: `pre-flight.sh` hook checks MCP connectivity, git state, and disk space before unattended sessions
- **Crash Recovery Hook**: `recover.sh` detects stale in-progress tasks from crashed sessions and resets them
- **Cross-task Dependency Validator**: Pre-dispatch validation ensures parallel tasks don't share file dependencies
- **Reference File Size Lint**: `check-ref-sizes.sh` pre-commit hook blocks commits with reference files over 500 lines
- **Subagent Token Tracking**: Session summaries now include per-agent token usage, tool counts, and duration via bridge.py state file
- **Memory Integration**: Worktree memory symlinked to main repo; chain learnings written at session end

### Changed
- **Two-Stage Review Pipeline**: Split yokay-task-reviewer back into adversarial spec-reviewer + quality-reviewer for better "right thing vs well-built" separation
- **CSO Skill Descriptions**: Rewrote 18 of 22 skill descriptions to trigger-condition-only format (prevents the "Description Trap" where Claude follows description instead of loading skill)
- **Domain-Specific TDD**: Skills now include TDD patterns and review checklists relevant to their domain
- **Planning Skill Routing**: Added cloud-infrastructure to skill catalog, routing logic, and feature mapping
- **Reference File Splits**: Split 30+ oversized reference files across 5 skills (testing-strategy, ci-cd, api-integration, figma-plugin, sdk-development) to comply with 500-line guideline
- **Session Summaries**: Now persisted to ohno activity log and `.ohno/sessions/` directory for chain reports
- **Task Handoff Data**: Resume flow now includes task handoff notes for better session continuity

## [0.10.1] - 2026-02-07

### Changed
- **Plan Command Efficiency**: Reduced `plan.md` from 562 to 435 lines (-23%) by extracting design-plugin detection logic to on-demand reference file
- **Task Description Quality**: Added Section 4.5 requiring rich task/story descriptions with behavior, acceptance criteria, dependency context, and pattern hints
- **Story Description Quality**: Stories now require Given/When/Then acceptance criteria, edge cases, and explicit out-of-scope items
- Updated `task-breakdown.md` templates to match ohno MCP call format with required description sections

## [0.10.0] - 2026-02-06

### Added
- **Unattended Mode**: New `/work unattended` mode that never pauses (not even at epic boundaries) for overnight/headless runs
- **Proactive Context Shutdown**: Coordinator detects compaction and gracefully exits to chain rather than degrading quality

### Changed
- Mode parameter renamed from `autonomous` to `auto` (shorter, clearer)
- Session chaining now uses state file (`.claude/pokayokay-chain-state.json`) instead of environment variables
- Implementer template now instructs agents to prefer MCP tools over CLI commands (avoids Bash permission prompts)

### Fixed
- Session chaining was broken due to env vars not propagating to hook subprocess

## [0.9.0] - 2026-02-05

### Added
- `/pokayokay:revise` command for plan revision with impact analysis
- `plan-revision` skill for guided plan modifications
- Two revision modes: explore (guided) and direct (fast path)
- Impact analysis showing ticket diff, risk assessment, and dependency graphs
- **Session Resume**: `/pokayokay:work --continue` resumes interrupted sessions with saved WIP data
- **Headless Session Chaining**: Automatic session chaining configured via `.claude/pokayokay.json` with scope control (`--epic`, `--story`, `--all`)
- **Adaptive Parallel Sizing**: `-n auto` starts at 2 and adjusts based on task outcomes (min 2, max 4)
- **yokay-fixer agent**: Auto-retry on test failures with targeted fixes
- **Skill Lazy Loading**: Skills restructured with compact SKILL.md and `references/` subdirectories for reduced context usage
- **Headless Planning**: `/plan --headless` for autonomous PRD analysis with notable decision tracking
- **Plan Review**: `/plan --review` for diff-style interactive review of planning decisions

### Changed
- Parallel flag renamed from `-p` to `-n` (`-p` reserved for Claude CLI `--prompt`)
- All 23 skills reduced to <100 line core files with detailed content in `references/`
- Sub-agent count increased from 10 to 12 (added yokay-fixer, yokay-browser-verifier)

## [0.4.0] - 2026-01-21

### Added
- **Brainstorm Gate**: Conditional brainstorming for ambiguous tasks before implementation
  - Detects short descriptions, missing acceptance criteria, ambiguous keywords
  - Refines requirements before dispatching implementer
- **Two-Stage Review System**: Sequential spec and quality reviews
  - `yokay-spec-reviewer`: Verifies implementation matches requirements
  - `yokay-quality-reviewer`: Checks code quality, tests, conventions
  - Both must PASS before task completion
- **Pressure Testing Framework**: Automated testing for agent behavior
- **Subagent Execution Model**: Fresh context per task via Task tool dispatch
  - `yokay-implementer`: TDD implementation with isolated context
  - Implementer prompt template for consistent dispatch
- Documentation for subagent dispatch patterns

### Changed
- Work loop now dispatches implementer as subagent (not inline)
- Review process split into spec compliance + quality checks

## [0.3.3] - 2026-01-19

### Added
- Post-command hooks for audit task verification
- Auto-task creation for `/pokayokay:security`, `/pokayokay:a11y`, and other audit commands
- `verify-tasks.sh` hook action to ensure audit findings become tracked tasks

### Fixed
- Standardized on `/pokayokay:` command prefix (was inconsistent)

## [0.3.0] - 2026-01-18

### Added
- Restructured as marketplace plugin (srstomp/pokayokay)
- 10 specialized sub-agents for isolated execution:
  - `yokay-auditor` - L0-L5 completeness scanning
  - `yokay-brainstormer` - Task refinement
  - `yokay-explorer` - Fast codebase exploration (Haiku)
  - `yokay-implementer` - TDD implementation
  - `yokay-quality-reviewer` - Code quality checks (Haiku)
  - `yokay-reviewer` - Code review
  - `yokay-security-scanner` - OWASP scanning
  - `yokay-spec-reviewer` - Spec compliance (Haiku)
  - `yokay-spike-runner` - Time-boxed investigations
  - `yokay-test-runner` - Test execution (Haiku)
- Hook system via Claude Code native hooks
- Intelligent hooks: skill suggestions, spike detection, knowledge capture
- Audit gate for quality thresholds at story/epic boundaries

### Changed
- Migrated from soft hooks (LLM memory) to hard hooks (guaranteed execution)
- Agents use Haiku model where appropriate for cost optimization

## [0.2.0] - 2026-01-15

### Added
- Multi-dimensional auditing (Accessibility, Testing, Documentation, Security, Observability)
- L0-L5 completeness levels for feature verification
- 25 specialized skills with automatic routing
- Spike protocol with mandatory decisions (GO/NO-GO/PIVOT/MORE-INFO)
- Session management with handoff notes

### Changed
- Expanded audit from single-dimension to 5 dimensions
- Skills now auto-route based on task keywords

## [0.1.0] - 2026-01-10

### Added
- Initial release
- `/pokayokay:plan` - PRD analysis and task creation
- `/pokayokay:work` - Orchestrated work sessions (supervised/semi-auto/auto)
- `/pokayokay:audit` - Feature completeness checking
- Integration with ohno MCP for task management
- Basic skill routing for common task types
