# CLAUDE.md

Session-start guidance for working on the Meridian framework itself.
Keep this under 60 lines (Principle 3: context-efficient).

## What this repo is

Meridian is an agent harness framework — infrastructure between you and the
model that enforces gates, validates memory, and emits engineer-legible
telemetry. Read [PHILOSOPHY.md](PHILOSOPHY.md) for the five principles.
This repo is Meridian building itself (dogfooding).

## Where things live

- `scripts/` — core framework scripts (gate engine, memory, telemetry, health, status)
- `.claude/hooks/` — PreToolUse / PostToolUse enforcement (source `hook-wrapper.sh`, never execute it)
- `.claude/skills/` — slash-command skill docs (`/health`, `/status`, `/memory`)
- `.meridian/` — runtime state (gitignored): `memory/`, `telemetry.jsonl`, `session.json`
- `recipes/` — pattern-based `gates.yaml` for fullstack-web, cli-tool, ml-research
- `tests/` — bash test suites (46 passing as of Phase 1)
- `ROADMAP.md` — gate progress + calibration data (single source of truth for status)

## Development model

Work proceeds gate-by-gate (G1.1, G1.2, …). Each gate: build → test → update
ROADMAP → write reflexion to `corrections.jsonl` → commit. One gate at a time
(Assumption A001). Track predicted vs actual hours; the goal is calibration
converging toward 1.0x.

## Bash compatibility (Windows / Git Bash)

- Use `$(( ))` for arithmetic, never `(( ))`
- Use `$(...)` not backticks
- No `bc` — use `awk` for float math
- Test `while read` loops with `|| [ -n "$line" ]` to catch the last line
- Prefer `jq -c '.'` to normalize mixed compact/pretty JSONL before querying

## Before committing

- Run the relevant `tests/test-*.sh` — all must pass
- Update ROADMAP.md gate status and the reflexion log
- Commit messages end with the Co-Authored-By trailer
- Commit/push only when asked

## Enforcement status (honest scope)

Phase 1 established hook infrastructure and detection. Blocking enforcement
(exit code 2 for gates/security) lands in Phase 2 — PreToolUse currently
detects and warns but does not block. Don't claim enforcement that isn't wired.
