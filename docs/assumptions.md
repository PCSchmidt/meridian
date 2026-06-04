# Maintaining ASSUMPTIONS.md

`ASSUMPTIONS.md` is Meridian's living governance document. Every harness rule
encodes an assumption about what the model **can't reliably do on its own**. Those
assumptions go stale as models improve — so they are documented, reviewed, and
*removed* when no longer needed. This guide explains how to keep it honest.

## Why it exists

A harness is scaffolding around model weakness. If you never revisit the
scaffolding, you cargo-cult constraints that the model has outgrown, and the
harness becomes bureaucracy. The measure of success is that the number of
assumptions *decreases* over time, not grows.

## Anatomy of an assumption

Each entry (`A001`, `A002`, …) carries:

- **Failure mode** — what goes wrong *without* the rule.
- **Source** — where you learned about the failure (research, an experiment, a
  real incident).
- **Rule** — what the harness does to prevent it.
- **Implementation status** — PLANNED / PARTIAL / IMPLEMENTED, with the gate.
- **Review trigger** — the concrete evidence that would invalidate the assumption.
- **Last reviewed** + **Status** — ACTIVE / DEPRECATED / REMOVED.

The review trigger is the important part: it states, in advance, *what would make
this assumption obsolete* — e.g. "model reliably self-limits scope across 10+
sessions without the constraint."

## Adding an assumption

When you find a failure mode that needs a harness rule:

1. Assign the next id (`A00N`).
2. Document the failure mode and cite the source.
3. State the rule the harness enforces.
4. Define the review trigger (the evidence that would retire it).
5. Set **Last reviewed** and mark **Status: ACTIVE**.
6. Update the counts at the bottom of the file.

Prefer evidence over intuition. `A003` (evaluator/generator separation) and `A004`
(drift threshold) are backed by Meridian experiments with recorded numbers; that's
the standard.

## The quarterly review

On the review schedule (Q2/Q3/Q4/Q1), for each assumption:

1. Test it against current model behavior.
2. Check for model updates that might invalidate it.
3. Update **Last reviewed**.
4. Mark any whose failure mode no longer occurs as **DEPRECATED**.
5. Remove assumptions that have been DEPRECATED for 2+ quarters.
6. Record changes in `CHANGELOG.md`.

A deprecated assumption isn't deleted immediately — it sits in a deprecated
section for two quarters as a hedge against a model regression, then is removed.

## Tie to enforcement

Assumptions aren't just prose; they map to mechanical rules:

- **A001** (one feature at a time) → `FEATURES.json` + the gate model.
- **A002** (JSON not markdown tracking) → schema validation on `PostToolUse`.
- **A003** (evaluator separation) → `run-evaluator.sh` blocks without an
  independent passing verdict.
- **A004** (drift threshold < 5 blocks) → baked into `drift-evaluator.md`.
- **A005** (enforcement-boundary relocation) → `meridian-verify.sh` + git/CI.

When you change a rule, update its assumption's implementation status. When you
remove an assumption, make sure no live rule still depends on it.

## The test

The honest question for any assumption: *would you still use this constraint on
your own project, knowing no one else sees the code?* If the answer is no because
the model no longer needs it — deprecate it. See [PHILOSOPHY.md](../PHILOSOPHY.md)
principle 5.
