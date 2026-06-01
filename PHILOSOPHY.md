# Meridian Philosophy

**Last updated:** 2026-06-01

---

## Why Meridian Exists

Long-running AI agents fail in predictable ways:

1. **Hallucinated completion** - "All tests passing!" when tests haven't been run
2. **Context loss** - Each session forgets what came before
3. **Generous self-evaluation** - Agents praise their own work regardless of quality
4. **No observability** - Engineers can't see what's happening or why
5. **No learning** - Same mistakes repeated, estimates never improve

Meridian fixes each of these **mechanically** - not through better prompts, but through infrastructure that the model cannot circumvent.

---

## Design Principles

### 1. Mechanical Enforcement Over Prompting

**The principle:** If the model can hallucinate past it, it's not a real boundary.

Gates are enforced by **shell hooks that exit with code 2**, blocking tool execution. The model cannot convince a bash script that tests are passing when they're not. This is deterministic, not probabilistic.

**Implication:** Every "must do" becomes a hook, not a prompt instruction.

**Rollout status:** Enforcement is delivered progressively by phase. Phase 1 established the hook infrastructure, exit-code contract (0/1/2), and detection logic — `PreToolUse` currently detects and warns on protected-file and destructive operations but does not yet block. Blocking enforcement (exit 2 for gate dependencies, security rules, and the Gate Evaluator) lands in Phase 2 (G2.1–G2.2) and Phase 5 (G5.1). The principle is the target architecture; the gates close mechanically as each phase ships, and this document will not claim enforcement that isn't yet wired.

---

### 2. Self-Improving Through Structured Memory

**The principle:** Mistakes become permanent fixes through calibration data, not retries.

When estimates are wrong, the delta is written to structured JSONL with the root cause. Over time, patterns emerge. "Frontend tasks with >8 components: apply 1.5x multiplier." The system learns from itself.

**Implication:** Memory is schema-validated JSON/JSONL (queryable, dedupable, integrity-checked), not markdown the model can corrupt.

---

### 3. Context-Efficient by Design

**The principle:** Load only what's needed when it's needed.

A 200k token context window still degrades when dense middle-of-context content gets ignored. Progressive disclosure: metadata always loaded (~5 tokens per skill), body loaded on invocation, reference loaded on demand.

**Implication:** CLAUDE.md stays under 60 lines. Skills use frontmatter metadata. Foundation files loaded on-demand.

---

### 4. Observability is Load-Bearing Infrastructure

**The principle:** If you can't see it, you can't trust it or debug it.

Every gate transition, every hook block, every evaluator verdict is logged to structured JSONL. `/health report` reads this and shows: gate pass rates, token costs, evaluator trends, calibration accuracy. Engineers get visibility, not just the model.

**Implication:** Telemetry is not optional. Every hook writes events. Every command reads telemetry to surface insights.

---

### 5. Assumptions Are Temporary and Documented

**The principle:** Harnesses encode assumptions about what models can't do. Those assumptions go stale as models improve.

Every assumption is documented in `ASSUMPTIONS.md` with its failure mode, source, and review trigger. When a model update eliminates the failure, the assumption is removed - not cargo-culted forward.

**Implication:** `ASSUMPTIONS.md` is a living document, reviewed quarterly, pruned when models improve.

---

## What Meridian Is Not

### Not a Benchmark or Evidence-Based Ranking

Calibration data is single-operator. Your estimates may differ. We don't claim "20% faster builds" - we claim "your estimates will improve over time through reflexion."

### Not a Prompt Collection

Meridian is infrastructure. The value is in hooks, schema validation, telemetry, and the composable gate DAG - not in clever prompts. Prompts are configuration, not the product.

### Not Finished, But Stable

v0.1.0 locks the API. Breaking changes require major version bumps. The architecture evolves based on usage, not whims.

### Not a Silver Bullet

Meridian makes capable models more reliable. It does not make weak prompts produce strong results. Garbage spec + enforced gates = gated garbage. The human's job of clear specification remains irreplaceable.

---

## The Generator-Evaluator Separation

**The core insight:** Agents that evaluate their own work praise it regardless of quality. Separation produces harsher, more accurate evaluation.

This is not a prompt trick. It's an architectural pattern validated by experiment:
- Same-session evaluation: 5.5/10, advisory feedback
- Separate-session evaluation: 2.5/10, blocking recommendation
- Difference: -3.0 points, 54% reduction

The Gate Evaluator is a separate subagent explicitly told "you did not produce this work." It cannot praise. It scores and flags. This is the mechanism that prevents hallucinated completion.

