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
| `PROJECT.md` | Shared context | prd-analyzer, product-manager |
| `tasks.db` | Source of truth | All skills |
| `features.json` | Machine-readable features | prd-analyzer |
| `kanban.html` | Interactive board | Generated, manual sync |
| `progress.md` | Session tracking | project-harness |

---

## Database Schema

### Full SQLite Schema (with Skill & Audit Fields)

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
    
    -- Skill assignment (NEW)
    assigned_skills TEXT,      -- JSON array: ["ux-design", "api-design"]
    skill_order TEXT,          -- JSON array: order to run skills
    current_skill TEXT,        -- Currently active skill
    
    -- Audit fields (NEW - updated by product-manager)
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
    assigned_skill TEXT,       -- Which skill handles this story (NEW)
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

-- Task dependencies
CREATE TABLE IF NOT EXISTS dependencies (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    blocker_task_id TEXT REFERENCES tasks(id) ON DELETE CASCADE,
    blocked_task_id TEXT REFERENCES tasks(id) ON DELETE CASCADE,
    dependency_type TEXT CHECK(dependency_type IN ('blocks', 'related')) DEFAULT 'blocks',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(blocker_task_id, blocked_task_id)
);

-- Tags for filtering
CREATE TABLE IF NOT EXISTS tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    color TEXT
);

CREATE TABLE IF NOT EXISTS task_tags (
    task_id TEXT REFERENCES tasks(id) ON DELETE CASCADE,
    tag_id INTEGER REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (task_id, tag_id)
);

-- Session log (NEW - for project-harness integration)
CREATE TABLE IF NOT EXISTS sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT UNIQUE NOT NULL,
    skill_used TEXT,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    stories_completed TEXT,    -- JSON array of story IDs
    notes TEXT
);

-- Kanban board configuration
CREATE TABLE IF NOT EXISTS kanban_columns (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    status_mapping TEXT,
    sort_order INTEGER DEFAULT 0,
    wip_limit INTEGER,
    color TEXT
);

-- Default columns
INSERT OR IGNORE INTO kanban_columns (id, title, status_mapping, sort_order) VALUES
    ('backlog', 'Backlog', 'todo', 0),
    ('in_progress', 'In Progress', 'in_progress', 1),
    ('review', 'Review', 'review', 2),
    ('done', 'Done', 'done', 3),
    ('blocked', 'Blocked', 'blocked', 4);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_epics_priority ON epics(priority);
