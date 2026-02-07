# Design Plugin Integration

When planning UI/UX heavy features, check if design plugin is available to enable design-first workflows.

## Detect UI/UX Heavy Features

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

## Detection Logic

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

## Design Plugin Availability Check

The design plugin availability was checked at the start of the workflow (Step 1).

Use the stored `design_plugin_available` variable to determine routing:

```python
# Already available from Step 1
if design_plugin_available:
    # Enable design-first workflows
else:
    # Suggest installation or proceed without design plugin
```

## Headless vs Interactive

**If `--headless` is active:**
- If design plugin IS available AND PRD is UI/UX heavy: automatically create design tasks with dependencies (option a). Log decision:
  ```
  mcp__ohno__add_task_activity(epic_id, "decision", "DESIGN: Auto-created design-first tasks for [story names] — PRD matches [N] UI/UX keyword categories")
  ```
- If design plugin is NOT available: continue without it (no prompt, no decision logged — this is the obvious default).

**If interactive (default, no flags):**
- Show the existing prompts below as-is (current behavior, unchanged).

## Design-First Workflow Suggestion

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

## Design Task Types

When creating design tasks, use appropriate task_type:

| Task Type | When to Use | Triggers |
|-----------|-------------|----------|
| `ux` | User flows, IA, interactions | `/design:ux` in `/work` |
| `ui` | Visual design, components | `/design:ui` in `/work` |
| `persona` | User research, personas | `/design:persona` in `/work` |
| `a11y` | Accessibility requirements | `/design:a11y` in `/work` |

These task types will trigger design routing in `/work` command (see Section 2.5 in work.md).

## Design Routing in Skill Hints

Update the skill hints table (Section 4) to explicitly include design routing:

**Design & UX** (expanded):
- User flows, wireframes, IA → `ux-design` (task_type: `ux`)
- Visual components, styling → `aesthetic-ui-designer` (task_type: `ui`)
- User research, personas → `persona-creation` (task_type: `persona`)
- Accessibility requirements → `accessibility-auditor` (task_type: `a11y`)

When design plugin is available, these skills map to `/design:*` commands.
When not available, tasks use standard skill-based implementation.

## Keyword Detection for Design

Add design keywords to the main keyword detection table:

| Keywords | Skill | Task Type |
|----------|-------|-----------|
| wireframe, mockup, user flow, journey, ia | ux-design | ux |
| visual, component, design system, tokens | aesthetic-ui-designer | ui |
| persona, user research, empathy map | persona-creation | persona |
| accessibility, a11y, wcag, screen reader | accessibility-auditor | a11y |

## Integration with Work Command

Tasks created with design task types will automatically route to design plugin in `/work`:

1. `/plan` creates task with `task_type: "ux"`
2. User runs `/work`
3. Work command detects design task type
4. Work routes to `/design:ux` (if plugin available)
5. Design command creates artifacts
6. Task is marked complete with design deliverables

See work.md Section 2.5 "Design Task Routing" for full routing logic.
