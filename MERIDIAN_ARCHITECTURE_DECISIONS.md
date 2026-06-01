# Meridian - Architectural Decisions & Blueprint
**Date:** 2026-05-26  
**Status:** Phase 1 Complete (7/7 gates, 40h/40h, 0.97x avg calibration — 2026-06-01)  
**Repository:** https://github.com/PCSchmidt/meridian

---

## Executive Summary

Meridian is a next-generation agent harness framework that improves upon Syntaris by adding:
- **Engineer-legible observability** (the key differentiator)
- **Composable gate DAG** (YAML-configured, not hardcoded)
- **Schema-validated memory** (JSON/JSONL with integrity checks)
- **Generator-Evaluator separation** (prevents self-grading)
- **Multi-platform support** (Claude Code, Cursor/Windsurf, advisory tier)

**Target users:** Developers building software with AI coding agents who want structure, verification, and observability.

**Timeline:** 8-12 weeks to v0.1.0 (no rush, build it right)

---

## Core Architectural Decisions

### Decision 1: Multi-Platform Support (All 3 Tiers)

**Decision:** Support Claude Code (Tier 1), Cursor/Windsurf (Tier 2), and Advisory platforms (Tier 3) from v0.1.0

**Rationale:**
- Maximum community reach
- Claude Code gets full hook enforcement
- Other platforms get partial/advisory support
- Follows original Syntaris pattern

**Implementation:**
- **Tier 1:** PreToolUse/PostToolUse hooks (mechanical enforcement)
- **Tier 2:** Auto-applied rules (partial enforcement ~60-70%)
- **Tier 3:** Advisory text (honor system ~50-60%)

**Reference:** Original Syntaris multi-tier model

---

### Decision 2: Recipe Strategy (3 Pattern-Based Recipes)

**Decision:** Ship with 3 flexible, pattern-based recipes (not tech-stack-specific)

**Recipes:**
1. **`fullstack-web`** - Any frontend + backend + database
   - Reference implementation: Next.js + FastAPI + Supabase
   
2. **`cli-tool`** - Any CLI framework/language
   - Reference implementation: Python + Click
   
3. **`ml-research`** - Any ML/data science stack
   - Reference implementation: PyTorch + FastAPI
   - **This is the unique differentiator** - no other framework has it

**Rationale:**
- Pattern-based names (not prescriptive like `nextjs-fastapi-supabase`)
- Users can adapt to their stack choice
- Reference implementations provide concrete examples
- Composable gate DAG makes recipes truly flexible

**Documentation requirement:** Clear docs showing how to adapt reference stack to user's choice

---

### Decision 3: Development Approach (Build Fully Upfront)

**Decision:** Build Meridian completely before using it on projects (8-12 weeks)

**Rationale:**
- Not in a hurry (Syntaris already works)
- Want to see if can improve upon Syntaris meaningfully
- Can design the complete architecture without incremental delivery pressure
- Validate with Generator-Evaluator experiment before committing

**Timeline:**
- Weeks 1-2: Core foundation (gate engine, memory system)
- Weeks 3-6: Observability layer, hooks, skills
- Weeks 7-8: Multi-tier support, recipes
- Weeks 9-10: Documentation, testing
- Weeks 11-12: Dogfooding with 2-3 real projects, refinement

---

### Decision 4: Observability Layer (Full Implementation - The Differentiator)

**Decision:** All "Must Have" observability features in v0.1.0

**Must Have Features:**
1. **JSONL telemetry** - Structured, grep-able, scriptable logs
   - File: `.meridian/telemetry.jsonl`
   - Events: gate blocks, evaluator verdicts, token usage, costs, session data

2. **`/health report` command** - Engineer-legible dashboard
   - Gate pass/fail rates
   - Token consumption trends
   - Cost tracking (per session, per project)
   - Evaluator score trends
   - Calibration accuracy (predicted vs actual)

3. **`/status` command** - Project completion view
   - Features done vs remaining
   - Completion percentage
   - Estimated time to completion

4. **Hook feedback visibility** - When hooks block, USER sees why
   - Not just Claude - human-readable error messages
   - Logged to telemetry for later analysis

**Deferred to Phase 2 (was "Must Have", reclassified 2026-06-01):**

5. **Real-time cost tracking**
   - Token usage per session
   - Cost per gate
   - Budget warnings
   - **Why deferred:** Cost capture requires a token-usage data source from the
     Claude Code session that the Phase 1 hook layer does not yet expose. The
     telemetry schema carries optional `input_tokens` / `output_tokens` /
     `cost_usd` fields as of Phase 1 (forward-compatible stub), but no capture
     or `/health` cost section ships until Phase 2. Reclassified from "Must
     Have v0.1.0" to Phase 2 to keep the documents honest about what is wired.

