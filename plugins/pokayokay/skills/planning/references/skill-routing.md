# Skill Routing

Logic for assigning skills to features and managing the workflow between them.

> **Note:** Design work routes to design plugin via `/design:*` commands

## Skill Catalog

Available skills that can be assigned to features:

| Skill | Purpose | Input | Output |
|-------|---------|-------|--------|
| `api-design` | REST/GraphQL API design | Feature requirements | OpenAPI spec, endpoints |
| `testing-strategy` | API test suites | API spec | Test files |
| `frontend-design` | Frontend architecture | Requirements | Component structure |
| `sdk-development` | SDK/library creation | API spec | SDK package |
| `feature-audit` | Completeness audit | Codebase | Gap report |

---

## Assignment Rules

### By Feature Type

```python
def assign_skills(feature: dict) -> list[str]:
    """Assign skills based on feature characteristics."""
    
    skills = []
    title = feature['title'].lower()
    description = feature.get('description', '').lower()
    
    # API/Backend features
    if any(word in title + description for word in [
        'api', 'endpoint', 'backend', 'service', 'integration',
        'authentication', 'authorization', 'webhook', 'sync'
    ]):
        skills.append('api-design')

    # SDK/Library features
    if any(word in title + description for word in [
        'sdk', 'library', 'package', 'npm', 'client'
    ]):
        skills.append('sdk-development')

    # If no skills assigned, default based on priority
    if not skills:
        skills = ['api-design']
    
    return skills
```

### Skill Order Rules

Skills should run in this order:

```
1. API
   - api-design (endpoints, contracts)
   - testing-strategy (after API implemented)

2. Implementation
   - sdk-development (if SDK needed)

3. Quality
   - feature-audit (final audit)
```

### Dependency Graph

```
      ┌──────────────┐
      │  api-design  │
      └──────┬───────┘
             │
             ▼
      ┌──────────────┐
      │  testing-strategy │
      └──────┬───────┘
             │
             ▼
      ┌──────────────┐
      │sdk-development│
      └──────┬───────┘
             │
             ▼
      ┌──────────────┐
      │feature-audit│
      └──────────────┘
```

---

## Feature to Skill Mapping

### Common Feature Types

| Feature Pattern | Primary | Secondary | Order |
|-----------------|---------|-----------|-------|
| "REST API for X" | api-design | testing-strategy | api → testing |
| "Slack Integration" | api-design | — | api |
| "SDK/Client Library" | sdk-development | — | sdk |

### Example Assignments

```json
{
  "features": [
    {
      "id": "F002",
      "title": "RAG Pipeline",
      "type_signals": ["api", "backend", "service"],
      "assigned_skills": ["api-design"],
      "skill_order": ["api-design"]
    },
    {
      "id": "F003",
      "title": "Chat API",
      "type_signals": ["api", "realtime"],
      "assigned_skills": ["api-design", "testing-strategy"],
      "skill_order": ["api-design", "testing-strategy"]
    },
    {
      "id": "F026",
      "title": "Mobile SDK",
      "type_signals": ["sdk", "mobile", "library"],
      "assigned_skills": ["sdk-development"],
      "skill_order": ["sdk-development"]
    }
  ]
}
```

---

## Skill State Tracking

### In tasks.db

```sql
-- Track skill assignment at epic level
UPDATE epics SET
    assigned_skills = '["api-design", "testing-strategy"]',
    skill_order = '["api-design", "testing-strategy"]',
    current_skill = 'api-design'
WHERE id = 'epic-001';

-- Track skill assignment at story level
UPDATE stories SET
    assigned_skill = 'api-design'
WHERE id = 'story-001-01';

-- Query features by skill
SELECT e.id, e.title, e.priority
FROM epics e
WHERE e.assigned_skills LIKE '%api-design%'
  AND e.current_skill = 'api-design'
ORDER BY
    CASE e.priority
        WHEN 'P0' THEN 0
        WHEN 'P1' THEN 1
        WHEN 'P2' THEN 2
        ELSE 3
    END;
```

### Skill Transition

```sql
-- When skill completes, move to next
UPDATE epics SET
    current_skill = (
        SELECT json_extract(skill_order, '$[' || (
            SELECT instr(skill_order, current_skill) + length(current_skill)
        ) || ']')
    ),
    updated_at = datetime('now')
WHERE id = 'epic-001';

-- Or explicitly
UPDATE epics SET
    current_skill = 'testing-strategy',  -- was 'api-design'
    updated_at = datetime('now')
WHERE id = 'epic-001';
```

---

## Routing Logic for Claude Code

### Reading Assigned Work

When a skill is invoked, it should:

```python
def get_my_work(skill_name: str, db_path: str) -> list:
    """Get features assigned to this skill."""
    
    conn = sqlite3.connect(db_path)
    
    # Get epics where this skill is current
    epics = conn.execute("""
        SELECT id, title, priority, description
        FROM epics
        WHERE current_skill = ?
          AND status != 'completed'
        ORDER BY 
            CASE priority 
                WHEN 'P0' THEN 0 
                WHEN 'P1' THEN 1 
                WHEN 'P2' THEN 2 
                ELSE 3 
            END
    """, (skill_name,)).fetchall()
    
    return [dict(e) for e in epics]
```

