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

**Status:** In Progress (4/6 gates)  
**Estimated:** 60 hours  
**Target completion:** 2026-06-25

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

#### G2.5: Skill Progressive Disclosure
**Estimated:** 4 hours  
**Deliverables:**
- Skill frontmatter metadata (name, trigger, purpose, tokens_metadata)
- Body/references sections
- Skills load on demand

#### G2.6: Phase 2 Integration Test
**Estimated:** 6 hours  
**Deliverables:**
- All hooks working
- All skills invocable
- Security blocking tested
- Memory validation tested
- Progressive disclosure working

---

## Phase 3: Multi-Tier Platform Support (Weeks 6-7)

**Status:** Not Started  
**Estimated:** 30 hours  
**Target completion:** 2026-07-09

### Gates:

#### G3.1: Tier 1 (Claude Code) - Full Enforcement
**Estimated:** 10 hours  
**Deliverables:**
- All hooks working with Claude Code PreToolUse/PostToolUse
- Test on real Claude Code session
- Installation guide for Claude Code

#### G3.2: Tier 2 (Cursor/Windsurf) - Rule-Based
**Estimated:** 12 hours  
**Deliverables:**
- Convert hooks to auto-applied rules
- Test on Cursor and Windsurf
- Measure compliance rate (~60-70% expected)
- Document differences from Tier 1

#### G3.3: Tier 3 (Advisory) - Markdown Guidance
**Estimated:** 6 hours  
**Deliverables:**
- Generate markdown guidance from hook logic
- Test on advisory platforms (Aider, Codex CLI, etc.)
- Document expected compliance (~50-60%)

#### G3.4: Platform Detection
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

| Phase | Status | Estimated | Actual | Variance | Completion Date |
|-------|--------|-----------|--------|----------|-----------------|
| 0. Planning & Validation | ✅ Complete | 8h | 6h | 1.33x | 2026-05-28 |
| 1. Foundation | ✅ Complete | 40h | 40h | 1.0x | 2026-06-01 |
| 2. Core Hooks & Skills | ⏳ Not Started | 60h | — | — | 2026-06-25 (target) |
| 3. Multi-Tier Support | ⏳ Not Started | 30h | — | — | 2026-07-09 (target) |
| 4. Recipes | ⏳ Not Started | 40h | — | — | 2026-07-23 (target) |
| 5. Subagents | ⏳ Not Started | 35h | — | — | 2026-08-06 (target) |
| 6. Documentation | ⏳ Not Started | 25h | — | — | 2026-08-20 (target) |
| 7. Dogfooding & Refinement | ⏳ Not Started | 40h | — | — | 2026-09-03 (target) |
| 8. Community Preparation | ⏳ Not Started | 15h | — | — | 2026-09-10 (target) |
| **TOTAL** | | **293h** | **6h** | | **~11 weeks** |

### Hours Breakdown
- **Total estimated:** 293 hours (~37 working days at 8h/day, ~11 weeks at 26h/week)
- **Total actual so far:** 6 hours
- **Remaining:** 287 hours

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
| 1 | TBD | TBD |

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
