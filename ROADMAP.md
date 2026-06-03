# Meridian Development Roadmap

**Project:** Building the Meridian framework itself  
**Start date:** 2026-05-28  
**Target:** v0.1.0 release (8-12 weeks)  
**Philosophy:** Dogfooding Meridian principles - estimate calibration, reflexion, structured progress tracking

---

## Roadmap Structure

Each phase has:
- **Estimated hours** (initial guess)
- **Actual hours** (tracked as we work)
- **Status** (Not Started, In Progress, Complete)
- **Completion date**
- **Variance** (predicted vs actual, calculated on completion)
- **Reflexion** (what we learned, what surprised us)

---

## Phase 0: Planning & Validation ✅

**Status:** COMPLETE  
**Estimated:** 8 hours  
**Actual:** 6 hours  
**Variance:** 1.33x (faster than expected)  
**Completed:** 2026-05-28

### Gates:
- [x] G0.1: Architectural decisions documented (2h est, 2h actual)
- [x] G0.2: Generator-Evaluator experiment validated (1h est, 0.5h actual)
- [x] G0.3: Repository initialized with foundation docs (1h est, 1h actual)
- [x] G0.4: PHILOSOPHY.md and ASSUMPTIONS.md written (4h est, 2.5h actual)

### Reflexion:
**What went faster:** 
- Generator-Evaluator experiment took 30 min instead of 1h (clear test case, obvious results)
- Foundation docs flowed quickly with architecture decisions already made

**What took expected time:**
- Architectural decision-making (needed thorough discussion of each choice)
- Repository setup (straightforward but methodical)

**Learnings:**
- Having the full architecture doc before starting made foundation docs much faster
- Experiment validation was critical - confirmed core assumption before investing in implementation
- No surprises in this phase

**Apply to future estimates:**
- Foundation docs with clear architecture: 0.6x multiplier (faster than estimated)
- Experiments with clear test cases: 0.5x multiplier

---

## Phase 1: Foundation (Weeks 1-2)

**Status:** COMPLETE (7/7 gates - 100%)  
**Estimated:** 40 hours  
**Actual:** 40 hours  
**Variance:** 1.0x (on target)  
**Completed:** 2026-06-01

### Gates:

#### G1.1: Composable Gate DAG Engine ✅
**Status:** COMPLETE  
**Estimated:** 8 hours  
**Actual:** 6 hours  
**Variance:** 1.33x (faster than estimated)  
**Completed:** 2026-05-28  
**Deliverables:**
- ✅ `.meridian/gate-schema.yaml` - YAML schema definition
- ✅ `scripts/gate-engine.sh` - Reads gates.yaml, validates DAG, enforces dependencies
- ✅ Sample gate definitions for 3 recipes (fullstack-web, cli-tool, ml-research)
- ✅ Circular dependency detection (DFS algorithm)
- ✅ Basic validation working (enhanced validation with yq/jq optional)

#### G1.2: Schema-Validated Memory System ✅
**Status:** COMPLETE  
**Estimated:** 10 hours  
**Actual:** 10 hours  
**Variance:** 1.0x (on target)  
**Completed:** 2026-05-28  
**Deliverables:**

- ✅ `.meridian/memory-schema.json` - JSON schema for all 3 memory types (semantic, episodic, corrections)
- ✅ `scripts/validate-memory.sh` - Schema validation script with deduplication
- ✅ `scripts/memory-doctor.sh` - Health check and validation wrapper
- ✅ `.claude/skills/memory/memory.md` - Memory management skill documentation
- ✅ Sample memory files demonstrating schema compliance
- ✅ Deduplication by hash for semantic patterns
- ✅ JSONL validation for episodic and corrections
- ✅ Tested with sample data (2 patterns, 4 events, 1 correction)

#### G1.3: Basic Hook Infrastructure ✅
**Status:** COMPLETE  
**Estimated:** 8 hours  
**Actual:** 8 hours  
**Variance:** 1.0x (on target)  
**Completed:** 2026-05-29  
**Deliverables:**

- ✅ `.claude/hooks/hook-wrapper.sh` - Common hook library (logging, error handling, timing)
- ✅ `.claude/hooks/PreToolUse.sh` - Pre-execution validation and enforcement
- ✅ `.claude/hooks/PostToolUse.sh` - Post-execution validation (memory, telemetry)
- ✅ Hook execution logging to `.meridian/hooks.log`
- ✅ Exit code 2 blocking mechanism working
- ✅ Environment variable and stdin JSON parsing
- ✅ Memory file validation integration
- ✅ Telemetry logging to `.meridian/telemetry.jsonl`
- ✅ `tests/test-hooks.sh` - Complete test suite (7/7 passing)
- ✅ `.claude/hooks/README.md` - Full hook system documentation

#### G1.4: Telemetry System (JSONL) ✅
**Status:** COMPLETE  
**Estimated:** 6 hours  
**Actual:** 6 hours  
**Variance:** 1.0x (on target)  
**Completed:** 2026-06-01  
**Deliverables:**

