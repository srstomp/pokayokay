# Task Implementation Assignment

You are being dispatched by the coordinator to implement a specific task. Read the details below carefully and ask questions if anything is unclear before proceeding.

---

## Task Information

**Task ID**: {TASK_ID}
**Title**: {TASK_TITLE}

### Description

{TASK_DESCRIPTION}

### Acceptance Criteria

{ACCEPTANCE_CRITERIA}

---

## Context

### Where This Fits

{CONTEXT}

### Recommended Skill

{RELEVANT_SKILL}

> **On-demand references**: The skill above is a concise summary. If you need deeper guidance, read specific files from the skill's `references/` directory — the reference table lists what's available.

---

## Working Environment

**Working Directory**: {WORKING_DIRECTORY}

All file paths should be relative to this directory unless specified otherwise.

{RESUME_CONTEXT}

---

## Your Instructions

1. **Review the task** - Read the description and acceptance criteria carefully
2. **Ask questions if unclear** - Do NOT proceed with ambiguous requirements
3. **Follow TDD discipline** - Write tests first, then implement
4. **Self-review before committing** - Check completeness, quality, and discipline
5. **Commit your work** - Use conventional commit messages
6. **Report back** - Provide a complete implementation report

### Before You Start

If you have ANY of these concerns, ask the coordinator NOW:

- Ambiguous or conflicting requirements
- Missing acceptance criteria details
- Unclear file locations or naming conventions
- Questions about scope boundaries
- Dependency or integration concerns
- Uncertainty about which skill/approach to use

**It is always better to clarify upfront than to implement incorrectly.**

---

## Expected Report Format

When you complete implementation, report back using this format:

```markdown
## Implementation Complete

**Task ID**: {TASK_ID}
**Task**: {TASK_TITLE}
**Status**: Complete / Partial / Blocked

### What Was Implemented
- [Bullet points of what you built]

### Tests Added
- [List of test cases with file locations]

### Files Changed
- `path/to/file` - [brief description]

### Self-Review Findings
- [Any concerns, technical debt, or follow-up suggestions]

### Issues Encountered
- [Problems hit and how they were resolved]

### Commit
- Hash: [commit hash]
- Message: [commit message summary]
```

---

## Reminders

- **ONE TASK**: Implement only what is described above
- **NO SCOPE CREEP**: Do not add unrequested features
- **TDD DISCIPLINE**: Test first, then implement, then refactor
- **ASK QUESTIONS**: Clarify before implementing
- **SELF-REVIEW**: Check your work before reporting complete

## Tool Preferences

**IMPORTANT: Use MCP tools instead of CLI commands where available.**

For ohno task management, prefer these MCP tools over `npx @stevestomp/ohno-cli`:

| Instead of CLI | Use MCP Tool |
|----------------|--------------|
| `npx @stevestomp/ohno-cli done <id>` | `mcp__ohno__update_task_status(task_id, "done")` |
| `npx @stevestomp/ohno-cli set-handoff <id> ...` | `mcp__ohno__set_task_handoff(task_id, ...)` |
| `npx @stevestomp/ohno-cli update-wip <id> ...` | `mcp__ohno__update_task_wip(task_id, ...)` |
| `npx @stevestomp/ohno-cli block <id> <reason>` | `mcp__ohno__set_blocker(task_id, reason)` |
| `npx @stevestomp/ohno-cli activity <id> ...` | `mcp__ohno__add_task_activity(task_id, ...)` |

**Why**: MCP tools don't require Bash permission approval, making unattended sessions smoother.

Begin when ready. If you have questions, ask them now.

---

<!-- Template Notes for Coordinator:

{RESUME_CONTEXT} is empty for fresh tasks. For --continue resumption, fill with:

## Resuming from Previous Session

This task was partially completed in a previous session. Here is the saved state:

- **Phase**: {wip.phase}
- **Files already modified**: {wip.files_modified}
- **Last commit**: {wip.last_commit}
- **Uncommitted changes**: {wip.uncommitted_changes}
- **Decisions already made**: {wip.decisions}
- **Test results**: {wip.test_results}
- **Errors encountered**: {wip.errors}
- **Next step**: {wip.next_step}

Pick up from where the previous session left off. Do NOT redo work that was
already committed. Start from the "next step" above.

If handoff data is available from get_task_handoff(), also include:

## Previous Implementation Context

- **Status**: {handoff.status}
- **Summary**: {handoff.summary}
- **Files changed**: {handoff.files_changed}
- **Self-review findings**: {handoff.full_details}

Skip this section if no handoff data exists (it may have been compacted).
-->
