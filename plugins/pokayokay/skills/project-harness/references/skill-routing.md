# Skill Routing Reference

Complete mapping of task types, feature characteristics, and work patterns to appropriate skills.

> **Note**: Design work routes to `/design:*` commands (requires design plugin)

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
| Code architecture | architecture-review | sdk-development |
| SDK/Library creation | sdk-development | api-design |
| Figma plugins | figma-plugin | - |

### By Task Type (from tasks.db)

| task_type | Skill | Notes |
|-----------|-------|-------|
| backend | api-design | Endpoints, business logic |
| database | architecture-review | Schema design, migrations |
| devops | - | No specific skill (use Claude knowledge) |
| qa | api-testing | Test suites |
| documentation | - | No specific skill |
| other | - | Analyze context |

### By Keywords in Feature/Task Title

| Keywords | Suggested Skill |
|----------|-----------------|
| "API", "endpoint", "REST", "GraphQL" | api-design |
| "test", "testing", "spec", "coverage" | api-testing |
| "refactor", "architecture", "structure" | architecture-review |
| "SDK", "library", "package", "npm" | sdk-development |
| "Figma", "plugin", "design tool" | figma-plugin |

## Skill Capabilities Matrix

### Core Development Skills

| Skill | Creates | Analyzes | Tests | Documents |
|-------|---------|----------|-------|-----------|
| api-design | ✓ | ✓ | - | ✓ |
| api-testing | - | ✓ | ✓ | ✓ |
| architecture-review | - | ✓ | - | ✓ |
| sdk-development | ✓ | ✓ | ✓ | ✓ |

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

### Example 2: No Hint Provided

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
