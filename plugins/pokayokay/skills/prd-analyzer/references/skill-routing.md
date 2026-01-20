# Skill Routing

Logic for assigning skills to features and managing the workflow between them.

## Skill Catalog

Available skills that can be assigned to features:

| Skill | Purpose | Input | Output |
|-------|---------|-------|--------|
| `ux-design` | User flows, wireframes, patterns | Feature requirements | UX spec, wireframes |
| `api-design` | REST/GraphQL API design | Feature requirements | OpenAPI spec, endpoints |
| `api-testing` | API test suites | API spec | Test files |
| `aesthetic-ui-designer` | UI implementation | UX spec | React/RN/Swift components |
| `frontend-design` | Frontend architecture | Requirements | Component structure |
| `sdk-development` | SDK/library creation | API spec | SDK package |
| `accessibility-auditor` | A11y compliance | UI components | Audit report, fixes |
| `persona-creation` | User personas | Research | Persona docs |
| `marketing-website` | Landing pages | Brief | Marketing site |
| `product-manager` | Completeness audit | Codebase | Gap report |

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
    
    # UI/Frontend features
    if any(word in title + description for word in [
        'dashboard', 'page', 'screen', 'ui', 'interface', 'form',
        'wizard', 'modal', 'component', 'widget'
    ]):
        skills.append('ux-design')
        skills.append('aesthetic-ui-designer')
    
    # Mobile features
    if any(word in title + description for word in [
        'mobile', 'ios', 'android', 'app', 'native'
    ]):
        skills.append('ux-design')
        skills.append('aesthetic-ui-designer')
    
    # SDK/Library features
    if any(word in title + description for word in [
        'sdk', 'library', 'package', 'npm', 'client'
    ]):
        skills.append('sdk-development')
    
    # Data/Analytics features
    if any(word in title + description for word in [
        'analytics', 'dashboard', 'chart', 'report', 'visualization'
    ]):
        skills.append('ux-design')
        skills.append('aesthetic-ui-designer')
    
    # If no skills assigned, default based on priority
    if not skills:
        if feature.get('priority') == 'P0':
            skills = ['api-design', 'ux-design']
        else:
            skills = ['api-design']
    
    return skills
```

### Skill Order Rules

Skills should run in this order:

```
1. Research/Planning
   - persona-creation (if user research needed)

2. Design
   - ux-design (structure, flows, wireframes)

3. API
   - api-design (endpoints, contracts)
   - api-testing (after API implemented)

4. Implementation
   - aesthetic-ui-designer (UI components)
   - sdk-development (if SDK needed)

5. Quality
   - accessibility-auditor (after UI implemented)
   - product-manager (final audit)
```

### Dependency Graph

```
                    ┌─────────────────┐
                    │ persona-creation │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │    ux-design    │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
      ┌──────────────┐ ┌──────────┐ ┌──────────────┐
      │  api-design  │ │  (skip)  │ │ frontend-    │
      └──────┬───────┘ └──────────┘ │   design     │
             │                       └──────┬───────┘
             ▼                              │
      ┌──────────────┐                      │
      │  api-testing │                      │
      └──────────────┘                      │
                                            ▼
                                   ┌─────────────────────┐
                                   │ aesthetic-ui-       │
                                   │      designer       │
                                   └──────────┬──────────┘
                                              │
                                              ▼
                                   ┌─────────────────────┐
                                   │ accessibility-      │
                                   │       auditor       │
                                   └──────────┬──────────┘
                                              │
                                              ▼
                                   ┌─────────────────────┐
                                   │  product-manager    │
                                   └─────────────────────┘
```

---

## Feature to Skill Mapping

### Common Feature Types

| Feature Pattern | Primary | Secondary | Order |
|-----------------|---------|-----------|-------|
| "User Dashboard" | ux-design | aesthetic-ui-designer | ux → aesthetic |
| "REST API for X" | api-design | api-testing | api → testing |
| "Mobile App" | ux-design | aesthetic-ui-designer | ux → aesthetic |
| "Admin Panel" | ux-design | aesthetic-ui-designer | ux → aesthetic |
| "Slack Integration" | api-design | — | api |
| "Search Feature" | api-design | ux-design, aesthetic | api → ux → aesthetic |
| "Analytics Dashboard" | ux-design | aesthetic-ui-designer | ux → aesthetic |
| "Export Feature" | api-design | ux-design | api → ux |
| "Settings Page" | ux-design | aesthetic-ui-designer | ux → aesthetic |
| "SDK/Client Library" | sdk-development | — | sdk |

### Example Assignments

```json
{
  "features": [
    {
      "id": "F001",
      "title": "Survey Studio",
      "type_signals": ["ui", "wizard", "form"],
      "assigned_skills": ["ux-design", "aesthetic-ui-designer"],
      "skill_order": ["ux-design", "aesthetic-ui-designer"]
    },
    {
      "id": "F002", 
      "title": "RAG Pipeline",
      "type_signals": ["api", "backend", "service"],
      "assigned_skills": ["api-design"],
      "skill_order": ["api-design"]
    },
    {
      "id": "F003",
      "title": "Chat Interface",
      "type_signals": ["ui", "interface", "realtime"],
      "assigned_skills": ["ux-design", "api-design", "aesthetic-ui-designer"],
      "skill_order": ["api-design", "ux-design", "aesthetic-ui-designer"]
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
    assigned_skills = '["ux-design", "aesthetic-ui-designer"]',
    skill_order = '["ux-design", "aesthetic-ui-designer"]',
    current_skill = 'ux-design'
WHERE id = 'epic-001';

-- Track skill assignment at story level
UPDATE stories SET
    assigned_skill = 'ux-design'
WHERE id = 'story-001-01';

-- Query features by skill
SELECT e.id, e.title, e.priority
FROM epics e
WHERE e.assigned_skills LIKE '%ux-design%'
  AND e.current_skill = 'ux-design'
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
    current_skill = 'aesthetic-ui-designer',  -- was 'ux-design'
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
| ux-design | F001, F003, F011 | P0, P0, P1 | pending |
| api-design | F002, F007, F008 | P0, P0, P0 | pending |
| aesthetic-ui-designer | F001, F003, F011 | P0, P0, P1 | blocked |
| accessibility-auditor | All UI features | — | not started |
| product-manager | All features | — | not started |

### Skill Dependencies

```
ux-design ──────────────────────┐
                                ▼
api-design ──────────────────► aesthetic-ui-designer
                                        │
                                        ▼
                              accessibility-auditor
                                        │
                                        ▼
                               product-manager
```

### Next Skill to Run

Based on dependencies and P0 priorities:
1. **api-design** for F002 (RAG Pipeline) — no blockers
2. **ux-design** for F001 (Survey Studio) — no blockers

After those complete:
3. **aesthetic-ui-designer** for F001, F003
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
- API design + UX design can happen in parallel
- Frontend + Backend can be parallel

Handle with:
```json
{
  "skill_order": [
    ["api-design", "ux-design"],  // parallel
    "aesthetic-ui-designer"       // sequential
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

### prd-analyzer Output
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

### product-manager Audit
- [ ] Runs after all skills complete
- [ ] Checks implementation matches assignments
- [ ] Updates audit_level in tasks.db
- [ ] Adds remediation tasks if gaps found
