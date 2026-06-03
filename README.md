# Meridian

A next-generation agent harness framework for AI coding assistants.

![Status](https://img.shields.io/badge/status-in%20development-green)
![Version](https://img.shields.io/badge/version-0.1.0--dev-blue)
![Phases 0-4](https://img.shields.io/badge/phases%200--4-complete-brightgreen)
![Tests](https://img.shields.io/badge/tests-186%20passing-brightgreen)

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

## Status: Phases 0–4 Complete

**Current status:** Phase 4 complete — all three recipes shipped (fullstack-web, cli-tool, ml-research). Phase 5 (Multi-Tier Platform Support) is next.

**Tests:** 186 passing across 13 suites.

### Phase Progress

| Phase | Status | Estimated | Actual |
| ----- | ------ | --------- | ------ |
| 0. Planning & Validation | ✅ Complete | 8h | 6h |
| 1. Foundation | ✅ Complete | 40h | 40h |
| 2. Core Hooks & Skills | ✅ Complete | 60h | 46h |
| 3. Prove the Thesis *(evaluator, drift sensor, real-project validation)* | ✅ Complete | 32h | 16h |
| 4. Recipes *(fullstack-web, cli-tool, ml-research)* | ✅ Complete | 40h | ~8.5h |
| 5. Multi-Tier Support *(Claude Code verify + Cursor/Windsurf + Advisory)* | ⏳ Not Started | 30h | — |
| 6. Documentation | ⏳ Upcoming | 25h | — |
| 7. Dogfooding & Refinement | ⏳ Upcoming | 40h | — |
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
  recipes.md    # Recipe adaptation guide: stack substitution, gate customization, DAG reshape examples
```

---

## What's Coming

### Phase 5: Multi-Tier Platform Support

- [ ] G5.1 — Tier 1 (Claude Code): verify full enforcement in a clean session, update installation guide
- [ ] G5.2 — Tier 2 (Cursor/Windsurf): convert hooks to auto-applied rules (~60-70% compliance)
- [ ] G5.3 — Tier 3 (Advisory): generate markdown guidance from hook logic (~50-60% compliance)
- [ ] G5.4 — Platform detection: `detect-runtime.sh` auto-adapts installation to platform tier

### Phase 6: Documentation

- Full user guide, API reference, getting-started tutorial

### Phase 7: Dogfooding & Refinement

- Run Meridian on 2-3 real projects; tighten based on friction

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
    skills/                   # 14 slash-command skill definitions
    agents/                   # 3 subagent definitions

  scripts/                    # Core framework scripts
  recipes/                    # Pattern-based gate definitions + foundation templates
    fullstack-web/
    cli-tool/
    ml-research/

  docs/                       # Framework documentation
    recipes.md                # Recipe adaptation guide

  tests/                      # 13 test suites (186 tests passing)
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

All 13 suites — **186 tests** — pass on Windows / Git Bash.

---

## Documentation

- [Architecture Decisions](MERIDIAN_ARCHITECTURE_DECISIONS.md) — Complete design blueprint
- [ROADMAP.md](ROADMAP.md) — Gate progress and calibration data
- [PHILOSOPHY.md](PHILOSOPHY.md) — Design principles and rationale
- [ASSUMPTIONS.md](ASSUMPTIONS.md) — Harness assumptions governance
- [Recipe Adaptation Guide](docs/recipes.md) — How to adapt recipes to your stack
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

**Phases 0–4 complete.** Blocking security enforcement, gate-transition validators, the generator-evaluator verdict contract, memory-management hooks, 14 progressively-disclosed skills, a calibrated drift sensor, a one-command installer validated on a real project, and three complete recipes (fullstack-web, cli-tool, ml-research) have all shipped (186 tests passing). Next: Phase 5 multi-tier platform support (Cursor/Windsurf/advisory). Target: v0.1.0 by 2026-09-10.
