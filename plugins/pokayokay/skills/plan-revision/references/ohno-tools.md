# ohno MCP Tools for Plan Revision

Tools used during plan revision workflows.

## Reading Plan State

- `get_tasks(fields: "standard")` - Load plan with descriptions
- `get_project_status()` - Summary of project progress
- `get_task_dependencies()` - Dependency map between tasks

## Modifying Plan

- `update_task()` - Modify task fields (title, description, type, priority)
- `archive_task()` - Remove tasks from plan
- `create_task()` - Add new tasks to plan

## Dependencies

- `add_dependency()` - Create dependency between tasks
- `remove_dependency()` - Remove dependency between tasks

## Activity Logging

- `add_task_activity()` - Log revision actions for audit trail
