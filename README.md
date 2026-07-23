# Meridian

**Without a harness, agents score their own work 5.5/10. An independent evaluator scores the same work 2.5/10.** That 3.0-point gap is why features get marked done while tests still fail. Meridian closes it mechanically.

![Status](https://img.shields.io/badge/status-v0.1.0-blue)
![Tests](https://img.shields.io/badge/tests-238%20passing-brightgreen)
![Phases 0-7](https://img.shields.io/badge/phases%200--7-complete-brightgreen)
![Dogfooded](https://img.shields.io/badge/dogfooded-2%20production%20projects-green)

---

## The Problem With AI-Assisted Development at Scale

Every developer who has used an AI coding agent on a complex project has hit the same wall. It starts well — features ship, momentum builds, confidence grows. Then, somewhere around 60–80% completion, things fall apart in predictable ways:

**The agent declares "done" when it isn't.** Tests haven't run, but the agent says they're passing. A feature is marked complete, but three edge cases were silently skipped. The agent evaluated its own work generously — "looks good!" — on code with SQL injection vulnerabilities. This isn't carelessness; it's structural. A model that generates work and then evaluates the same work in the same session has no incentive toward harsh self-assessment.

**Each session starts from zero.** The context window resets. What was decided two sessions ago — the auth approach, the API design, the scope boundary that was agreed upon — is gone. The next session re-derives it, possibly differently. Over a multi-week project, this compounds into subtle divergence from the original intent.

**Estimates are fiction.** "This will take about a day" is a guess that never gets validated. When the actual time is three days, the reason isn't captured. The same mistake happens again on the next project. There's no mechanism for the agent's estimates to improve over time.

**Scope drifts silently.** Features get added mid-gate because they seemed related. Architectural decisions get made ad hoc because the original spec didn't cover the case. By the time anyone notices, unwinding the drift is more work than the drift was.

**You can't see what happened.** When a session goes wrong — when something breaks that was working, when a gate that passed earlier is now failing — there's no record. No log of what the agent did, what it evaluated, what it blocked. Debugging means re-deriving from scratch.

None of these are prompt quality problems. You can't word-craft your way out of them. They're structural failures that require structural solutions.

---

## What Meridian Does

Meridian is an **agent harness** — infrastructure that sits between your AI coding agent and the work being done, enforcing rules that the model cannot hallucinate past.

Not prompt rules. Mechanical rules. When a gate check fails, the hook exits with code 2 and the model's next tool call is **blocked**. No amount of "but I think it's done" changes exit code 2. The model cannot convince a bash script that tests are passing when they're not.

The harness enforces five things:

**Enforced gates.** You define checkpoints in a YAML gate graph — milestones like `scope_confirmed`, `tests_passing`, `api_integrated`, `deployed`. The model cannot advance past a gate until its pre-conditions pass mechanically. A `tests_passing` gate wired to your test runner will block if tests fail, regardless of what the agent believes.

**Independent evaluation.** The Gate Evaluator subagent runs in a fresh context with no memory of what was generated. It's told "you did not produce this work" and scores it adversarially: completeness, quality, consistency, spec adherence. A score below 7.0 or a `fail` verdict blocks the gate at exit 2. This is the mechanism that eliminates the 3.0-point self-grading gap.

**Schema-validated persistent memory.** Three memory types persist across session resets: semantic patterns ("this kind of task takes 1.5x longer than estimated"), episodic events (what happened in each session), and corrections (predicted vs actual, for calibration). These are JSONL files validated against schemas on every write — not markdown the model can silently corrupt.

**Calibration data.** After each gate, you write a reflexion entry: predicted hours, actual hours, root cause, next-action. Over time these compound into a personal calibration dataset. Your estimates improve because you're measuring them, not guessing.

**Engineer-legible observability.** Every gate transition, hook block, and evaluator verdict is written to structured JSONL. `/health report` surfaces calibration trends, gate pass rates, and token costs. You can answer "why did this fail three sessions ago?" with a one-line jq query.

---

## How a Meridian Project Works

Here is the development loop, concretely — from install to shipped gate.

### Step 1: Install and define scope

Install Meridian into your project once, choosing a recipe that matches your project type:

```bash
git clone https://github.com/PCSchmidt/meridian
cd your-project
bash ../meridian/install.sh . --recipe fullstack-web
# recipes: fullstack-web | cli-tool | ml-research
```

This copies the hooks, skills, subagents, scripts, schemas, a git pre-commit boundary, and a CI workflow into your project and registers hooks with Claude Code automatically. Nothing else to configure.

Then write two documents that define your project's intent:

```text
CONTRACT.md  — what you're building, what's out of scope, acceptance criteria
SPEC.md      — features as ## headings, in priority order
```

The `/build-rules` skill walks you through defining a gate DAG in `.meridian/gates.yaml` — the ordered sequence of checkpoints your project must pass through. For a web app this might be:

```text
scope_confirmed → backend_working → frontend_working → integrated → deployed
```

For a CLI tool it looks different. For an ML project it includes a `data_contract` gate that enforces methodology decisions before any training code runs. Recipes provide starting point DAGs for each pattern. The DAG is yours to adapt — gates are not hardcoded.

### Step 2: Work one gate at a time

Each gate has pre-conditions — hooks that must pass before the gate can advance. Work on what the current gate requires, then check where you stand:

```bash
bash scripts/gate-engine.sh current            # what gate am I on?
bash scripts/gate-engine.sh verify <gate-id>   # do this gate's checks pass?
```

If a check fails, the engine tells you exactly why. Fix it, re-verify. You cannot declare a gate complete by stating it is — it has to pass. This is a harder constraint than it sounds: in practice, most "I think this is done" moments fail the first verification for a reason that matters.

### Step 3: Get an independent evaluation

Before advancing, invoke the Gate Evaluator on the current gate's artifacts:

```bash
/evaluate <gate-id>
```

This spawns the evaluator subagent in a fresh context — no memory of what was just built. It reads the artifacts cold, scores them on a 0–10 scale across four dimensions, and returns a structured JSON verdict. A score below 7.0 or any high-severity issue produces a `fail` verdict that blocks the gate.

The adversarial framing matters. The evaluator is instructed: *"You did not produce these artifacts. Your job is to evaluate, not to help. Do not praise. Find what is wrong."* This is the architectural separation that eliminates self-grading bias.

**In practice, what does the evaluator catch?** On the Hard Power Intelligence project (a production full-stack build used to dogfood Meridian), Gate 5 (`brief_verified`) failed its first evaluation because citation handling was stub code, not working infrastructure. The spec required verified citations. The agent had marked the gate ready. The evaluator flagged the gap as a high-severity issue and blocked. Citation evaluation was then built as actual infrastructure rather than a post-hoc add-on. Without the gate, this would have shipped as technical debt — exactly the kind of quiet drift that accumulates into rewrites.

### Step 4: Write a reflexion entry

After each gate passes, record what you learned about your estimate:

```bash
bash scripts/write-reflexion.sh \
  --gate backend_working \
  --predicted 8 --actual 5 \
  --root-cause "API documentation was thorough; integration was faster than modeled" \
  --action-next "Reduce API integration estimates by 35% for well-documented APIs"
```

The script validates the entry before appending it to schema-validated memory. Over time, these entries surface patterns: "frontend gates with more than 8 components consistently take 1.5x the estimate." Your operator multiplier converges toward 1.0x. This is the mechanism that makes your estimates improve across projects, not just within one.

### Step 5: Commit — the boundary enforces at the edge

The git pre-commit hook runs `meridian-verify.sh` — the same gate engine, memory validator, and evaluator contract check — before every commit. If anything is misaligned, the commit is blocked. This boundary runs on every platform, not just Claude Code.

Then push, and move to the next gate.

### Step 6: Resume the next session without ceremony

When you open the next session:

```bash
/start
```

Meridian restores session state, shows the current gate, surfaces any stop events from the previous session, and loads relevant memory. You don't re-derive what was decided — it was written down and validated. You pick up from exactly where you left off.

---

## What Projects Benefit Most

**Where Meridian adds the most value:**

- **Multi-session projects.** If you can finish something in a single sitting, you don't need a harness. A production web app, a CLI tool with a real release cycle, an ML pipeline with training and evaluation — these span sessions and accumulate context loss, drift, and unverified "done" claims. That's the environment Meridian was built for.

- **When "done" meaning "mostly done" has real cost.** A shipped feature with a silent bug is worse than a delayed feature. Gates force verification at the checkpoints that matter — before integration, before deploy, before the next phase starts.

- **After you've been burned by context loss.** If you've spent a session re-explaining decisions from two sessions ago, or watched a session re-derive an architectural choice in a different direction, persistent schema-validated memory solves this directly.

- **When estimates matter.** Client projects, deadline-driven releases, or any work where you need to give a forecast: the calibration system turns "I have no idea how long this will take" into a compounding dataset that gets more accurate with every gate.

- **Complex domains with methodology risk.** The `ml-research` recipe enforces a `data_contract` gate: the human must define the target metric, evaluation thresholds, baseline, and approach constraints *before* any training code runs. No other agent framework enforces ML methodological decisions mechanically.

**Where Meridian is not the right tool:**

- Exploratory one-off scripts, prototypes, or throwaway experiments where the "done" criteria cannot be defined upfront.
- Projects where the entire build fits in a single session.
- Teams unwilling to write CONTRACT.md and SPEC.md before starting — the harness enforces the discipline of defined scope, and shortcuts here undermine the framework's entire premise.

---

## Getting Started

```bash
# Prerequisites: bash ≥ 4, jq, yq (mikefarah), git
# (see docs/quickstart.md for install commands per platform)

git clone https://github.com/PCSchmidt/meridian
cd your-project
bash ../meridian/install.sh . --recipe fullstack-web

# Verify installation
bash scripts/meridian-doctor.sh   # expect: GOOD
```

- Full walkthrough: [docs/quickstart.md](docs/quickstart.md)
- Gate model deep dive: [docs/gate-model.md](docs/gate-model.md)
- Windows setup: [docs/windows-install.md](docs/windows-install.md)
- Adapting recipes to your stack: [docs/recipes.md](docs/recipes.md)

---

## Key Differentiators

1. **Engineer-legible observability** — Gate pass rates, calibration trends, error logs you can grep; not just LLM-readable markdown
2. **Composable gate DAG** — YAML-configured, project-specific, not hardcoded into the framework
3. **Schema-validated memory** — Integrity-guaranteed JSONL with deduplication; validated on every write
4. **Generator-Evaluator separation** — Independent evaluation prevents self-grading (validated by experiment: −3.0 point delta)
5. **ASSUMPTIONS.md governance** — Every harness assumption documented with a review trigger; pruned as models improve
6. **Pattern-based recipes** — Stack-flexible (`fullstack-web`, `cli-tool`, `ml-research`) with `DATA_CONTRACT` gate for ML methodology enforcement

---

## Status: v0.1.0 — Phases 0–7 Complete

Dogfooded on two production projects (AeroIntel + Hard Power Intelligence — live at hardpowerintel.com). 238 tests passing across 18 suites. All three recipes verified end-to-end. `meridian-doctor` passes GOOD. shellcheck clean on all hooks.

**Experiment result:** Generator-Evaluator separation delta = **−3.0 points** (self: 5.5/10 vs independent: 2.5/10). This is the core finding the framework was built to enforce. See `experiment/GENERATOR_EVALUATOR_VALIDATION.md`.

**Dogfood result (HPI):** 9 gates enforced through a production full-stack build (Next.js + FastAPI + Supabase). `brief_verified` (Gate 5) forced citation evaluation to be built as infrastructure, not a post-hoc add-on — exactly the kind of drift a gate-less process would have let slip.

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
| 7. Dogfooding & Refinement | ✅ Complete | 40h | ~13h |
| 8. Community Preparation | ⏳ Next | 15h | — |

See [ROADMAP.md](ROADMAP.md) for detailed gate tracking and calibration data.

---

## What's Built

### Foundation Scripts

| Script | Purpose |
| ------ | ------- |
| `scripts/gate-engine.sh` | Reads `gates.yaml`, validates DAG, enforces dependencies |
| `scripts/validate-memory.sh` | Schema validates all three memory types |
| `scripts/memory-doctor.sh` | Memory health check and repair wrapper |
| `scripts/log-event.sh` | Appends structured events to `telemetry.jsonl` |
| `scripts/session.sh` | Session lifecycle management (start/end/id/status) |
| `scripts/start-session.sh` | Session bootstrap — resume/new, status, current gate, memory check |
| `scripts/log-episodic.sh` | Write a typed episodic event to `episodic.jsonl` |
| `scripts/telemetry-query.sh` | Query telemetry: summary, gates, tools, errors, tail |
| `scripts/health-report.sh` | Full health report: session, calibration, memory, telemetry |
| `scripts/status-report.sh` | Compact session-start status — completed gates + calibration |
| `scripts/write-reflexion.sh` | Append calibration entry to `corrections.jsonl` (write-ahead validated) |
| `scripts/global-memory-sync.sh` | Cross-project memory sync to `~/.meridian/global/` (push/pull/status) |
| `scripts/context-trim.sh` | Trim `episodic.jsonl` to last N sessions, archive the rest |
| `scripts/rollback-gate.sh` | Revert gate state to an earlier gate (+ git guidance) |
| `scripts/security-audit.sh` | Active rules + security telemetry summary |
| `scripts/cost-report.sh` | Aggregate token/cost telemetry |
| `scripts/skill-manifest.sh` | Emit the always-loaded skill metadata layer |
| `scripts/features-init.sh` | Seed `.meridian/FEATURES.json` from SPEC.md headings |
| `scripts/features-report.sh` | Two metrics: happy-path % vs full-lifecycle % |
| `scripts/drift-report.sh` | Run drift evaluator and emit advisory drift verdict |
| `scripts/meridian-doctor.sh` | Full installation health check (deps, schemas, hooks, memory) |
| `scripts/meridian-verify.sh` | Platform-neutral gate+memory+evaluator verifier (git/CI boundary) |

### Subagents (`.claude/agents/`)

| Agent | Purpose |
| ----- | ------- |
| `gate-evaluator.md` | Adversarial 4-dimension scorer; pass/warn/fail verdict |
| `spec-reviewer.md` | Spec completeness reviewer; gap and contradiction detection |
| `drift-evaluator.md` | SPEC/FEATURES alignment scorer; advisory drift detection |

### Hook System

| Hook | Purpose |
| ---- | ------- |
| `.claude/hooks/hook-wrapper.sh` | Common library: logging, timing, error handling |
| `.claude/hooks/SessionStart.sh` | Auto-start session on conversation open |
| `.claude/hooks/PreToolUse.sh` | Pre-execution validation — **blocks (exit 2)** via `block-dangerous.sh` |
| `.claude/hooks/PostToolUse.sh` | Post-execution validation — memory schema + telemetry |
| `.claude/hooks/block-dangerous.sh` | Security blocklist enforcement (exit 2 on dangerous ops) |
| `.claude/hooks/validate-contract.sh` | Gate-transition validator for `CONTRACT.md` |
| `.claude/hooks/validate-spec.sh` | Gate-transition validator for `SPEC.md` |
| `.claude/hooks/validate-roadmap.sh` | Gate-transition validator for `ROADMAP.md` |
| `.claude/hooks/run-tests.sh` | Auto-detect + run tests; blocks on regression |
| `.claude/hooks/run-evaluator.sh` | Enforce generator-evaluator separation (A003) |

### Skills (15, progressively disclosed)

| Skill | Trigger | Purpose |
| ----- | ------- | ------- |
| `start` | `/start` | Begin/resume a session, restore gate state and memory |
| `health` | `/health` | Health report: calibration, memory, telemetry |
| `status` | `/status` | Session-start status: completed gates + lifecycle |
| `memory` | `/memory` | Memory: doctor, show, stats, prune, reflect, sync |
| `security` | `/security` | Audit active rules + security telemetry |
| `testing` | `/testing` | Run tests + check evaluator verdict |
| `costs` | `/costs` | Token/cost report from telemetry |
| `rollback` | `/rollback` | Revert gate state to an earlier gate |
| `deploy` | `/deploy` | Orchestrate the pre-deploy gate sequence |
| `build-rules` | `/build-rules` | Author a project gate DAG from your CONTRACT + SPEC |
| `critical-thinker` | `/critical-thinker` | Pressure-test a decision before it locks |
| `research` | `/research` | Memory-first research workflow |
| `evaluate` | `/evaluate` | Invoke gate-evaluator subagent for adversarial scoring |
| `review` | `/review` | Invoke spec-reviewer subagent for spec completeness |
| `drift-check` | `/drift-check` | Advisory scope drift check (never blocks) |

### Memory System

```text
.meridian/memory/
  semantic.json        # Validated patterns across projects (deduplicated by hash)
  episodic.jsonl       # Session events (append-only)
  corrections.jsonl    # Reflexion entries: predicted vs actual calibration
```

Memory is schema-validated JSONL — queryable with jq, dedupable, integrity-checked. `PostToolUse.sh` validates every write at keystroke time. The portable verifier re-checks at commit time. If memory is corrupt, the gate blocks; there's no silent failure.

### Recipes (Gate Definitions + Foundation Templates)

```text
recipes/
  fullstack-web/
    gates.yaml                        # 6-gate DAG: scope → backend → frontend → integrated → tested → deployed
    README.md                         # Reference implementation (Next.js + FastAPI + Supabase)
    foundation/CONTRACT.md.template
    foundation/SPEC.md.template

  cli-tool/
    gates.yaml                        # 5-gate DAG: scope → commands → tests → packaged → released
    README.md                         # Reference implementation (Python + Click)
    foundation/CONTRACT.md.template
    foundation/SPEC.md.template
    foundation/COMMANDS_SPEC.md.template   # CLI contract: every command/flag/exit code

  ml-research/
    gates.yaml                        # 6-gate DAG: data_contract → pipeline → model_eval → validated → deploy → documented
    README.md                         # Reference implementation (PyTorch + FastAPI)
    foundation/DATA_CONTRACT.md.template   # Methodology decisions locked before training
    foundation/CONTRACT.md.template
    foundation/SPEC.md.template
    foundation/MODEL_CARD.md.template
```

**The `DATA_CONTRACT` gate** — unique to Meridian — enforces that the human defines the target metric, evaluation thresholds, baseline, and approach constraints before a line of training code runs. No other agent framework enforces ML methodological decisions mechanically.

### Telemetry Schema

Eight event types in `.meridian/telemetry.jsonl`:

- `session_start` / `session_end`
- `gate_passed` / `gate_blocked`
- `tool_used`
- `evaluator_verdict`
- `memory_write`
- `error`

---

## What's Next

### Phase 8: Community Preparation

- [ ] G8.1 — Benchmark task definitions (`bench/tasks/`, 8-10 tasks, 5-dimension scoring rubric)
- [ ] G8.2 — Community benchmark guide (`docs/benchmark.md`)
- [ ] G8.3 — v0.1.0 GitHub release + release notes
- [ ] G8.4 — Post-release monitoring

### Phase 7: Dogfooding & Refinement ✅ Complete

- [x] G7.1 — AeroIntel (FastAPI + Next.js + ML): installed + validated, "90% done" illusion confirmed
- [x] G7.2 — Hard Power Intelligence (full ground-up): 9 gates enforced through production deploy
- [x] G7.3 — Refinement: hours optional in reflexion, episodic auto-writer, SessionStart hook, confidence ceiling docs, TDD red-phase fix
- [x] G7.4 — meridian-doctor final polish: schema parse validation, expanded core-script + hook checks
- [x] G7.5 — Pre-release checklist: shellcheck clean, all 3 recipes verified, CHANGELOG, v0.1.0 tag

---

## Design Principles

From [PHILOSOPHY.md](PHILOSOPHY.md):

1. **Mechanical enforcement** — If the model can hallucinate past it, it's not a real boundary. Gates enforce through exit codes, not through prompts.
2. **Self-improving** — Mistakes become permanent calibration data, not retries. The corrections log compounds across every project.
3. **Context-efficient** — Load only what's needed when it's needed. CLAUDE.md stays under 60 lines; skills use progressive-disclosure frontmatter.
4. **Observability-complete** — Every event is logged to JSONL that engineers can grep. If you can't see it, you can't trust it.
5. **Assumptions are temporary** — Every harness rule encodes an assumption about model weakness. When models improve, assumptions are pruned. See [ASSUMPTIONS.md](ASSUMPTIONS.md).

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
    hooks/                    # SessionStart / PreToolUse / PostToolUse enforcement
    skills/                   # 15 slash-command skill definitions
    agents/                   # 3 subagent definitions (evaluator, reviewer, drift)

  scripts/                    # Core framework scripts (22 scripts)
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

  tests/                      # 18 test suites (238 tests passing)
  experiment/                 # Generator-Evaluator validation experiment + results
  install.sh                  # One-command project installer

  PHILOSOPHY.md               # Design principles and rationale
  ASSUMPTIONS.md              # Harness assumptions governance
  CHANGELOG.md                # Release history
  ROADMAP.md                  # Gate progress and calibration tracking
  MERIDIAN_ARCHITECTURE_DECISIONS.md
```

---

## Running Tests

```bash
bash tests/test-hooks.sh               # Hook system (7 tests)
bash tests/test-telemetry.sh           # Telemetry pipeline (8 tests)
bash tests/test-security.sh            # Security blocklist (14 tests)
bash tests/test-health.sh              # /health report (12 tests)
bash tests/test-status.sh             # /status command (11 tests)
bash tests/test-gate-enforcement.sh    # Gate validators + evaluator (19 tests)
bash tests/test-memory-hooks.sh        # Reflexion / sync / trim (14 tests)
bash tests/test-skills.sh              # Core skills + manifest (19 tests)
bash tests/test-lifecycle.sh           # Lifecycle-aware completion (19 tests)
bash tests/test-drift.sh               # Drift sensor (15 tests)
bash tests/test-calibration.sh         # Judge calibration (21 tests)
bash tests/test-integration-phase1.sh  # Phase 1 end-to-end (8 tests)
bash tests/test-integration-phase2.sh  # Phase 2 end-to-end (19 tests)
```

All 18 suites — **238 tests** — pass on Windows / Git Bash.

---

## Documentation

### Guides

- [Quickstart](docs/quickstart.md) — Meridian in 10 minutes (install → first gate)
- [Gate Model](docs/gate-model.md) — the composable gate DAG and how it's enforced
- [Memory System](docs/memory.md) — the three schema-validated memory types
- [Observability](docs/observability.md) — telemetry, `/health`, `/status`, costs
- [Recipe Adaptation Guide](docs/recipes.md) — how to adapt recipes to your stack
- [Platform Tiers](docs/platform-tiers.md) — tier definitions and feature parity matrix
- [Tier 1 Verification](docs/tier1-verification.md) — Claude Code hook stdin contract and verification protocol
- [Maintaining ASSUMPTIONS.md](docs/assumptions.md) — assumption governance, in practice
- [Windows Install](docs/windows-install.md) — Git Bash and WSL2 setup
- [Troubleshooting](docs/troubleshooting.md) — field-tested fixes for common issues

### Reference

- [API Reference](docs/api-reference.md) — scripts, hooks, skills, schemas, exit codes
- [Architecture Decisions](MERIDIAN_ARCHITECTURE_DECISIONS.md) — complete design blueprint
- [ROADMAP.md](ROADMAP.md) — gate progress and calibration data
- [PHILOSOPHY.md](PHILOSOPHY.md) — design principles and rationale
- [ASSUMPTIONS.md](ASSUMPTIONS.md) — harness assumptions governance
- [CHANGELOG.md](CHANGELOG.md) — release history
- [CONTRIBUTING.md](CONTRIBUTING.md) — development model, standards, PR process
- [Hook System](.claude/hooks/README.md) — hook architecture and usage

---

## Contributing

Contributions welcome after the v0.1.0 GitHub release (Phase 8). See [CONTRIBUTING.md](CONTRIBUTING.md) for development model and standards, and [ROADMAP.md](ROADMAP.md) for planned work.

---

## License

MIT — see `LICENSE` (coming in Phase 8 release).

---

## Author

Paul Christopher Schmidt

- GitHub: [@PCSchmidt](https://github.com/PCSchmidt)
- Email: [p.christopher.schmidt@gmail.com](mailto:p.christopher.schmidt@gmail.com)

---

## Acknowledgments

Built on research and patterns from:

- Syntaris framework (brianonieal) — gate enforcement, memory taxonomy, recipe structure
- Anthropic Engineering — harness design, context management, agent patterns
- Reflexion (Shinn et al., NeurIPS 2023) — verbal reflection into episodic memory
- Martin Fowler — harness engineering, feedforward/feedback controls
