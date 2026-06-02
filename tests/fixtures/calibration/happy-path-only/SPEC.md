# Spec — todo-cli v1.0

## Add Task
Command: `todo add <title> [--due <date>]`
Creates a new task. Assigns a unique integer id. Stores in `~/.todo/tasks.json`.
Edge cases: empty title (reject), invalid date format (reject), duplicate title (warn, allow).

## List Tasks
Command: `todo list [--status open|done|all]`
Default: show open tasks only. Columns: id, title, due date, status.
Edge cases: no tasks (print "No tasks."), invalid status filter (error).

## Delete Task
Command: `todo delete <id>`
Removes task by id. Confirms before deletion.
Edge cases: non-existent id (error), malformed id (error).

## Complete Task
Command: `todo complete <id>`
Marks task done. Idempotent (completing an already-done task is a no-op).
Edge cases: non-existent id (error), already-complete (no-op with message).
