# Database Schema

## Updated Schema with Audit Fields

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
    assigned_skills TEXT,      -- JSON array
    skill_order TEXT,          -- JSON array
    current_skill TEXT,
    audit_level INTEGER DEFAULT 0 CHECK(audit_level BETWEEN 0 AND 5),
    audit_date TEXT,
    audit_gaps TEXT,           -- JSON array
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
    assigned_skill TEXT,
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
    status TEXT DEFAULT 'todo' CHECK(status IN ('todo', 'in_progress', 'review', 'done', 'blocked')),
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

-- Session log
CREATE TABLE IF NOT EXISTS sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT UNIQUE NOT NULL,
    skill_used TEXT,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    stories_completed TEXT,    -- JSON array
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
    e.id, e.title, e.priority, e.audit_level, e.assigned_skills,
    COUNT(s.id) as total_stories,
    SUM(CASE WHEN s.status = 'done' THEN 1 ELSE 0 END) as done_stories,
    ROUND(100.0 * SUM(CASE WHEN s.status = 'done' THEN 1 ELSE 0 END) / COUNT(s.id), 1) as progress_pct
FROM epics e LEFT JOIN stories s ON s.epic_id = e.id GROUP BY e.id;

CREATE VIEW IF NOT EXISTS v_skill_workload AS
SELECT
    e.assigned_skills,
    COUNT(DISTINCT e.id) as epic_count,
    COUNT(s.id) as story_count,
    SUM(CASE WHEN s.status != 'done' THEN 1 ELSE 0 END) as pending_stories
FROM epics e LEFT JOIN stories s ON s.epic_id = e.id GROUP BY e.assigned_skills;
```
