# Tier 1 Verification — Claude Code Hook Contract

Tier 1 is the only platform where Meridian enforces at the keystroke boundary:
Claude Code runs `PreToolUse`/`PostToolUse` hooks that can exit 2 to block a tool
call. This document pins the **exact stdin contract** those hooks receive, the
manual protocol to verify enforcement in a live session, and the field-name bug
this gate (G5.1) found and fixed.

It exists because the automated suite injects `TOOL_NAME`/`COMMAND`/`CONTENT` via
environment variables — which never exercises the JSON-on-stdin path that a real
Claude Code session uses. The contract below is what production actually sends.

---

## The stdin contract

Claude Code invokes each configured hook as a subprocess and writes a single JSON
object to the hook's **stdin** (not environment variables, not argv).

### PreToolUse

```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/working/dir",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "rm -rf /",
    "description": "..."
  }
}
```

### PostToolUse

Same shape, plus the tool's result:

```json
{
  "session_id": "abc123",
  "hook_event_name": "PostToolUse",
  "tool_name": "Write",
  "tool_input": { "file_path": "...", "content": "..." },
  "tool_response": { "filePath": "...", "success": true }
}
```

### Key fields by tool

| Tool  | Identity key | Payload keys (under `tool_input`)        |
|-------|--------------|------------------------------------------|
| Bash  | `tool_name`  | `command`, `description`                  |
| Write | `tool_name`  | `file_path`, `content`                    |
| Edit  | `tool_name`  | `file_path`, `old_string`, `new_string`  |
| Read  | `tool_name`  | `file_path`                              |

**Two facts that matter:** the tool name is `tool_name` (not `tool`), and the
arguments live under `tool_input` (not `arguments`).

---

## How Meridian consumes it

`parse_tool_use()` in `.claude/hooks/hook-wrapper.sh` reads stdin once and exports:

| Export      | Source (with legacy fallback)                          |
|-------------|--------------------------------------------------------|
| `TOOL_NAME` | `.tool_name` → `.tool`                                  |
| `TOOL_ARGS` | `.tool_input` → `.arguments`                            |
| `FILE_PATH` | `.tool_input.file_path` → `.arguments.file_path`        |
| `COMMAND`   | `.tool_input.command` → `.arguments.command`            |
| `CONTENT`   | `.tool_input.content` (Write) / `.new_string` (Edit)   |

`parse_tool_use` consumes stdin with `cat`, so downstream hooks (e.g.
`block-dangerous.sh`) **cannot re-read stdin** — they rely on these exported
variables. That is by design, but it means a parsing bug silently disables every
downstream check.

---

## The bug this gate found (and fixed)

Before G5.1, `parse_tool_use()` read `.tool` and `.arguments.*` — keys that **do
not exist** in the Claude Code contract. In a live session the result was:

- `TOOL_NAME="unknown"`, `COMMAND=""`, `FILE_PATH=""`, `CONTENT=""`
- `block-dangerous.sh` saw nothing to scan → **exited 0 (allowed) for every
  operation**, including `rm -rf /`

The security boundary (Gate 2.1) — Meridian's flagship "mechanical enforcement,
Principle 1" feature — **silently did not fire in a real Claude Code session.**
It only appeared to work because the test suite set the variables directly via
the environment, bypassing the broken stdin parse.

The fix reads the real keys (`.tool_name`, `.tool_input.*`) with a fallback to the
legacy shape, and `tests/test-hook-contract.sh` now feeds real-shaped fixtures
through `PreToolUse.sh` end-to-end and asserts exit 2 on a dangerous command and
on secret content. This is the regression guard: the env-var path can no longer
mask a broken contract.

---

## Manual verification protocol (live Claude Code session)

The automated suite (`tests/test-hook-contract.sh`) covers the contract via
fixtures. To confirm in an actual Claude Code session on a freshly installed
project:

1. **Install and check health**
   ```bash
   bash install.sh /path/to/test-project --recipe cli-tool
   cd /path/to/test-project
   bash scripts/meridian-doctor.sh   # must be GOOD (install yq if CRITICAL)
   ```

2. **Wire the hooks** in the project's Claude Code settings
   (`.claude/settings.json`) so `PreToolUse`/`PostToolUse` point at
   `.claude/hooks/PreToolUse.sh` / `PostToolUse.sh`.

3. **Trigger a block.** In the session, ask Claude to run a clearly dangerous
   command (e.g. `rm -rf ~`). Expected: the tool call is blocked; the hook's
   stderr message appears; `.meridian/telemetry.jsonl` gains a
   `tool_used … outcome=blocked` event.

4. **Trigger an allow.** Ask Claude to run `echo hello`. Expected: the command
   runs; telemetry records `outcome=allowed`.

5. **Trigger a content block.** Ask Claude to write a file containing a line like
   `-----BEGIN PRIVATE KEY-----`. Expected: blocked by the `private-key-block`
   rule.

6. **Confirm the parse.** Tail `.meridian/hooks.log` and verify the logged
   `Tool: <name>` matches the real tool (not `unknown`).

### Capturing a fresh fixture

If Claude Code's contract ever changes, capture the real payload by temporarily
making the hook echo stdin:

```bash
# add as the first line of a hook's main(), then run one tool call:
cat | tee -a /tmp/meridian-hook-capture.json
```

Compare `/tmp/meridian-hook-capture.json` against the fixtures in
`tests/fixtures/hook-stdin/` and update the parser + fixtures together.

---

## Status

- ✅ Contract documented and pinned to fixtures
- ✅ Field-name bug fixed in `hook-wrapper.sh` + `block-dangerous.sh`
- ✅ `tests/test-hook-contract.sh` (9 tests) asserts the live path end-to-end
- ☐ Manual live-session run (steps above) — operator task, recommended after any
  Claude Code update

See ROADMAP.md Phase 5 (G5.1) and `docs/platform-tiers.md` for how Tier 1 relates
to the portable git/CI boundary that covers the other tiers.