CREATE INDEX IF NOT EXISTS idx_epics_audit ON epics(audit_level);
CREATE INDEX IF NOT EXISTS idx_epics_skill ON epics(current_skill);
CREATE INDEX IF NOT EXISTS idx_stories_epic ON stories(epic_id);
CREATE INDEX IF NOT EXISTS idx_stories_status ON stories(status);
CREATE INDEX IF NOT EXISTS idx_stories_skill ON stories(assigned_skill);
CREATE INDEX IF NOT EXISTS idx_tasks_story ON tasks(story_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_dependencies_blocker ON dependencies(blocker_task_id);
CREATE INDEX IF NOT EXISTS idx_dependencies_blocked ON dependencies(blocked_task_id);

-- Views for common queries
CREATE VIEW IF NOT EXISTS v_epic_progress AS
SELECT 
    e.id,
    e.title,
    e.priority,
    e.audit_level,
    e.assigned_skills,
    e.current_skill,
    COUNT(s.id) as total_stories,
    SUM(CASE WHEN s.status = 'done' THEN 1 ELSE 0 END) as done_stories,
    ROUND(100.0 * SUM(CASE WHEN s.status = 'done' THEN 1 ELSE 0 END) / COUNT(s.id), 1) as progress_pct
FROM epics e
LEFT JOIN stories s ON s.epic_id = e.id
GROUP BY e.id;

CREATE VIEW IF NOT EXISTS v_tasks_with_context AS
SELECT 
    t.*,
    s.title as story_title,
    s.assigned_skill,
    e.title as epic_title,
    e.priority as epic_priority,
    e.color as epic_color,
    e.audit_level
FROM tasks t
LEFT JOIN stories s ON t.story_id = s.id
LEFT JOIN epics e ON s.epic_id = e.id;

CREATE VIEW IF NOT EXISTS v_audit_summary AS
SELECT 
    audit_level,
    CASE audit_level
        WHEN 0 THEN 'Not Started'
        WHEN 1 THEN 'Backend Only'
        WHEN 2 THEN 'Frontend Exists'
        WHEN 3 THEN 'Routable'
        WHEN 4 THEN 'Accessible'
        WHEN 5 THEN 'Complete'
    END as level_name,
    COUNT(*) as count,
    GROUP_CONCAT(id) as features
FROM epics
GROUP BY audit_level
ORDER BY audit_level;

-- Triggers to update timestamps
CREATE TRIGGER IF NOT EXISTS update_epic_timestamp 
AFTER UPDATE ON epics
BEGIN
    UPDATE epics SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_story_timestamp 
AFTER UPDATE ON stories
BEGIN
    UPDATE stories SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_task_timestamp 
AFTER UPDATE ON tasks
BEGIN
    UPDATE tasks SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;
```

---

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
        """Update audit information (called by product-manager)."""
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
        """Log a work session (called by project-harness)."""
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
    title="Survey Studio",
    priority="P0",
    assigned_skills=["ux-design", "aesthetic-ui-designer"],
    skill_order=["ux-design", "aesthetic-ui-designer"],
    color="#3B82F6"
)

# Create story
db.create_story(
    id="story-001-01",
    epic_id="epic-001",
    title="Goal Input Interface",
    user_story="As a researcher, I want to describe my survey goals...",
    estimate_days=2,
    assigned_skill="ux-design"
)

# Create tasks
db.create_task("task-001-01-01", "story-001-01", "Create GoalInput component", "frontend", 4)
db.create_task("task-001-01-02", "story-001-01", "Add document upload", "frontend", 3)

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
      "title": "Survey Studio",
      "priority": "P0",
      "status": "in_progress",
      "assigned_skills": "[\"ux-design\", \"aesthetic-ui-designer\"]",
      "skill_order": "[\"ux-design\", \"aesthetic-ui-designer\"]",
      "current_skill": "ux-design",
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

---

## features.json Format

Separate from tasks.json, optimized for skill routing:

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
    "by_priority": {"P0": 5, "P1": 12, "P2": 10, "P3": 3},
    "by_audit_level": {"0": 30, "1": 0, "2": 0, "3": 0, "4": 0, "5": 0}
  },
  "features": [
    {
      "id": "F001",
      "epic_id": "epic-001",
      "title": "Survey Studio",
      "priority": "P0",
      "assigned_skills": ["ux-design", "aesthetic-ui-designer"],
      "skill_order": ["ux-design", "aesthetic-ui-designer"],
      "current_skill": "ux-design",
      "audit_level": 0,
      "stories": ["story-001-01", "story-001-02", "story-001-03"]
    }
  ],
  "skill_summary": {
    "ux-design": ["F001", "F003", "F011"],
    "api-design": ["F002", "F007", "F008"],
    "aesthetic-ui-designer": ["F001", "F003", "F011"]
  }
}
```

---

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
        <option value="ux-design">UX Design</option>
        <option value="api-design">API Design</option>
        <option value="aesthetic-ui-designer">UI Designer</option>
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

When prd-analyzer runs:

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

---

## Useful SQL Queries

### Progress by Priority

```sql
SELECT 
    e.priority,
    COUNT(DISTINCT e.id) as epics,
    COUNT(s.id) as stories,
    SUM(CASE WHEN s.status = 'done' THEN 1 ELSE 0 END) as done,
    ROUND(100.0 * SUM(CASE WHEN s.status = 'done' THEN 1 ELSE 0 END) / COUNT(s.id), 1) as pct
FROM epics e
LEFT JOIN stories s ON s.epic_id = e.id
GROUP BY e.priority
ORDER BY CASE e.priority WHEN 'P0' THEN 0 WHEN 'P1' THEN 1 WHEN 'P2' THEN 2 ELSE 3 END;
```

### Work by Skill

```sql
SELECT 
    e.current_skill as skill,
    COUNT(DISTINCT e.id) as epics,
    COUNT(s.id) as stories,
    SUM(CASE WHEN s.status != 'done' THEN 1 ELSE 0 END) as pending
FROM epics e
LEFT JOIN stories s ON s.epic_id = e.id
WHERE e.current_skill IS NOT NULL
GROUP BY e.current_skill;
```

### Audit Status

```sql
SELECT * FROM v_audit_summary;
```

### Blocked Tasks

```sql
SELECT 
    t.id,
    t.title,
    t.blocked_reason,
    GROUP_CONCAT(d.blocker_task_id) as blocked_by
FROM tasks t
LEFT JOIN dependencies d ON d.blocked_task_id = t.id
WHERE t.status = 'blocked'
GROUP BY t.id;
```
