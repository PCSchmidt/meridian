# API Reference

A flat reference for Meridian's scripts, hooks, skills, schemas, and exit-code
conventions. For concepts, see the guides; this is the lookup table.

## Exit-code convention

Meridian hooks use a three-value contract; Claude Code honors it:

| Code | Meaning |
|------|---------|
| `0` | allow / success |
| `1` | warn or recoverable error (allowed, logged) |
| `2` | **block** — prevent the tool call |

CLI tools (`meridian-verify`, `meridian-doctor`) use `0` = ok / `1` = fail, so they
work as git pre-commit hooks and CI steps.

## Core scripts (`scripts/`)

| Script | Purpose | Key invocation |
|--------|---------|----------------|
| `meridian-doctor.sh` | installation health check | `meridian-doctor.sh [dir]` → 0 GOOD/WARNING, 1 CRITICAL |
| `meridian-verify.sh` | portable verifier (commit/CI boundary) | `meridian-verify.sh [dir] [--no-drift]` → 0 pass, 1 fail |
| `gate-engine.sh` | gate DAG engine | `validate` · `check-circular` · `current` · `can-proceed <id>` · `verify <id>` · `mark-passed <id>` |
| `validate-memory.sh` | validate a memory file vs schema | `validate-memory.sh <semantic\|episodic\|corrections> <file>` |
| `memory-doctor.sh` | validate all memory + calibration report | `memory-doctor.sh [dir]` |
| `log-event.sh` | append a telemetry event | `log-event.sh <event_type> [k=v ...]` |
| `telemetry-query.sh` | common telemetry queries | `telemetry-query.sh ...` |
| `health-report.sh` | gate/cost/evaluator/calibration dashboard | `health-report.sh` (skill `/health`) |
| `status-report.sh` | features done vs remaining, completion % | `status-report.sh` (skill `/status`) |
| `cost-report.sh` | token/cost per session and gate | `cost-report.sh` (skill `/costs`) |
| `features-init.sh` | seed `FEATURES.json` from SPEC.md | `features-init.sh --spec SPEC.md` |
| `features-report.sh` | feature lifecycle summary | `features-report.sh` |
| `drift-check.sh` | drift sensor (advisory) | `drift-check.sh [--prepare\|--check]` |
| `write-reflexion.sh` | append a corrections entry | `write-reflexion.sh ...` |
| `gen-rules.sh` | generate Tier-2/3 rule surfaces from source | `gen-rules.sh [dir] --platform <cursor\|windsurf\|cline\|advisory\|all>` |
| `detect-runtime.sh` | best-effort platform detection | `detect-runtime.sh [dir]` → `claude-code\|cursor\|windsurf\|cline\|generic` |
| `rollback-gate.sh` | revert a gate transition | `rollback-gate.sh <id>` (skill `/rollback`) |
| `security-audit.sh` | OWASP-style audit pass | `security-audit.sh` (skill `/security`) |
| `global-memory-sync.sh` | sync patterns to `~/.meridian/global/` | `global-memory-sync.sh` |
| `session.sh` / `start-session.sh` | session lifecycle | — |
| `context-trim.sh` | context-budget trimming | — |
| `skill-manifest.sh` | list/validate skill frontmatter | — |

## Hooks (`.claude/hooks/`)

| Hook | Event | Role |
|------|-------|------|
| `hook-wrapper.sh` | (sourced, never executed) | logging, `block/warn/info`, `parse_tool_use`, `PROJECT_DIR` |
| `PreToolUse.sh` | PreToolUse | gate checks + runs `block-dangerous.sh`; can exit 2 |
| `PostToolUse.sh` | PostToolUse | validates memory writes, logs telemetry |
| `block-dangerous.sh` | (subprocess of PreToolUse) | scans command/content vs `security-rules.yaml`; exit 2 on a `block` rule |
| `run-evaluator.sh` | gate verify | enforces the evaluator verdict contract (A003); exit 2 if no passing verdict |
| `run-tests.sh` | gate pre-hook | runs the project test command |
| `validate-contract.sh` / `validate-spec.sh` / `validate-roadmap.sh` | gate pre-hooks | structural checks on foundation docs |

`hook-wrapper.sh` must be **sourced**, not executed. Every hook starts with
`source "$(dirname "${BASH_SOURCE[0]}")/hook-wrapper.sh"`.

## Skills (slash commands)

`/start` · `/health` · `/status` · `/memory` · `/costs` · `/security` ·
`/testing` · `/rollback` · `/deploy` · `/build-rules` · `/critical-thinker` ·
`/research` · `/evaluate` · `/review` · `/drift-check`

Each lives under `.claude/skills/<name>/<name>.md` with progressive-disclosure
frontmatter (metadata always loaded; body on invocation).

## Subagents (`.claude/agents/`)

| Agent | Role |
|-------|------|
| `gate-evaluator.md` | independent gate scoring (A003); writes a verdict JSON |
| `drift-evaluator.md` | alignment scoring for the drift sensor (A004) |
| `spec-reviewer.md` | CONTRACT/SPEC completeness gap analysis |

## Schemas (`.meridian/`)

| Schema | Validates |
|--------|-----------|
| `memory-schema.json` | semantic / episodic / corrections entries |
| `telemetry-schema.json` | telemetry events (oneOf per `event_type`) |
| `gate-schema.yaml` | `gates.yaml` structure |
| `features-schema.json` | `FEATURES.json` entries |

## Key environment variables

| Var | Used by | Effect |
|-----|---------|--------|
| `MERIDIAN_PROJECT_DIR` | all scripts/hooks | project root (defaults to cwd) |
| `EVALUATOR_THRESHOLD` | `run-evaluator`, `meridian-verify` | min passing score (default 7.0) |
| `MERIDIAN_DRIFT_BLOCK` | `meridian-verify` | `1` promotes drift from advisory to blocking |
| `CLAUDECODE` | `detect-runtime` | platform detection signal (set by Claude Code) |
