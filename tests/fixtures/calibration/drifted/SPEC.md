# Spec — todo-cli v1.0

## Add Task
Command: `todo add <title> [--due <date>]`
Creates a new task. Assigns a unique integer id.

## List Tasks
Command: `todo list [--status open|done|all]`
Default: show open tasks only.

## Delete Task
Command: `todo delete <id>`
Removes task by id.

## Complete Task
Command: `todo complete <id>`
Marks task done.
