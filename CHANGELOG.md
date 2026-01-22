# Changelog

All notable changes to pokayokay are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `/pokayokay:revise` command for plan revision with impact analysis
- `plan-revision` skill for guided plan modifications
- Two revision modes: explore (guided) and direct (fast path)
- Impact analysis showing ticket diff, risk assessment, and dependency graphs

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
- `/pokayokay:work` - Orchestrated work sessions (supervised/semi-auto/autonomous)
- `/pokayokay:audit` - Feature completeness checking
- Integration with ohno MCP for task management
- Basic skill routing for common task types
