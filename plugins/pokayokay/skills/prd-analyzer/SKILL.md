---
name: prd-analyzer
description: Analyzes PRD documents, concept briefs, or feature specs and creates structured implementation plans with visual kanban tracking. Breaks requirements into epics, stories, and tasks with dependencies and estimates. Outputs to `.claude/` folder for integration with project-harness and other skills. Generates PROJECT.md for shared project context.
---

# PRD Analyzer & Implementation Planner

Transform product requirements into actionable implementation plans with visual kanban tracking.

**Integrates with:**
- `product-manager` — Audits completeness, adds remediation tasks
- `project-harness` — Reads PROJECT.md, manages work sessions
- `ux-design`, `api-design`, etc. — Assigned to specific features

## Process Overview

```
PRD/Brief → Analysis → Task Breakdown → .claude/ Output
    │           │            │              │
 Upload    Extract       Epic →         PROJECT.md
  doc      scope &      Story →         tasks.db
          features      Task            features.json
                                        kanban.html
```

## Output Location

All outputs go to `.claude/` folder in the project root:

```
.claude/
├── PROJECT.md          ← Project context (all skills read this)
├── tasks.db            ← SQLite database (source of truth)
├── features.json       ← Feature definitions with skill assignments
├── kanban.html         ← Interactive board
├── progress.md         ← Session progress tracking
└── implementation-plan.md  ← Markdown summary
```

---

## Quick Start

### 1. Analyze the Document

When given a PRD or concept brief:

```
1. Read the entire document
2. Extract: Goals, Features, Constraints, Dependencies
3. Identify scope boundaries (in/out)
4. Note technical requirements and assumptions
5. Assign skills to features based on type
```

### 2. Create Task Breakdown

Structure work hierarchically:

```
Epic (large feature area)
├── Story (user-facing capability)
│   ├── Task (implementable unit, 1-8 hours)
│   ├── Task
│   └── Task
└── Story
    └── Tasks...
```

### 3. Generate Outputs

Create all files in `.claude/`:
- `PROJECT.md` — Shared context for all skills
- `tasks.db` — SQLite database with full task structure
- `features.json` — Feature list with metadata
- `kanban.html` — Interactive board (open in browser)

---

## PROJECT.md Generation

The most important output — shared context for all skills.

### Template

```markdown
# Project: [Name]

## Overview
[1-2 sentence description from PRD]

## Status
- **Phase**: Planning | Design | Implementation | Polish | Launch
- **Created**: [Date]
- **Last Updated**: [Date]
- **Overall Progress**: 0/[N] stories complete

## Metrics
| Metric | Count |
|--------|-------|
| Epics | [N] |
| Stories | [N] |
| Estimated Hours | [N] |
| Estimated Days | [N] |

## Tech Stack
- **Frontend**: [Framework]
- **Backend**: [Framework]
- **Database**: [Database]
- **Hosting**: [Platform]

## Design Artifacts
[Include this section only if design artifacts found]

**Personas** (from `.claude/design/[project-name]/personas.md`):
- [Persona Name 1]
- [Persona Name 2]
- [Persona Name 3]

User stories validated against these personas.

## Feature Overview

| ID | Feature | Priority | Skill | Status |
|----|---------|----------|-------|--------|
| F001 | [Name] | P0 | [skill] | planned |
| F002 | [Name] | P0 | [skill] | planned |
| ... | ... | ... | ... | ... |

## Skill Assignments

| Skill | Features | Status |
|-------|----------|--------|
| ux-design | F001, F005, F012 | pending |
| api-design | F002, F003, F007 | pending |
| aesthetic-ui-designer | F001, F005 | blocked by ux-design |

## Current Gaps
[Updated by product-manager after audit]
[Include persona validation warnings if any:]
- User story references undefined persona: [Name] (Story: [ID])
  → Add persona definition or update story to use generic role

## Next Actions
1. [First recommended action]
2. [Second recommended action]

## Key Files
- PRD: [path or "uploaded"]
- Tasks DB: `.claude/tasks.db`
- Kanban: `.claude/kanban.html`
[If personas used:]
- Personas: `.claude/design/[project-name]/personas.md`

## Session Log
| Date | Session | Completed | Notes |
|------|---------|-----------|-------|
| [Date] | prd-analyzer | PROJECT.md, tasks.db | Initial setup |
```