**Rationale:**
- **Your main pain point with Syntaris:** "There is no feedback that I'm aware of"
- This is Meridian's competitive moat over Syntaris
- Observability is what makes agents debuggable and trustworthy
- From research: "Observability isn't nice-to-have, it's load-bearing infrastructure"

**Status (2026-06-01):** Items 1–4 shipped in Phase 1 (JSONL telemetry,
`/health report`, `/status`, hook feedback visibility). Item 5 (cost tracking)
deferred to Phase 2 as noted above.

**Nice to Have (defer to v0.2.0):**
- Dashboard UI (web view)
- Budget enforcement (hard limits)
- Notifications (Slack/email)
- Multi-project analytics

---

### Decision 5: Memory System (Hybrid - JSONL + Human Views)

**Decision:** JSONL internally with `/memory show` for human-readable views

**Structure:**
```
.meridian/memory/
  semantic.json       # Validated patterns, deduped by hash
  episodic.jsonl      # Append-only session log
  corrections.jsonl   # Reflexion entries (schema-validated)
  
~/.meridian/global/
  semantic_global.json  # Cross-project patterns
  stats.json            # Operator multiplier, calibration data
```

**Key Features:**
- **Schema validation** via `memory-schema.json`
- **Deduplication** - semantic patterns hashed, duplicates removed
- **Integrity checks** - PostToolUse hook validates all writes
- **`/memory doctor`** - Validates, deduplicates, reports health
- **`/memory show`** - Human-readable view of JSONL data

**Rationale:**
- Syntaris's markdown memory has no schema, no deduplication, no integrity checks
- JSONL is queryable and scriptable (can grep, jq, analyze)
- Hybrid approach gives engineer-queryable data AND human readability
- Cross-project learning via `~/.meridian/global/`

---

### Decision 6: Gate DAG Flexibility (Disciplined Flexibility)

**Decision:** Composable gates with discipline, not chaos

