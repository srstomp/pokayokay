# Headless Planning Session Response

## Simulated Execution of `/plan --headless docs/prds/api-v3-migration.md`

---

## Argument Parsing

Parsed from `$ARGUMENTS`:
- **Mode**: `--headless` (autonomous, no interactive prompts)
- **PRD Path**: `docs/prds/api-v3-migration.md`

Mode routing: Run Steps 1-7 with all prompts auto-decided. Skip review at the end per user instruction.

---

## Step 1: Check Design Plugin Availability

Checking for design plugin commands (`/design:ux`, `/design:ui`, etc.)...

Result: **Design plugin not available.** In headless mode, the auto-decision for "Continue without design plugin?" is **Yes (continue without)** -- no decision log needed per the command spec.

---

## Step 2: Dispatch Planner Agent

Dispatching `yokay-planner` subagent via Task tool:

```
Task tool (yokay-planner):
  description: "Plan: api-v3-migration.md"
  prompt: [planner-prompt.md filled with:
    - PRD_PATH: docs/prds/api-v3-migration.md
    - PROJECT_CONTEXT: (existing codebase structure, tech stack, conventions discovered via Glob/Read/Grep)
    - DESIGN_PLUGIN_AVAILABLE: false
    - MODE: headless
  ]
```

The planner agent reads the PRD, explores the codebase, and returns a structured JSON plan. Below is the simulated planner output based on a representative API v3 migration PRD:

```json
{
  "project_name": "API v3 Migration",
  "project_description": "Migrate from REST API v2 to v3 with versioned routing, new auth model, pagination overhaul, and deprecation of legacy endpoints.",
  "tech_stack": ["Node.js", "Express", "PostgreSQL", "Prisma", "Jest"],
  "epics": [
    {
      "title": "API Versioning Infrastructure",
      "description": "Establish v3 routing layer, version negotiation middleware, and backward-compatible v2 shim so both versions run simultaneously during migration.",
      "priority": "P0",
      "stories": [
        {
          "title": "Version-Aware Router Setup",
          "description": "The API serves requests on /api/v2/* and /api/v3/* simultaneously, routing to the appropriate handler set.\n\nAcceptance Criteria:\n- Given a request to /api/v3/users, when the v3 router is active, then the v3 handler responds\n- Given a request to /api/v2/users, when both versions are active, then the v2 handler responds unchanged\n- Given a request to /api/v4/anything, when no v4 exists, then a 404 with version-not-found error is returned\n\nEdge Cases:\n- Request with no version prefix (should default to v2 during migration)\n- Accept-Version header conflicts with URL version\n\nOut of Scope:\n- Version sunset headers (separate story)\n- Rate limiting per version (separate story)",
          "tasks": [
            {
              "title": "Create versioned router factory",
              "task_type": "feature",
              "estimate_hours": 3,
              "skill": "api-design",
              "description": "Factory function that mounts route sets under /api/v{N}/ prefix.\n\nBehavior:\n- createVersionedRouter(version, routes) returns an Express router mounted at /api/v{version}/\n- Version extracted from URL path, validated as integer\n- Invalid version returns 404 with {error: 'version_not_found', available: ['v2', 'v3']}\n\nAcceptance Criteria:\n- [ ] Factory creates router at correct prefix\n- [ ] Invalid versions return 404 with available versions list\n- [ ] Existing v2 routes continue to work when v3 router is added\n- [ ] Router factory is reusable for future versions\n\nConnects To:\n- Blocks: All v3 endpoint tasks (they register on this router)\n\nPatterns to Follow:\n- Follow existing router setup in src/routes/index.ts",
              "depends_on": []
            },
            {
              "title": "Add version negotiation middleware",
              "task_type": "feature",
              "estimate_hours": 4,
              "skill": "api-design",
              "description": "Middleware that resolves API version from URL path and optional Accept-Version header.\n\nBehavior:\n- Extract version from URL path (/api/v3/...) as primary source\n- If Accept-Version header is present and conflicts with URL, return 400 with explanation\n- Attach resolved version to req.apiVersion for downstream handlers\n- Log version usage for migration tracking metrics\n\nAcceptance Criteria:\n- [ ] req.apiVersion is set correctly for v2 and v3 requests\n- [ ] Header/URL conflict returns 400 with clear error message\n- [ ] Version-less requests default to v2\n- [ ] Version usage is logged (stdout or structured log)\n\nConnects To:\n- Depends on: Versioned router factory\n- Blocks: All v3 endpoint handlers (they read req.apiVersion)\n\nPatterns to Follow:\n- Follow existing middleware patterns in src/middleware/",
              "depends_on": ["Create versioned router factory"]
            },
            {
              "title": "Create v2 compatibility shim",
              "task_type": "feature",
              "estimate_hours": 4,
              "skill": "api-design",
              "description": "Thin adapter layer that translates v2 request/response shapes to v3 internals, so v2 endpoints can delegate to v3 logic without duplication.\n\nBehavior:\n- shimV2ToV3(handler) wraps a v3 handler to accept v2 request format\n- Transforms v2 query params to v3 format (e.g., page/per_page to cursor-based)\n- Transforms v3 response format back to v2 shape (e.g., cursor pagination to offset pagination)\n- Logs shimmed requests for deprecation tracking\n\nAcceptance Criteria:\n- [ ] Shimmed v2 endpoints return identical responses to current v2\n- [ ] v2 pagination params are translated to v3 cursor format internally\n- [ ] v3 response is translated back to v2 envelope format\n- [ ] Shim usage is logged for deprecation metrics\n\nConnects To:\n- Depends on: Versioned router factory, version negotiation middleware\n- Blocks: V2 deprecation story (needs shim to safely deprecate)\n\nPatterns to Follow:\n- Follow adapter patterns; create in src/middleware/v2-shim.ts",
              "depends_on": ["Create versioned router factory", "Add version negotiation middleware"]
            }
          ]
        }
      ]
    },
    {
      "title": "V3 Authentication Model",
      "description": "Replace API key auth with OAuth 2.0 client credentials flow for v3 endpoints. V2 API key auth continues to work unchanged.",
      "priority": "P0",
      "stories": [
        {
          "title": "OAuth 2.0 Client Credentials for V3",
          "description": "V3 endpoints authenticate via OAuth 2.0 client credentials flow instead of API keys.\n\nAcceptance Criteria:\n- Given valid client_id and client_secret, when POST /api/v3/oauth/token, then a bearer token is returned with configurable expiry\n- Given an expired bearer token, when calling any v3 endpoint, then 401 with token_expired error is returned\n- Given a valid v2 API key, when calling a v3 endpoint, then 401 with upgrade_required error is returned\n\nEdge Cases:\n- Client credentials rotated mid-session\n- Token issued just before key rotation\n- Concurrent token requests from same client\n\nOut of Scope:\n- Authorization code flow (not needed for API-to-API)\n- Refresh tokens (client credentials re-issue instead)\n- Scoped permissions (future iteration)",
          "tasks": [
            {
              "title": "Create OAuth client registration schema",
              "task_type": "feature",
              "estimate_hours": 3,
              "skill": "database-design",
              "description": "Database table for OAuth clients with credentials.\n\nBehavior:\n- Table: oauth_clients with columns: id (uuid), client_id (unique), client_secret_hash, name, created_at, revoked_at\n- Prisma migration to create table\n- Client secret stored as bcrypt hash, never in plaintext\n\nAcceptance Criteria:\n- [ ] Migration creates oauth_clients table\n- [ ] client_id has unique constraint\n- [ ] client_secret is stored hashed\n- [ ] revoked_at allows soft-revocation\n\nConnects To:\n- Blocks: Token endpoint, auth middleware\n\nPatterns to Follow:\n- Follow existing Prisma migration patterns in prisma/migrations/",
              "depends_on": []
            },
            {
              "title": "Implement token endpoint POST /api/v3/oauth/token",
              "task_type": "feature",
              "estimate_hours": 4,
              "skill": "api-design",
              "description": "OAuth 2.0 client credentials token endpoint.\n\nBehavior:\n- Accept POST with grant_type=client_credentials, client_id, client_secret\n- Validate credentials against oauth_clients table\n- Generate JWT with client_id claim, configurable expiry (default 1h)\n- Return {access_token, token_type: 'bearer', expires_in}\n- Return 401 for invalid credentials, 400 for wrong grant_type\n\nAcceptance Criteria:\n- [ ] Valid credentials return bearer token\n- [ ] Invalid credentials return 401\n- [ ] Wrong grant_type returns 400\n- [ ] Token contains client_id claim and expiry\n- [ ] Revoked clients cannot obtain tokens\n\nConnects To:\n- Depends on: OAuth client schema\n- Blocks: V3 auth middleware\n\nPatterns to Follow:\n- Follow existing auth patterns; create in src/routes/v3/oauth.ts",
              "depends_on": ["Create OAuth client registration schema"]
            },
            {
              "title": "Create v3 bearer token auth middleware",
              "task_type": "feature",
              "estimate_hours": 3,
              "skill": "api-design",
              "description": "Middleware that validates bearer tokens on all v3 endpoints.\n\nBehavior:\n- Extract token from Authorization: Bearer header\n- Validate JWT signature and expiry\n- Attach client context to req.auth\n- Return 401 with token_expired or token_invalid error\n- If v2-style API key is sent to v3, return 401 with upgrade_required error and link to migration docs\n\nAcceptance Criteria:\n- [ ] Valid bearer token passes through with req.auth populated\n- [ ] Expired token returns 401 token_expired\n- [ ] Invalid token returns 401 token_invalid\n- [ ] API key on v3 returns 401 upgrade_required with docs link\n\nConnects To:\n- Depends on: Token endpoint\n- Blocks: All v3 protected endpoints\n\nPatterns to Follow:\n- Follow src/middleware/auth.ts patterns",
              "depends_on": ["Implement token endpoint POST /api/v3/oauth/token"]
            }
          ]
        }
      ]
    },
    {
      "title": "V3 Pagination Overhaul",
      "description": "Replace offset-based pagination with cursor-based pagination across all v3 list endpoints for consistent, performant pagination.",
      "priority": "P1",
      "stories": [
        {
          "title": "Cursor-Based Pagination Library",
          "description": "Shared pagination utility that all v3 list endpoints use for consistent cursor-based pagination.\n\nAcceptance Criteria:\n- Given a list request with no cursor, when the endpoint responds, then the first page is returned with a next_cursor\n- Given a valid cursor, when the endpoint responds, then the next page is returned\n- Given an invalid or expired cursor, when the endpoint responds, then 400 with invalid_cursor error\n- Given a page_size parameter, when the endpoint responds, then at most page_size items are returned\n\nEdge Cases:\n- Empty result set (no cursor returned)\n- Last page (next_cursor is null)\n- Concurrent inserts during pagination\n\nOut of Scope:\n- Backward pagination (prev_cursor)\n- Total count (expensive, deferred)",
          "tasks": [
            {
              "title": "Create cursor pagination utility",
              "task_type": "feature",
              "estimate_hours": 4,
              "skill": "api-design",
              "description": "Reusable cursor pagination module for Prisma queries.\n\nBehavior:\n- paginateCursor(model, {cursor?, pageSize?, orderBy}) returns {items, next_cursor, has_more}\n- Cursor is opaque base64-encoded string containing sort key + id\n- Default page_size is 25, max is 100\n- Invalid cursor throws CursorError (caught by error middleware)\n\nAcceptance Criteria:\n- [ ] First page returns items + next_cursor when more exist\n- [ ] Passing next_cursor returns subsequent page\n- [ ] Last page has has_more: false and next_cursor: null\n- [ ] Invalid cursor throws descriptive error\n- [ ] Page size is bounded (1-100)\n\nConnects To:\n- Blocks: All v3 list endpoint tasks\n\nPatterns to Follow:\n- Create as src/lib/pagination.ts",
              "depends_on": []
            },
            {
              "title": "Migrate /users list endpoint to cursor pagination",
              "task_type": "feature",
              "estimate_hours": 3,
              "skill": "api-design",
              "description": "Convert GET /api/v3/users from offset to cursor pagination.\n\nBehavior:\n- Accept cursor and page_size query params (instead of page/per_page)\n- Use pagination utility for query\n- Response envelope: {data: [...], pagination: {next_cursor, has_more}}\n- V2 shim translates to/from offset format for backward compatibility\n\nAcceptance Criteria:\n- [ ] GET /api/v3/users returns cursor-paginated response\n- [ ] V2 /api/v2/users continues to work with offset pagination via shim\n- [ ] Empty result returns {data: [], pagination: {next_cursor: null, has_more: false}}\n\nConnects To:\n- Depends on: Cursor pagination utility, versioned router factory\n- Blocks: Other list endpoint migrations (use as reference)\n\nPatterns to Follow:\n- Follow existing list patterns; update src/routes/v3/users.ts",
              "depends_on": ["Create cursor pagination utility", "Create versioned router factory"]
            },
            {
              "title": "Migrate remaining list endpoints to cursor pagination",
              "task_type": "feature",
              "estimate_hours": 6,
              "skill": "api-design",
              "description": "Convert all remaining v3 list endpoints (projects, teams, webhooks, audit-log) to cursor pagination using the pagination utility.\n\nBehavior:\n- Apply same pattern as /users migration to: /projects, /teams, /webhooks, /audit-log\n- Each endpoint uses paginateCursor with appropriate orderBy\n- Response envelope matches /users format exactly\n\nAcceptance Criteria:\n- [ ] All list endpoints return cursor-paginated responses\n- [ ] All endpoints use the shared pagination utility\n- [ ] V2 shim works for all migrated endpoints\n- [ ] Response envelope is consistent across all endpoints\n\nConnects To:\n- Depends on: /users migration (use as reference implementation)\n\nPatterns to Follow:\n- Follow the /users migration as the reference pattern",
              "depends_on": ["Migrate /users list endpoint to cursor pagination"]
            }
          ]
        }
      ]
    },
    {
      "title": "V2 Deprecation & Migration Path",
      "description": "Implement deprecation headers, migration documentation, and sunset timeline for v2 endpoints.",
      "priority": "P2",
      "stories": [
        {
          "title": "Deprecation Headers and Logging",
          "description": "All v2 responses include deprecation headers and usage is logged for sunset planning.\n\nAcceptance Criteria:\n- Given any v2 request, when the response is sent, then Deprecation and Sunset headers are included\n- Given v2 usage tracking is active, when a v2 endpoint is called, then the call is logged with client identifier and endpoint\n- Given a client making only v2 calls, when migration reports are generated, then that client appears as not-yet-migrated\n\nEdge Cases:\n- Unauthenticated v2 requests (log by IP, not client)\n- Health check endpoints (exclude from deprecation headers)\n\nOut of Scope:\n- Automatic v2 shutdown (manual process)\n- Per-client sunset dates (all clients same timeline)",
          "tasks": [
            {
              "title": "Add deprecation headers middleware for v2",
              "task_type": "feature",
              "estimate_hours": 2,
              "skill": "api-design",
              "description": "Middleware that adds RFC 8594 deprecation headers to all v2 responses.\n\nBehavior:\n- Add Deprecation: true header to all v2 responses\n- Add Sunset: <date> header with configurable sunset date from env var API_V2_SUNSET_DATE\n- Add Link: <migration-docs-url>; rel=\"successor-version\" header\n- Skip headers for health/status endpoints\n\nAcceptance Criteria:\n- [ ] All v2 responses include Deprecation header\n- [ ] Sunset date is configurable via environment variable\n- [ ] Link header points to migration documentation\n- [ ] Health endpoints are excluded\n\nConnects To:\n- Depends on: V2 compatibility shim (shim must exist before adding deprecation)\n\nPatterns to Follow:\n- Follow middleware patterns in src/middleware/",
              "depends_on": ["Create v2 compatibility shim"]
            },
            {
              "title": "Create v2 usage tracking for migration reports",
              "task_type": "feature",
              "estimate_hours": 4,
              "skill": "observability",
              "description": "Track v2 API usage per client to generate migration readiness reports.\n\nBehavior:\n- Log each v2 request with: client_id (or IP), endpoint, timestamp\n- Store in lightweight table (v2_usage_log) or structured log\n- Provide query for migration report: clients still using v2, last call date, most-used endpoints\n\nAcceptance Criteria:\n- [ ] Every v2 request is logged with client identifier\n- [ ] Migration report query returns clients, last-used date, endpoint counts\n- [ ] Logging does not measurably impact request latency\n- [ ] Unauthenticated requests tracked by IP\n\nConnects To:\n- Depends on: Deprecation headers middleware\n\nPatterns to Follow:\n- Follow existing logging patterns; create in src/services/migration-tracker.ts",
              "depends_on": ["Add deprecation headers middleware for v2"]
            }
          ]
        }
      ]
    }
  ],
  "spikes": [
    {
      "title": "Spike: Evaluate cursor pagination performance at scale",
      "estimate_hours": 3,
      "question": "Does cursor-based pagination maintain sub-100ms response times with 1M+ rows in users/projects tables?",
      "blocks": ["Migrate remaining list endpoints to cursor pagination"]
    },
    {
      "title": "Spike: JWT token size impact on request overhead",
      "estimate_hours": 2,
      "question": "With planned claims (client_id, scopes, org_id), does JWT size cause measurable overhead vs current API key auth?",
      "blocks": ["Create v3 bearer token auth middleware"]
    }
  ],
  "design_tasks": []
}
```

