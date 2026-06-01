# Meridian

A next-generation agent harness framework for AI coding assistants.

![Status](https://img.shields.io/badge/status-in%20development-green)
![Version](https://img.shields.io/badge/version-0.1.0--dev-blue)
![Phase 1](https://img.shields.io/badge/phase%201-complete-brightgreen)
![Phase 2](https://img.shields.io/badge/phase%202-starting-yellow)

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

## Status: Phase 1 Complete — Phase 2 Starting

**Current phase:** Phase 2 — Core Hooks & Skills (starting)

**Last completed:** Phase 1 — Foundation (7/7 gates, 40h/40h, 0.97x avg calibration, completed 2026-06-01)

**Timeline:** ~10 weeks remaining to v0.1.0 (target: 2026-09-10)

### Phase Progress

| Phase | Status | Estimated | Actual |
|-------|--------|-----------|--------|
| 0. Planning & Validation | ✅ Complete | 8h | 6h |
| 1. Foundation | ✅ Complete | 40h | 40h |
| 2. Core Hooks & Skills | 🔄 Starting | 60h | — |
| 3. Multi-Tier Support | ⏳ Upcoming | 30h | — |
| 4. Recipes | ⏳ Upcoming | 40h | — |
| 5. Subagents | ⏳ Upcoming | 35h | — |
| 6. Documentation | ⏳ Upcoming | 25h | — |
| 7. Dogfooding & Refinement | ⏳ Upcoming | 40h | — |
| 8. Community Preparation | ⏳ Upcoming | 15h | — |

### Phase 1 Gates (All Complete)

- ✅ G1.1: Composable Gate DAG Engine (6h)
- ✅ G1.2: Schema-Validated Memory System (10h)
- ✅ G1.3: Basic Hook Infrastructure (8h)
- ✅ G1.4: Telemetry System / JSONL (6h)
- ✅ G1.5: `/health report` Command (6h)
- ✅ G1.6: `/status` Command (2h)
- ✅ G1.7: Phase 1 Integration Test — 46 tests passing (2h)

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

## What's Built (Phase 1)

### Foundation Scripts

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

### Hook System

| Hook | Purpose |
|------|---------|
| `.claude/hooks/hook-wrapper.sh` | Common library: logging, timing, error handling |
| `.claude/hooks/PreToolUse.sh` | Pre-execution validation — blocks destructive ops |
| `.claude/hooks/PostToolUse.sh` | Post-execution validation — memory schema + telemetry |

### Skills

| Skill | Trigger | Purpose |
|-------|---------|---------|
| `.claude/skills/health/health.md` | `/health` | Health report: calibration, memory, telemetry |
| `.claude/skills/status/status.md` | `/status` | Session-start status: completed gates, current gate |
| `.claude/skills/memory/memory.md` | `/memory` | Memory management: doctor, show, stats, prune |

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

## What's Coming (Phase 2+)

### Core Architecture

- [ ] Multi-tier platform support (Claude Code, Cursor/Windsurf, Advisory)
- [ ] Generator-Evaluator feedback loop (Gate Evaluator subagent)
- [ ] Real-time cost tracking

### Hooks (Phase 2)

- [ ] `block-dangerous.sh` — security rule enforcement
- [ ] `validate-contract.sh` / `validate-spec.sh` — gate artifact checks
- [ ] `run-evaluator.sh` — Generator-Evaluator integration
- [ ] `write-reflexion.sh` — automated reflexion writes
- [ ] `global-memory-sync.sh` — cross-project pattern sync

### Skills (Phase 2)

- [ ] `/start` — session initialization with memory reconstruction
- [ ] `/deploy` — deployment workflow
- [ ] `/rollback` — rollback to last gate
- [ ] `/security` — security audit
- [ ] `/costs` — cost tracking
- [ ] `/build-rules` — build workflow orchestration

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

  tests/                      # Test suites (46 tests passing)
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
```

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

**Phase 1 complete.** Gate DAG engine, schema-validated memory, hook infrastructure, telemetry, `/health`, `/status`, and integration tests all shipped. Phase 2 starting. Target: v0.1.0 by 2026-09-10.
