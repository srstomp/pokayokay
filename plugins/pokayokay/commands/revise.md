---
description: Revise existing plan through guided conversation or directed changes
argument-hint: [--direct]
skill: plan-revision
---

# Plan Revision Workflow

Revise the current plan with impact analysis before making changes.

**Mode**: `$ARGUMENTS` (default: explore)

## Mode Detection

Parse `$ARGUMENTS`:
- `--direct` flag → Direct mode (you know what to change)
- No flag → Explore mode (guided discovery)
- Specific statement without flag → Auto-detect direct mode

If user says something specific like "I want to remove feature X" without `--direct`, treat as direct mode.