---

## Skill Assignment

Assign skills to features based on their nature.

### Skill Mapping

| Feature Type | Primary Skill | Secondary Skills |
|--------------|---------------|------------------|
| User flows, wireframes | `ux-design` | `persona-creation` |
| REST/GraphQL APIs | `api-design` | `api-testing` |
| UI implementation | `aesthetic-ui-designer` | `frontend-design` |
| SDK/library creation | `sdk-development` | — |
| Data visualization | `ux-design` | `aesthetic-ui-designer` |
| Authentication/Security | `api-design` | — |
| Mobile screens | `ux-design` | `aesthetic-ui-designer` |
| Integrations (Slack, etc.) | `api-design` | — |
| Accessibility review | `accessibility-auditor` | — |

### Assignment Rules

1. **UX before UI**: Features needing design get `ux-design` first
2. **API before Frontend**: Data-dependent features get `api-design` first
3. **Audit at end**: All features get `product-manager` audit
4. **Accessibility check**: User-facing features get `accessibility-auditor`

### In features.json

```json
{
  "features": [
    {
      "id": "F001",
      "title": "Survey Studio",
      "priority": "P0",
      "assigned_skills": ["ux-design", "aesthetic-ui-designer"],
      "skill_order": ["ux-design", "aesthetic-ui-designer"],
      "current_skill": null,
      "audit_level": 0,
      "stories": ["story-001-01", "story-001-02", ...]
    }
  ]
}
```

---

## Analysis Framework

### Design Artifact Discovery

Before parsing the PRD, check for design artifacts:

```
1. Search for .claude/design/*/personas.md
2. If found:
   - Read file content
   - Parse persona names from headers: "# Persona: [Name]"
   - Store persona list for validation
3. If not found:
   - Proceed without persona validation
   - Continue normally
```

**Persona Name Extraction Pattern:**

```
# Persona: Maria Santos    → Extract "Maria Santos"
# Persona: Jamie Cooper    → Extract "Jamie Cooper"
## Demographics            → Ignore (sub-header)
### Goals                  → Ignore (sub-header)
```

Only extract from top-level persona headers (`# Persona:`).

### Document Parsing

Extract these elements from any PRD/brief:

| Element | What to Find | Output |
|---------|--------------|--------|
| **Vision** | Why build this? Problem solved? | 1-2 sentence summary |
| **Users** | Who uses it? Personas? | User types list (cross-reference with personas.md if available) |
| **Features** | What does it do? | Feature list with priority |
| **Scope** | What's included/excluded? | In/Out lists |
| **Constraints** | Tech stack, timeline, budget? | Constraint list |
| **Dependencies** | External systems, APIs, teams? | Dependency map |
| **Success Metrics** | How measured? | KPI list |
| **Risks** | What could go wrong? | Risk register |

**User Element Enhancement:**

If personas.md exists:
- Cross-reference PRD user types with persona names
- Suggest using specific personas instead of generic roles
- Note any personas not mentioned in PRD (might be relevant)

### Scope Classification

For each feature, classify:

```
P0 - Must Have (MVP, launch blocker)
P1 - Should Have (important, not blocking)
P2 - Nice to Have (future iteration)
P3 - Out of Scope (explicitly excluded)
```

### Ambiguity Detection

Flag unclear requirements:

```markdown
## Ambiguities Identified

1. **User authentication** — SSO required? Which providers?
2. **Data export** — Format not specified (CSV? JSON? Excel?)
3. **Mobile support** — Responsive web or native apps?

Recommend: Clarify before implementation planning.
```

---

## Database Schema

### Updated Schema with Audit Fields

