# Kanban Board Setup

Technical details for generating the local kanban board system.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      .claude/ Folder                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  PROJECT.md        tasks.db           features.json             │
│  (Context)         (SQLite)           (Machine-readable)        │
│      │                 │                   │                    │
│      │                 │                   │                    │
│      └────────┬────────┴───────────────────┘                    │
│               │                                                 │
│               ▼                                                 │
│         Source of Truth                                         │
│               │                                                 │
│               ▼                                                 │
│         kanban.html ◄──────── Reads from tasks.db               │
│         (Interactive)                                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Output Files

All outputs go to `.claude/` folder:

| File | Purpose | Updated By |
|------|---------|------------|
| `PROJECT.md` | Shared context | planning, feature-audit |
| `tasks.db` | Source of truth | All skills |
| `features.json` | Machine-readable features | planning |
| `kanban.html` | Interactive board | Generated, manual sync |
| `progress.md` | Session tracking | work-session |

## Data Generation

### Python Database Helper

```python
import sqlite3
import json
from datetime import datetime
from pathlib import Path

class KanbanDB:
    def __init__(self, db_path: str = ".claude/tasks.db"):
        self.db_path = db_path
        Path(db_path).parent.mkdir(parents=True, exist_ok=True)
        self.conn = sqlite3.connect(db_path)
        self.conn.row_factory = sqlite3.Row
        self._init_schema()
    
    def _init_schema(self):
        """Initialize database schema."""
        # Execute full schema from above
        self.conn.executescript(SCHEMA_SQL)
        self.conn.commit()
    
    def create_project(self, id: str, name: str, description: str = None,
                       tech_stack: dict = None) -> str:
        self.conn.execute(
            """INSERT INTO projects (id, name, description, tech_stack) 
               VALUES (?, ?, ?, ?)""",
            (id, name, description, json.dumps(tech_stack) if tech_stack else None)
        )
        self.conn.commit()
        return id
    
    def create_epic(self, id: str, project_id: str, title: str, 
                    priority: str = "P1", description: str = None,
                    assigned_skills: list = None, skill_order: list = None,
                    color: str = None) -> str:
        current_skill = skill_order[0] if skill_order else None
        self.conn.execute(
            """INSERT INTO epics 
               (id, project_id, title, description, priority, 
                assigned_skills, skill_order, current_skill, color)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (id, project_id, title, description, priority,
             json.dumps(assigned_skills) if assigned_skills else None,
             json.dumps(skill_order) if skill_order else None,
             current_skill, color)
        )
        self.conn.commit()
        return id
    
    def create_story(self, id: str, epic_id: str, title: str,
                     description: str = None, user_story: str = None,
                     acceptance_criteria: str = None, estimate_days: float = None,
                     assigned_skill: str = None) -> str:
        self.conn.execute(
            """INSERT INTO stories 
               (id, epic_id, title, description, user_story, 
                acceptance_criteria, estimate_days, assigned_skill)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            (id, epic_id, title, description, user_story, 
             acceptance_criteria, estimate_days, assigned_skill)
        )
        self.conn.commit()
        return id
    
    def create_task(self, id: str, story_id: str, title: str,
                    task_type: str = "other", estimate_hours: float = None,
                    description: str = None) -> str:
        self.conn.execute(
            """INSERT INTO tasks (id, story_id, title, description, task_type, estimate_hours)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (id, story_id, title, description, task_type, estimate_hours)
        )
        self.conn.commit()
        return id
    
    def add_dependency(self, blocker_id: str, blocked_id: str, 
                       dep_type: str = "blocks"):
        self.conn.execute(
            """INSERT OR IGNORE INTO dependencies 
               (blocker_task_id, blocked_task_id, dependency_type)
               VALUES (?, ?, ?)""",
            (blocker_id, blocked_id, dep_type)
        )
        self.conn.commit()
    
    def update_task_status(self, task_id: str, status: str):
        now = datetime.now().isoformat()
        
        if status == "in_progress":
            self.conn.execute(
                """UPDATE tasks SET status = ?, column_id = ?, started_at = ? 
                   WHERE id = ?""",
                (status, status, now, task_id)
            )
        elif status == "done":
            self.conn.execute(
                """UPDATE tasks SET status = ?, column_id = ?, completed_at = ? 
                   WHERE id = ?""",
                (status, status, now, task_id)
            )
        else:
            self.conn.execute(
                "UPDATE tasks SET status = ?, column_id = ? WHERE id = ?",
                (status, status, task_id)
            )
        self.conn.commit()
    
    def update_epic_audit(self, epic_id: str, audit_level: int, 
                          audit_gaps: list = None):
        """Update audit information (called by feature-audit)."""
        self.conn.execute(
            """UPDATE epics SET 
               audit_level = ?, audit_date = ?, audit_gaps = ?
               WHERE id = ?""",
            (audit_level, datetime.now().isoformat(), 
             json.dumps(audit_gaps) if audit_gaps else None, epic_id)
        )
        self.conn.commit()
    
    def transition_skill(self, epic_id: str):
        """Move to next skill in order (called when skill completes)."""
        result = self.conn.execute(
            "SELECT skill_order, current_skill FROM epics WHERE id = ?",
            (epic_id,)
        ).fetchone()
        
        if not result or not result['skill_order']:
            return
        
        skill_order = json.loads(result['skill_order'])
        current = result['current_skill']
        
        if current in skill_order:
            idx = skill_order.index(current)
            if idx + 1 < len(skill_order):
                next_skill = skill_order[idx + 1]
                self.conn.execute(
                    "UPDATE epics SET current_skill = ? WHERE id = ?",
                    (next_skill, epic_id)
                )
            else:
                # All skills done
                self.conn.execute(
                    "UPDATE epics SET current_skill = NULL WHERE id = ?",
                    (epic_id,)
                )
        self.conn.commit()
    
    def log_session(self, session_id: str, skill_used: str, 
                    stories_completed: list = None, notes: str = None):
        """Log a work session (called by work-session)."""
        self.conn.execute(
            """INSERT INTO sessions 
               (session_id, skill_used, stories_completed, notes)
               VALUES (?, ?, ?, ?)""",
            (session_id, skill_used,
             json.dumps(stories_completed) if stories_completed else None, notes)
        )
        self.conn.commit()
    
    def get_work_for_skill(self, skill_name: str) -> list:
        """Get features assigned to a skill."""
        cursor = self.conn.execute("""
            SELECT id, title, priority, description
            FROM epics
            WHERE current_skill = ?
              AND status != 'completed'
            ORDER BY 
                CASE priority WHEN 'P0' THEN 0 WHEN 'P1' THEN 1 
                              WHEN 'P2' THEN 2 ELSE 3 END
        """, (skill_name,))
        return [dict(row) for row in cursor.fetchall()]
    
    def get_audit_summary(self) -> list:
        """Get audit level summary."""
        cursor = self.conn.execute("SELECT * FROM v_audit_summary")
        return [dict(row) for row in cursor.fetchall()]
    
    def export_json(self, output_path: str = ".claude/tasks.json"):
        """Export all data to JSON."""
        data = {
            "exported_at": datetime.now().isoformat(),
            "projects": [],
            "epics": [],
            "stories": [],
            "tasks": [],
            "dependencies": [],
            "sessions": []
        }
        
        for table in data.keys():
            if table == "exported_at":
                continue
            try:
                cursor = self.conn.execute(f"SELECT * FROM {table}")
                data[table] = [dict(row) for row in cursor.fetchall()]
            except:
                pass
        
        with open(output_path, "w") as f:
            json.dump(data, f, indent=2, default=str)
        
        return output_path
    
    def close(self):
        self.conn.close()
```

