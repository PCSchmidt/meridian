# Contract — todo-cli v1.0

## Client: Internal
## Project type: CLI tool

## Scope
Build a command-line task manager for personal use.

**In scope:**
- `add` — create a task with title and optional due date
- `list` — show all tasks, filterable by status (open/done)
- `delete` — remove a task by id
- `complete` — mark a task done

**Out of scope:**
- User authentication or accounts
- Network sync or remote storage
- Multi-user or sharing
- Import/export

## Acceptance criteria
- Tasks persist between invocations (local file storage)
- `add` creates a task; `list` shows it; `complete` marks it done; `delete` removes it
- All four commands tested with unit + integration tests before release

## Timeline
4 weeks. Weekly check-ins.
