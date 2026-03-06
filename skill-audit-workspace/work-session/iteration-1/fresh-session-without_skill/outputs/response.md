# Simulated Claude Response: `/work semi-auto` Without Skill Guidance

## What Claude Would Say

---

Great, let's get your user-management epic rolling in semi-auto mode. I'll work through the tasks sequentially, pausing at story and epic boundaries so you can review, but continuing automatically between individual tasks.

Let me start by getting the current state from ohno and understanding what we're working with.

---

## Tools Claude Would Call

### Phase 1: Session Initialization

**Step 1 — Get session context from ohno:**

```
mcp__ohno__get_session_context()
```

Purpose: Check for any previous session state, in-progress tasks, or blockers.

**Step 2 — Get the epic details:**

Claude would likely try to find the epic, either by listing epics or asking the user for the ID. Without skill guidance, the approach would be less structured:

```
mcp__ohno__get_epics()
```

Then, upon finding the user-management epic:

```
mcp__ohno__get_epic(epic_id="<discovered-id>")
```

**Step 3 — List the stories and tasks:**

```
mcp__ohno__list_stories(epic_id="<epic-id>")
mcp__ohno__get_tasks(epic_id="<epic-id>")
```

**Step 4 — Announce the session plan:**

Claude would present something like:

> **Session: User Management Epic**
> **Mode**: semi-auto (pause at story/epic boundaries)
> **Project**: ~/Projects/acme/webapp
>
> **Stories:**
> 1. Story A — [title] (X tasks)
> 2. Story B — [title] (Y tasks)
> 3. Story C — [title] (Z tasks)
>
> **Total**: ~9 tasks
>
> I'll work through these in order. You'll see a log for each task completion, and I'll pause when a story finishes so you can review.
>
> Starting with the first task...

**Step 5 — Get the first task:**

```
mcp__ohno__get_next_task()
```

### Phase 2: Work Loop (Per Task)

For each task, Claude would likely:

**Step 6 — Start the task:**

```
mcp__ohno__update_task_status(task_id="<id>", status="in_progress")
```

**Step 7 — Read the task details:**

```
mcp__ohno__get_task(task_id="<id>")
```

**Step 8 — Implement the task inline:**

Without skill guidance, Claude would **not** dispatch a subagent. It would implement the task directly in the conversation context, using tools like:

- `Read` to explore the Next.js project at `~/Projects/acme/webapp`
- `Grep` / `Glob` to find relevant files
- `Edit` / `Write` to make changes
- `Bash` to run tests, install dependencies, etc.

**Step 9 — Mark the task complete:**

```
mcp__ohno__update_task_status(task_id="<id>", status="done")
```

Possibly also:

```
mcp__ohno__add_task_activity(task_id="<id>", activity_type="note", description="Implemented [description of what was done]")
```

**Step 10 — Checkpoint behavior:**

In semi-auto mode, Claude would log the task completion and continue:

> Task [title] complete. Moving to next task...

At story boundaries, Claude would pause:

> Story [title] complete (X/X tasks done). Here's a summary of what was built:
> - [summary]
>
> Would you like to continue to the next story, review the changes, or stop?

### Phase 3: Session End

When all tasks are done or the user stops:

```
mcp__ohno__add_task_activity(...) or equivalent session logging
```

Claude would summarize what was accomplished and what remains.

---

## Approach Assessment: What Would Be Missing Without the Skill

### Critical Gaps

1. **No subagent dispatch.** Claude would implement everything inline in the coordinator context. This means:
   - Context accumulates across all 9 tasks (no fresh context per task)
   - Quality degrades as the conversation grows
   - No separation between coordinator logic and implementation work
   - By task 6-7, Claude is likely experiencing significant context pressure

2. **No brainstorm gate.** Claude would not evaluate whether tasks are well-specified before implementing. Underspecified tasks would be attempted as-is, potentially producing wrong implementations.

3. **No two-stage review.** There would be no spec compliance or code quality review after each implementation. Tasks would be marked done based solely on Claude's self-assessment of its own work.

4. **No auto-fix pipeline.** If tests fail, Claude would attempt to fix them inline rather than dispatching the yokay-fixer agent with structured retry limits.

5. **No worktree management.** Claude would not create isolated git worktrees for feature/bug tasks. All work would happen in the main working directory, risking cross-contamination between tasks.

6. **No browser verification.** Even if Playwright MCP is available, Claude would not know to check UI changes in a browser after implementation.

7. **No skill routing.** Tasks would not be routed to domain-specific skills (api-design, database-design, testing-strategy, etc.), so the implementer would lack specialized guidance.

8. **No hook awareness.** Claude would not know about the bridge.py hook system, so post-task actions (sync, commit, detect-spike) would not be triggered properly.

9. **No parallel execution option.** Even though the user didn't request parallel mode here, the skill enables `-n` support. Without it, Claude has no framework for concurrent task dispatch.

10. **No proactive context shutdown.** In a long session, Claude would not detect context pressure and gracefully chain to a new session. It would degrade until the conversation dies.

### Partial Coverage

1. **Mode semantics.** Claude generally understands "semi-auto" from the argument hint in the command frontmatter, but without the skill's operating-modes reference, the exact checkpoint behavior (log vs. pause at which boundary) would be approximate rather than precise.

2. **ohno MCP usage.** Claude can use the ohno MCP tools since they're available, but without the skill's ohno-integration reference, it might miss tools like `get_task_handoff`, `update_task_wip`, or `set_handoff_notes`.

3. **Git workflow.** Claude knows how to commit code, but without worktree-management guidance, it won't follow the story-level branch reuse pattern or handle the merge/PR prompt flow on story completion.

### What Would Actually Happen

Claude would likely:

1. Call `get_session_context()` and `get_epics()` to orient itself
2. Get the first task via `get_next_task()`
3. Read the task, then start implementing it inline by exploring the Next.js codebase
4. Commit changes and mark the task done
5. Move to the next task
6. Repeat until context fills up (probably around task 5-7)
7. At some point, lose track of the session structure and either stall or produce lower-quality work
8. May or may not correctly pause at story boundaries (would attempt it but might get the timing wrong since it doesn't have boundary metadata awareness)

The work would get done for the first few tasks, but without the subagent architecture providing fresh context per task, quality would noticeably degrade in the second half of the session. The lack of review stages means bugs and spec misses would go undetected until the user manually reviews.

---

## How Claude Would Proceed (Concretely)

Claude's opening response would look approximately like this:

---

> Let's start the semi-auto work session on your user-management epic. In semi-auto mode, I'll log task completions and keep moving, but I'll pause for your review whenever a story completes.
>
> First, let me get the current state from ohno and see what's in the epic.
>
> *[Calls `mcp__ohno__get_session_context()`]*
> *[Calls `mcp__ohno__get_epics()`]*
>
> *[After results come back, identifies the epic, lists stories/tasks]*
>
> Here's what I see in the user-management epic:
>
> **Epic**: User Management
> **Stories**: 3 stories, ~9 tasks total
>
> | Story | Tasks | Status |
> |-------|-------|--------|
> | [Story 1 title] | 3 tasks | todo |
> | [Story 2 title] | 3 tasks | todo |
> | [Story 3 title] | 3 tasks | todo |
>
> I'll start with the first available task. Let me grab it.
>
> *[Calls `mcp__ohno__get_next_task()`]*
>
> *[Gets task, starts implementing inline...]*

---

The key structural difference: without the skill, Claude becomes both coordinator AND implementer in the same context, which is precisely the anti-pattern the work-session skill's subagent architecture is designed to prevent.