```sql
-- Enable foreign keys
PRAGMA foreign_keys = ON;

-- Projects table
CREATE TABLE IF NOT EXISTS projects (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    phase TEXT DEFAULT 'planning' 
        CHECK(phase IN ('planning', 'design', 'implementation', 'polish', 'launch')),
    tech_stack TEXT,  -- JSON: {frontend, backend, database, hosting}
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Epics: Large feature areas
CREATE TABLE IF NOT EXISTS epics (
    id TEXT PRIMARY KEY,
    project_id TEXT REFERENCES projects(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    priority TEXT CHECK(priority IN ('P0', 'P1', 'P2', 'P3')) DEFAULT 'P1',
    status TEXT CHECK(status IN ('planned', 'in_progress', 'completed', 'cancelled')) DEFAULT 'planned',
    
    -- Skill assignment
    assigned_skills TEXT,      -- JSON array: ["ux-design", "api-design"]
    skill_order TEXT,          -- JSON array: order to run skills
    current_skill TEXT,        -- Currently active skill
    
    -- Audit fields (updated by product-manager)
    audit_level INTEGER DEFAULT 0 
        CHECK(audit_level BETWEEN 0 AND 5),
    audit_date TEXT,
    audit_gaps TEXT,           -- JSON array: ["no_frontend", "no_navigation"]
    
    color TEXT,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Stories: User-facing capabilities
CREATE TABLE IF NOT EXISTS stories (
    id TEXT PRIMARY KEY,
    epic_id TEXT REFERENCES epics(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    user_story TEXT,
    acceptance_criteria TEXT,
    estimate_days REAL,
    status TEXT CHECK(status IN ('backlog', 'ready', 'in_progress', 'review', 'done')) DEFAULT 'backlog',
    assigned_skill TEXT,       -- Which skill handles this story
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tasks: Implementable units
CREATE TABLE IF NOT EXISTS tasks (
    id TEXT PRIMARY KEY,
    story_id TEXT REFERENCES stories(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    task_type TEXT CHECK(task_type IN ('frontend', 'backend', 'database', 'design', 'devops', 'qa', 'documentation', 'other')) DEFAULT 'other',
    estimate_hours REAL,
    status TEXT DEFAULT 'todo' 
        CHECK(status IN ('todo', 'in_progress', 'review', 'done', 'blocked')),
    assignee TEXT,
    column_id TEXT DEFAULT 'todo',
    sort_order INTEGER DEFAULT 0,
    blocked_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP
);

-- Dependencies between tasks
CREATE TABLE IF NOT EXISTS dependencies (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    blocker_task_id TEXT REFERENCES tasks(id) ON DELETE CASCADE,
    blocked_task_id TEXT REFERENCES tasks(id) ON DELETE CASCADE,
    dependency_type TEXT CHECK(dependency_type IN ('blocks', 'related')) DEFAULT 'blocks',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(blocker_task_id, blocked_task_id)
);

-- Session log (for project-harness integration)
CREATE TABLE IF NOT EXISTS sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT UNIQUE NOT NULL,
    skill_used TEXT,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    stories_completed TEXT,    -- JSON array of story IDs
    notes TEXT
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_epics_priority ON epics(priority);
CREATE INDEX IF NOT EXISTS idx_epics_audit ON epics(audit_level);
CREATE INDEX IF NOT EXISTS idx_stories_epic ON stories(epic_id);
CREATE INDEX IF NOT EXISTS idx_stories_status ON stories(status);
CREATE INDEX IF NOT EXISTS idx_tasks_story ON tasks(story_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);

-- Useful views
CREATE VIEW IF NOT EXISTS v_epic_progress AS
SELECT 
    e.id,
    e.title,
    e.priority,
    e.audit_level,
    e.assigned_skills,
    COUNT(s.id) as total_stories,
    SUM(CASE WHEN s.status = 'done' THEN 1 ELSE 0 END) as done_stories,
    ROUND(100.0 * SUM(CASE WHEN s.status = 'done' THEN 1 ELSE 0 END) / COUNT(s.id), 1) as progress_pct
FROM epics e
LEFT JOIN stories s ON s.epic_id = e.id
GROUP BY e.id;

CREATE VIEW IF NOT EXISTS v_skill_workload AS
SELECT 
    e.assigned_skills,
    COUNT(DISTINCT e.id) as epic_count,
    COUNT(s.id) as story_count,
    SUM(CASE WHEN s.status != 'done' THEN 1 ELSE 0 END) as pending_stories
FROM epics e
LEFT JOIN stories s ON s.epic_id = e.id
GROUP BY e.assigned_skills;
```