### Marking Work Complete

When a skill finishes:

```python
def complete_skill_work(skill_name: str, epic_id: str, db_path: str):
    """Mark skill as complete, transition to next."""
    
    conn = sqlite3.connect(db_path)
    
    # Get skill order
    result = conn.execute("""
        SELECT skill_order, current_skill
        FROM epics WHERE id = ?
    """, (epic_id,)).fetchone()
    
    skill_order = json.loads(result['skill_order'])
    current_idx = skill_order.index(skill_name)
    
    # Move to next skill or mark complete
    if current_idx + 1 < len(skill_order):
        next_skill = skill_order[current_idx + 1]
        conn.execute("""
            UPDATE epics SET
                current_skill = ?,
                updated_at = datetime('now')
            WHERE id = ?
        """, (next_skill, epic_id))
    else:
        # All skills complete
        conn.execute("""
            UPDATE epics SET
                current_skill = NULL,
                status = 'completed',
                updated_at = datetime('now')
            WHERE id = ?
        """, (epic_id,))
    
    conn.commit()
```

---

## PROJECT.md Skill Section

### Template

```markdown
## Skill Assignments

### By Skill

| Skill | Features | Priority | Status |
|-------|----------|----------|--------|
| api-design | F002, F007, F008 | P0, P0, P0 | pending |
| testing-strategy | F002, F007 | P0, P0 | blocked |
| sdk-development | F026 | P1 | not started |
| feature-audit | All features | — | not started |

### Skill Dependencies

```
api-design ──────────────────► testing-strategy
                                     │
                                     ▼
                              sdk-development
                                     │
                                     ▼
                              feature-audit
```

### Next Skill to Run

Based on dependencies and P0 priorities:
1. **api-design** for F002 (RAG Pipeline) — no blockers

After those complete:
2. **testing-strategy** for F002, F007
```

---

## Automation Helpers

### SQL: Pending Work by Skill

```sql
-- Get all pending work grouped by skill
SELECT 
    e.current_skill as skill,
    e.priority,
    COUNT(*) as feature_count,
    GROUP_CONCAT(e.id) as features
FROM epics e
WHERE e.current_skill IS NOT NULL
  AND e.status != 'completed'
GROUP BY e.current_skill, e.priority
ORDER BY 
    CASE e.priority 
        WHEN 'P0' THEN 0 
        WHEN 'P1' THEN 1 
        WHEN 'P2' THEN 2 
        ELSE 3 
    END,
    e.current_skill;
```

### SQL: Skill Progress

```sql
-- Track how much work each skill has completed
SELECT 
    skill,
    SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed,
    SUM(CASE WHEN status = 'in_progress' THEN 1 ELSE 0 END) as in_progress,
    SUM(CASE WHEN status = 'planned' THEN 1 ELSE 0 END) as pending,
    COUNT(*) as total
FROM (
    SELECT 
        e.id,
        e.status,
        json_each.value as skill
    FROM epics e, json_each(e.assigned_skills)
) grouped
GROUP BY skill;
```

### Bash: Check Next Skill

```bash
#!/bin/bash
# next-skill.sh - Determine which skill to run next

DB_PATH=".claude/tasks.db"

echo "=== Next Skill to Run ==="

# Get P0 features with pending skills
sqlite3 "$DB_PATH" "
SELECT current_skill, GROUP_CONCAT(id, ', ') as features
FROM epics
WHERE current_skill IS NOT NULL
  AND status != 'completed'
  AND priority = 'P0'
GROUP BY current_skill
LIMIT 1;
"
```

---

## Edge Cases

### Feature Needs Multiple Skills Simultaneously

Some features may need parallel work:
- API design + testing can happen after implementation

Handle with:
```json
{
  "skill_order": [
    "api-design",      // sequential
    "testing-strategy"      // sequential
  ]
}
```

### Skill Not Available

If a skill isn't in the user's collection:
1. Check `.claude/skills/` for available skills
2. Suggest alternative or manual approach
3. Log gap in PROJECT.md

### Feature Doesn't Need Any Skills

Pure configuration or documentation features:
```json
{
  "assigned_skills": [],
  "skill_order": [],
  "notes": "Manual configuration, no skill needed"
}
```

---

## Integration Checklist

### planning Output
- [ ] Every feature has `assigned_skills`
- [ ] Every feature has `skill_order`
- [ ] `current_skill` set to first in order
- [ ] PROJECT.md includes skill assignments section
- [ ] features.json includes skill_summary

### Skill Invocation
- [ ] Skill reads PROJECT.md first
- [ ] Skill queries tasks.db for assigned work
- [ ] Skill updates status when complete
- [ ] Skill transitions to next skill in order

### feature-audit Audit
- [ ] Runs after all skills complete
- [ ] Checks implementation matches assignments
- [ ] Updates audit_level in tasks.db
- [ ] Adds remediation tasks if gaps found
