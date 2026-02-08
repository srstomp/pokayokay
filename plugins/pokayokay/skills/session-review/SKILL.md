---
name: session-review
description: Use after completing work sessions to analyze agent behavior patterns, prepare session handoffs for continuity, document completed work, identify blockers, or preserve context for the next session.
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

## Key Principles

- Compare plan vs reality — what was expected vs what happened
- Assess work quality — were reviews passing? How many cycles?
- Detect patterns — recurring issues across multiple sessions
- Learn from checkpoints — were pauses at the right moments?

## Quick Start Checklist

1. Gather session data (git log, ohno activity, session notes)
2. Analyze execution against original task plan
3. Evaluate quality metrics (review pass rate, cycle count)
4. Identify patterns (positive and negative)
5. Generate actionable improvements

## References

| Reference | Description |
|-----------|-------------|
| [pattern-library.md](references/pattern-library.md) | Common session patterns and their fixes |
| [analysis-scripts.md](references/analysis-scripts.md) | Scripts for extracting session metrics |
| [review-report-template.md](references/review-report-template.md) | Template for session review reports |
| [handoff-guide.md](references/handoff-guide.md) | Handoff state documentation, templates, ohno integration |