---

## Task Breakdown Methodology

### Epic Definition

Epics are large feature areas (1-4 weeks of work):

```markdown
## Epic: User Authentication

**ID**: epic-001 (or F001)
**Priority**: P0
**Assigned Skills**: ["api-design", "ux-design", "aesthetic-ui-designer"]
**Skill Order**: api-design → ux-design → aesthetic-ui-designer

**Goal**: Users can create accounts and log in securely
**Scope**: Email/password, OAuth (Google, GitHub), password reset
**Out of Scope**: SSO, 2FA (P2)
**Dependencies**: Email service, OAuth provider setup
**Estimate**: 2 weeks
```

### Story Definition

Stories are user-facing capabilities (1-5 days):

```markdown
### Story: Email/Password Registration

**ID**: story-001-01
**Epic**: epic-001
**Assigned Skill**: api-design (backend-heavy story)

**As a** new user
**I want to** create an account with email and password
**So that** I can access the application

**Acceptance Criteria**:
- [ ] Email validation (format, uniqueness)
- [ ] Password requirements (8+ chars, complexity)
- [ ] Email verification flow
- [ ] Error handling for duplicates

**Estimate**: 3 days
```

**Persona-Based Stories:**

When design personas are available, prefer persona-specific stories over generic roles:

```markdown
### Story: Offline Soil Sample Collection

**ID**: story-003-01
**Epic**: epic-003
**Assigned Skill**: ux-design

**As Maria Santos** (persona from design artifacts)
**I want to** collect soil samples using my iPad without cell coverage
**So that** I can work in remote field areas without losing data

**Acceptance Criteria**:
- [ ] Offline mode stores data locally
- [ ] Auto-syncs when connection restored
- [ ] Clear indicator of offline/online status
- [ ] No data loss during connectivity transitions

**Estimate**: 4 days

**Persona Note:** This story addresses Maria's specific frustration with farm management apps that fail in areas without cell signal (see personas.md).
```

**Persona Validation:**

- **Valid:** "As Maria Santos, I want to..." (references defined persona)
- **Valid:** "As a farmer, I want to..." (generic role, no validation)
- **Warning:** "As John Doe, I want to..." (persona not in personas.md)

Generic roles are acceptable when:
- No personas.md exists
- Story applies to any user type
- Persona-specific details not relevant to the story

### Task Definition

Tasks are implementable units (1-8 hours):

```markdown
#### Task: Create registration form component

**ID**: task-001-01-01
**Story**: story-001-01
**Type**: Frontend
**Estimate**: 4h

**Description**: 
- Email input with validation
- Password input with strength indicator
- Confirm password field
- Submit button with loading state

**Acceptance**: Form validates and submits to API
**Blocked By**: None
**Blocks**: Registration API integration
```

---

## Workflow

### Step-by-Step Process

1. **Receive PRD/Brief**
   - Read full document
   - Ask clarifying questions if critical gaps

2. **Check for Design Artifacts** (optional)
   - Search for `.claude/design/*/personas.md`
   - If found, parse persona names
   - Make available for user story validation
   - If not found, proceed without persona validation

3. **Create Analysis Summary**
   - Vision, users, features, constraints
   - Scope classification (P0-P3)
   - Flag ambiguities
   - Assign skills to features

4. **Break Down Tasks**
   - Define epics from major features
   - Break epics into stories
   - Break stories into tasks (≤8h each)
   - Map dependencies
   - **Validate user stories against personas** (if personas.md exists)

5. **Generate Outputs to `.claude/`**
   - Create PROJECT.md (shared context)
     - Include design artifacts section if personas used
     - Document persona validation warnings in gaps section
   - Create SQLite database (tasks.db)
   - Generate features.json
   - Generate kanban HTML
   - Write implementation plan markdown
     - Include persona validation summary
   - Create progress.md template

6. **Deliver Files**
   - All files in `.claude/` folder
   - Present kanban.html for interactive use
   - Report persona validation results (if applicable)
   - Explain next steps (which skill to run first)

---

## features.json Format

