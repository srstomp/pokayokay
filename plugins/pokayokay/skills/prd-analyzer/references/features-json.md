# features.json Format

## Structure

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
    "by_priority": { "P0": 5, "P1": 12, "P2": 10, "P3": 3 }
  },
  "features": [
    {
      "id": "F001",
      "epic_id": "epic-001",
      "title": "Data Pipeline",
      "description": "Process and store data with efficient schemas",
      "priority": "P0",
      "assigned_skills": ["database-design", "api-design"],
      "skill_order": ["database-design", "api-design"],
      "dependencies": [],
      "audit_level": 0,
      "stories": ["story-001-01", "story-001-02"]
    }
  ],
  "skill_summary": {
    "database-design": ["F001", "F003"],
    "api-design": ["F002", "F007"]
  }
}
```

## Integration Points

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

Skills like `api-design`, `database-design`:
1. Read `PROJECT.md` for context
2. Check `features.json` for assigned work
3. Filter by `assigned_skills` containing their name
4. Update story status when complete