---

## Step 3: Initialize ohno

```bash
npx @stevestomp/ohno-cli init
# ohno already initialized, skipping.
```

---

## Step 4: Create Hierarchical Structure from Plan

### 4.1 Create Epics

```
mcp__ohno__create_epic:
  title: "API Versioning Infrastructure"
  description: "Establish v3 routing layer, version negotiation middleware, and backward-compatible v2 shim so both versions run simultaneously during migration."
  priority: "P0"
  → epic_id: "epic-001"

mcp__ohno__create_epic:
  title: "V3 Authentication Model"
  description: "Replace API key auth with OAuth 2.0 client credentials flow for v3 endpoints. V2 API key auth continues to work unchanged."
  priority: "P0"
  → epic_id: "epic-002"

mcp__ohno__create_epic:
  title: "V3 Pagination Overhaul"
  description: "Replace offset-based pagination with cursor-based pagination across all v3 list endpoints for consistent, performant pagination."
  priority: "P1"
  → epic_id: "epic-003"

mcp__ohno__create_epic:
  title: "V2 Deprecation & Migration Path"
  description: "Implement deprecation headers, migration documentation, and sunset timeline for v2 endpoints."
  priority: "P2"
  → epic_id: "epic-004"
```

### 4.2 Create Stories (with rich descriptions per Section 4.5)

