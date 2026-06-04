# Meridian

A next-generation agent harness framework for AI coding assistants.

![Status](https://img.shields.io/badge/status-in%20development-green)
![Version](https://img.shields.io/badge/version-0.1.0--dev-blue)
![Phases 0-6](https://img.shields.io/badge/phases%200--6-complete-brightgreen)
![Tests](https://img.shields.io/badge/tests-226%20passing-brightgreen)

---

## What Is Meridian?

Long-running AI agents fail predictably: hallucinated completion, context loss, generous self-evaluation. **Meridian fixes each mechanically** — enforced gates, validated memory, a separate Evaluator subagent that cannot praise its own work, and engineer-legible telemetry.

Meridian is an agent harness framework that sits between you and the AI model, providing:

- **Enforced gates** the model cannot hallucinate past
- **Schema-validated memory** that persists across sessions
- **Generator-Evaluator separation** to prevent self-grading
- **Engineer-legible observability** via `/health report` and structured telemetry
- **Composable gate DAG** configured in YAML, not hardcoded
- **Multi-platform support** (Claude Code, Cursor, Windsurf, and advisory tier)

---

## Status: Phases 0–6 Complete

**Current status:** Phase 6 complete — the full documentation set shipped (quickstart, gate model, memory, observability, assumptions, Windows install, troubleshooting, API reference, contributing). Portable enforcement (Phase 5) and three recipes (Phase 4) are in place. Phase 7 (Dogfooding & Refinement) is next.

**Tests:** 226 passing across 18 suites.

### Phase Progress

| Phase | Status | Estimated | Actual |
| ----- | ------ | --------- | ------ |
| 0. Planning & Validation | ✅ Complete | 8h | 6h |
| 1. Foundation | ✅ Complete | 40h | 40h |
| 2. Core Hooks & Skills | ✅ Complete | 60h | 49h |
| 3. Prove the Thesis *(evaluator, drift sensor, real-project validation)* | ✅ Complete | 32h | 12.5h |
| 4. Recipes *(fullstack-web, cli-tool, ml-research)* | ✅ Complete | 40h | ~8.5h |
| 5. Portable Enforcement & Multi-Tier *(verifier + git/CI + Cursor/Windsurf/Cline + Advisory)* | ✅ Complete | 34h | ~13.5h |
| 6. Documentation | ✅ Complete | 25h | ~4.5h |
| 7. Dogfooding & Refinement | ⏳ Next | 40h | — |
| 8. Community Preparation | ⏳ Upcoming | 15h | — |

### Phase 3 Gates (Complete)

- ✅ G3.1: Gate Evaluator Subagent — `gate-evaluator.md`, `spec-reviewer.md`, `/evaluate`, `/review`
- ✅ G3.2: Lifecycle-Aware Completion — `FEATURES.json`, `features-init.sh`, `features-report.sh`
- ✅ G3.3: Continuous Drift Sensor — `drift-evaluator.md`, `drift-report.sh`, advisory drift checks
- ✅ G3.4: Calibrate the Judge — threshold experiment (< 5 = drifted, < 7 = warn), 3-fixture validation
- ✅ G3.5: Minimal Installer + Real-Project Validation — `install.sh`, AeroIntel north-star test

### Phase 4 Gates (Complete)

- ✅ G4.1: fullstack-web recipe — gate DAG (6 gates) + README + templates
- ✅ G4.2: cli-tool recipe — gate DAG (5 gates) + README + COMMANDS_SPEC template
- ✅ G4.3: ml-research recipe — gate DAG (6 gates) + DATA_CONTRACT template + MODEL_CARD template
- ✅ G4.4: Recipe Adaptation Guide — `docs/recipes.md` (stack substitution, gate customization, DAG reshape examples)

See [ROADMAP.md](ROADMAP.md) for detailed gate tracking and calibration data.

---

## Key Differentiators

1. **Engineer-legible observability** — Gate pass rates, calibration trends, error logs you can grep
2. **Composable gate DAG** — YAML-configured, project-specific, not hardcoded
3. **Schema-validated memory** — Integrity-guaranteed JSONL storage with deduplication
4. **Generator-Evaluator separation** — Independent evaluation prevents self-grading (validated by experiment: -3.0 point delta)
5. **ASSUMPTIONS.md governance** — Every harness assumption documented, pruned as models improve
6. **Pattern-based recipes** — Stack-flexible (`fullstack-web`, `cli-tool`, `ml-research`) with `DATA_CONTRACT` gate for ML methodology enforcement

---

## What's Built

### Foundation Scripts (Phase 1)

| Script | Purpose |
|--------|---------|
| `scripts/gate-engine.sh` | Reads `gates.yaml`, validates DAG, enforces dependencies |
| `scripts/validate-memory.sh` | Schema validates all three memory types |
| `scripts/memory-doctor.sh` | Memory health check and repair wrapper |
| `scripts/log-event.sh` | Appends structured events to `telemetry.jsonl` |
| `scripts/session.sh` | Session lifecycle management (start/end/id/status) |
| `scripts/telemetry-query.sh` | Query telemetry: summary, gates, tools, errors, tail |
| `scripts/health-report.sh` | Full health report: session, calibration, memory, telemetry |
| `scripts/status-report.sh` | Compact session-start status — completed gates + calibration |

### Phase 2 Scripts

| Script | Purpose |
|--------|---------|
| `scripts/write-reflexion.sh` | Append calibration entry to `corrections.jsonl` (write-ahead validated) |
| `scripts/global-memory-sync.sh` | Cross-project memory sync to `~/.meridian/global/` (push/pull/status) |
| `scripts/context-trim.sh` | Trim `episodic.jsonl` to last N sessions, archive the rest |
| `scripts/start-session.sh` | Session bootstrap — resume/new, status, current gate, memory check |
| `scripts/rollback-gate.sh` | Revert gate state to an earlier gate (+ git guidance) |
| `scripts/security-audit.sh` | Active rules + security telemetry summary |
| `scripts/cost-report.sh` | Aggregate token/cost telemetry (reserved stub fields) |
| `scripts/skill-manifest.sh` | Emit the always-loaded skill metadata layer |

### Phase 3 Scripts

| Script | Purpose |
|--------|---------|
| `scripts/features-init.sh` | Seed `.meridian/FEATURES.json` from SPEC.md headings |
| `scripts/features-report.sh` | Two metrics: happy-path % vs full-lifecycle % |
| `scripts/drift-report.sh` | Run drift evaluator and emit advisory drift verdict |

### Subagents (`.claude/agents/`)

| Agent | Purpose |
|-------|---------|
| `gate-evaluator.md` | Adversarial 4-dimension scorer; pass/warn/fail verdict |
| `spec-reviewer.md` | Spec completeness reviewer; gap and contradiction detection |
| `drift-evaluator.md` | SPEC/FEATURES alignment scorer; advisory drift detection |

### Hook System

| Hook | Purpose |
|------|---------|
| `.claude/hooks/hook-wrapper.sh` | Common library: logging, timing, error handling |
| `.claude/hooks/PreToolUse.sh` | Pre-execution validation — **blocks (exit 2)** via `block-dangerous.sh` |
| `.claude/hooks/PostToolUse.sh` | Post-execution validation — memory schema + telemetry |
| `.claude/hooks/block-dangerous.sh` | Security blocklist enforcement (exit 2 on dangerous ops) |
| `.claude/hooks/validate-contract.sh` | Gate-transition validator for `CONTRACT.md` |
| `.claude/hooks/validate-spec.sh` | Gate-transition validator for `SPEC.md` |
| `.claude/hooks/validate-roadmap.sh` | Gate-transition validator for `ROADMAP.md` |
| `.claude/hooks/run-tests.sh` | Auto-detect + run tests; blocks on failure |
| `.claude/hooks/run-evaluator.sh` | Enforce generator-evaluator separation (A003) |

### Skills (14, with progressive-disclosure frontmatter)

| Skill | Trigger | Purpose |
|-------|---------|---------|
| `start` | `/start` | Begin/resume a session, show where you are |
| `health` | `/health` | Health report: calibration, memory, telemetry |
| `status` | `/status` | Session-start status: completed gates + lifecycle |
| `memory` | `/memory` | Memory: doctor, show, stats, prune, reflect, sync |
| `security` | `/security` | Audit active rules + security telemetry |
| `testing` | `/testing` | Run tests + check evaluator verdict |
| `costs` | `/costs` | Token/cost report from telemetry |
| `rollback` | `/rollback` | Revert gate state to an earlier gate |
| `deploy` | `/deploy` | Orchestrate the pre-deploy gate sequence |
| `build-rules` | `/build-rules` | Author a project gate DAG |
| `critical-thinker` | `/critical-thinker` | Pressure-test a decision before it locks |
| `research` | `/research` | Memory-first research workflow |
| `evaluate` | `/evaluate` | Invoke gate-evaluator subagent for adversarial scoring |
| `review` | `/review` | Invoke spec-reviewer subagent for spec completeness |

### Memory System

```
.meridian/memory/
  semantic.json        # Validated patterns across projects (deduplicated by hash)
  episodic.jsonl       # Session events (append-only)
  corrections.jsonl    # Reflexion entries: predicted vs actual calibration
```

### Telemetry Schema

Eight event types in `.meridian/telemetry.jsonl`:

- `session_start` / `session_end`
- `gate_passed` / `gate_blocked`
- `tool_used`
- `evaluator_verdict`
- `memory_write`
- `error`

### Recipes (Gate Definitions + Foundation Templates)

```
recipes/
  fullstack-web/
    gates.yaml                        # 6-gate DAG: frontend + backend + database
    README.md                         # Reference implementation (Next.js + FastAPI + Supabase)
    foundation/CONTRACT.md.template
    foundation/SPEC.md.template
  cli-tool/
    gates.yaml                        # 5-gate DAG: commands → tests → package
    README.md                         # Reference implementation (Python + Click)
    foundation/CONTRACT.md.template
    foundation/SPEC.md.template
    foundation/COMMANDS_SPEC.md.template   # CLI contract: every command/flag/exit code
  ml-research/
    gates.yaml                        # 6-gate DAG: data_contract → pipeline → model_eval → deploy
    README.md                         # Reference implementation (PyTorch + FastAPI)
    foundation/DATA_CONTRACT.md.template   # The unique differentiator: methodology decisions locked before training
    foundation/CONTRACT.md.template
    foundation/SPEC.md.template
    foundation/MODEL_CARD.md.template
```

**The `DATA_CONTRACT` gate** — unique to Meridian — enforces that the human defines the target metric, evaluation thresholds, baseline, and approach constraints before a line of training code runs. No other agent framework enforces ML methodological decisions.

### Documentation

```
docs/
  quickstart.md          # Meridian in 10 minutes (install → first gate)
  gate-model.md          # The composable gate DAG and how it's enforced
  memory.md              # The three schema-validated memory types
  observability.md       # Telemetry, /health, /status, costs
  assumptions.md         # Maintaining ASSUMPTIONS.md in practice
  windows-install.md     # Git Bash + WSL2 setup
  troubleshooting.md     # Field-tested fixes for common issues
  api-reference.md       # Scripts, hooks, skills, schemas, exit codes
  recipes.md             # Recipe adaptation guide: stack substitution, gate customization, DAG reshape examples
  platform-tiers.md      # Tier definitions + feature parity matrix (Claude Code / Cursor / advisory)
  tier1-verification.md  # Claude Code hook stdin contract + live-session verification protocol
```

---

## What's Coming

### Phase 5: Portable Enforcement & Multi-Tier Platform Support

Off-Claude platforms can't block at the keystroke boundary, so enforcement is relocated to the
git/CI boundary — which every platform shares. See [docs/platform-tiers.md](docs/platform-tiers.md)
for the feature parity matrix and tier definitions.

- [x] G5.0 — Reconcile roadmap, ship `meridian-doctor.sh`, close the `yq` gate-detection gap ✅
- [x] G5.1 — Tier 1 (Claude Code): verify full enforcement with a real live-session protocol ✅ (found + fixed a live hook-contract bug; see `docs/tier1-verification.md`)
- [x] G5.2 — Portable verifier: `meridian-verify.sh` + generated `pre-commit` hook + CI workflow (the shared boundary) ✅ (end-to-end git block proven)
- [x] G5.3 — Tier 2 (Cursor/Windsurf/Cline): editor rules generated from the same source as the hooks ✅ (idempotent, round-trip tested)
- [x] G5.4 — Tier 3 (Advisory): generated `MERIDIAN.md`, enforced via CI ✅ (same generator)
- [x] G5.5 — Platform detection (`detect-runtime.sh`) + install wiring + published parity matrix ✅

### Phase 6: Documentation ✅ Complete

- [x] G6.1 — Component docs: quickstart, gate model, memory, observability, assumptions
- [x] G6.2 — Windows installation guide (Git Bash + WSL2)
- [x] G6.3 — Troubleshooting guide (field-tested fixes)
- [x] G6.4 — API reference (scripts, hooks, skills, schemas, exit codes)
- [x] G6.5 — Contributing guide

### Phase 7: Dogfooding & Refinement

- Run Meridian on real projects; tighten based on friction (AeroIntel is already
  installed and self-verifying as of Phase 5)

---

## Design Principles

From [MERIDIAN_ARCHITECTURE_DECISIONS.md](MERIDIAN_ARCHITECTURE_DECISIONS.md):

1. **Mechanical enforcement** — Nothing the model can hallucinate past
2. **Self-improving** — Mistakes become permanent calibration data, not retries
3. **Context-efficient** — Load only what's needed when it's needed
4. **Observability-complete** — Engineer-legible, not just LLM-readable
5. **Model-agnostic** — Assumptions documented and pruned as models improve

---

## Repository Structure

```text
meridian/
  .meridian/                  # Runtime state (gitignored)
    memory/                   # Three-tier memory files
    telemetry.jsonl           # Structured event log
    session.json              # Active session state
    gate-schema.yaml          # Gate definition reference
    memory-schema.json        # Memory validation schema
    telemetry-schema.json     # Telemetry event schema

  .claude/                    # Claude Code integration
    hooks/                    # PreToolUse / PostToolUse enforcement
    skills/                   # 15 slash-command skill definitions
    agents/                   # 3 subagent definitions

  scripts/                    # Core framework scripts
  recipes/                    # Pattern-based gate definitions + foundation templates
    fullstack-web/
    cli-tool/
    ml-research/

  docs/                       # Framework documentation
    quickstart.md             # Meridian in 10 minutes
    gate-model.md             # Composable gate DAG + enforcement
    memory.md                 # Schema-validated memory types
    observability.md          # Telemetry + dashboards
    assumptions.md            # Assumption governance in practice
    windows-install.md        # Git Bash + WSL2 setup
    troubleshooting.md        # Field-tested fixes
    api-reference.md          # Scripts, hooks, skills, schemas
    recipes.md                # Recipe adaptation guide
    platform-tiers.md         # Tier definitions + feature parity matrix
    tier1-verification.md     # Claude Code hook contract + verification protocol

  tests/                      # 18 test suites (226 tests passing)
  experiment/                 # Generator-Evaluator validation experiment
  install.sh                  # One-command project installer

  README.md
  ROADMAP.md                  # Gate progress and calibration tracking
  PHILOSOPHY.md               # Design principles
  ASSUMPTIONS.md              # Harness assumptions governance
  MERIDIAN_ARCHITECTURE_DECISIONS.md
```

---

## Installation

```bash
# Clone the framework
git clone https://github.com/PCSchmidt/meridian

# Install to your project
cd your-project
bash ../meridian/install.sh . --recipe fullstack-web
# or: --recipe cli-tool
# or: --recipe ml-research

# Verify installation
bash scripts/gate-engine.sh validate .meridian/gates.yaml
```

See [docs/recipes.md](docs/recipes.md) for adapting the recipe to your stack.

---

## Running Tests

```bash
bash tests/test-hooks.sh               # Hook system (7 tests)
bash tests/test-telemetry.sh           # Telemetry pipeline (8 tests)
bash tests/test-security.sh            # Security blocklist (14 tests)
bash tests/test-health.sh              # /health report (12 tests)
bash tests/test-status.sh              # /status command (11 tests)
bash tests/test-gate-enforcement.sh    # Gate validators + evaluator (19 tests)
bash tests/test-memory-hooks.sh        # Reflexion / sync / trim (14 tests)
bash tests/test-skills.sh              # Core skills + manifest (19 tests)
bash tests/test-lifecycle.sh           # Lifecycle-aware completion (19 tests)
bash tests/test-drift.sh               # Drift sensor (15 tests)
bash tests/test-calibration.sh         # Judge calibration (21 tests)
bash tests/test-integration-phase1.sh  # Phase 1 end-to-end (8 tests)
bash tests/test-integration-phase2.sh  # Phase 2 end-to-end (19 tests)
```

All 18 suites — **226 tests** — pass on Windows / Git Bash.

---

## Documentation

**Guides**

- [Quickstart](docs/quickstart.md) — Meridian in 10 minutes (install → first gate)
- [Gate Model](docs/gate-model.md) — the composable gate DAG and how it's enforced
- [Memory System](docs/memory.md) — the three schema-validated memory types
- [Observability](docs/observability.md) — telemetry, `/health`, `/status`, costs
- [Recipe Adaptation Guide](docs/recipes.md) — How to adapt recipes to your stack
- [Platform Tiers](docs/platform-tiers.md) — Tier definitions and feature parity matrix
- [Tier 1 Verification](docs/tier1-verification.md) — Claude Code hook stdin contract and verification protocol
- [Maintaining ASSUMPTIONS.md](docs/assumptions.md) — assumption governance, in practice
- [Windows Install](docs/windows-install.md) — Git Bash and WSL2 setup
- [Troubleshooting](docs/troubleshooting.md) — field-tested fixes for common issues

**Reference**

- [API Reference](docs/api-reference.md) — scripts, hooks, skills, schemas, exit codes
- [Architecture Decisions](MERIDIAN_ARCHITECTURE_DECISIONS.md) — Complete design blueprint
- [ROADMAP.md](ROADMAP.md) — Gate progress and calibration data
- [PHILOSOPHY.md](PHILOSOPHY.md) — Design principles and rationale
- [ASSUMPTIONS.md](ASSUMPTIONS.md) — Harness assumptions governance
- [CONTRIBUTING.md](CONTRIBUTING.md) — Development model, standards, PR process
- [Hook System](.claude/hooks/README.md) — Hook architecture and usage

---

## Contributing

Meridian is in active development. Contributions will be welcome after v0.1.0 release. See [ROADMAP.md](ROADMAP.md) for planned work.

---

## License

MIT License — See LICENSE file (coming soon)

---

## Author

**Paul Christopher Schmidt**

- GitHub: [@PCSchmidt](https://github.com/PCSchmidt)
- Email: p.christopher.schmidt@gmail.com

---

## Acknowledgments

Built on research and patterns from:

- Syntaris framework (brianonieal) — gate enforcement, memory taxonomy, recipe structure
- Anthropic Engineering — harness design, context management, agent patterns
- Reflexion (Shinn et al., NeurIPS 2023) — verbal reflection into episodic memory
- Martin Fowler — harness engineering, feedforward/feedback controls

---

**Phases 0–6 complete.** Blocking security enforcement, gate-transition validators, the generator-evaluator verdict contract, memory-management hooks, 15 progressively-disclosed skills, a calibrated drift sensor, a one-command installer, three complete recipes (fullstack-web, cli-tool, ml-research), and **portable enforcement** — a platform-neutral verifier wired to a git pre-commit + CI boundary, plus rule surfaces generated from source for Cursor/Windsurf/Cline/advisory — have all shipped (226 tests passing). Documentation is complete (Phase 6): quickstart, gate model, memory, observability, Windows install, troubleshooting, API reference, and contributing guides. Next: Phase 7 (Dogfooding & Refinement). Target: v0.1.0 by 2026-09-10.
