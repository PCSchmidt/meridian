# Meridian Assumptions

**Purpose:** Documents every harness assumption with its failure mode and source.

**Review process:** Quarterly review to check if assumptions are still valid. Remove assumptions when model updates eliminate the underlying failure mode.

**Last reviewed:** 2026-06-01

---

## A001: One-feature-at-a-time constraint

**Failure mode:** Agents attempt to implement multiple features simultaneously, run out of context mid-implementation, and leave the codebase in a half-built state.

**Source:** Anthropic Engineering, "Effective Harnesses for Long-Running Agents", 2025.

**Rule:** The Coding Agent is prompted to work on exactly one feature per session. `FEATURES.json` tracks feature state, and the agent is instructed to mark only one feature as `in_progress` at a time.

**Implementation status:** PLANNED (Phase 2/4). `FEATURES.json` is a framework-delivered artifact for *end-user projects* built with Meridian — it ships as part of the recipes and install flow (G4.x), with schema validation via the gate-enforcement hooks (G2.2). It is not yet implemented. Meridian's *own* development follows the one-feature/one-gate discipline through the gate model in [ROADMAP.md](ROADMAP.md) and the reflexion log in `.meridian/memory/corrections.jsonl`, not a `FEATURES.json` file.

**Review trigger:** Model reliably self-limits scope without the constraint. Evidence: successful multi-feature implementations across 10+ sessions without context overflow.

**Last reviewed:** 2026-06-01 (Q2 review — no change, still necessary)

**Status:** ACTIVE — Still necessary as of Claude Sonnet 4.6

---

## A002: JSON feature tracking (not markdown)

**Failure mode:** Agents inappropriately modify or overwrite markdown task lists, marking features as complete without actually verifying them. Markdown is also not queryable or schema-validated, allowing silent corruption.

**Source:** Anthropic Engineering, "Effective Harnesses for Long-Running Agents", 2025.

**Rule:** `FEATURES.json` uses JSON format instead of markdown. Agents are explicitly told not to remove or edit feature entries, only to update the `passing` field. A JSON schema validates all writes via PostToolUse hook.

**Implementation status:** PLANNED (Phase 2/4) — see A001. The JSON-not-markdown principle is already proven in Phase 1 by the schema-validated memory system (`.meridian/memory/*.json[l]` validated via `validate-memory.sh` on PostToolUse). `FEATURES.json` applies that same discipline to feature tracking for end-user projects; it ships with the recipes and install flow, not yet built.

**Review trigger:** Model reliably respects markdown task lists without modification across 10+ sessions. Evidence: no false completion markers, no deleted entries, no format corruption.

**Last reviewed:** 2026-06-01 (Q2 review — no change, still necessary)

**Status:** ACTIVE — Still necessary as of Claude Sonnet 4.6

---

## A003: Evaluator/generator separation

**Failure mode:** When asked to evaluate work they've produced, agents respond by confidently praising the work regardless of actual quality. Self-evaluation scores are consistently 3+ points higher than independent evaluation.

**Source:** 
- Anthropic Engineering, "Harness Design for Long-Running Apps", 2026
- Meridian experiment (2026-05-28): Same-session 5.5/10 vs separate-session 2.5/10 (-3.0 point difference)

**Rule:** The Gate Evaluator is a separate subagent with an explicit system prompt: "You did not produce the artifacts you are reviewing. Do not praise. Do not explain. Score and flag." The evaluator cannot access the generation conversation and returns only structured JSON.

**Review trigger:** Model reliably self-evaluates critically without separation. Evidence: same-session evaluation scores match or exceed adversarial evaluation harshness across 10+ evaluations.

**Last reviewed:** 2026-06-01 (Q2 review — no change, still necessary)

**Status:** ACTIVE — Validated by experiment, proceed with implementation

**Experiment reference:** `experiment/GENERATOR_EVALUATOR_VALIDATION.md`

---

## How to Add New Assumptions

When you discover a failure mode that requires a harness rule, add it here:

1. **Assign next ID** (A004, A005, etc.)
2. **Document the failure mode** - What goes wrong without the rule?
3. **Cite the source** - Where did you learn about this failure?
4. **State the rule** - What does the harness do to prevent it?
5. **Define review trigger** - What evidence would invalidate this assumption?
6. **Set Last reviewed date**
7. **Mark Status** - ACTIVE, DEPRECATED, or REMOVED

---

## Review Process

**Quarterly schedule:**
- **Q2 2026** (Jun 1) - First review ✅ Completed 2026-06-01 — all 3 assumptions still ACTIVE (Claude Sonnet 4.6)
- **Q3 2026** (Sep 1)
- **Q4 2026** (Dec 1)
- **Q1 2027** (Mar 1)

**Review checklist:**
1. Test each assumption against current model behavior
2. Check for model updates that might invalidate assumptions
3. Update "Last reviewed" date
4. Mark deprecated assumptions (failure no longer occurs)
5. Remove assumptions that have been deprecated for 2+ quarters
6. Document changes in `CHANGELOG.md`

---

## Deprecated Assumptions (Examples for Future Reference)

*No deprecated assumptions yet - this section shows the format for when assumptions are removed.*

### Example Format:

## A999: [Deprecated] Example assumption

**Original failure mode:** [what used to fail]

**Deprecated:** 2026-XX-XX - Model update eliminated failure mode

**Evidence:** [what demonstrated the assumption is no longer needed]

**Removed:** 2026-XX-XX - After 2 quarters in deprecated status

---

## Philosophy

This document is **living governance**. Assumptions are not permanent truths - they're temporary scaffolding that becomes obsolete as models improve.

The goal is not to accumulate assumptions. The goal is to **actively remove** assumptions that are no longer needed, making the harness lighter and more aligned with model capabilities.

**Measure of success:** The number of assumptions should *decrease* over time, not increase.

---

**Current active assumptions:** 3  
**Current deprecated assumptions:** 0  
**Total removed assumptions:** 0