### Usage Example

```python
# Create database and populate from PRD analysis
db = KanbanDB(".claude/tasks.db")

# Create project
db.create_project(
    "proj-001", 
    "VoiceForm AI", 
    "AI-powered voice survey platform",
    tech_stack={"frontend": "Next.js", "backend": "Node.js", "database": "PostgreSQL"}
)

# Create epic with skill assignments
db.create_epic(
    id="epic-001",
    project_id="proj-001",
    title="Data Pipeline",
    priority="P0",
    assigned_skills=["database-design", "api-design"],
    skill_order=["database-design", "api-design"],
    color="#3B82F6"
)

# Create story
db.create_story(
    id="story-001-01",
    epic_id="epic-001",
    title="Schema Design",
    user_story="As a developer, I want efficient database schemas...",
    estimate_days=2,
    assigned_skill="database-design"
)

# Create tasks (vertical slices — each task is end-to-end for one feature)
db.create_task("task-001-01-01", "story-001-01", "Goal input: form + API endpoint + DB insert", "feature", 4)
db.create_task("task-001-01-02", "story-001-01", "Document upload: dropzone + upload API + storage", "feature", 3)

# Add dependencies
db.add_dependency("task-001-01-01", "task-001-01-02")

# Export to JSON
db.export_json()

db.close()
```

---

## JSON Export Format

