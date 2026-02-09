# Changelog

All notable changes to pokayokay are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
