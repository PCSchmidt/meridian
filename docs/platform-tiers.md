# Platform Tiers & Feature Parity

Meridian's enforcement model assumes a boundary the model cannot hallucinate past
(PHILOSOPHY.md, Principle 1). Only Claude Code exposes pre-execution hooks that can
block a tool call by exiting 2. Every other platform can only *inject context* — rules
or markdown the model is asked to follow but can ignore.

Rather than ship a watered-down "honor system" copy of enforcement to those platforms,
Meridian **relocates the enforcement boundary to git/CI**, which every platform shares.
A `pre-commit` hook or a CI check that exits non-zero blocks a merge just as hard as a
`PreToolUse` hook exiting 2 — and it does so independently of which agent wrote the code.

This document is the single source of truth for what each tier actually delivers. It is
referenced by PHILOSOPHY.md (Multi-Platform Support), ASSUMPTIONS.md (A005), and the
Phase 5 plan in ROADMAP.md.

---

## The Two Boundaries

| Boundary | What runs there | Who can enforce |
|----------|-----------------|-----------------|
| **Keystroke** (in-editor, per tool call) | `PreToolUse`/`PostToolUse` hooks, exit 2 | Claude Code only |
| **Commit / CI** (per git commit / push / PR) | `meridian-verify.sh` via `pre-commit` + CI workflow | Every platform (all commit to git) |

The engines are identical at both boundaries — `gate-engine.sh verify`, `drift-check.sh`,
`validate-memory.sh`, and the evaluator contract (`run-evaluator.sh`). The keystroke
boundary is a Claude Code privilege; the commit boundary is universal.

---

## Tier Definitions

| Tier | Name | Platforms | Keystroke boundary | Commit/CI boundary |
|------|------|-----------|--------------------|--------------------|
| 1 | **Enforced** | Claude Code | Hooks block (exit 2) | Verifier blocks |
| 2 | **Guided + CI** | Cursor, Windsurf, Cline | Editor rules (context, advisory) | Verifier blocks |
| 3 | **Reference + CI** | Aider, Codex CLI, generic | Markdown guidance (context, advisory) | Verifier blocks |

A platform is Tier 2 if it auto-loads a project rules file into context but has no
exit-2-style hook to block a tool call. **Cline** qualifies (it loads `.clinerules`
but cannot mechanically block) — same profile as Cursor/Windsurf.

"Guided" and "Reference" describe the *context* layer honestly: it shapes behavior but
does not block. The teeth on Tiers 2 and 3 come from the shared commit/CI boundary.

---

## Per-Capability Parity Matrix

Legend: **Enforced** = mechanically blocks · **CI-Enforced** = blocks at commit/CI ·
**Advisory** = injected as context, model may ignore · **n/a** = not applicable.

| Capability | Tier 1 (Claude Code) | Tier 2 (Cursor/Windsurf) | Tier 3 (Aider/Codex) |
|------------|----------------------|--------------------------|----------------------|
| Dangerous-op blocking (`block-dangerous.sh`) | Enforced (keystroke) | CI-Enforced + Advisory | CI-Enforced + Advisory |
| Gate verification (`gate-engine.sh verify`) | Enforced + CI-Enforced | CI-Enforced | CI-Enforced |
| Memory schema validation (`validate-memory.sh`) | Enforced (PostToolUse) + CI | CI-Enforced | CI-Enforced |
| Evaluator verdict contract (`run-evaluator.sh`) | Enforced + CI-Enforced | CI-Enforced | CI-Enforced |
| Drift sensor (`drift-check.sh`) | CI-Enforced (advisory by design) | CI-Enforced | CI-Enforced |
| Telemetry (`log-event.sh`) | Automatic (hooks) | On verifier run | On verifier run |
| Calibration / reflexion memory | Full | Full | Full |
| Rule freshness (editor rules match hooks) | n/a (hooks are source) | Generated from source | Generated from source |

Notes:
- Telemetry on Tiers 2/3 is captured whenever the verifier runs (commit/CI), not on
  every keystroke — so the event stream is coarser but not absent.
- The drift sensor is advisory-by-design even on Tier 1 (A004); promotion to blocking is
  an operator decision after real-project validation.

---

## How Each Tier Is Installed

`install.sh` detects the platform (`detect-runtime.sh`) and installs the right *surface
set*, but **always** installs the git/CI verifier:

| Tier | Installed surfaces |
|------|--------------------|
| 1 | `.claude/hooks/` + `pre-commit` + CI workflow |
| 2 | generated editor rules + `pre-commit` + CI workflow |
| 3 | `MERIDIAN.md` (generated) + `pre-commit` + CI workflow |

The Tier-2 editor rules are generated per platform by `scripts/gen-rules.sh`:

| Platform | Generated file |
|----------|----------------|
| Cursor | `.cursor/rules/meridian.mdc` (MDC, `alwaysApply: true`) |
| Windsurf | `.windsurf/rules/meridian.md` |
| Cline | `.clinerules/meridian.md` |
| Advisory (Tier 3) | `MERIDIAN.md` |

All four come from **one generator** reading the same `.meridian/gates.yaml` and
`.meridian/security-rules.yaml` the hooks read, so the context layer cannot silently
drift from the enforced layer. Output is deterministic (no timestamps): regenerating
produces a byte-identical file, which the test suite asserts. Regenerate after editing
either source: `bash scripts/gen-rules.sh --platform all`.

---

## On Compliance Percentages

Earlier drafts of the roadmap quoted "~60-70%" (Tier 2) and "~50-60%" (Tier 3) compliance.
Those numbers were never measured — there is no harness that defines a compliant behavior,
runs it across platforms, and counts adherence. Per Principle 5 (assumptions are documented,
not cargo-culted), Meridian does **not** publish compliance percentages without a measurement
methodology. The honest claim is structural: Tier 1 enforces at keystroke; all tiers enforce
at commit/CI; the rest is advisory context.

---

## Status

Tier definitions and this matrix are the design target for **Phase 5** (Portable Enforcement
& Multi-Tier Platform Support). Implementation gates:

- **G5.2** ✅ — `meridian-verify.sh` + `templates/pre-commit` + `templates/meridian-ci.yml`, installed by `install.sh` for every tier. **The shared commit/CI boundary now exists and is proven end-to-end** (a failing verification rejects a real git commit). This is what gives Tiers 2 and 3 their teeth.
- **G5.3** ✅ — `scripts/gen-rules.sh` generates the Tier-2 editor surfaces (Cursor, Windsurf, Cline) from the same source as the hooks; idempotent, round-trip tested.
- **G5.4** ✅ — the same generator emits the Tier-3 `MERIDIAN.md` (`--platform advisory`); no separate `gen-guidance.sh` was needed.
- **G5.5** ✅ — `scripts/detect-runtime.sh` + `install.sh` wiring: auto-detect (or `--platform`), always emit advisory `MERIDIAN.md`, plus the detected editor's surface; the git/CI verifier installs for every platform regardless.

**Phase 5 is complete.** The commit/CI boundary (the "CI-Enforced" column above) is live, the
Tier-2/3 context surfaces are generated from source, and `install.sh` selects the right surface
set per detected platform (override with `--platform`). Detection is best-effort: reliable for
Claude Code (env), heuristic for editors (project markers), `generic` otherwise. See ROADMAP.md
Phase 5 for the full record.
