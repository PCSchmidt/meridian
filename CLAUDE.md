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
- `.claude/skills/` — 14 slash-command skill docs with progressive-disclosure frontmatter (`/start`, `/health`, `/status`, `/memory`, `/security`, `/testing`, `/costs`, `/rollback`, `/deploy`, `/build-rules`, `/critical-thinker`, `/research`, `/evaluate`, `/review`)
- `.meridian/` — runtime state (gitignored): `memory/`, `telemetry.jsonl`, `session.json`; plus tracked `security-rules.yaml`, `*-schema.{json,yaml}`
- `recipes/` — pattern-based `gates.yaml` + foundation templates for fullstack-web, cli-tool, ml-research
- `docs/` — framework documentation (`recipes.md` — recipe adaptation guide; `platform-tiers.md` — tier definitions + feature parity matrix)
- `tests/` — bash test suites (194 passing across 14 suites, as of Phase 5 G5.0)
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

Blocking enforcement is live as of Phase 2. `PreToolUse` runs `block-dangerous.sh`
and exits 2 on deterministic dangerous ops (G2.1); `gate-engine.sh verify` runs a
gate's pre-hooks and blocks on failure; `run-evaluator.sh` blocks a gate without a
passing independent verdict (G2.2). Heuristic checks still warn (non-blocking) by
design. The live Evaluator *subagent* that produces verdicts landed in Phase 3
(G3.1, `.claude/agents/gate-evaluator.md`). Phase 5 relocates enforcement to the
git/CI boundary for non-Claude platforms (see `docs/platform-tiers.md`). Don't
claim enforcement that isn't wired — but blocking now is.
