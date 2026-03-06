# Response: Overnight Unattended Run (Without Skill Guidance)

## What Claude Would Produce

Got it -- I will set up an overnight unattended run to work through the remaining tasks in the notifications epic with 3 parallel agents.

First, let me find the notifications epic ID and verify there are tasks ready to work.

**Tool calls:**

1. `mcp__ohno__get_epics(status="active")` -- to find the notifications epic and get its ID.

*(After getting the epic ID, e.g. `epic-abc123`:)*

2. `mcp__ohno__get_tasks(epic_id="epic-abc123")` -- to see how many tasks remain and their status.

**After confirming tasks exist, the response would be:**

---

Found the notifications epic (`epic-abc123`) with N remaining tasks. Here is the command to kick off the overnight run:

```bash
claude --headless --dangerously-skip-permissions --prompt="/pokayokay:work unattended -n 3 --epic epic-abc123"
```

This will:

- **Unattended mode**: No pauses at task, story, or epic boundaries -- it will run straight through without waiting for human input.
- **3 parallel agents**: Dispatches up to 3 implementer subagents simultaneously for independent tasks. Tasks with dependency relationships (via ohno's `blockedBy` graph) will be serialized automatically -- only independent tasks run in parallel.
- **Epic scope**: Limits work to tasks within the notifications epic only, preventing runaway execution into unrelated work.
- **Headless + skip permissions**: Required for true unattended operation so no interactive prompts block execution.

The session will automatically chain if it hits context limits -- the `session-chain.sh` hook spawns a new session that picks up where the previous one left off. Chain config defaults to max 10 sessions, which should be plenty.

When you check in the morning, you can review what happened by looking at:
- The ohno task activity log for each completed task
- The git log for commits made during the session
- Any session summary output generated at session end

Want me to run it now?

---

## Analysis of Response Quality

### Assertions Evaluation

| # | Assertion | Met? | Notes |
|---|-----------|------|-------|
| 1 | References unattended mode (no pauses at any boundary) | YES | Explicitly states "No pauses at task, story, or epic boundaries" |
| 2 | Configures parallel execution with multiple agents | YES | Uses `-n 3` flag and explains 3 parallel implementers |
| 3 | Mentions or performs pre-flight checks before starting | NO | Does not mention pre-flight checks at all |
| 4 | Describes how parallel tasks avoid dependencies or conflicts | YES | Mentions ohno's `blockedBy` graph and serialization of dependent tasks |
| 5 | Plans for session summary or handoff notes at the end | PARTIAL | Mentions session summary and task activity logs but does not explicitly describe handoff notes or the structured session-summary hook |

### Key Gaps Without Skill Guidance

1. **Pre-flight checks omitted**: The work-session skill's pre-flight-checks reference documents automatic validation (git clean, ohno responsive, tasks available, disk space, worktree locks, chain state) that runs at SessionStart in unattended mode. Without skill guidance, Claude relies on general knowledge from CLAUDE.md/MEMORY.md, which mentions `pre-flight.sh` in the hook flow but does not emphasize it as something to surface to the user. A skill-guided response would likely mention that pre-flight checks run automatically and what they validate, giving the user confidence the overnight run will fail fast on environment issues.

2. **Session summary detail**: The response mentions session summary as an output to check but does not describe the structured format (token costs, tasks completed, chain metadata) that the `session-summary.sh` hook produces. A skill-guided response would be more specific about what the morning review looks like.

3. **Worktree management not mentioned**: The skill references document that parallel tasks get isolated worktrees, which is important context for understanding how 3 agents avoid stepping on each other. This is distinct from dependency ordering.

4. **`.claude/pokayokay.json` headless config not surfaced**: The work command references headless configuration (max_chains, report settings) that could be customized for the overnight run. Without skill guidance, Claude uses the defaults without mentioning them.

### Score Estimate

Meets 3 of 5 assertions fully, 1 partially, 1 missed. Approximately 70% coverage. The response is functionally correct and would work, but lacks the operational confidence details (pre-flight validation, structured summary format) that the skill guidance would provide.
