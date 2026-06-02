# Meridian

A next-generation agent harness framework for AI coding assistants.

![Status](https://img.shields.io/badge/status-in%20development-green)
![Version](https://img.shields.io/badge/version-0.1.0--dev-blue)
![Phase 1](https://img.shields.io/badge/phase%201-complete-brightgreen)
![Phase 2](https://img.shields.io/badge/phase%202-5%2F6%20gates-brightgreen)
![Tests](https://img.shields.io/badge/tests-111%20passing-brightgreen)

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

## Status: Phase 2 In Progress (5/6 gates)

**Current phase:** Phase 2 — Core Hooks & Skills (5/6 gates, 46h/54h so far)

**Last completed:** G2.5 — Skill Progressive Disclosure (2026-06-02). Phase 1 — Foundation closed at 7/7 gates, 40h/40h, on 2026-06-01.

**Tests:** 111 passing across 9 suites.

### Phase Progress

| Phase | Status | Estimated | Actual |
|-------|--------|-----------|--------|
| 0. Planning & Validation | ✅ Complete | 8h | 6h |
| 1. Foundation | ✅ Complete | 40h | 40h |
| 2. Core Hooks & Skills | ✅ Complete | 60h | 46h |
| 3. Prove the Thesis *(redirected — evaluator, drift sensor, real-project validation)* | 🔄 2/5 gates | 32h | 7h |
| 4. Recipes | ⏳ Deferred | 40h | — |
| 5. Multi-Tier Support *(was Phase 3)* | ⏳ Deferred | 30h | — |
| (former 5) Subagents → merged into Phase 3 | — | — | — |
| 6. Documentation | ⏳ Upcoming | 25h | — |
| 7. Dogfooding & Refinement | ⏳ Upcoming | 40h | — |
| 8. Community Preparation | ⏳ Upcoming | 15h | — |

### Phase 2 Gates (Complete)

- ✅ G2.1: Security Hooks — `block-dangerous.sh`, first hook that blocks (exit 2)
- ✅ G2.2: Gate Enforcement Hooks — validators, `run-tests`, `run-evaluator`, `gate-engine verify`
- ✅ G2.3: Memory Management Hooks — `write-reflexion`, `global-memory-sync`, `context-trim`
- ✅ G2.4: Core Skills — 12 skill docs + backing scripts
- ✅ G2.5: Skill Progressive Disclosure — frontmatter metadata + `skill-manifest.sh`
- ✅ G2.6: Phase 2 Integration Test — 131 tests across 10 suites, all passing

### Phase 3 Gates (In Progress)

- ✅ G3.1: Gate Evaluator Subagent — `gate-evaluator.md`, `spec-reviewer.md`, `/evaluate`, `/review`
- ✅ G3.2: Lifecycle-Aware Completion — `FEATURES.json`, `features-init.sh`, `features-report.sh`, `/status` upgrade
- ⏳ G3.3: Continuous Drift Sensor
- ⏳ G3.4: Calibrate the Judge
- ⏳ G3.5: Minimal Installer + Real-Project Validation

See [ROADMAP.md](ROADMAP.md) for detailed gate tracking and calibration data.

---

## Key Differentiators

1. **Engineer-legible observability** — Gate pass rates, calibration trends, error logs you can grep
2. **Composable gate DAG** — YAML-configured, project-specific, not hardcoded
3. **Schema-validated memory** — Integrity-guaranteed JSONL storage with deduplication
4. **Generator-Evaluator separation** — Independent evaluation prevents self-grading (validated by experiment: -3.0 point delta)
5. **ASSUMPTIONS.md governance** — Every harness assumption documented, pruned as models improve
6. **Pattern-based recipes** — Stack-flexible (`fullstack-web`, `cli-tool`, `ml-research`)

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

### Subagents (`.claude/agents/`)

| Agent | Purpose |
|-------|---------|
| `gate-evaluator.md` | Adversarial 4-dimension scorer; pass/warn/fail verdict |
| `spec-reviewer.md` | Spec completeness reviewer; gap and contradiction detection |

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

### Recipes (Gate Definitions)

```
recipes/
  fullstack-web/gates.yaml    # Frontend + backend + database gate model
  cli-tool/gates.yaml         # Command-line tool gate model
  ml-research/gates.yaml      # ML pipeline gate model (unique to Meridian)
```

---

## What's Coming

### Remaining in Phase 3

- [ ] G3.3 — Continuous Drift Sensor (advisory warning light)
- [ ] G3.4 — Calibrate the Judge (fixture-based discrimination test)
- [ ] G3.5 — Minimal Installer + Real-Project Validation

### Core Architecture (Phase 5)

- [ ] Multi-tier platform support (Claude Code, Cursor/Windsurf, Advisory)
- [ ] Live in-loop Gate Evaluator **subagent** (G5.1) — the verdict *contract* is already enforced by `run-evaluator.sh`
- [ ] Cost capture wired to a token source (aggregation already built in `cost-report.sh`)

### Shipped in Phase 2

- [x] `block-dangerous.sh` — security rule enforcement (exit 2)
- [x] `validate-contract.sh` / `validate-spec.sh` / `validate-roadmap.sh` — gate artifact checks
- [x] `run-evaluator.sh` — generator-evaluator verdict enforcement
- [x] `write-reflexion.sh` — reflexion writer
- [x] `global-memory-sync.sh` — cross-project pattern sync
- [x] `context-trim.sh` — episodic memory trimming
- [x] 14 skills (`/start`, `/deploy`, `/rollback`, `/security`, `/costs`, `/testing`, `/build-rules`, `/critical-thinker`, `/research`, `/health`, `/status`, `/memory`, `/evaluate`, `/review`) with progressive disclosure
- [x] `features-init.sh` / `features-report.sh` — lifecycle-aware completion (happy-path % vs full-lifecycle %)
- [x] `gate-evaluator.md` / `spec-reviewer.md` — adversarial subagents for generator-evaluator separation

### Recipes (Phase 4)

- [ ] `fullstack-web` — full gate model with reference implementation (Next.js + FastAPI + Supabase)
- [ ] `cli-tool` — full gate model with reference implementation (Python + Click)
- [ ] `ml-research` — full gate model with reference implementation (PyTorch + FastAPI) — **unique to Meridian**

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
    skills/                   # Slash-command skill definitions
    agents/                   # Subagent definitions (Phase 5)

  scripts/                    # Core framework scripts
  recipes/                    # Pattern-based gate definitions
    fullstack-web/
    cli-tool/
    ml-research/

  tests/                      # Test suites (111 tests passing)
  experiment/                 # Generator-Evaluator validation
  docs/                       # Documentation (Phase 6)

  README.md
  ROADMAP.md                  # Gate progress and calibration tracking
  PHILOSOPHY.md               # Design principles
  ASSUMPTIONS.md              # Harness assumptions governance
  MERIDIAN_ARCHITECTURE_DECISIONS.md
```

---

## Installation (Coming in Phase 6)

```bash
# Clone the framework
git clone https://github.com/PCSchmidt/meridian

# Install to your project
cd your-project
bash ../meridian/install.sh --recipe fullstack-web

# Verify installation
bash meridian-doctor.sh
```

---

## Running Tests

```bash
bash tests/test-hooks.sh               # Hook system (7 tests)
bash tests/test-telemetry.sh           # Telemetry pipeline (8 tests)
bash tests/test-health.sh              # /health report (12 tests)
bash tests/test-status.sh              # /status command (11 tests)
bash tests/test-integration-phase1.sh  # Phase 1 end-to-end (8 tests)
bash tests/test-security.sh            # Security blocklist (14 tests)
bash tests/test-gate-enforcement.sh    # Gate validators + evaluator (19 tests)
bash tests/test-memory-hooks.sh        # Reflexion / sync / trim (14 tests)
bash tests/test-skills.sh              # Core skills + manifest (18 tests)
```

All 9 suites — **111 tests** — pass on Windows / Git Bash.

---

## Documentation

- [Architecture Decisions](MERIDIAN_ARCHITECTURE_DECISIONS.md) — Complete design blueprint
- [ROADMAP.md](ROADMAP.md) — Gate progress and calibration data
- [PHILOSOPHY.md](PHILOSOPHY.md) — Design principles and rationale
- [ASSUMPTIONS.md](ASSUMPTIONS.md) — Harness assumptions governance
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

**Phase 1 complete; Phase 2 at 5/6 gates.** Blocking security enforcement, gate-transition validators, the generator-evaluator verdict contract, memory-management hooks, and 12 progressively-disclosed skills have all shipped (111 tests passing). Next: the Phase 2 integration test (G2.6). Target: v0.1.0 by 2026-09-10.
