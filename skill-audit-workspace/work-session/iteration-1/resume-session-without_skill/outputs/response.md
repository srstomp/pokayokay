# Simulated Claude Response (Without Skill Guidance)

## What Claude Would Say

> Got it — you want to pick up where you left off on the payments epic in auto mode. Let me get the session context from ohno and figure out exactly where things stand.

## Tools Claude Would Call

### Step 1: Get Session Context

Claude would call `mcp__ohno__get_session_context()` to retrieve:
- Previous session notes
- In-progress tasks
- Current blockers

### Step 2: Get the Epic

Based on the session context response (which would name the payments epic), Claude would call `mcp__ohno__get_epics()` or search for the payments epic to get its ID. Then call `mcp__ohno__get_epic(epic_id)` for full details.

### Step 3: List Stories in the Epic

Claude would call `mcp__ohno__list_stories()` filtered to the payments epic to see:
- Story-1 status (expected: done)
- Story-2 status (expected: in_progress)
- Remaining stories

### Step 4: Get Tasks for Story-2

Claude would call `mcp__ohno__get_tasks()` filtered to story-2 to find:
- Which tasks are done
- Which task is in_progress or next up

### Step 5: Check for In-Progress/WIP Tasks

Claude would call `mcp__ohno__get_next_task()` to find the recommended next task, and check for any tasks with WIP (work-in-progress) data from the interrupted session.

## What Claude Would Produce as Session Start Output

Something like:

> ## Session Start
>
> **Mode**: auto
> **Scope**: epic — [payments epic ID]
> **Parallel**: 1
>
> ## Current State
>
> **Epic**: Payments Integration
> - Story 1: [title] — DONE
> - Story 2: [title] — IN PROGRESS (3/6 tasks done)
> - Story 3: [title] — TODO
>
> **Resuming from**: [task title] ([task ID])
> **Previous session notes**: [from get_session_context]
>
> Proceeding in auto mode — will pause only at epic boundary.

## The Approach Claude Would Take

1. **Parse the request**: Mode = auto, scope = payments epic (inferred from user's statement), no explicit --continue flag but user clearly wants to resume
2. **Get session context** via ohno MCP to understand previous session state
3. **Identify the payments epic** and scope work to it
4. **Find where story-2 left off** — locate the next incomplete task
5. **Enter the work loop** in auto mode:
   - For each task: dispatch yokay-implementer subagent, run spec + quality review, mark done
   - At task boundaries: skip checkpoint (auto mode)
   - At story boundaries: log and continue (auto mode)
   - At epic boundary: PAUSE for human review
6. **Worktree handling**: Check if a worktree already exists for story-2 (story tasks reuse the same worktree); if so, reuse it

## Key Gaps Without Skill Guidance

Without the work-session skill loaded, Claude would likely:

1. **Miss the chain state initialization** — Auto mode with scope should write `.claude/pokayokay-chain-state.json` so that SessionEnd hooks can spawn continuation sessions. Without skill guidance, Claude wouldn't know to create this file.

2. **Skip scope validation formality** — The skill specifies that auto mode requires explicit scope (`--epic`, `--story`, or `--all`). Claude would infer the epic scope from context but wouldn't follow the formal validation flow that pauses if scope is ambiguous.

3. **Not load project learnings** — The skill specifies checking `memory/recurring-failures.md`, `memory/spike-results.md`, and `memory/chain-learnings.md` during session start. Without the skill, Claude wouldn't know these files exist or matter.

4. **Miss the brainstorm gate** — The skill defines a conditional brainstorming step for ambiguous tasks. Without it, Claude would dispatch the implementer directly for every task.

5. **Omit the two-stage review** — The skill specifies adversarial spec review followed by quality review. Without it, Claude would likely either skip review entirely or do a single-pass review.

6. **Not handle worktree reuse correctly** — The skill specifies that story tasks reuse the same worktree. Claude might know this from CLAUDE.md context but wouldn't follow the exact setup flow.

7. **Miss proactive context shutdown** — The skill describes detecting context pressure and gracefully ending the session before quality degrades. Without it, Claude would just keep working until the context fills up.

8. **Skip adaptive parallel sizing** — Not immediately relevant at parallel=1, but if `-n auto` were used, Claude wouldn't know the adaptive sizing rules.

9. **Not use the implementer prompt template** — The skill specifies filling `agents/templates/implementer-prompt.md` with specific template variables. Without it, Claude would construct an ad-hoc prompt for the Task tool.

10. **Miss checkpoint behavior specifics** — Claude would know auto mode means "less pausing" but wouldn't know the exact matrix (skip at task, log at story, pause at epic).

## What Claude Would Actually Do (Realistic Assessment)

Claude would likely:
- Call `get_session_context()` and `get_epics()` — **correct**
- Identify the payments epic and story-2 — **correct**
- Find the next task in story-2 — **correct**
- Attempt to use `/pokayokay:work auto --epic <id>` or try to manually orchestrate — **partially correct**
- Try to dispatch a subagent using the Task tool — **would struggle without knowing agent names and template format**
- Fall back to implementing inline if Task tool dispatch fails — **reasonable fallback but defeats the fresh-context-per-task architecture**

The biggest risk is that without the skill, Claude would try to implement tasks inline rather than dispatching subagents, which means context degradation across multiple tasks — the exact problem pokayokay's architecture is designed to prevent.