```json
{
  "project": {
    "name": "VoiceForm AI",
    "description": "AI-powered voice survey platform",
    "created_at": "2026-01-10T10:00:00Z"
  },
  "summary": {
    "total_epics": 30,
    "total_stories": 150,
    "total_hours": 1972,
    "by_priority": {
      "P0": 5,
      "P1": 12,
      "P2": 10,
      "P3": 3
    }
  },
  "features": [
    {
      "id": "F001",
      "epic_id": "epic-001",
      "title": "Survey Studio",
      "description": "Create and configure surveys with AI assistance",
      "priority": "P0",
      "assigned_skills": ["ux-design", "aesthetic-ui-designer"],
      "skill_order": ["ux-design", "aesthetic-ui-designer"],
      "dependencies": [],
      "audit_level": 0,
      "stories": ["story-001-01", "story-001-02", "story-001-03", "story-001-04", "story-001-05"]
    },
    {
      "id": "F002",
      "epic_id": "epic-002",
      "title": "RAG Pipeline",
      "description": "Document processing and semantic search",
      "priority": "P0",
      "assigned_skills": ["api-design"],
      "skill_order": ["api-design"],
      "dependencies": ["F001"],
      "audit_level": 0,
      "stories": ["story-002-01", "story-002-02", "story-002-03", "story-002-04", "story-002-05"]
    }
  ],
  "skill_summary": {
    "ux-design": ["F001", "F003", "F011"],
    "api-design": ["F002", "F007", "F008"],
    "aesthetic-ui-designer": ["F001", "F003", "F011"],
    "accessibility-auditor": ["F001", "F003"]
  }
}
```

---

## Design Artifact Integration

### Consuming Personas from Design Plugin

The prd-analyzer can consume persona definitions from the design plugin to validate user stories against real user research.

**Persona Discovery:**

```
1. Check for .claude/design/*/personas.md files
2. If found:
   - Parse persona names from "# Persona: [Name]" headers
   - Make available for user story validation
3. If not found:
   - Proceed normally without persona validation
   - No errors or warnings about missing file
```

**Persona Validation Process:**

When creating user stories:

```
IF personas.md exists:
  FOR EACH user story:
    IF story format is "As [Persona Name], I want to..."
      Check if [Persona Name] exists in personas.md
      IF NOT found:
        WARN: "User story references undefined persona: [Name]"
        SUGGEST: "Add persona to .claude/design/[project]/personas.md or use generic role"
    ELSE IF story format is "As a [role], I want to..."
      # Generic role-based story, no validation needed
      Continue normally
```

**Distinguishing Personas from Roles:**

- **Persona reference:** "As Maria Santos, I want to..." (specific name, title case)
- **Generic role:** "As a farmer, I want to..." (generic role, lowercase "a")

Only validate persona references, not generic roles.

**Multiple Design Projects:**

If multiple `.claude/design/*/personas.md` files exist:

```
projects = find_all(".claude/design/*/personas.md")
IF length(projects) == 1:
  USE projects[0]
ELSE IF length(projects) > 1:
  ASK USER: "Multiple design projects found: [list]. Which personas should I use?"
  USE selected_project
```

**PROJECT.md Documentation:**

When personas are used, add section to PROJECT.md:

```markdown
## Design Artifacts

**Personas** (from `.claude/design/[project-name]/personas.md`):
- [Persona Name 1]
- [Persona Name 2]
- [Persona Name 3]

User stories validated against these personas.

## Current Gaps
[If validation warnings exist]
- User story references undefined persona: [Name] (Story: [ID])
  → Add persona definition or update story to use generic role
```

**Validation Output:**

Include validation summary in implementation-plan.md:

```markdown
## Design Artifacts Used

**Personas:** `.claude/design/[project]/personas.md`
- Maria Santos
- Alex Kim
- Jamie Cooper

**Persona Validation:**
✓ 12 stories reference defined personas
⚠ 2 stories reference undefined personas:
  - Story-005-02: References "John Doe" (not in personas.md)
  - Story-008-01: References "Jane Smith" (not in personas.md)

**Recommendation:** Add persona definitions for John Doe and Jane Smith, or revise stories to use generic roles ("As a [role]").
```

**Backward Compatibility:**