```
mcp__ohno__create_story:
  title: "Version-Aware Router Setup"
  epic_id: "epic-001"
  description: [full description with Given/When/Then AC, edge cases, out-of-scope — as shown in planner output]
  → story_id: "story-001"

mcp__ohno__create_story:
  title: "OAuth 2.0 Client Credentials for V3"
  epic_id: "epic-002"
  description: [full description — as shown in planner output]
  → story_id: "story-002"

mcp__ohno__create_story:
  title: "Cursor-Based Pagination Library"
  epic_id: "epic-003"
  description: [full description — as shown in planner output]
  → story_id: "story-003"

mcp__ohno__create_story:
  title: "Deprecation Headers and Logging"
  epic_id: "epic-004"
  description: [full description — as shown in planner output]
  → story_id: "story-004"
```

### 4.3 Create Tasks (with self-contained descriptions per Section 4.5)

All 14 implementation tasks created with full Behavior/AC/Connects To/Patterns sections as shown in planner output. Task IDs assigned sequentially:

| ID | Task | Type | Hours | Story | Skill |
|----|------|------|-------|-------|-------|
| task-001 | Create versioned router factory | feature | 3 | story-001 | api-design |
| task-002 | Add version negotiation middleware | feature | 4 | story-001 | api-design |
| task-003 | Create v2 compatibility shim | feature | 4 | story-001 | api-design |
| task-004 | Create OAuth client registration schema | feature | 3 | story-002 | database-design |
| task-005 | Implement token endpoint POST /api/v3/oauth/token | feature | 4 | story-002 | api-design |
| task-006 | Create v3 bearer token auth middleware | feature | 3 | story-002 | api-design |
| task-007 | Create cursor pagination utility | feature | 4 | story-003 | api-design |
| task-008 | Migrate /users list endpoint to cursor pagination | feature | 3 | story-003 | api-design |
| task-009 | Migrate remaining list endpoints to cursor pagination | feature | 6 | story-003 | api-design |
| task-010 | Add deprecation headers middleware for v2 | feature | 2 | story-004 | api-design |
| task-011 | Create v2 usage tracking for migration reports | feature | 4 | story-004 | observability |
| task-012 | Spike: Evaluate cursor pagination performance at scale | spike | 3 | story-003 | spike |
| task-013 | Spike: JWT token size impact on request overhead | spike | 2 | story-002 | spike |

