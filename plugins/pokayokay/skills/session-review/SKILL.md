---
name: session-review
description: Analyzes completed agent sessions to identify what went well, what went wrong, and patterns to improve. Reads from .claude/ folder (session logs, progress.md, git history) and produces actionable insights. Use after completing work sessions to learn from agent behavior and improve future runs.
---

# Session Review

Analyze agent sessions to extract lessons and improve future performance.

## Purpose

After an agent session, this skill helps you:
- Understand what the agent actually did vs what was planned
- Identify good patterns to reinforce and bad patterns to prevent
- Find wasted effort and context efficiency issues
- Generate improvements for skills, prompts, and workflows

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
