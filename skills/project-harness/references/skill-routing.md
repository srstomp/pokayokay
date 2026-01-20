# Skill Routing Reference

Complete mapping of task types, feature characteristics, and work patterns to appropriate skills.

## Routing Decision Tree

```
START
  │
  ▼
┌─────────────────────────────┐
│ Does feature have           │
│ skill_hint in features.json?│
└─────────────┬───────────────┘
              │
     ┌────────┴────────┐
     │ YES             │ NO
     ▼                 ▼
┌─────────────┐  ┌─────────────────┐
│ Use hinted  │  │ Analyze feature │
│ skill(s)    │  │ characteristics │
└─────────────┘  └────────┬────────┘
                          │
                          ▼
                 ┌─────────────────┐
                 │ Match to skill  │
                 │ by type below   │
                 └─────────────────┘
```

## Primary Skill Mapping

### By Feature Type

| Feature Type | Primary Skill | Secondary Skills |
|--------------|---------------|------------------|
| API/Backend endpoints | api-design | api-testing |
| User interface | aesthetic-ui-designer | ux-design |
| User flows/journeys | ux-design | persona-creation |
| User research | persona-creation | ux-design |
| Accessibility audit | accessibility-auditor | ux-design |
| Code architecture | architecture-review | sdk-development |
| SDK/Library creation | sdk-development | api-design |
| Marketing/Landing pages | marketing-website | aesthetic-ui-designer |
| Figma plugins | figma-plugin | - |

### By Task Type (from tasks.db)

| task_type | Skill | Notes |
|-----------|-------|-------|
| frontend | aesthetic-ui-designer | UI components, styling |
| backend | api-design | Endpoints, business logic |
| database | architecture-review | Schema design, migrations |
| design | ux-design | Wireframes, flows |
| devops | - | No specific skill (use Claude knowledge) |
| qa | api-testing | Test suites |
| documentation | - | No specific skill |
| other | - | Analyze context |

### By Keywords in Feature/Task Title

| Keywords | Suggested Skill |
|----------|-----------------|
| "API", "endpoint", "REST", "GraphQL" | api-design |
| "test", "testing", "spec", "coverage" | api-testing |
| "UI", "component", "button", "form", "modal" | aesthetic-ui-designer |
| "flow", "journey", "wireframe", "prototype" | ux-design |
| "persona", "user research", "interview" | persona-creation |
| "a11y", "accessibility", "WCAG", "screen reader" | accessibility-auditor |
| "refactor", "architecture", "structure" | architecture-review |
| "SDK", "library", "package", "npm" | sdk-development |
| "landing", "marketing", "homepage", "conversion" | marketing-website |
| "Figma", "plugin", "design tool" | figma-plugin |

## Skill Capabilities Matrix

### Core Development Skills

| Skill | Creates | Analyzes | Tests | Documents |
|-------|---------|----------|-------|-----------|
| api-design | ✓ | ✓ | - | ✓ |
| api-testing | - | ✓ | ✓ | ✓ |
| aesthetic-ui-designer | ✓ | ✓ | - | - |
| architecture-review | - | ✓ | - | ✓ |
| sdk-development | ✓ | ✓ | ✓ | ✓ |

### UX/Design Skills

| Skill | Creates | Analyzes | Research | Audit |
|-------|---------|----------|----------|-------|
| ux-design | ✓ | ✓ | ✓ | - |
| persona-creation | ✓ | - | ✓ | - |
| accessibility-auditor | - | ✓ | - | ✓ |
| marketing-website | ✓ | ✓ | - | - |

### Specialized Skills

| Skill | Domain | Primary Use |
|-------|--------|-------------|
| figma-plugin | Design tools | Figma plugin development |

## Multi-Skill Workflows

Some features benefit from multiple skills in sequence:

### New API Feature

```
1. api-design      → Design endpoints, request/response
2. architecture-review → Verify fits existing structure
3. api-testing     → Create test suite
```

### New UI Feature

```
1. ux-design       → Define user flow
2. aesthetic-ui-designer → Implement components
3. accessibility-auditor → Verify accessibility
```

### New User-Facing Product

```
1. persona-creation → Define target users
2. ux-design       → Design experience
3. aesthetic-ui-designer → Build UI
4. accessibility-auditor → Audit accessibility
5. marketing-website → Create landing page
```

### SDK/Library Project

```
1. architecture-review → Plan structure
2. api-design      → Design public API
3. sdk-development → Implement package
4. api-testing     → Test suite
```

## Skill Invocation Protocol

When routing to a skill:

### 1. Announce Skill Switch

```markdown
## Skill Invocation: api-design

**Reason**: Feature F003 requires REST API endpoint design
**Task**: T012 - Design user CRUD endpoints
**Context**: Part of Authentication epic

Switching to api-design skill...
```

### 2. Load Skill Documentation

Read the skill's SKILL.md file to understand:
- Required inputs
- Expected outputs
- Workflow steps
- Anti-patterns to avoid

### 3. Execute Within Skill Context

Follow the skill's prescribed workflow until task complete.

### 4. Return to Harness

```markdown
## Skill Complete: api-design

**Output**: 
- Endpoint specifications in /docs/api/users.md
- OpenAPI schema updated

**Returning to project-harness...**
**Syncing kanban...** ✓
```

## When No Skill Matches

If no skill matches the task:

1. **Check if task is well-defined**
   - Vague tasks may need breakdown first
   
2. **Use Claude's general capabilities**
   - Many tasks don't need specialized skills
   
3. **Ask human for guidance**
   - "This task doesn't match any skill. Should I proceed with general approach or do you have specific guidance?"

## Skill Availability Check

Before routing, verify skill is available:

```bash
# Skills should be in one of:
ls /mnt/skills/user/       # User-added skills
ls /mnt/skills/public/     # Anthropic public skills
ls /mnt/skills/examples/   # Example skills
```

If skill not found, inform human and suggest alternatives.

## Routing Examples

### Example 1: API Endpoint Feature

```json
{
  "id": "F003",
  "title": "User API Endpoints",
  "description": "CRUD operations for user management",
  "skill_hint": "api-design, api-testing"
}
```

**Routing**: api-design → api-testing (in sequence)

### Example 2: Dashboard UI Feature

```json
{
  "id": "F005",
  "title": "Analytics Dashboard",
  "description": "Visual dashboard with charts and metrics",
  "skill_hint": "ux-design, aesthetic-ui-designer"
}
```

**Routing**: ux-design (for flow) → aesthetic-ui-designer (for implementation)

### Example 3: No Hint Provided

```json
{
  "id": "F007",
  "title": "Email Notifications",
  "description": "Send transactional emails to users"
}
```

**Analysis**: 
- Keywords: "email", "notifications" 
- Task type: backend
- No specific skill match

**Routing**: Use general Claude capabilities (no skill)

### Example 4: Accessibility Review

```json
{
  "id": "F010",
  "title": "WCAG Compliance Audit",
  "description": "Ensure all UI meets WCAG 2.1 AA standards",
  "skill_hint": "accessibility-auditor"
}
```

**Routing**: accessibility-auditor (single skill)