### 4.4 Add Dependencies

```
mcp__ohno__add_dependency: task-002 depends on task-001
mcp__ohno__add_dependency: task-003 depends on task-001
mcp__ohno__add_dependency: task-003 depends on task-002
mcp__ohno__add_dependency: task-005 depends on task-004
mcp__ohno__add_dependency: task-006 depends on task-005
mcp__ohno__add_dependency: task-006 depends on task-013  (spike must complete first)
mcp__ohno__add_dependency: task-008 depends on task-007
mcp__ohno__add_dependency: task-008 depends on task-001
mcp__ohno__add_dependency: task-009 depends on task-008
mcp__ohno__add_dependency: task-009 depends on task-012  (spike must complete first)
mcp__ohno__add_dependency: task-010 depends on task-003
mcp__ohno__add_dependency: task-011 depends on task-010
```

---

## Headless Auto-Decisions (Decision Logging)

Every auto-decision was logged via `mcp__ohno__add_task_activity` as required by the headless behavior spec:

### Decision 1: SPIKE

```
mcp__ohno__add_task_activity:
  task_id: "task-012"
  type: "decision"
  description: "SPIKE: Created spike for cursor pagination performance — PRD says 'performant pagination' but doesn't specify latency targets or data volume. Need to verify sub-100ms at 1M+ rows before committing to cursor approach across all endpoints."
```

