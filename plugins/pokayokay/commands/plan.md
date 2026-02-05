---
description: Analyze PRD and create implementation plan with task breakdown
argument-hint: [--headless] [--review] <prd-path>
skill: prd-analyzer
---

# PRD Analysis Workflow

Analyze the PRD at `$ARGUMENTS` and create a structured implementation plan.

## Argument Parsing

Parse `$ARGUMENTS` to extract:
1. **Mode**: `--headless` (autonomous, no prompts) or `--review` (review existing plan) or default (interactive)
2. **PRD Path**: Remaining argument after flags

Example arguments:
- `docs/prd.md` → mode=interactive, path=docs/prd.md
- `--headless docs/prd.md` → mode=headless, path=docs/prd.md
- `--review` → mode=review, path=none (loads from ohno)

### Mode Routing

- If `--review`: skip to "## Plan Review Session" section below
- If `--headless`: run Steps 1-7 with all prompts auto-decided (see Headless Behavior below)
- Otherwise: run Steps 1-7 interactively (current behavior)

## Headless Behavior

When `--headless` is active, suppress ALL user-facing prompts and auto-decide:

### Decision Logging

Every auto-decision MUST be logged via ohno:

```
mcp__ohno__add_task_activity:
  task_id: <relevant_task_or_epic_id>
  type: "decision"
  description: "CATEGORY: rationale"
```

Categories: SPIKE, DESIGN, SPLIT, MERGE, DEPENDENCY, PRIORITY, SCOPE

Examples:
- `"SPIKE: Created spike for Redis session storage — PRD says 'fast sessions' but doesn't specify technology"`
- `"DESIGN: Added 3 design-first tasks — PRD mentions wireframes, user flows, responsive layout (2+ UI/UX categories detected)"`
- `"DEPENDENCY: Made payment integration depend on auth spike — need session approach first"`

Cross-cutting decisions (SPLIT, SCOPE, MERGE) go on the epic. Task-specific decisions go on the task.

### Auto-Decisions

| Interactive Prompt | Headless Auto-Decision | Decision Category |
|-------------------|----------------------|-------------------|
| Design plugin: "Create design tasks now?" | Yes (create design tasks + dependencies) | DESIGN |
| Design plugin: "Continue without design plugin?" | Yes (continue without) | — (no decision needed) |
| Spike opportunity detected | Create the spike task | SPIKE |
| Feature split into multiple stories | Split and log rationale | SPLIT |
| Non-obvious dependency added | Add dependency and log | DEPENDENCY |
| Priority differs from PRD ordering | Assign and log rationale | PRIORITY |
| PRD item excluded as out-of-scope | Exclude and log rationale | SCOPE |

### Post-Completion Summary

After Step 7 (Sync and Report), display:

```
Planning complete: [N] epics, [N] stories, [N] tasks
[N] notable decisions to review

Review now? (or run `/plan --review` later)
```

If user says yes, proceed to "## Plan Review Session" below.
If user says no or doesn't respond, end the session.

## Steps

### 1. Check Design Plugin Availability

Before analyzing the PRD, check if the design plugin is installed to enable design-first workflows for UI/UX heavy features.

```python
def is_design_plugin_available():
    """Check if design plugin commands are available"""
    design_commands = ['/design:ux', '/design:ui', '/design:persona', '/design:a11y', '/design:marketing']
    return any(has_command(cmd) for cmd in design_commands)

# Store result for later use
design_plugin_available = is_design_plugin_available()
```

This check is non-blocking - it only detects availability. The result will be used later during task creation to:
- Route design-related tasks to `/design:*` commands when available
- Suggest design plugin installation for UI/UX heavy features when not available
- Enable design-first workflows that create design artifacts before implementation

### 2. Read the PRD
Read and understand the document at the provided path. Extract:
- Project name and description
- Core features and requirements
- Technical constraints
- Success criteria

### 3. Initialize ohno (if needed)
```bash
npx @stevestomp/ohno-cli init
```

### 4. Create Hierarchical Structure

Use the ohno MCP tools to create a proper epic → story → task hierarchy:

#### 4.1 Create Epics (Major Features)
For each major feature area, create an epic with priority:
```
mcp__ohno__create_epic:
  title: "User Authentication"
  description: "Complete auth system with login, registration, password reset"
  priority: "P0"  # P0=critical, P1=high, P2=medium, P3=low
```

#### 4.2 Create Stories (User-Facing Capabilities)
For each epic, create stories representing user-facing chunks:
```
mcp__ohno__create_story:
  title: "Email/Password Registration"
  epic_id: "<epic_id from step above>"
  description: "Users can create accounts with email and password"
```

#### 4.3 Create Tasks (Implementable Units)
For each story, create tasks (1-8 hours each):
```
mcp__ohno__create_task:
  title: "Create registration form component"
  story_id: "<story_id from step above>"
  task_type: "feature"  # feature, bug, chore, spike, test
  estimate_hours: 4
```

