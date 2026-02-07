---
name: spike
agents: [yokay-spike-runner]
description: Time-boxed technical investigation with structured output. Use for feasibility studies, architecture exploration, integration assessment, performance analysis, or risk evaluation. Creates spike tasks in ohno, enforces time-boxing, generates spike reports, and creates actionable follow-up tasks.
---

# Spike

Structured technical investigation to reduce uncertainty. Answer specific questions, not "explore X."

## Key Principles

- Every spike answers a specific, measurable question
- Strict time-box (default 4h) — produce a decision at the end, even if incomplete
- Output is a decision (GO/NO-GO/PIVOT/MORE-INFO), not a general exploration
- Create follow-up tasks from findings, not just a report

## When NOT to Use

- **Multi-day evaluations** — Use `deep-research` for comprehensive technology evaluations with stakeholder reports
- **Already know what to build** — Skip straight to implementation; spikes are for reducing uncertainty, not planning known work
- **Bug investigation** — Use `error-handling` or `/fix`; bugs have reproduction steps, spikes have open questions

## Quick Start Checklist

1. Define the question clearly (what are we trying to learn?)
2. Set a time-box (hours, not days — use deep-research for multi-day)
3. Identify evaluation criteria upfront
4. Investigate with focused experiments or prototypes
5. Checkpoint at 50% — assess progress, decide if pivoting
6. Produce mandatory conclusion: GO / NO-GO / PIVOT / MORE-INFO

## Mandatory Outputs

- **Decision**: GO, NO-GO, PIVOT, or MORE-INFO
- **Evidence**: What was tested, results observed
- **Follow-up tasks**: Created in ohno if GO
- **Report**: Saved to `.claude/spikes/[name]-[date].md`

## References

| Reference | Description |
|-----------|-------------|
| [spike-types.md](references/spike-types.md) | Feasibility, architecture, integration, performance spikes |
| [question-patterns.md](references/question-patterns.md) | How to frame good spike questions |
| [output-templates.md](references/output-templates.md) | Spike report templates and examples |