- ✅ `.meridian/telemetry-schema.json` - Full event schema (8 event types)
- ✅ `scripts/log-event.sh` - Append structured events to telemetry.jsonl
- ✅ `scripts/session.sh` - Session lifecycle management (start/end/id/status)
- ✅ `scripts/telemetry-query.sh` - Query and summarize telemetry data
- ✅ PostToolUse hook updated to use log-event.sh
- ✅ `tests/test-telemetry.sh` - Complete test suite (8/8 passing)

#### G1.5: `/health report` Command ✅
**Status:** COMPLETE  
**Estimated:** 6 hours  
**Actual:** 6 hours  
**Variance:** 1.0x (on target)  
**Completed:** 2026-06-01  
**Deliverables:**

- ✅ `scripts/health-report.sh` - Full health report with four sections (session, gates, memory, telemetry)
- ✅ `.claude/skills/health/health.md` - Skill documentation for `/health` command
- ✅ Gate calibration table with operator multiplier trend and color-coded assessment
- ✅ Memory health summary (pattern confidence distribution, event counts)
- ✅ Telemetry summary (event breakdown, error rate, top tools)
- ✅ `--json` machine-readable output mode
- ✅ `tests/test-health.sh` - Complete test suite (12/12 passing)

#### G1.6: `/status` Command ✅
**Status:** COMPLETE  
**Estimated:** 2 hours  
**Actual:** 2 hours  
**Variance:** 1.0x (on target)  
**Completed:** 2026-06-01  
**Deliverables:**

- ✅ `scripts/status-report.sh` - Compact session-start status (completed gates, calibration, last activity)
- ✅ `.claude/skills/status/status.md` - Skill documentation for `/status` command
- ✅ `--short` one-liner mode and `--json` machine-readable mode
- ✅ `tests/test-status.sh` - Complete test suite (11/11 passing)

#### G1.7: Phase 1 Integration Test ✅
**Status:** COMPLETE  
**Estimated:** 2 hours  
**Actual:** 2 hours  
**Variance:** 1.0x (on target)  
**Completed:** 2026-06-01  
**Deliverables:**

- ✅ `tests/test-integration-phase1.sh` - 8/8 cross-component integration tests
- ✅ Gate engine validates recipe gates.yaml and manages state (mark-passed)
- ✅ Session → telemetry pipeline: session_start events logged automatically
- ✅ log-event.sh → telemetry-query.sh pipeline verified end-to-end
- ✅ Memory validation passes on all three real memory files
- ✅ memory-doctor.sh reports no CRITICAL issues
- ✅ `/health report` aggregates all four data sources coherently
- ✅ `/health` and `/status` agree on gate count (6 gates)

---

## Phase 2: Core Hooks & Skills (Weeks 3-5)

**Status:** COMPLETE (6/6 gates, 49h/60h, 1.22x avg) — 2026-06-02  
**Estimated:** 60 hours | **Actual:** 49 hours

### Gates:

#### G2.1: Security Hooks ✅ COMPLETE (2026-06-01)
**Estimated:** 8 hours | **Actual:** 7 hours | **Calibration:** 1.14x
**Deliverables:**
- ✅ `.claude/hooks/block-dangerous.sh` - Rule engine; **first hook that mechanically blocks (exit 2)**. Parses rules via `yq` when present, awk fallback otherwise.
- ✅ `.meridian/security-rules.yaml` - Configurable blocklist (11 rules: destructive commands, secrets, SQLi) with per-rule `severity: block|warn|off`
- ✅ Wired into `PreToolUse.sh` — propagates exit 2 for all tools
- ✅ `tests/test-security.sh` - 14 tests (SQL injection, hardcoded secrets, destructive commands, clean-input pass-through, PreToolUse propagation)

**Design notes:** Deterministic risks (recursive root delete, dd/mkfs, fork bomb, AWS keys, private keys) **block**; heuristic detections (SQLi concat/f-string, generic secret literals, `git reset --hard`) **warn** to avoid false-positive friction. This is the first delivery of the Phase 1 progressive-enforcement promise — `PreToolUse` now exits 2.

#### G2.2: Gate Enforcement Hooks ✅ COMPLETE (2026-06-01)
**Estimated:** 12 hours | **Actual:** 11 hours | **Calibration:** 1.09x
**Deliverables:**
- ✅ `.claude/hooks/validate-contract.sh` - CONTRACT.md required-section validator (configurable via `CONTRACT_REQUIRED_SECTIONS`)
- ✅ `.claude/hooks/validate-spec.sh` - SPEC.md structure validator (title + sections + min content)
- ✅ `.claude/hooks/validate-roadmap.sh` - ROADMAP.md gate/status-surface validator
- ✅ `.claude/hooks/run-tests.sh` - auto-detects runner (bash suites, pytest, cargo, go, npm, make) and blocks (exit 2) on failure
- ✅ `.claude/hooks/run-evaluator.sh` - **mechanically enforces A003**: `--prepare` writes the evaluator request payload; `--check` blocks a gate unless an independent verdict file clears `verdict==pass` and `score >= EVALUATOR_THRESHOLD` (default 7.0)
- ✅ `scripts/gate-engine.sh verify <gate>` - new command runs a gate's `hooks.pre` in order and blocks (exit 2) on the first failure (yq parse + awk fallback); logs `gate_blocked` telemetry
- ✅ `tests/test-gate-enforcement.sh` - 19 tests