### Decision 2: SPIKE

```
mcp__ohno__add_task_activity:
  task_id: "task-013"
  type: "decision"
  description: "SPIKE: Created spike for JWT token size overhead — PRD specifies OAuth 2.0 but doesn't address token payload size vs API key. With planned claims (client_id, scopes, org_id), JWT could add measurable per-request overhead."
```

### Decision 3: DEPENDENCY

```
mcp__ohno__add_task_activity:
  task_id: "task-009"
  type: "decision"
  description: "DEPENDENCY: Made 'Migrate remaining list endpoints' depend on pagination performance spike — if cursor pagination doesn't meet latency targets at scale, the approach for bulk endpoints may need to change. Don't migrate everything before validating."
```

### Decision 4: DEPENDENCY

```
mcp__ohno__add_task_activity:
  task_id: "task-006"
  type: "decision"
  description: "DEPENDENCY: Made v3 auth middleware depend on JWT size spike — middleware design may need to account for token caching or compression if overhead is significant."
```

### Decision 5: PRIORITY

```
mcp__ohno__add_task_activity:
  task_id: "epic-004"
  type: "decision"
  description: "PRIORITY: Set V2 Deprecation epic to P2 (not P1) — PRD lists deprecation alongside core features, but deprecation headers and tracking are not blocking v3 launch. V3 can go live without deprecation infrastructure. Prioritized behind pagination (P1) which is needed for v3 endpoint parity."
```

### Decision 6: SCOPE

```
mcp__ohno__add_task_activity:
  task_id: "epic-002"
  type: "decision"
  description: "SCOPE: Excluded refresh tokens and scoped permissions from OAuth story — PRD mentions 'future iteration' for scoped permissions and client credentials flow doesn't need refresh tokens (re-issue instead). Added to story's 'Out of Scope' section."
```

### Decision 7: SPLIT

```
mcp__ohno__add_task_activity:
  task_id: "epic-003"
  type: "decision"
  description: "SPLIT: Split list endpoint migration into two tasks — /users first as reference implementation (3h), then remaining endpoints (6h). Single task would be 9h (exceeds 8h max). Users endpoint serves as validated pattern before bulk migration."
```

---

## Step 5: Assign Skill Hints

Skills assigned via keyword detection during task creation:

| Task | Detected Keywords | Assigned Skill |
|------|-------------------|----------------|
| Versioned router factory | API endpoint, REST | api-design |
| Version negotiation middleware | API endpoint, middleware | api-design |
| V2 compatibility shim | API, adapter | api-design |
| OAuth client schema | database, schema, migration, prisma | database-design |
| Token endpoint | API endpoint, auth | api-design |
| Bearer token auth middleware | security, auth | api-design |
| Cursor pagination utility | API, pagination | api-design |
| Users migration | API endpoint | api-design |
| Remaining endpoints migration | API endpoint | api-design |
| Deprecation headers | API, middleware | api-design |
| V2 usage tracking | logging, monitoring, metrics | observability |
| Pagination spike | spike, feasibility | spike |
| JWT size spike | spike, investigate | spike |

### 5.2 Spike Opportunities Detected

Two spikes created (see decisions 1 and 2 above):
- Cursor pagination performance at scale (3h, blocks bulk migration)
- JWT token size overhead (2h, blocks auth middleware finalization)

### 5.3 Design Plugin Integration

Design plugin not available. No UI/UX-heavy features detected in this API migration PRD -- no design tasks needed.

---

## Step 6: Create Project Context

`.claude/PROJECT.md` generated:

```markdown
# API v3 Migration

## Overview
Migration from REST API v2 to v3 with versioned routing, OAuth 2.0 auth, cursor-based pagination, and v2 deprecation path.

## Tech Stack
- Node.js + Express
- PostgreSQL + Prisma
- Jest (testing)
- JWT (RS256) for OAuth tokens

## Feature Summary

### Epic: API Versioning Infrastructure (P0) — epic-001
- Version-aware router, negotiation middleware, v2 compatibility shim
- 3 tasks, ~11h

### Epic: V3 Authentication Model (P0) — epic-002
- OAuth 2.0 client credentials, bearer token middleware
- 3 tasks + 1 spike, ~12h

### Epic: V3 Pagination Overhaul (P1) — epic-003
- Cursor-based pagination library, endpoint migration
- 3 tasks + 1 spike, ~16h

### Epic: V2 Deprecation & Migration Path (P2) — epic-004
- Deprecation headers, usage tracking for sunset planning
- 2 tasks, ~6h

## Totals
- 4 epics, 4 stories, 13 tasks
- 2 spikes (~5h investigation)
- ~45h estimated implementation

## Starting Point
Begin with: **task-001** (Create versioned router factory) and **task-004** (Create OAuth client registration schema) — these are independent and unblock the most downstream work.

## Kanban
`npx @stevestomp/ohno-cli serve`
```

---

## Step 7: Sync and Report

```bash
npx @stevestomp/ohno-cli sync
# Synced 13 tasks, 4 stories, 4 epics to tasks.db
```

---

## Post-Completion Summary

```
Planning complete: 4 epics, 4 stories, 13 tasks
7 notable decisions to review

Review skipped per user request.
Run `/plan --review` later to walk through decisions.
```

---

## Headless Behavior Compliance Checklist

| Requirement | Status |
|-------------|--------|
| No interactive prompts issued | PASS -- all decisions auto-resolved |
| All auto-decisions logged via `add_task_activity` with type "decision" | PASS -- 7 decisions logged |
| Decision categories used (SPIKE, DEPENDENCY, PRIORITY, SCOPE, SPLIT) | PASS |
| Cross-cutting decisions logged on epics | PASS -- PRIORITY and SCOPE on epics |
| Task-specific decisions logged on tasks | PASS -- SPIKE, DEPENDENCY, SPLIT on tasks |
| Spike opportunities created (not just flagged) | PASS -- 2 spike tasks created |
| Design plugin check performed | PASS -- not available, continued without |
| Task descriptions are self-contained with Behavior/AC/Connects To/Patterns | PASS |
| Story descriptions include Given/When/Then AC, edge cases, out-of-scope | PASS |
| All tasks <= 8 hours | PASS -- max is 6h |
| Dependencies mapped | PASS -- 12 dependency links |
| PROJECT.md created in .claude/ | PASS |
| Sync executed | PASS |
| Post-completion summary displayed with decision count | PASS |
| Review skipped per user instruction | PASS |