**Rules:**
- **No gate skipping** - Gates enforce discipline (that's the point)
- **Optional vs required gates** - YAML allows `required: true/false`
- **Install-time validation** - `meridian-doctor` checks for circular dependencies
- **Standard gate types only** for v0.1.0 (`human_approval`, `automated`)

**Example YAML:**
```yaml
gates:
  - id: tests_passing
    type: automated
    required: true        # Cannot be skipped
    hooks: [run-tests.sh]
  
  - id: security_scan
    type: automated
    required: false       # Optional, warns if skipped
    hooks: [security-check.sh]
```

**Rationale:**
- Start opinionated, relax later based on usage
- Gates without enforcement are just suggestions
- Easier to add flexibility than remove it
- Custom gate types deferred to v0.2.0 (ship faster)

---

### Decision 7: Generator-Evaluator Pattern (Validate First)

**Decision:** Run 30-minute experiment to validate the pattern before building it

**Experiment:**
1. Use Claude Code to generate code with intentional issues
2. Same session: "Evaluate this code" → record score
3. New session with evaluator prompt: "You didn't produce this. Evaluate harshly" → record score
4. Compare: Does separation produce lower, more accurate scores?

**If experiment validates pattern:**
- Build Gate Evaluator subagent as specified
- Structured JSON output (no prose)
- System prompt: "You did not produce this work. Do not praise. Score and flag."

**If experiment fails:**
- Rethink the approach before investing implementation effort

**Rationale:**
- This is the claimed A+ differentiator
- Too important to assume - must validate
- 30 minutes to test vs weeks to build
- Anthropic research suggests it works, but verify

**Status:** Pending - run experiment before proceeding with implementation

---

### Decision 8: Shell Compatibility (Bash-Only with Excellent Windows Docs)

**Decision:** Bash hooks only, document Git Bash and WSL2 for Windows users

**Rationale:**
- You already use Git Bash (MINGW64)
- Dual implementation (bash + PowerShell) = 2x maintenance burden
- Original Syntaris retired PowerShell for this reason
- Git Bash comes with Git for Windows (already installed for most devs)
- WSL2 is excellent for users who want native Linux experience
- Community standard is bash

**Windows Documentation:**
```markdown
# Windows Installation

Meridian uses bash hooks. You have two options:

## Option 1: Git Bash (Easiest)
If you have Git for Windows, you already have Git Bash.
Run: `bash install.sh`

## Option 2: WSL2 (Best Performance)  
Enable WSL2: `wsl --install`
Run: `bash install.sh`
```

**Maintenance:** 18 hooks (not 36), one environment to test

---

### Decision 9: Benchmark Strategy (Dogfooding + Community)

**Decision:** Validate through real usage, not synthetic benchmarks

**Phase 1 (Before v0.1.0 release):**
- Build 2-3 of your 17 projects using Meridian
- Track observability data (gate pass rates, estimate calibration)
- Use real results: "Built 3 projects, estimates improved from 0.68x → 0.85x"

**Phase 2 (After v0.1.0 release):**
- Provide benchmark task definitions in repo
- Invite community to run tasks and submit results
- Aggregate and publish community data

**Rationale:**
- Free (using projects you're building anyway)
- Authentic (real usage, not synthetic tasks)
- Community validation (multi-operator, not single-operator)
- Ship faster (no expensive pre-launch benchmark)

**Cost:** $0 (vs $50-100+ for synthetic benchmark suite)

---

### Decision 10: Documentation Strategy (Living Documentation)

**Decision:** Structured hybrid approach - write docs as components are built, maintain forever

**Phase 1 (Week 1 - Before coding):**
- Write `PHILOSOPHY.md` - The "why" (never changes)
- Write `ASSUMPTIONS.md` - Start with 3 entries from transcript
- Write `README.md` skeleton

**Phase 2 (Weeks 2-10 - While building):**
- Update `README.md` after each major component
- Write component docs immediately after implementation
- **Rule:** Don't merge a component without its doc
- Keep docs in sync with code

**Phase 3 (After v0.1.0 - Ongoing):**
- Update docs based on user questions
- Review `ASSUMPTIONS.md` quarterly
- Keep `CHANGELOG.md` updated

**Key Documents:**
- `README.md` - Overview, installation, quick start
- `PHILOSOPHY.md` - Design principles (write upfront)
- `ASSUMPTIONS.md` - Every harness assumption documented (living document)
- `docs/quickstart.md` - Zero to `/init` in 10 minutes
- `docs/gate-model.md` - Composable gates explained
- `docs/memory.md` - Memory system
- `docs/observability.md` - `/health report`, telemetry
- `docs/recipes.md` - How to write/adapt recipes
- `docs/windows-install.md` - Git Bash/WSL guide

**Rationale:**
- Building many projects over time (not just immediate 17)
- Need docs that serve future-you and community
- Living documentation evolves with framework
- Always accurate (written with fresh context)

---

### Decision 11: ASSUMPTIONS.md Governance (Pre-populate + Living Document)

**Decision:** Start with 3 proven assumptions, grow as needed, review quarterly

**Initial Entries (from Anthropic research):**

```markdown
## A001: One-feature-at-a-time constraint
**Failure mode:** Agents attempt multiple features simultaneously, run out of context, leave codebase half-built.
**Source:** Anthropic Engineering, "Effective Harnesses for Long-Running Agents", 2025.
**Rule:** Coding Agent prompted to work on exactly one feature per session.
**Review trigger:** Model reliably self-limits scope without constraint.
**Last reviewed:** 2026-05-26

## A002: JSON feature tracking (not markdown)
**Failure mode:** Agents inappropriately modify markdown task lists, marking complete without verification.
**Source:** Anthropic Engineering, same post.
**Rule:** FEATURES.json uses JSON; agents told not to remove entries, only update `passing` field.
**Review trigger:** Model reliably respects markdown task lists.
**Last reviewed:** 2026-05-26

## A003: Evaluator/generator separation
**Failure mode:** Agents self-evaluating confidently praise work regardless of quality.
**Source:** Anthropic Engineering, "Harness Design for Long-Running Apps", 2026.
**Rule:** Gate Evaluator is separate subagent, prohibited from explaining or praising.
**Review trigger:** Model reliably self-evaluates critically.
**Last reviewed:** 2026-05-26
```

**Ongoing Process:**
- Add assumptions as discovered during development
- Quarterly review: check if still valid
- Remove assumptions when model updates make them obsolete
- Document changes in `CHANGELOG.md`

**Rationale:**
- Documents WHY each design decision was made
- Future-you understands the reasoning
- Can safely remove assumptions as models improve
- Creates audit trail of framework evolution
- Unique to Meridian (no other framework has this)

---

## Implementation Priorities for v0.1.0

### Phase 1: Foundation (Weeks 1-2)
1. Repository structure
2. Composable gate DAG engine (reads `.meridian/gates.yaml`)
3. Schema-validated memory system (JSONL + validation hooks)
4. Basic hook infrastructure (PreToolUse/PostToolUse)

### Phase 2: Observability (Weeks 3-4)
1. Telemetry system (`.meridian/telemetry.jsonl`)
2. `/health report` command
3. `/status` command
4. Cost tracking integration

### Phase 3: Core Hooks & Skills (Weeks 5-7)
1. 18 bash hooks (gate enforcement, security, tests, memory validation)
2. 12+ skills (start, health, memory, deploy, security, testing, etc.)
3. `/memory show` and `/memory doctor` commands

### Phase 4: Multi-Tier Support (Week 7-8)
1. Tier 1 (Claude Code) - full hook enforcement
2. Tier 2 (Cursor/Windsurf) - rule-based partial enforcement
3. Tier 3 (Advisory) - markdown-based guidance

### Phase 5: Recipes (Week 8-9)
1. `fullstack-web` recipe with Next.js + FastAPI + Supabase reference
2. `cli-tool` recipe with Python + Click reference
3. `ml-research` recipe with PyTorch + FastAPI reference

### Phase 6: Subagents (Week 9-10)
1. **Generator-Evaluator experiment** (validate pattern first!)
2. Gate Evaluator subagent (if experiment validates)
3. Spec Reviewer subagent
4. Test Writer subagent
5. Security Auditor subagent

### Phase 7: Documentation (Week 10-11)
1. All docs written per component
2. Windows installation guide
3. Recipe adaptation guide
4. Troubleshooting guide

### Phase 8: Dogfooding & Refinement (Week 11-12)
1. Build 2-3 real projects using Meridian
2. Track observability data
3. Identify and fix issues
4. Refine based on real usage

---

## Success Criteria for v0.1.0

**Must Have:**
- [ ] All 3 tiers working (Claude Code, Cursor/Windsurf, Advisory)
- [ ] All 3 recipes functional end-to-end
- [ ] Observability layer complete (`/health report`, `/status`, telemetry)
- [ ] Memory system with schema validation
- [ ] Composable gate DAG (users can customize)
- [ ] Generator-Evaluator validated and working
- [ ] All documentation written
- [ ] Successfully built 2-3 real projects with Meridian
- [ ] `meridian-doctor` validates installation
- [ ] Bash hooks working on Windows (Git Bash tested)

**Nice to Have (can defer):**
- Dashboard UI
- Budget hard limits
- Custom gate types
- Notifications

---

## Key Differentiators Over Syntaris

1. **Engineer-legible observability** - You can see what's happening
2. **Composable gate DAG** - Not hardcoded, fully customizable
3. **Schema-validated memory** - Integrity guaranteed, queryable
4. **Generator-Evaluator separation** - No self-grading
5. **ASSUMPTIONS.md governance** - Documents why, evolves with models
6. **Cost transparency** - Real-time token/cost tracking
7. **Multi-project learning** - Operator multiplier across projects

---

## Next Steps

### Immediate (Before Starting Implementation):

1. **Run Generator-Evaluator experiment** (30 minutes)
   - Validate the core assumption
   - Document results
   - Decide: build it or rethink

2. **Set up repository structure**
   - Initialize git repo
   - Create directory structure
   - Write initial `README.md` and `PHILOSOPHY.md`

3. **Write initial `ASSUMPTIONS.md`**
   - Add the 3 entries from Anthropic research
   - Document the governance process

### Week 1:
- Implement composable gate DAG engine
- Write gate YAML schema
- Create basic hook wrapper infrastructure

### Week 2:
- Implement memory system with schema validation
- Create telemetry logging infrastructure
- Write `/memory doctor` command

Continue following implementation priorities above...

---

## Reference Materials

- **Transcript:** `scratch-notes.txt` - Contains full architectural research and recommendations
- **Original Syntaris:** https://github.com/brianonieal/Syntaris
- **Your Syntaris fork:** C:\Users\pchri\Syntaris
- **Target repo:** https://github.com/PCSchmidt/meridian
- **Anthropic research:** Referenced in ASSUMPTIONS.md entries

---

## Notes

- This is a **long-term framework** - building many projects over years, not just immediate 17
- **No rush** - Syntaris works, this is about meaningful improvement
- **Community-focused** - Pattern-based recipes, clear docs, Windows support
- **Evidence-based** - Every design decision documented with rationale
- **Living architecture** - Will evolve as models improve and usage reveals needs

---

**Status:** Phase 1 implementation in progress (3/7 gates complete - 43%)

**Last updated:** 2026-05-29