**Honest boundary:** the evaluator *subagent* is invoked by the harness/skill layer (Claude Code's Task/Agent tool) — a bash hook cannot spawn a subagent. `run-evaluator.sh` owns and enforces the *verdict contract* around it, which is what makes the generator-evaluator separation mechanical rather than advisory.

#### G2.3: Memory Management Hooks ✅ COMPLETE (2026-06-02)
**Estimated:** 6 hours | **Actual:** 5 hours | **Calibration:** 1.20x
**Deliverables:**
- ✅ `scripts/write-reflexion.sh` - Appends to corrections.jsonl; computes `delta_ratio`/`variance_percent` from predicted vs actual hours, pulls session/project from `session.json`, **write-ahead validates** the entry via `validate-memory.sh` before appending, logs a `memory_write` telemetry event
- ✅ `scripts/validate-memory.sh` - Schema validation on writes (pre-existing from G1.2; already wired into `PostToolUse.sh`)
- ✅ `scripts/global-memory-sync.sh` - `push`/`pull`/`status` sync to `~/.meridian/global/`; merges semantic patterns by `hash` and corrections by `(session_id,gate,date,project)` identity (idempotent), keeping JSONL compact
- ✅ `scripts/context-trim.sh` - Trims `episodic.jsonl` to the last N sessions (ordered by earliest timestamp), archiving older events to `episodic-archive.jsonl`; `--dry-run` and `-n N` modes
- ✅ `tests/test-memory-hooks.sh` - 14 tests

**Notes:** `validate-memory.sh` was already built and wired in Phase 1, so it is noted as satisfied rather than rebuilt. Two test-assertion fixes were needed for the Windows toolchain: jq emits CRLF (strip `\r` before string compares) and jq 1.7 preserves numeric literals (`6/5` serializes as `1.20`, not `1.2`). CRLF in the `.jsonl` data files is the pre-existing repo norm and was left as-is.

#### G2.4: Core Skills (12+ skills) ✅ COMPLETE (2026-06-02)
**Estimated:** 24 hours | **Actual:** 20 hours | **Calibration:** 1.20x
**Deliverables (12 skill docs in `.claude/skills/`):**
- ✅ `/start` - session bootstrap → `scripts/start-session.sh` (resume/new, status, gate, memory check)
- ✅ `/health` - health reporting (pre-existing, G1.5)
- ✅ `/memory` - memory mgmt; **refreshed** for G2.3 (added `prune`→context-trim, `reflect`→write-reflexion, `sync`→global-memory-sync; fixed stale global file paths)
- ✅ `/status` - project status (pre-existing, G1.6)
- ✅ `/deploy` - **orchestration** skill: composes run-tests → security-audit → run-evaluator → gate verify/mark-passed (deploy automation is end-user scope)
- ✅ `/security` - security audit → `scripts/security-audit.sh` (rules + telemetry events) over G2.1 enforcement
- ✅ `/testing` - test mgmt → wraps `run-tests.sh` + `run-evaluator.sh`
- ✅ `/costs` - cost report → `scripts/cost-report.sh` (aggregates the reserved stub fields; honest zero until a token source is wired)
- ✅ `/rollback` - rollback gate state → `scripts/rollback-gate.sh` (--list/--to/--dry-run, backup + git guidance)
- ✅ `/build-rules` - **process** skill: gate DAG authoring over `gate-engine.sh` + recipes
- ✅ `/critical-thinker` - **process** skill: decision pressure-test paired with ASSUMPTIONS.md
- ✅ `/research` - **process** skill: memory-first research workflow
- ✅ `tests/test-skills.sh` - 14 tests (doc presence + 4 backing scripts)

**Honest scope:** four skills wrap new backing scripts (start, security, costs, rollback); two wrap existing G2.2 hooks (testing, deploy-orchestration); three are inherently prompt/process skills with no script (build-rules, critical-thinker, research); three pre-existed (health, memory, status). `/costs` aggregation is wired but capture awaits a token source (Decision 4); `/deploy` orchestrates gates but does not ship stack-specific deploy automation.

#### G2.5: Skill Progressive Disclosure ✅ COMPLETE (2026-06-02)
**Estimated:** 4 hours | **Actual:** 3 hours | **Calibration:** 1.33x
**Deliverables:**
- ✅ YAML frontmatter on all 12 skill docs: `name, trigger, purpose, type, backing, load, tokens_metadata, references`
- ✅ Three-tier disclosure: **metadata** (frontmatter, always loaded) → **body** (doc content, `load: on-invocation`) → **references** (the `references:` field — machine-readable on-demand pointers, kept lean instead of duplicate prose sections)
- ✅ `scripts/skill-manifest.sh` - emits the always-loaded metadata layer (`list` / `--json` / `validate`); CRLF-safe frontmatter parser, computes body-token estimates, `validate` exits 2 on any incomplete frontmatter
- ✅ `tests/test-skills.sh` extended +4 (frontmatter presence, manifest validate/json, missing-frontmatter detection) → 18 tests

**Measured payoff:** always-loaded metadata ≈ 725 tokens for all 12 skills vs ≈ 6,494 tokens of full bodies — ~5,769 tokens deferred until a skill is actually invoked.

#### G2.6: Phase 2 Integration Test ✅ COMPLETE (2026-06-02)
**Estimated:** 6 hours | **Actual:** 3 hours | **Calibration:** 2.0x
**Deliverables:**
- ✅ `tests/test-integration-phase2.sh` — 19/19 passing across 6 sections
- ✅ Security blocking end-to-end: PreToolUse exits 2 on dangerous commands
- ✅ Gate enforcement pipeline: verify passes/blocks + evaluator contract
- ✅ Memory hooks pipeline: reflexion write + schema validation + sync idempotency + trim
- ✅ Skills layer: all 14 docs present, manifest validates
- ✅ Progressive disclosure: 725t metadata vs 6,494t bodies (~5,769t savings proven)
- ✅ Phase coherence: health + status agree on ≥9 gates; all 9 prior suites regression-clean
- ✅ **Total: 131 tests passing** across 10 suites (prior to Phase 3)

---

## Phase 3: Prove the Thesis — Keystone Slice (REDIRECTED 2026-06-02)

> **Why this phase was redirected:** See MERIDIAN_ARCHITECTURE_DECISIONS.md Decision 9.
> The original Phase 3 (Multi-Tier Platform Support) has been deferred to Phase 5.
> This phase pulls forward the highest-risk, highest-value components — the ones
> that actually address the core pain (goal drift, false "90% done" completion) —
> and validates the thesis on a real codebase before investing in breadth.

**Status:** COMPLETE ✅ (G3.1 ✅, G3.2 ✅, G3.3 ✅, G3.4 ✅, G3.5 ✅)
**Estimated:** 32 hours  
**Actual:** 12.5 hours (G3.1: 4h, G3.2: 3h, G3.3: 2h, G3.4: 1.5h, G3.5: 2h)
**Variance:** 2.56x (faster than estimated)

### North-star test for this phase:
> On a real, non-trivial codebase: (a) does the evaluator catch a real drift that
> would otherwise surface late, and (b) does completion tracking report a number
> that matches reality rather than the "happy-path done" illusion?

### Gates:

#### G3.1: Gate Evaluator Subagent (the missing producer) ✅
**Status:** COMPLETE
**Estimated:** 10 hours
**Actual:** 4 hours
**Variance:** 2.5x (faster than estimated)
**Completed:** 2026-06-02
**Deliverables:**
- ✅ `.claude/agents/gate-evaluator.md` — adversarial system prompt + four-dimension scoring (completeness, quality, consistency, spec_adherence); strict JSON-only output; anti-praise discipline
- ✅ `.claude/agents/spec-reviewer.md` — spec completeness reviewer for CONTRACT.md/SPEC.md/DECISIONS.md
- ✅ `.claude/skills/evaluate/evaluate.md` — `/evaluate` skill backed by gate-evaluator subagent
- ✅ `.claude/skills/review/review.md` — `/review` skill backed by spec-reviewer subagent
- ✅ `tests/test-skills.sh` updated — 14 skills + agent doc presence tests; 19/19 passing

**Why now:** This is the keystone. Today Meridian enforces the *verdict contract* (gates block without a passing file) but nothing *produces* verdicts. Until this is built, the anti-drift enforcement is structural, not semantic.

#### G3.2: Lifecycle-Aware Completion (`FEATURES.json`) ✅
**Status:** COMPLETE
**Estimated:** 8 hours
**Actual:** 3 hours
**Variance:** 2.67x (faster than estimated)
**Completed:** 2026-06-02
**Deliverables:**
- ✅ `.meridian/features-schema.json` — JSON schema: five lifecycle sub-states per feature (happy_path, integration, edge_cases, error_handling, hardening)
- ✅ `scripts/features-init.sh` — seeds FEATURES.json from SPEC.md ## and ### headings; all states start false; supports --force, --spec
- ✅ `scripts/features-report.sh` — reports "X% happy-path / Y% full-lifecycle" as two distinct numbers; --json, --short, --full modes
- ✅ `/status` upgraded — shows lifecycle section when FEATURES.json present; --json includes lifecycle object
- ✅ `tests/test-lifecycle.sh` — 18/18 passing; covers init, report math, and status integration

**Why now:** Directly defuses the "90% done" illusion. A feature with only `happy_path: true` is not done — it is 20% done. This is one of the two mechanisms the project was founded to deliver.

#### G3.3: Continuous Drift Sensor (advisory) ✅
**Status:** COMPLETE
**Estimated:** 8 hours
**Actual:** 2 hours
**Variance:** 4.0x (faster than estimated)
**Completed:** 2026-06-02
**Deliverables:**
- ✅ `.claude/agents/drift-evaluator.md` — subagent returning `alignment_score` (0-10), `divergences[]`, `recommendation` (aligned/warn/drifted)
- ✅ `scripts/drift-check.sh` — `--prepare` assembles context; `--check` reads verdict, logs `drift_score` to telemetry; exits 0 always (advisory)
- ✅ `.claude/skills/drift-check/drift-check.md` — `/drift-check` skill; advisory only, never blocks
- ✅ `tests/test-drift.sh` — 15/15 passing; prepare, aligned, drifted, warn, no-verdict, agent doc, skill doc

**Why advisory:** We calibrate before we block. A drift sensor that fires false positives would become bureaucracy. Build it as a warning light first; promote to blocking after G3.4 validates it discriminates cleanly.

**Why this is novel:** The original blueprint only checked alignment at gate boundaries. Your specific pain — *subtle drift that compounds inside a gate* — requires a signal that fires more frequently than once per checkpoint.

#### G3.4: Calibrate the Judge ✅
**Status:** COMPLETE
**Estimated:** 2 hours
**Actual:** 1.5 hours
**Variance:** 1.33x (faster than estimated)
**Completed:** 2026-06-02
**Deliverables:**
- ✅ `tests/fixtures/calibration/aligned/` — 4 contracted features, lifecycle progressing, no out-of-scope work
- ✅ `tests/fixtures/calibration/drifted/` — 2 CONTRACT exclusions (auth, sync) actively tracked; 2 contracted features stalled
- ✅ `tests/fixtures/calibration/happy-path-only/` — 4 features, all happy_path=true, all other states false
- ✅ Pre-computed verdicts: both evaluators run against all 3 fixtures; scores and verdicts recorded
- ✅ `CALIBRATION.md` — discrimination table + 4 key findings
- ✅ `tests/test-calibration.sh` — 21/21 passing; discrimination asserted
- ✅ `ASSUMPTIONS.md` A004 — drift threshold validated; tuning decisions recorded

**Key findings:** Drift sensor delta = 5 pts (aligned 8 vs drifted 3). Gate evaluator delta = 4.9 pts (8.5 vs 3.6). No false positives on aligned fixture. Gate evaluator provides stronger signal on happy-path-only (5.95) than drift sensor (7.0) — gate is the right tool for lifecycle depth; drift sensor is right for scope creep.

**Why before blocking:** Don't trust an anti-drift tool that hasn't been shown to detect drift.

#### G3.5: Minimal Installer + Real-Project Validation ✅
**Status:** COMPLETE
**Estimated:** 4 hours
**Actual:** 2 hours
**Variance:** 2.0x (faster than estimated)
**Completed:** 2026-06-02
**Deliverables:**
- ✅ `install.sh` — 7-step installer: hooks, skills, agents, schemas, runtime skeleton, recipe gates.yaml, .gitignore; runs `gate-engine validate`
- ✅ Installed into **AeroIntel** (`aerointel/`) — FastAPI + Next.js + ML pipeline, Phase 5, deployed on Fly.io + Vercel
- ✅ `CONTRACT.md` and `SPEC.md` written for AeroIntel; 13 features seeded via `features-init.sh`
- ✅ Lifecycle report: **100% happy-path / 0% full-lifecycle** — "90% done" illusion confirmed on real production project
- ✅ Drift sensor: alignment_score 7 / aligned — caught 1 real staleness (Portfolio Evidence Package at 0% despite evidence existing); corrected via FEATURES.json update
- ✅ `G3.5-FINDINGS.md` — findings report with north-star test results

**Key findings:**
- **Lifecycle tracker:** 100%/0% split on a production-deployed project is an immediately actionable signal. No engineer looking at this would say "we're done." The two numbers created the conversation.
- **Drift sensor:** Score 7 (aligned) — no false positives. Caught 1 real feature_lag staleness. Advisory is correct posture; promote `drifted` verdict to warn-blocking.
- **Rough edges:** gates.yaml path bug (root vs .meridian/) found and fixed; SPEC.md `## Feature List` heading picked up as feature (boilerplate filter gap); no CLAUDE.md generated for target project.

**North-star test:** PASS on both dimensions (drift caught real signal; completion matched reality).

**Reassessment gate:** Proceed to Phase 4 (breadth). Thesis holds on real data.

---

## Phase 4: Recipes — Deepen the Validated Path (deferred until Phase 3 validates)

**Status:** In Progress  
**Estimated:** 40 hours  
**Target completion:** TBD

> Previously Phase 4. Re-numbered 2026-06-02. Content unchanged — only moved.

### Gates:

#### G4.1: Recipe: fullstack-web
**Status:** COMPLETE  
**Estimated:** 14 hours | **Actual:** 3.5 hours | **Ratio:** 4.0x  
**Deliverables:**

- `recipes/fullstack-web/gates.yaml` - Stack-agnostic gate model ✓
- `recipes/fullstack-web/README.md` - Reference implementation (Next.js + FastAPI + Supabase) ✓
- `recipes/fullstack-web/foundation/CONTRACT.md.template` ✓
- `recipes/fullstack-web/foundation/SPEC.md.template` ✓
- Installation test end-to-end (AeroIntel, 2026-06-02) ✓

#### G4.2: Recipe: cli-tool
**Status:** COMPLETE  
**Estimated:** 10 hours | **Actual:** 2 hours | **Ratio:** 5.0x  
**Deliverables:**

- `recipes/cli-tool/gates.yaml` — 5-gate DAG (confirmed → commands_approved → tests_passing → [usability_check] → package_ready) ✓
- `recipes/cli-tool/README.md` — reference implementation (Python + Click) ✓
- `recipes/cli-tool/foundation/CONTRACT.md.template` ✓
- `recipes/cli-tool/foundation/SPEC.md.template` ✓
- `recipes/cli-tool/foundation/COMMANDS_SPEC.md.template` — CLI contract template (unique to cli-tool recipe) ✓
- Installation test (temp dir, 2026-06-03) ✓

#### G4.3: Recipe: ml-research
**Status:** COMPLETE  
**Estimated:** 14 hours | **Actual:** 2 hours | **Ratio:** 7.0x  
**Deliverables:**

- `recipes/ml-research/gates.yaml` — 6-gate DAG with DATA_CONTRACT as first gate ✓
- `recipes/ml-research/README.md` — reference implementation (PyTorch + FastAPI), DATA_CONTRACT pattern explained ✓
- `recipes/ml-research/foundation/DATA_CONTRACT.md.template` — the unique differentiator artifact ✓
- `recipes/ml-research/foundation/CONTRACT.md.template` ✓
- `recipes/ml-research/foundation/SPEC.md.template` ✓
- `recipes/ml-research/foundation/MODEL_CARD.md.template` ✓
- Installation test (temp dir, 2026-06-03) ✓
- **This is the unique differentiator** — no other agent framework enforces human methodological decisions before model training

#### G4.4: Recipe Adaptation Guide
**Status:** COMPLETE  
**Estimated:** 2 hours | **Actual:** 1 hour | **Ratio:** 2.0x  
**Deliverables:**

- `docs/recipes.md` — how to choose a recipe, substitute stacks, reshape gate DAGs ✓
- Stack substitution tables for all three recipes ✓
- Gate customization reference (all fields, required vs optional, adding/removing gates) ✓
- Custom hook template and from-scratch recipe example ✓
- Concrete examples: collapse fullstack DAG, add staging gate, add install-test gate, add drift-check gate ✓

---

## Phase 4 Reflexion

**Phase status:** COMPLETE (4/4 gates)  
**Estimated:** 40 hours | **Actual:** ~8.5 hours | **Phase ratio:** ~4.7x

**Pattern:** All four gates in Phase 4 ran 2–7x faster than estimated. Root cause is consistent: the design and validation work happened in Phase 3 (G3.5 north-star test). By the time G4.x started, all three recipes were already proven concepts — the work was documentation, not design.

**Corrected estimate for future recipe doc gates:** 1–2h each (not 10–14h). The 10–14h estimates assumed design-from-scratch work that didn't exist.

**What the ratio means:** A 4.7x ratio here is not a calibration failure — it's a signal that Phase 3 did its job. The purpose of the north-star test was to validate before investing in breadth. It validated completely. Phase 4 was the breadth investment; it was cheap because Phase 3 was thorough.

---

## Phase 5: Multi-Tier Platform Support (deferred from original Phase 3)

**Status:** Not Started  
**Estimated:** 30 hours  
**Target completion:** TBD (after Phase 3 reassessment gate)

> Previously Phase 3. Deferred 2026-06-02 per Decision 9 — depth before breadth.
> Multi-tier porting before the core thesis is validated on Claude Code inverts priority.

### Gates:

#### G5.1: Tier 1 (Claude Code) - Verify Full Enforcement
**Estimated:** 4 hours
**Deliverables:**
- Confirm all Phase 2–3 hooks work correctly in a clean Claude Code session
- Installation guide for Claude Code updated

#### G5.2: Tier 2 (Cursor/Windsurf) - Rule-Based
**Estimated:** 12 hours  
**Deliverables:**
- Convert hooks to auto-applied rules
- Test on Cursor and Windsurf
- Measure compliance rate (~60-70% expected)
- Document differences from Tier 1

#### G5.3: Tier 3 (Advisory) - Markdown Guidance
**Estimated:** 6 hours  
**Deliverables:**
- Generate markdown guidance from hook logic
- Test on advisory platforms (Aider, Codex CLI, etc.)
- Document expected compliance (~50-60%)

#### G5.4: Platform Detection
**Estimated:** 2 hours  
**Deliverables:**
- `scripts/detect-runtime.sh` - Auto-detect platform
- Installation adapts to platform tier

---

## Phase 4: Recipes (Weeks 7-8)

**Status:** Not Started  
**Estimated:** 40 hours  
**Target completion:** 2026-07-23

### Gates:

#### G4.1: Recipe: fullstack-web
**Estimated:** 14 hours  
**Deliverables:**
- `recipes/fullstack-web/gates.yaml` - Stack-agnostic gate model
- `recipes/fullstack-web/README.md` - Reference implementation (Next.js + FastAPI + Supabase)
- `recipes/fullstack-web/foundation/` - Template files
- Installation test end-to-end

#### G4.2: Recipe: cli-tool
**Estimated:** 10 hours  
**Deliverables:**
- `recipes/cli-tool/gates.yaml`
- `recipes/cli-tool/README.md` - Reference implementation (Python + Click)
- `recipes/cli-tool/foundation/`
- Installation test

#### G4.3: Recipe: ml-research
**Estimated:** 14 hours  
**Deliverables:**
- `recipes/ml-research/gates.yaml` - ML-specific gate model (DATA_CONTRACT → PIPELINE_VALIDATED → MODEL_EVAL → DEPLOY)
- `recipes/ml-research/README.md` - Reference implementation (PyTorch + FastAPI)
- `recipes/ml-research/foundation/`
- Installation test
- **This is the unique differentiator**

#### G4.4: Recipe Adaptation Guide
**Estimated:** 2 hours  
**Deliverables:**
- `docs/recipes.md` - How to adapt reference stacks
- Examples of customizing gate models

---

## Phase 5: Subagents (Weeks 9-10)

**Status:** Not Started  
**Estimated:** 35 hours  
**Target completion:** 2026-08-06

### Gates:

#### G5.1: Gate Evaluator Subagent
**Estimated:** 12 hours  
**Deliverables:**
- `.claude/agents/gate-evaluator.md` - Evaluator prompt and schema
- JSON output schema validation
- `run-evaluator.sh` hook integration
- Test blocking on BLOCK recommendation
- Test warnings on PASS_WITH_WARNINGS

#### G5.2: Spec Reviewer Subagent
**Estimated:** 8 hours  
**Deliverables:**
- `.claude/agents/spec-reviewer.md`
- Checks CONTRACT.md and SPEC.md completeness
- Returns structured gap analysis

#### G5.3: Test Writer Subagent
**Estimated:** 8 hours  
**Deliverables:**
- `.claude/agents/test-writer.md`
- Writes tests from spec (not from implementation)
- Prevents tautological tests

#### G5.4: Security Auditor Subagent
**Estimated:** 6 hours  
**Deliverables:**
- `.claude/agents/security-auditor.md`
- OWASP Top 10 checks
- AI-specific threat model

#### G5.5: Subagent Integration Test
**Estimated:** 1 hour  
**Deliverables:**
- All subagents invocable
- Proper isolation (separate contexts)
- Structured output validation

---

## Phase 6: Documentation (Weeks 10-11)

**Status:** Not Started  
**Estimated:** 25 hours  
**Target completion:** 2026-08-20

### Gates:

#### G6.1: Component Documentation
**Estimated:** 12 hours  
**Deliverables:**
- `docs/quickstart.md` - Zero to `/init` in 10 minutes
- `docs/gate-model.md` - Composable gates explained
- `docs/memory.md` - Memory system guide
- `docs/observability.md` - Telemetry and `/health report`
- `docs/assumptions.md` - How to maintain ASSUMPTIONS.md

#### G6.2: Windows Installation Guide
**Estimated:** 4 hours  
**Deliverables:**
- `docs/windows-install.md` - Git Bash and WSL2 setup
- Test on fresh Windows machine

#### G6.3: Troubleshooting Guide
**Estimated:** 4 hours  
**Deliverables:**
- `docs/troubleshooting.md` - Common issues and solutions
- Hook debugging
- Memory corruption recovery

#### G6.4: API Reference
**Estimated:** 3 hours  
**Deliverables:**
- `docs/api-reference.md` - All skills, hooks, schemas
- Skill parameters
- Hook exit codes

#### G6.5: Contributing Guide
**Estimated:** 2 hours  
**Deliverables:**
- `CONTRIBUTING.md` - How to contribute after v0.1.0
- Code standards
- PR process

---

## Phase 7: Dogfooding & Refinement (Weeks 11-12)

**Status:** Not Started  
**Estimated:** 40 hours  
**Target completion:** 2026-09-03

### Gates:

#### G7.1: Build Real Project #1 with Meridian
**Estimated:** 15 hours  
**Deliverables:**
- Use Meridian to build a real project (from your 17-project roadmap)
- Track observability data (gate pass rates, token costs, calibration)
- Document issues found
- Fix critical bugs

#### G7.2: Build Real Project #2 with Meridian
**Estimated:** 12 hours  
**Deliverables:**
- Second real project
- Different recipe than Project #1
- Compare calibration data across projects
- Validate cross-project learning

#### G7.3: Refinement Based on Dogfooding
**Estimated:** 8 hours  
**Deliverables:**
- Fix bugs discovered during Projects #1 and #2
- Improve error messages
- Adjust gate models based on real usage
- Update documentation with lessons learned

#### G7.4: meridian-doctor Final Polish
**Estimated:** 3 hours  
**Deliverables:**
- `meridian-doctor.sh` validates complete installation
- Checks all dependencies
- Tests all hooks
- Validates all schemas
- Clear error messages

#### G7.5: Pre-Release Checklist
**Estimated:** 2 hours  
**Deliverables:**
- All todos from architecture doc completed
- README opens with real benchmark number
- All 3 recipes tested end-to-end
- `meridian-doctor` passes clean
- ASSUMPTIONS.md has ≥5 entries, all sourced
- shellcheck passes on all hooks
- CHANGELOG.md documents v0.1.0

---

## Phase 8: Community Preparation (Week 13)

**Status:** Not Started  
**Estimated:** 15 hours  
**Target completion:** 2026-09-10

### Gates:

#### G8.1: Benchmark Task Definitions
**Estimated:** 6 hours  
**Deliverables:**
- `bench/tasks/` - 8-10 task definitions in YAML
- 5-dimension scoring rubric
- Baseline instructions (no framework)

#### G8.2: Community Benchmark Guide
**Estimated:** 4 hours  
**Deliverables:**
- `docs/benchmark.md` - How to run benchmarks
- How to submit results
- Results format specification

#### G8.3: v0.1.0 Release
**Estimated:** 3 hours  
**Deliverables:**
- Git tag v0.1.0
- GitHub release with release notes
- Update README with "Released" status
- Announce on relevant channels (if appropriate)

#### G8.4: Post-Release Monitoring
**Estimated:** 2 hours  
**Deliverables:**
- Monitor for early issues
- Quick-fix critical bugs
- Start collecting community feedback

---

## Summary Statistics

### Phase Overview

> **Note (2026-06-02):** Phases 3–5 have been re-sequenced per Decision 9 (use-first,
> risk-first). Phase 3 is now the keystone "Prove the Thesis" slice. Original Phase 3
> (Multi-Tier) moved to Phase 5. See MERIDIAN_ARCHITECTURE_DECISIONS.md Decision 9.

| Phase | Status | Estimated | Actual | Variance | Completion Date |
|-------|--------|-----------|--------|----------|-----------------|
| 0. Planning & Validation | ✅ Complete | 8h | 6h | 1.33x | 2026-05-28 |
| 1. Foundation | ✅ Complete | 40h | 40h | 1.0x | 2026-06-01 |
| 2. Core Hooks & Skills | ✅ Complete | 60h | 49h | 1.22x | 2026-06-02 |
| 3. Prove the Thesis *(was Phase 5/8, redirected)* | ⏳ Next | 32h | — | — | TBD |
| 4. Recipes *(was Phase 4, unchanged)* | ⏳ Deferred | 40h | — | — | TBD |
| 5. Multi-Tier Support *(was Phase 3, deferred)* | ⏳ Deferred | 30h | — | — | TBD |
| 6. Documentation | ⏳ Deferred | 25h | — | — | TBD |
| 7. Dogfooding & Refinement | ⏳ Deferred | 40h | — | — | TBD |
| 8. Community Preparation | ⏳ Deferred | 15h | — | — | TBD |
| **TOTAL** | | **290h** | **92h** | | TBD after Phase 3 reassessment |

### Hours Breakdown
- **Total estimated:** ~290 hours (Phase 3 re-estimated at 32h; other phases unchanged)
- **Total actual so far:** 95 hours (Phase 0: 6h, Phase 1: 40h, Phase 2: 49h)
- **Remaining:** ~195 hours estimated; Phases 4–8 targets deferred to Phase 3 reassessment gate

### Working Pace Assumptions
- **If full-time (40h/week):** 7.3 weeks remaining
- **If part-time (20h/week):** 14.4 weeks remaining  
- **If casual (10h/week):** 28.7 weeks remaining
- **Current target (26h/week):** 11 weeks from 2026-05-28 = 2026-08-13

---

## Calibration Tracking

As we complete phases, we'll track actual vs estimated time to calibrate future estimates.

### Completed Phases

**Phase 0: Planning & Validation**
- Estimated: 8h
- Actual: 6h
- Variance: **1.33x** (faster than estimated)
- Operator multiplier: **0.75x** (delivered in 75% of estimated time)

### Operator Multiplier Trend
(Will update as more phases complete)

| Phase | Variance | Running Avg Multiplier |
|-------|----------|------------------------|
| 0 | 1.33x (0.75x) | 0.75x |
| 1 | 1.0x | 0.93x |
| 2 (5/6) | 1.17x (0.85x) | 0.90x |

Per-gate calibration in Phase 2 (estimate/actual): G2.1 1.14x, G2.2 1.09x,
G2.3 1.20x, G2.4 1.20x, G2.5 1.33x — steady mild over-estimation on
hook/script/doc work; the multiplier is converging.

**Target:** Operator multiplier converges toward 1.0x over time (accurate estimates)

---

## Reflexion Log

### Phase 0 Reflexion (Complete)
**Predicted:** 8h  
**Actual:** 6h  
**Variance:** 1.33x faster

**What went right:**
- Architecture decisions already made → foundation docs flowed quickly
- Generator-Evaluator experiment had clear test case → fast validation
- Repository setup was straightforward

**What surprised us:**
- Foundation docs took half the estimated time (2.5h vs 4h)
- No unexpected complexity in this phase

**Apply to future estimates:**
- When architecture is pre-defined, documentation tasks: **0.6x multiplier**
- Experiments with clear test cases: **0.5x multiplier**
- Keep early-phase estimates conservative until we establish working rhythm

**Next phase prediction:**
- Phase 1 (Foundation) might also go faster than estimated if we maintain this pace
- Watch for complexity in gate DAG engine and memory validation

---

## Notes

- This roadmap uses **hours** instead of days/weeks for more granular tracking
- **Variance** is calculated as: Actual / Estimated (higher = slower than expected)
- **Operator multiplier** is the inverse: Estimated / Actual (measures estimate accuracy)
- Target is **1.0x multiplier** (perfect estimates)
- We'll update this document at each gate completion
- Reflexion entries written at phase completion to capture learnings

---

**Status:** Phase 0 complete, Phase 1 in progress  
**Last updated:** 2026-05-28  
**Next milestone:** G1.1 (Gate DAG Engine) - Estimated 8h
