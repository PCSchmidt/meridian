# Changelog

All notable changes to Meridian are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [0.1.0] — 2026-07-23

First stable release. Dogfooded on two production projects (AeroIntel and Hard Power
Intelligence) before tagging. Every gate gate-by-gate, every test green, every hook
shellcheck-clean.

### Added

**Phase 1 — Foundation**
- `scripts/gate-engine.sh` — composable gate DAG engine; validates YAML, detects circular deps
- `scripts/validate-memory.sh` — schema validation for all three memory types (semantic, episodic, corrections)
- `scripts/log-event.sh` — structured telemetry append (8 event types)
- `scripts/session.sh` — session lifecycle (start/end/id/status)
- `scripts/health-report.sh` — four-section health report with calibration table
- `scripts/status-report.sh` — compact session-start status
- `.meridian/` schemas: `memory-schema.json`, `telemetry-schema.json`, `gate-schema.yaml`

**Phase 2 — Core Hooks & Skills**
- `.claude/hooks/PreToolUse.sh` / `PostToolUse.sh` — blocking enforcement (exit 2)
- `.claude/hooks/block-dangerous.sh` — security blocklist (11 rules; deterministic block vs heuristic warn)
- `.meridian/security-rules.yaml` — configurable rule engine (block/warn/off per rule)
- `.claude/hooks/run-evaluator.sh` — generator-evaluator separation contract enforcement
- `.claude/hooks/run-tests.sh` — auto-detect test runner; blocks on failure
- `scripts/write-reflexion.sh` — write-ahead-validated calibration entries
- `scripts/skill-manifest.sh` — progressive-disclosure skill metadata layer
- 12 skills with frontmatter progressive disclosure: `/start`, `/health`, `/memory`, `/status`, `/security`, `/testing`, `/costs`, `/rollback`, `/deploy`, `/build-rules`, `/critical-thinker`, `/research`

**Phase 3 — Prove the Thesis**
- `.claude/agents/gate-evaluator.md` — adversarial 4-dimension scorer; strict JSON-only output
- `.claude/agents/drift-evaluator.md` — scope drift sensor; advisory by default
- `.claude/agents/spec-reviewer.md` — spec completeness reviewer
- `scripts/features-init.sh` / `features-report.sh` — lifecycle-aware completion (happy-path % vs full-lifecycle %)
- `.meridian/features-schema.json` — 5 lifecycle sub-states per feature
- `CALIBRATION.md` — drift/gate evaluator discrimination table; threshold validated at alignment_score < 5
- `install.sh` — one-command project installer (7→11 steps across phases)

**Phase 4 — Recipes**
- `recipes/fullstack-web/` — 6-gate DAG + Next.js/FastAPI/Supabase reference + templates
- `recipes/cli-tool/` — 5-gate DAG + Python/Click reference + COMMANDS_SPEC template
- `recipes/ml-research/` — 6-gate DAG + DATA_CONTRACT gate (unique: locks methodology before training)
- `docs/recipes.md` — stack substitution, gate customization, DAG reshape examples

**Phase 5 — Portable Enforcement**
- `scripts/meridian-doctor.sh` — install validator; exits 1 on CRITICAL, 0 on GOOD/WARNING
- `scripts/meridian-verify.sh` — platform-neutral verifier; wired to git pre-commit + CI
- `templates/pre-commit` + `templates/meridian-ci.yml` — the commit/CI enforcement boundary
- `scripts/gen-rules.sh` — Tier 2/3 rule surfaces from the same source as the hooks (idempotent)
- `scripts/detect-runtime.sh` — platform detection (Claude Code / Cursor / Windsurf / Cline / generic)
- `docs/platform-tiers.md` — Enforced / Guided+CI / Reference+CI parity matrix

**Phase 6 — Documentation**
- `docs/quickstart.md` — Meridian in 10 minutes
- `docs/gate-model.md`, `docs/memory.md`, `docs/observability.md` — core concepts
- `docs/windows-install.md` — Git Bash + WSL2 setup (validated on this machine)
- `docs/troubleshooting.md` — field-tested fixes (real bugs this project hit)
- `docs/api-reference.md` — scripts, hooks, skills, schemas, exit codes
- `CONTRIBUTING.md` — gate-by-gate dev model, bash-compat rules, PR process

**Phase 7 — Dogfooding & Refinement**
- `scripts/log-episodic.sh` — automatic episodic event writer; wired into session.sh + gate-engine.sh
- `.claude/hooks/SessionStart.sh` — auto-starts session on conversation open
- `.claude/settings.json` — Claude Code hook registration (SessionStart/PreToolUse/PostToolUse)
- `docs/memory.md` updated — confidence ceiling (LOW→MEDIUM→HIGH multi-project requirement)
- `write-reflexion.sh` — hours now optional (must be paired if provided)
- `run-tests.sh` — TDD red-phase fix; `.meridian/test-baseline.txt` tracks passing suites
- `meridian-doctor.sh` — schema parse validation (jq/yq), expanded hooks (SessionStart, bash -n, settings.json)
- `install.sh` — now creates `.claude/settings.json` for installed projects (step 1)
- `CHANGELOG.md` — this file

### Fixed

- `hook-wrapper.sh` `parse_tool_use()` — was reading wrong stdin keys (`.tool`/`.arguments.*`);
  Claude Code sends `.tool_name`/`.tool_input.*`. Security boundary silently never fired in
  live sessions before this fix (G5.1). Fixed + pinned with end-to-end fixtures.
- `install.sh` — never copied `scripts/`; installed hooks referenced engines that didn't exist.
  Fixed in G5.2; prior installs (AeroIntel) needed re-install.
- `hook-wrapper.sh` shellcheck SC2155 — `export VAR=$(...)` separated into assign + export to
  avoid masking subshell return values (G7.5).
- `run-evaluator.sh` — removed unused `mode` variable (G7.5 shellcheck).

### Experiment Results (v0.1.0 baseline)

| Measurement | Score | Source |
|-------------|-------|--------|
| Self-evaluation (same session) | 5.5/10 | `experiment/GENERATOR_EVALUATOR_VALIDATION.md` |
| Independent evaluation (separate session) | 2.5/10 | `experiment/GENERATOR_EVALUATOR_VALIDATION.md` |
| **Generator-evaluator delta** | **−3.0 pts** | G0.2 experiment, 2026-05-28 |
| Drift sensor: aligned fixture | 8/10 | `CALIBRATION.md`, G3.4 |
| Drift sensor: drifted fixture | 3/10 | `CALIBRATION.md`, G3.4 |
| Gate evaluator: aligned fixture | 8.5/10 | `CALIBRATION.md`, G3.4 |
| Gate evaluator: drifted fixture | 3.6/10 | `CALIBRATION.md`, G3.4 |

### Active Assumptions (v0.1.0)

Five assumptions documented in `ASSUMPTIONS.md`, all ACTIVE:
- A001 — One-feature-at-a-time constraint
- A002 — JSON feature tracking (not markdown)
- A003 — Evaluator/generator separation (experiment-validated)
- A004 — Drift sensor threshold at alignment_score < 5 (calibration-validated)
- A005 — Enforcement boundary relocation for non-Claude platforms

---

## [Unreleased]

Nothing yet. See [ROADMAP.md](ROADMAP.md) for Phase 8 (Community Preparation) plans.