#### 4.4 Add Dependencies
Link tasks that depend on each other:
```
mcp__ohno__add_dependency:
  task_id: "<task that is blocked>"
  depends_on_task_id: "<task that must complete first>"
```

**Important**: Always create in order: epics first, then stories (with epic_id), then tasks (with story_id). This ensures proper relationships.

### 5. Assign Skill Hints

Tag tasks with recommended skills based on their content:

**Backend & API**:
- API endpoints, REST/GraphQL → api-design
- Database schema, migrations → database-design
- Architecture decisions → architecture-review
- Third-party integrations → api-integration

**DevOps & Infrastructure**:
- CI/CD pipelines, GitHub Actions → ci-cd-expert
- Logging, monitoring, alerts → observability

**Quality & Security**:
- Test architecture, coverage → testing-strategy
- Security review, authentication → security-audit

**Investigation**:
- Time-boxed technical questions → spike (task_type: spike)
- Multi-day technology evaluation → deep-research (task_type: research)

### 5.1 Keyword Detection

When skill not explicitly specified, detect from task title/description:

| Keywords | Skill | Task Type |
|----------|-------|-----------|
| database, schema, migration, model, prisma | database-design | feature |
| test, coverage, e2e, playwright, cypress, jest | testing-strategy | test |
| deploy, pipeline, ci/cd, github actions, release | ci-cd-expert | chore |
| security, auth, encryption, vulnerability, owasp | security-audit | feature |
| logging, monitoring, alert, metrics, tracing | observability | feature |
| spike, investigate, feasibility, can we, how hard | spike | spike |
| research, evaluate, compare, vendor, assessment | deep-research | research |

### 5.2 Detect Spike Opportunities

For features with high uncertainty, create spike tasks:
- "Can we...?" or "Is it possible to...?" questions
- Performance or feasibility unknowns
- Technology selection decisions
- Complex integration assessments

Example:
```
mcp__ohno__create_task:
  title: "Spike: Can D1 handle multi-tenant isolation?"
  story_id: "<relevant_story_id>"
  task_type: "spike"
  estimate_hours: 3
```

### 5.3 Design Plugin Integration

When planning UI/UX heavy features, check if design plugin is available to enable design-first workflows.

#### Detect UI/UX Heavy Features

A feature is considered UI/UX heavy if the PRD contains:

**Visual/Component Keywords:**
- `wireframe`, `mockup`, `prototype`, `design system`
- `component`, `interface`, `visual`, `layout`, `responsive`
- `ui`, `ux`, `user interface`, `user experience`

**Interaction Keywords:**
- `flow`, `journey`, `interaction`, `navigation`
- `animation`, `transition`, `gesture`

**Design System Keywords:**
- `tokens`, `theming`, `branding`, `style guide`
- `design tokens`, `design system`, `component library`

**Persona/Research Keywords:**
- `persona`, `user research`, `empathy map`, `user needs`

**Accessibility Keywords:**
- `accessibility`, `a11y`, `wcag`, `screen reader`, `keyboard navigation`

#### Detection Logic

```python
def is_uiux_heavy(prd_text):
    """Check if PRD describes UI/UX heavy work"""
    text = prd_text.lower()

    visual_keywords = ['wireframe', 'mockup', 'prototype', 'component',
                       'interface', 'visual', 'layout', 'responsive',
                       'ui', 'ux', 'user interface', 'user experience']

    interaction_keywords = ['flow', 'journey', 'interaction', 'navigation',
                           'animation', 'transition']

    design_system_keywords = ['tokens', 'theming', 'design system',
                             'component library', 'style guide']

    persona_keywords = ['persona', 'user research', 'empathy map']

    accessibility_keywords = ['accessibility', 'a11y', 'wcag', 'screen reader']

    # Count keyword categories found
    categories_found = 0
    if any(kw in text for kw in visual_keywords):
        categories_found += 1
    if any(kw in text for kw in interaction_keywords):
        categories_found += 1
    if any(kw in text for kw in design_system_keywords):
        categories_found += 1
    if any(kw in text for kw in persona_keywords):
        categories_found += 1
    if any(kw in text for kw in accessibility_keywords):
        categories_found += 1

    # Feature is UI/UX heavy if 2+ categories present
    return categories_found >= 2
```

#### Design Plugin Availability Check

The design plugin availability was checked at the start of the workflow (Step 1).

Use the stored `design_plugin_available` variable to determine routing:

```python
# Already available from Step 1
if design_plugin_available:
    # Enable design-first workflows
else:
    # Suggest installation or proceed without design plugin
```

#### Headless vs Interactive

**If `--headless` is active:**
- If design plugin IS available AND PRD is UI/UX heavy: automatically create design tasks with dependencies (option a). Log decision:
  ```
  mcp__ohno__add_task_activity(epic_id, "decision", "DESIGN: Auto-created design-first tasks for [story names] — PRD matches [N] UI/UX keyword categories")
  ```
- If design plugin is NOT available: continue without it (no prompt, no decision logged — this is the obvious default).

**If interactive (default, no flags):**
- Show the existing prompts below as-is (current behavior, unchanged).

#### Design-First Workflow Suggestion

