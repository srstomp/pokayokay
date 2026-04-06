---
name: session-review
description: "Generates session summary reports, handoff documents with key decisions and blockers, and improvement recommendations by analyzing git history, ohno task activity, and agent behavior patterns. Use when wrapping up a session, preparing a handoff, reviewing what happened, writing session notes, or generating an end-of-day summary."
---

# Session Review & Handoff

Analyze agent sessions and prepare context handoffs for session continuity.

## Purpose

This skill serves two complementary workflows:

**Review** (`/pokayokay:review`) — Retrospective analysis:
- Understand what the agent actually did vs what was planned
- Identify good patterns to reinforce and bad patterns to prevent
- Find wasted effort and context efficiency issues
- Generate improvements for skills, prompts, and workflows

**Handoff** (`/pokayokay:handoff`) — Forward-looking context preservation:
- Document completed work and in-progress state
- Capture decisions, blockers, and next steps
- Track skill usage and ad-hoc work
- Prepare context for the next session or agent

## Quick Start Checklist

1. Gather session data:
   ```bash
   git log --since="8 hours ago" --oneline --stat
   ```
   Also pull ohno activity: MCP `get_session_context()` and `get_task()` for each worked task.
2. Compare execution against the original task plan — note deviations and unplanned work.
3. Evaluate quality metrics: review pass rate, implementation cycle count, time per task.
4. Identify patterns (positive and negative) — check [pattern-library.md](references/pattern-library.md) for known patterns.
5. Generate a report using the [review-report-template.md](references/review-report-template.md). Example output:
   ```
   ## Session Summary — 2025-02-04
   Tasks completed: 3/5 | Review pass rate: 67% | Avg cycles: 2.3
   ### Blockers: CI timeout on integration tests (resolved)
   ### Next: Complete auth middleware refactor (task-abc123)
   ```
6. **Validate**: Confirm all in-progress tasks have WIP data saved in ohno before closing the session.

## References

| Reference | Description |
|-----------|-------------|
| [pattern-library.md](references/pattern-library.md) | Common session patterns and their fixes |
| [analysis-scripts.md](references/analysis-scripts.md) | Scripts for extracting session metrics |
| [review-report-template.md](references/review-report-template.md) | Template for session review reports |
| [handoff-guide.md](references/handoff-guide.md) | Handoff state documentation, templates, ohno integration |
