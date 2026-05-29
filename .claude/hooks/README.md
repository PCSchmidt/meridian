# Meridian Hook System

**Purpose:** Enforcement layer for Meridian's agent harness - validates operations, enforces gates, and logs telemetry.

---

## Architecture

Hooks are bash scripts that run before/after tool execution in Claude Code:

- **PreToolUse.sh** - Runs BEFORE tool execution (can block with exit code 2)
- **PostToolUse.sh** - Runs AFTER tool execution (validates results)
- **hook-wrapper.sh** - Common library (logging, error handling, timing)

---

## Hook Wrapper Functions

All hooks source `hook-wrapper.sh` to get:

### Logging Functions
```bash
log INFO "message"     # General info
log WARN "message"     # Warning
log ERROR "message"    # Error (exit 1)
log BLOCK "message"    # Block operation (exit 2)

# Shortcuts
info "message"         # log INFO
warn "message"         # log WARN  
error "message"        # log ERROR + exit 1
block "message"        # log BLOCK + exit 2
```

### Utility Functions
```bash
check_meridian_project      # Returns 0 if in Meridian project
get_current_gate           # Returns current gate ID from state
parse_tool_use             # Parse tool info from stdin or env vars
timer_start                # Start execution timer
timer_end                  # End timer and log duration
```

### Environment Variables
```bash
$TOOL_NAME                 # Tool being executed (Read, Edit, Write, Bash)
$FILE_PATH                 # File path for Read/Edit/Write
$COMMAND                   # Command for Bash tool
$TOOL_ARGS                 # Full JSON arguments
$HOOK_NAME                 # Current hook name
$PROJECT_DIR               # Meridian project directory
$LOG_FILE                  # Hook log file path
```

---

## Exit Codes

- **0** = Success, allow operation
- **1** = Error, but allow operation (logged)
- **2** = **BLOCK** operation (prevents tool execution)

---

## PreToolUse Hook

**Purpose:** Enforce constraints BEFORE tool execution

**Checks:**
- Gate dependencies (future: block edits if gate not passed)
- Protected file modifications
- Destructive operations (rm -rf, git reset --hard)
- Memory file edits (flags for PostToolUse validation)

**Example blocking scenario:**
```bash
# If user tries to edit code before gate is passed
if [ "$current_gate" != "confirmed" ] && [[ "$FILE_PATH" == *".ts" ]]; then
    block "Cannot edit TypeScript files - gate 'confirmed' not passed"
fi
```

---

## PostToolUse Hook

**Purpose:** Validate results AFTER tool execution

**Checks:**
- Memory file schema validation (semantic.json, episodic.jsonl, corrections.jsonl)
- Telemetry logging
- Error detection
- Artifact completion (future)

**Automatic actions:**
- Validates memory writes against JSON schema
- Logs tool usage to `.meridian/telemetry.jsonl`
- Reports validation failures

---

## Hook Logs

All hook activity is logged to:

```
.meridian/hooks.log
```

**Format:**
```
2026-05-28T17:00:00Z [INFO] [PreToolUse] Tool: Edit
2026-05-28T17:00:00Z [INFO] [PreToolUse] Current gate: 1.3
2026-05-28T17:00:00Z [INFO] [PreToolUse] Tool execution allowed
2026-05-28T17:00:05Z [INFO] [PostToolUse] Tool: Edit
2026-05-28T17:00:05Z [INFO] [PostToolUse] Validating semantic memory file
2026-05-28T17:00:05Z [INFO] [PostToolUse] Memory validation passed: semantic
2026-05-28T17:00:05Z [INFO] [PostToolUse] Telemetry logged
```

---

## Telemetry

PostToolUse hook logs telemetry to:

```
.meridian/telemetry.jsonl
```

**Format:** One JSON object per line
```json
{"timestamp":"2026-05-28T17:00:05Z","hook":"PostToolUse","tool":"Edit"}
{"timestamp":"2026-05-28T17:00:10Z","hook":"PostToolUse","tool":"Bash"}
```

---

## Testing

Run hook tests:

```bash
bash tests/test-hooks.sh
```

**Tests:**
- ✅ Hook wrapper loading
- ✅ PreToolUse execution
- ✅ PostToolUse execution
- ✅ Memory validation
- ✅ Logging
- ✅ Exit codes
- ✅ Telemetry

---

## Writing New Hooks

**Template:**
```bash
#!/bin/bash
# my-hook.sh
# Description of what this hook does

# Load common logic
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/hook-wrapper.sh"

HOOK_NAME="my-hook"

#######################################
# Main hook logic
#######################################
main() {
    # Parse tool info
    parse_tool_use
    
    info "Tool: ${TOOL_NAME:-unknown}"
    
    # Your validation logic here
    if [ some_condition ]; then
        block "Reason for blocking"
    fi
    
    # Success
    info "Hook complete"
    timer_end
    exit 0
}

main "$@"
```

---

## Integration with Claude Code

Hooks are automatically executed by Claude Code when:
1. Tool is about to execute (PreToolUse)
2. Tool has finished executing (PostToolUse)

**No manual configuration needed** - hooks in `.claude/hooks/` are automatically discovered.

---

## Future Enhancements

Phase 2+:
- Gate dependency enforcement (block operations based on gates.yaml)
- Artifact tracking (detect when gate artifacts are complete)
- Cost tracking hooks
- Security scanning hooks
- Test coverage hooks

---

**Status:** Basic hook infrastructure complete (Gate 1.3)  
**Next:** Enhanced enforcement rules in Phase 2