```json
{
  "exported_at": "2026-01-12T10:00:00",
  "projects": [
    {
      "id": "proj-001",
      "name": "VoiceForm AI",
      "description": "AI-powered voice survey platform",
      "phase": "implementation",
      "tech_stack": "{\"frontend\": \"Next.js\", \"backend\": \"Node.js\"}"
    }
  ],
  "epics": [
    {
      "id": "epic-001",
      "project_id": "proj-001",
      "title": "Data Pipeline",
      "priority": "P0",
      "status": "in_progress",
      "assigned_skills": "[\"database-design\", \"api-design\"]",
      "skill_order": "[\"database-design\", \"api-design\"]",
      "current_skill": "database-design",
      "audit_level": 0,
      "audit_date": null,
      "audit_gaps": null
    }
  ],
  "stories": [...],
  "tasks": [...],
  "dependencies": [...],
  "sessions": [...]
}
```


## Kanban HTML Updates

The kanban.html template should display:
- Epic priority badges
- Audit level indicators
- Current skill badges
- Skill filter dropdown

### Additional Filter

```html
<!-- Add to filters bar -->
<div class="filter-group">
    <span class="filter-label">Skill</span>
    <select class="filter-select" id="filterSkill">
        <option value="">All Skills</option>
        <option value="database-design">Database Design</option>
        <option value="api-design">API Design</option>
        <option value="testing-strategy">Testing Strategy</option>
        <!-- dynamically populated -->
    </select>
</div>

<div class="filter-group">
    <span class="filter-label">Audit Level</span>
    <select class="filter-select" id="filterAudit">
        <option value="">All Levels</option>
        <option value="0">L0 - Not Started</option>
        <option value="1">L1 - Backend Only</option>
        <option value="2">L2 - Frontend Exists</option>
        <option value="3">L3 - Routable</option>
        <option value="4">L4 - Accessible</option>
        <option value="5">L5 - Complete</option>
    </select>
</div>
```

### Audit Level Badge

```html
<!-- In task card -->
<span class="audit-badge level-${epic.audit_level}">
    L${epic.audit_level}
</span>

<style>
.audit-badge {
    font-size: 10px;
    padding: 2px 6px;
    border-radius: 3px;
    font-weight: 600;
}
.audit-badge.level-0 { background: #6b7280; color: white; }
.audit-badge.level-1 { background: #ef4444; color: white; }
.audit-badge.level-2 { background: #f97316; color: white; }
.audit-badge.level-3 { background: #eab308; color: black; }
.audit-badge.level-4 { background: #22c55e; color: white; }
.audit-badge.level-5 { background: #3b82f6; color: white; }
</style>
```

---

## Sync Script

Script to regenerate kanban.html from tasks.db:

```python
#!/usr/bin/env python3
# sync-kanban.py

import sqlite3
import json
from pathlib import Path

def sync_kanban(db_path=".claude/tasks.db", output_path=".claude/kanban.html"):
    """Regenerate kanban.html from tasks.db"""
    
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    
    # Export data
    data = {
        "projects": [],
        "epics": [],
        "stories": [],
        "tasks": [],
        "dependencies": []
    }
    
    for table in data.keys():
        cursor = conn.execute(f"SELECT * FROM {table}")
        data[table] = [dict(row) for row in cursor.fetchall()]
    
    # Read template
    template_path = Path(__file__).parent / "kanban-template.html"
    if template_path.exists():
        template = template_path.read_text()
    else:
        # Use embedded template
        template = KANBAN_TEMPLATE
    
    # Embed data
    html = template.replace(
        "// EMBEDDED_DATA will be set",
        f"window.EMBEDDED_DATA = {json.dumps(data, default=str)};"
    )
    
    # Write output
    Path(output_path).write_text(html)
    print(f"✅ Synced kanban.html from {db_path}")
    
    conn.close()

if __name__ == "__main__":
    sync_kanban()
```

---

## File Generation Workflow

When planning runs:

1. **Create `.claude/` folder**
   ```bash
   mkdir -p .claude
   ```

2. **Generate tasks.db**
   ```python
   db = KanbanDB(".claude/tasks.db")
   # ... populate from PRD analysis
   db.close()
   ```

3. **Generate features.json**
   ```python
   with open(".claude/features.json", "w") as f:
       json.dump(features_data, f, indent=2)
   ```

4. **Generate PROJECT.md**
   ```python
   with open(".claude/PROJECT.md", "w") as f:
       f.write(project_md_content)
   ```

5. **Generate kanban.html**
   ```python
   # Embed data into template
   sync_kanban()
   ```

6. **Create progress.md template**
   ```python
   with open(".claude/progress.md", "w") as f:
       f.write(progress_template)
   ```