**See:** `experiment/GENERATOR_EVALUATOR_VALIDATION.md` for full experiment results.

---

## The Composable Gate DAG

**The philosophy:** Projects are not linear. A fixed 5-gate ladder breaks for anything that isn't a SaaS app.

Gates are defined in `.meridian/gates.yaml` - user-written, project-specific. The gate engine reads this file and enforces the dependency graph. ML projects have different gates than web apps. Research projects have different gates than production deploys.

**The discipline:** Gates are still mandatory (no skipping). They're just not hardcoded.

---

## Engineer-Legible vs LLM-Legible

**The distinction:**

- **LLM-legible:** Markdown files the model reads. Useful for context.
- **Engineer-legible:** JSONL files engineers can grep, jq, script. Useful for debugging.

Meridian provides both:
- Memory files are JSONL internally (engineer-queryable)
- `/memory show` renders markdown views (human-readable)
- Telemetry is JSONL (scriptable)
- `/health report` renders summaries (dashboard)

**The principle:** Data should be queryable by engineers, not just readable by models.

---

## Recipe Philosophy: Patterns, Not Prescriptions

**The design:**

Recipes are named for **patterns** (`fullstack-web`, `cli-tool`, `ml-research`), not stacks (`nextjs-fastapi-supabase`).

Each recipe provides a **reference implementation** in docs (e.g., Next.js + FastAPI + Supabase for `fullstack-web`), but the gate model is stack-agnostic. Users adapt the reference to their stack.

**Why:** Different developers have different stack preferences for valid reasons. Meridian should work for React, Vue, Svelte, or anything else. Prescriptive stack names create false expectations.

---

## The Three Memory Types

From Reflexion (Shinn et al., NeurIPS 2023) and Anthropic's engineering research:

1. **Semantic** - Validated patterns across projects ("Frontend with >8 components → 1.5x multiplier")
2. **Episodic** - Session events and gate outcomes (what happened when)
3. **Corrections** - Predicted vs actual reflexion (calibration data)

These map to cognitive science: semantic = long-term patterns, episodic = event log, corrections = error correction loop.

**The discipline:** All three are schema-validated JSONL with integrity hooks.

---

## Multi-Platform Support

**Tier 1 (Claude Code):** Full hook enforcement - `PreToolUse`/`PostToolUse` exit 2 blocks tool execution  
**Tier 2 (Cursor/Windsurf):** Rule-based partial enforcement (~60-70% compliance)  
**Tier 3 (Advisory):** Markdown guidance (honor system ~50-60%)

**The principle:** Maximize reach without diluting quality. Tier 1 gets the full experience. Other platforms get what their architecture allows.

---

## Success Criteria

Meridian succeeds when:

1. **Estimates improve over time** - Your operator multiplier converges toward 1.0x
2. **Gates catch hallucinations** - The model cannot declare completion falsely
3. **You can debug failures** - Telemetry answers "why did this fail 3 sessions ago?"
4. **Memory persists** - Context resets don't erase progress
5. **Evaluator blocks bad work** - Low-quality outputs are flagged before merge

Meridian fails when:

1. **Gates are circumvented** - The model finds ways around enforcement
2. **Observability is ignored** - Engineers don't use `/health report` or telemetry
3. **Assumptions go stale** - `ASSUMPTIONS.md` is not reviewed as models improve
4. **It becomes bureaucracy** - Gates slow work without adding value

**The test:** Would you use Meridian for your own projects, even if no one else saw the code?

---

## Influences and Prior Art

Meridian builds on research and patterns from:

- **Syntaris** (brianonieal) - Gate enforcement, memory taxonomy, recipe structure
- **Anthropic Engineering** - Harness design, context management, agent patterns
- **Reflexion** (Shinn et al., NeurIPS 2023) - Verbal reflection into episodic memory
- **Martin Fowler** - Harness engineering, feedforward/feedback controls
- **OpenAI / Lopopolo** - Harness as compilation-stage knowledge layer

We stand on the shoulders of giants. Where we differ: observability-first, composable gates, generator-evaluator separation, and `ASSUMPTIONS.md` governance.

---

## The Long View

Meridian is designed for long-term use across many projects, not just immediate needs.

- **Living documentation** - Docs evolve with the framework
- **Quarterly assumption review** - Remove obsolete assumptions as models improve
- **Cross-project learning** - Operator multiplier aggregates across all your work
- **Community validation** - Benchmarks are crowdsourced, not single-operator

**The horizon:** Years of use, hundreds of projects, models improving continuously. Meridian adapts.

---

**This philosophy drives every design decision in Meridian.**

If a feature doesn't align with these principles, it doesn't belong in the framework.