- Skill works normally if no personas.md exists
- No errors, warnings, or blocking behavior
- User stories processed without persona validation
- Optional note in output: "No design personas found (proceeding without validation)"

### Integration Points

### With product-manager

After implementation, product-manager:
1. Reads `tasks.db` and `features.json`
2. Scans codebase for implementation evidence
3. Updates `audit_level` and `audit_gaps` in epics table
4. Adds remediation tasks to `tasks.db`
5. Updates `PROJECT.md` with current gaps

### With project-harness

Project-harness:
1. Reads `PROJECT.md` for context
2. Checks `tasks.db` for next work
3. Logs sessions to `sessions` table
4. Updates `progress.md` after each session

### With Implementation Skills

Skills like `ux-design`, `api-design`:
1. Read `PROJECT.md` for context
2. Check `features.json` for assigned work
3. Filter by `assigned_skills` containing their name
4. Update story status when complete

### With Design Plugin

Design plugin integration:
1. Reads `.claude/design/*/personas.md` for user persona definitions
2. Validates user stories reference defined personas
3. Documents design artifacts used in PROJECT.md
4. Reports validation warnings in implementation plan

---

## Anti-Patterns

### Analysis Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Accepting vague requirements | Builds wrong thing | Flag ambiguities, ask questions |
| Scope creep in breakdown | Adds unspecified work | Stick to documented requirements |
| Ignoring constraints | Infeasible plan | Check tech stack, timeline, budget |
| Missing dependencies | Blocked work | Map all external dependencies |
| No skill assignment | Work not routed | Assign skills to every feature |
| Ignoring design artifacts | Misses user research insights | Check for .claude/design/*/personas.md, use when available |

### Task Breakdown Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Tasks > 8 hours | Too vague to estimate | Split into smaller tasks |
| No acceptance criteria | Unclear "done" | Define measurable criteria |
| Missing task types | Can't assign properly | Tag: frontend, backend, design, etc. |
| Circular dependencies | Deadlock | Identify and break cycles |
| Everything P0 | No prioritization | Force-rank priorities |

### Output Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Output to random location | Skills can't find | Always use `.claude/` |
| No PROJECT.md | No shared context | Always generate PROJECT.md |
| No skill assignments | Manual routing needed | Assign skills during analysis |
| Missing features.json | No machine-readable list | Always generate features.json |

---

## Checklist: Complete PRD Analysis

### Before Starting
- [ ] Full PRD/brief received
- [ ] Clarifying questions asked (if needed)
- [ ] Tech stack identified
- [ ] `.claude/` folder created
- [ ] Design artifacts checked (`.claude/design/*/personas.md`)

### During Analysis
- [ ] All features extracted
- [ ] Priorities assigned (P0-P3)
- [ ] Skills assigned to features
- [ ] Ambiguities documented
- [ ] Personas loaded (if available)

### Task Breakdown
- [ ] Epics created (1 per feature)
- [ ] Stories created (achievable chunks)
- [ ] Tasks created (≤8h each)
- [ ] Dependencies mapped
- [ ] User stories validated against personas (if available)

### Output Generation
- [ ] PROJECT.md created
  - [ ] Design artifacts section (if personas used)
  - [ ] Persona validation warnings (if any)
- [ ] tasks.db created with full schema
- [ ] features.json created
- [ ] kanban.html generated
- [ ] progress.md template created
- [ ] implementation-plan.md written
  - [ ] Persona validation summary (if applicable)

### Handoff
- [ ] Next steps explained
- [ ] First skill to run identified
- [ ] Files presented to user
- [ ] Persona validation results reported (if applicable)

---

## References

- [references/prd-analysis.md](references/prd-analysis.md) — Deep dive on document analysis
- [references/task-breakdown.md](references/task-breakdown.md) — Detailed breakdown methodology
- [references/kanban-setup.md](references/kanban-setup.md) — Database schema and HTML generation
- [references/skill-routing.md](references/skill-routing.md) — Skill assignment logic
- [references/design-artifact-integration.md](references/design-artifact-integration.md) — Consuming design plugin personas for story validation
- [templates/kanban.html](templates/kanban.html) — Kanban board template
