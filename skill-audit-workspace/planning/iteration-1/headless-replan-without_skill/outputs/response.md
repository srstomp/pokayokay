# Headless Planning Session Response (Without Skill)

## What Claude Would Do

This documents the response Claude would produce for the prompt:

> I want to do a headless planning session on the API migration PRD at docs/prds/api-v3-migration.md. Auto-decide on ambiguities, skip the review, just generate the full plan and task breakdown into ohno.

---

## Step 1: Parse Arguments and Set Mode

Claude interprets `$ARGUMENTS` as: `--headless docs/prds/api-v3-migration.md`

- **Mode**: headless (autonomous, no prompts)
- **PRD Path**: `docs/prds/api-v3-migration.md`
- **Review**: skipped (user explicitly said "skip the review")

## Step 2: Check Design Plugin Availability

Claude checks for `/design:*` commands. Result stored for planner dispatch.

## Step 3: Dispatch Planner Agent

Claude dispatches the `yokay-planner` subagent via the Task tool:

```
Task tool (yokay-planner):
  description: "Plan: api-v3-migration.md"
  prompt: |
    # PRD Analysis Assignment

    ## PRD

    Read and analyze the PRD at: `docs/prds/api-v3-migration.md`

    ## Project Context

    - Tech stack: Node.js, TypeScript
    - Package manager: npm
    - Test framework: (detected from codebase exploration)
    - Existing patterns: (detected from codebase exploration)

    ## Configuration

    - Design plugin available: false
    - Mode: headless

    ## Instructions

    Analyze the PRD and produce a structured implementation plan following
    the yokay-planner agent instructions.

    Return a JSON plan with epics, stories, tasks, dependencies, spike
    opportunities, and design tasks (if applicable).

    Ensure every task description is self-contained with behavior,
    acceptance criteria, and patterns to follow.
```

The planner agent would:

1. **Read the PRD** at `docs/prds/api-v3-migration.md`
2. **Explore the codebase** via Glob/Grep/Read to understand current API v2 structure, routes, middleware, test setup, database patterns
3. **Extract requirements** — endpoints to migrate, breaking changes, deprecation timeline, new features in v3
4. **Classify priorities** — P0 for breaking changes and core endpoints, P1 for new v3 features, P2 for deprecation tooling
5. **Map dependencies** — schema changes before endpoint migration, auth before protected routes, v2 compatibility layer before deprecation
6. **Detect spikes** — any unclear migration paths, performance concerns, or third-party integration questions
7. **Return structured JSON plan**

### Planner Return Value (Simulated)

The planner returns a JSON plan. Claude (the coordinator) receives this and proceeds to create the ohno hierarchy.

## Step 4: Create Hierarchical Structure in ohno

Claude takes the planner's JSON output and creates the full hierarchy. For an API v3 migration, the expected structure would be:

### 4.1 Create Epics

```
mcp__ohno__create_epic:
  title: "API v3 Core Migration"
  description: "Migrate core API endpoints from v2 to v3 with new request/response contracts, versioned routing, and backward-compatible deprecation headers."
  priority: "P0"

mcp__ohno__create_epic:
  title: "API v3 Authentication & Authorization"
  description: "Migrate auth system to v3 patterns — OAuth 2.1 flows, scoped tokens, API key rotation."
  priority: "P0"

mcp__ohno__create_epic:
  title: "API v3 New Features"
  description: "New capabilities exclusive to v3 — batch operations, cursor pagination, webhook subscriptions."
  priority: "P1"

mcp__ohno__create_epic:
  title: "v2 Deprecation & Migration Tooling"
  description: "v2 sunset headers, migration guide generation, client SDK compatibility layer, usage tracking for deprecation timeline."
  priority: "P1"

mcp__ohno__create_epic:
  title: "API v3 Testing & Documentation"
  description: "Comprehensive test coverage for v3 endpoints, OpenAPI spec generation, migration guide documentation."
  priority: "P2"
```

### 4.2 Create Stories and Tasks

For each epic, Claude creates stories with rich descriptions (Given/When/Then acceptance criteria, edge cases, out-of-scope), then tasks with self-contained descriptions (behavior, input/output contract, acceptance criteria checkboxes, connects-to, patterns to follow).

Example story + tasks for the first epic:

```
mcp__ohno__create_story:
  title: "Versioned Route Infrastructure"
  epic_id: "<epic-core-migration>"
  description: |
    Set up the v3 routing layer so all v3 endpoints are served under /api/v3/*
    while v2 continues operating under /api/v2/*.

    Acceptance Criteria:
    - Given a request to /api/v3/*, when the route exists, then it is handled by the v3 router
    - Given a request to /api/v2/*, when the route exists, then it continues to work unchanged
    - Given a request to /api/v3/* with no matching route, then 404 is returned with v3 error format

    Edge Cases:
    - Requests without version prefix (legacy /api/* routes)
    - OPTIONS/CORS preflight for versioned routes

    Out of Scope:
    - Actual endpoint migration (separate stories)
    - v1 routes (already removed)
```

```
mcp__ohno__create_task:
  title: "Create v3 router mount and version middleware"
  story_id: "<story-versioned-route-infra>"
  task_type: "feature"
  estimate_hours: 3
  description: |
    Create Express/Fastify router for v3 API routes and version-detection middleware.

    Behavior:
    - Create src/routes/v3/index.ts as the v3 router entry point
    - Implement versionMiddleware that reads API version from URL path (/api/v3/*)
    - Set req.apiVersion = "v3" for downstream handlers
    - Mount v3 router at /api/v3 in the main app
    - Keep existing /api/v2 mount unchanged

    Acceptance Criteria:
    - [ ] /api/v3/ routes are handled by v3 router
    - [ ] /api/v2/ routes continue working (regression check)
    - [ ] req.apiVersion is set correctly for v3 requests
    - [ ] 404 responses from v3 router use v3 error envelope

    Connects To:
    - Blocks: All v3 endpoint migration tasks (they register on this router)

    Patterns to Follow:
    - Mirror structure of existing src/routes/v2/index.ts
    - Follow middleware pattern in src/middleware/
```

```
mcp__ohno__create_task:
  title: "Implement v3 error envelope and response formatter"
  story_id: "<story-versioned-route-infra>"
  task_type: "feature"
  estimate_hours: 4
  description: |
    Standardize v3 API responses with a consistent envelope format.

    Behavior:
    - Create src/lib/v3/response.ts with formatSuccess(data, meta?) and formatError(code, message, details?)
    - Success envelope: { "data": <payload>, "meta": { "version": "v3", "requestId": "<uuid>" } }
    - Error envelope: { "error": { "code": "<ERROR_CODE>", "message": "<human-readable>", "details": [...] }, "meta": { "version": "v3", "requestId": "<uuid>" } }
    - Create Express/Fastify response helper middleware that attaches res.v3Success() and res.v3Error() methods
    - Error codes are UPPER_SNAKE_CASE strings (not HTTP status codes)

    Acceptance Criteria:
    - [ ] res.v3Success(data) returns 200 with correct envelope
    - [ ] res.v3Error(code, message, status) returns error envelope with correct HTTP status
    - [ ] All responses include requestId in meta
    - [ ] Error details array supports field-level validation errors
    - [ ] TypeScript types exported for V3Response<T> and V3Error

    Connects To:
    - Depends on: v3 router mount (middleware needs to be registered on v3 router)
    - Blocks: All v3 endpoint tasks (they use res.v3Success/v3Error)

    Patterns to Follow:
    - Check existing error handling in src/middleware/error-handler.ts
    - Follow TypeScript patterns in src/types/
```

Claude would continue creating 20-40 tasks across all epics, each with this level of description detail.

### 4.3 Add Dependencies

```
mcp__ohno__add_dependency:
  task_id: "<v3-error-envelope>"
  depends_on_task_id: "<v3-router-mount>"

mcp__ohno__add_dependency:
  task_id: "<migrate-users-endpoint>"
  depends_on_task_id: "<v3-error-envelope>"

mcp__ohno__add_dependency:
  task_id: "<migrate-users-endpoint>"
  depends_on_task_id: "<v3-router-mount>"

... (all cross-task dependencies)
```

### 4.4 Log Headless Decisions

Every auto-decision logged via ohno:

```
mcp__ohno__add_task_activity:
  task_id: "<spike-task-id>"
  type: "decision"
  description: "SPIKE: Created spike for v2-to-v3 data migration strategy — PRD mentions 'seamless migration' but doesn't specify whether to transform in-place or dual-write"

mcp__ohno__add_task_activity:
  task_id: "<epic-core-migration>"
  type: "decision"
  description: "DEPENDENCY: Made all endpoint migration tasks depend on v3 router + error envelope — infrastructure must exist before endpoints can register"

mcp__ohno__add_task_activity:
  task_id: "<epic-core-migration>"
  type: "decision"
  description: "SPLIT: Split 'API migration' into 5 epics (core, auth, new features, deprecation tooling, testing) — single epic would exceed 4-week threshold"

mcp__ohno__add_task_activity:
  task_id: "<epic-deprecation>"
  type: "decision"
  description: "PRIORITY: Set deprecation tooling to P1 not P0 — v3 must work before v2 sunset matters. Users said 'skip review' so applying conservative ordering."

mcp__ohno__add_task_activity:
  task_id: "<batch-operations-task>"
  type: "decision"
  description: "SCOPE: Included batch operations in v3 scope — PRD lists it as 'v3 exclusive feature', not deferred"
```

## Step 5: Assign Skill Hints

Tasks tagged with skills based on content:

| Task Pattern | Skill |
|---|---|
| Router, middleware, endpoints | api-design |
| Schema changes, migrations | database-design |
| Auth flows, token management | security-audit |
| Test infrastructure, coverage | testing-strategy |
| CI/CD for versioned deployments | ci-cd |
| Spike tasks | spike |

## Step 6: Create PROJECT.md

```
Write .claude/PROJECT.md with:
- Project: API v3 Migration
- Tech stack from codebase exploration
- Epic summary with IDs
- Task count by status
- Skill assignments
- Critical path
- Link to kanban
```

## Step 7: Sync and Report

```bash
npx @stevestomp/ohno-cli sync
```

### Final Output to User

```
Planning complete (headless): 5 epics, 14 stories, 38 tasks
  - 3 spike tasks (migration strategy, rate limiting approach, webhook delivery guarantees)
  - 0 design tasks (no UI/UX detected)
  - 6 notable decisions auto-resolved

Critical path: v3 router → error envelope → auth migration → core endpoints → deprecation headers
Estimated total: ~160 hours across 5 epics

Review skipped per request. Run `/plan --review` to inspect decisions later.

Ready to implement: `/work auto --all` or `/work semi-auto --epic <epic-id>`
```

---

## Observations: What Happens Without the Planning Skill

Without the planning skill loaded, Claude would still execute this workflow because:

1. **The `/plan` command's markdown** contains the complete step-by-step procedure (Steps 1-7), headless behavior rules, auto-decision table, decision logging format, and description quality requirements.
2. **The `yokay-planner` agent definition** contains the full PRD analysis process, output JSON schema, skill routing table, dependency mapping rules, and quality requirements for self-contained task descriptions.
3. **The planner prompt template** provides the dispatch format.

The planning skill's references (prd-analysis.md, task-breakdown.md, skill-routing.md, anti-patterns.md, design-integration.md) provide **depth** that the command and agent alone don't carry:

- **prd-analysis.md**: Three-pass parsing strategy (structure recognition, information extraction, gap analysis), document type classification, complexity scoring matrix, stakeholder analysis, quality checklist. Without this, the planner would do a single-pass read rather than systematic extraction.
- **task-breakdown.md**: INVEST criteria for stories, story splitting patterns (workflow steps, business rules, simple/complex, happy path/edge cases, data variations), estimation adjustment factors (+50% for new tech, +30% for unclear requirements), critical path analysis methodology. Without this, task sizing would be less calibrated.
- **skill-routing.md**: Detailed keyword-to-skill mapping with SQL queries for skill state tracking, skill transition logic, edge cases (feature needs multiple skills, skill not available). Without this, skill assignment would rely only on the simpler table in the planner agent.
- **anti-patterns.md**: Three categories of anti-patterns (analysis, breakdown, output) with specific fixes. Without this, the planner might fall into patterns like "tasks > 8 hours", "everything P0", or "missing features.json".

### Quality Difference

The **command + agent alone** would produce a functional plan. The skill references would make it:
- More systematic (three-pass PRD analysis vs. single-pass)
- Better calibrated (estimation adjustments, sizing guidelines)
- More robust (anti-pattern avoidance, edge case handling)
- More complete (features.json, kanban.html, full PROJECT.md template)

However, for a headless session where the user said "auto-decide on ambiguities, skip the review", the skill's interactive guidance (stakeholder analysis, RACI matrix, complexity scoring presentation) provides less marginal value. The core value of the skill in headless mode is the anti-patterns list and the task breakdown methodology — both of which help the planner avoid producing vague or oversized tasks.