**When design plugin IS available (`design_plugin_available == True`):**

After creating epics and stories, suggest design tasks BEFORE implementation:

```markdown
## Design-First Workflow Detected

This feature appears to be UI/UX heavy. The design plugin is available.

**Suggested workflow:**
1. Run design commands BEFORE creating implementation tasks
2. Design artifacts inform implementation requirements
3. Implementation follows validated designs

**Design commands to consider:**
- `/design:ux` - For user flows, information architecture, interactions
- `/design:ui` - For visual design, components, design tokens
- `/design:persona` - For user personas and research insights
- `/design:a11y` - For accessibility requirements and audit

**Example approach:**
1. Create epic and stories as planned
2. For each story, run appropriate design commands first
3. Design outputs become input to implementation tasks
4. Create implementation tasks based on design artifacts

Would you like to:
  a) Create design tasks now (recommended)
  b) Skip and create implementation tasks only
  c) Mix: Some stories need design first, others don't
```

**If user chooses (a) - Create design tasks:**

For each story identified as design-heavy, create design tasks:

```
mcp__ohno__create_task:
  title: "Design: [UX/UI aspect] for [story name]"
  story_id: "<story_id>"
  task_type: "ux"  # or "ui", "persona", "a11y"
  estimate_hours: 3
  description: "Run /design:[command] to create design artifacts before implementation"
```

Then create implementation tasks that depend on design tasks:

```
mcp__ohno__add_dependency:
  task_id: "<implementation_task_id>"
  depends_on_task_id: "<design_task_id>"
```

**When design plugin is NOT available:**

Show installation suggestion:

```markdown
## UI/UX Heavy Feature Detected

This feature appears to require significant design work, but the design plugin is not installed.

**The design plugin provides:**
- UX flows and user journeys (`/design:ux`)
- Visual design and components (`/design:ui`)
- User personas and research (`/design:persona`)
- Accessibility audits (`/design:a11y`)
- Marketing pages (`/design:marketing`)

**Benefits of design-first approach:**
- Validate user flows before building
- Establish design system early
- Catch accessibility issues in design phase
- Reduce implementation rework

**To enable design workflows:**
```bash
claude plugin install design
```

Then re-run `/plan` to include design tasks in the breakdown.

**Continue without design plugin?** [y/n]
```

If user chooses yes, continue with standard task creation. If no, pause and suggest plugin installation.

#### Design Task Types

When creating design tasks, use appropriate task_type:

| Task Type | When to Use | Triggers |
|-----------|-------------|----------|
| `ux` | User flows, IA, interactions | `/design:ux` in `/work` |
| `ui` | Visual design, components | `/design:ui` in `/work` |
| `persona` | User research, personas | `/design:persona` in `/work` |
| `a11y` | Accessibility requirements | `/design:a11y` in `/work` |

These task types will trigger design routing in `/work` command (see Section 2.5 in work.md).

#### Design Routing in Skill Hints

Update the skill hints table (Section 4) to explicitly include design routing:

**Design & UX** (expanded):
- User flows, wireframes, IA → `ux-design` (task_type: `ux`)
- Visual components, styling → `aesthetic-ui-designer` (task_type: `ui`)
- User research, personas → `persona-creation` (task_type: `persona`)
- Accessibility requirements → `accessibility-auditor` (task_type: `a11y`)

When design plugin is available, these skills map to `/design:*` commands.
When not available, tasks use standard skill-based implementation.

#### Keyword Detection Updates

Add design keywords to Section 4.1 table:

| Keywords | Skill | Task Type |
|----------|-------|-----------|
| wireframe, mockup, user flow, journey, ia | ux-design | ux |
| visual, component, design system, tokens | aesthetic-ui-designer | ui |
| persona, user research, empathy map | persona-creation | persona |
| accessibility, a11y, wcag, screen reader | accessibility-auditor | a11y |

#### Integration with Work Command

Tasks created with design task types will automatically route to design plugin in `/work`:

1. `/plan` creates task with `task_type: "ux"`
2. User runs `/work`
3. Work command detects design task type
4. Work routes to `/design:ux` (if plugin available)
5. Design command creates artifacts
6. Task is marked complete with design deliverables

See work.md Section 2.5 "Design Task Routing" for full routing logic.

### 6. Create Project Context
Create `.claude/PROJECT.md` with:
- Project overview
- Tech stack decisions
- Feature summary with task IDs
- Links to ohno kanban

### 7. Sync and Report
```bash
npx @stevestomp/ohno-cli sync
```

Report to user:
- Total tasks created
- Epic/story breakdown
- Recommended starting point
- Link to kanban board

## Output

After completion:
- Tasks in ohno (view with `npx @stevestomp/ohno-cli tasks`)
- `.claude/PROJECT.md` for session context
- Kanban at `npx @stevestomp/ohno-cli serve`

## Related Commands

- `/pokayokay:work` - Start implementation after planning
- `/pokayokay:audit` - Check feature completeness after implementation
- `/pokayokay:review` - Analyze planning patterns over time
