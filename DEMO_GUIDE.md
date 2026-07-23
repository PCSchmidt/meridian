# Meridian — Demo Guide

A scripted 6–8 minute walk-through for a live demo, screenshare, or technical
interview. Meridian is a framework, not a web app, so the "demo" is showing the
enforcement working: watching the harness block work the model claims is done.

---

## Demo Objective

Demonstrate:

- **Mechanical gate enforcement** — a hook that exits with code 2 and blocks the model's next action, not a prompt the model can talk past.
- **Generator-Evaluator separation** — an independent evaluator, run in a fresh context, scores work adversarially and blocks a gate on a failing verdict.
- **The core finding** — without a harness, an agent scores its own work 5.5/10; an independent evaluator scores the same work 2.5/10. That −3.0-point gap is what Meridian closes.
- **Engineer-legible observability** — every gate transition, block, and verdict is queryable JSONL, not just LLM-readable markdown.

---

## Quick View (No Setup Required)

If you only have two minutes, read these three files in the repo — they tell the
whole story without installing anything:

- [`README.md`](README.md) — the problem, the mechanism, and what shipped.
- [`experiment/GENERATOR_EVALUATOR_VALIDATION.md`](experiment/GENERATOR_EVALUATOR_VALIDATION.md) — the −3.0-point self-grading experiment that the framework was built to enforce.
- [`MERIDIAN_ARCHITECTURE_DECISIONS.md`](MERIDIAN_ARCHITECTURE_DECISIONS.md) — the full design blueprint and every decision, with rationale.

---

## Prerequisites (live demo)

```bash
# Dependencies: bash >= 4, jq, yq (mikefarah), git
git clone https://github.com/PCSchmidt/meridian.git
cd meridian

# Confirm the install is healthy
bash scripts/meridian-doctor.sh          # expect: GOOD
```

To demo enforcement inside a target project, install Meridian into one:

```bash
cd ../your-project
bash ../meridian/install.sh . --recipe fullstack-web
```

---

## Demo Script

### 1. The problem, stated as a number (0:00 – 1:00)

**Say:** "Every AI coding agent hits the same wall on a long project — around 70%
done, it starts declaring features complete when the tests haven't run. This isn't
a prompt-quality problem. A model that generates work and then grades that same
work has no incentive to be harsh. I measured it: same artifacts, same model —
self-scored 5.5 out of 10, independently scored 2.5. That three-point gap is the
bug. Meridian closes it mechanically."

Open [`experiment/GENERATOR_EVALUATOR_VALIDATION.md`](experiment/GENERATOR_EVALUATOR_VALIDATION.md) and show the delta.

### 2. Gates are a DAG you define, not a fixed ladder (1:00 – 2:30)

Open a recipe's `gates.yaml` (e.g. `recipes/fullstack-web/gates.yaml`).

**Say:** "Checkpoints are a dependency graph in YAML — `scope → backend → frontend
→ integrated → deployed` for a web app. A CLI tool looks different. An ML project
gets a `data_contract` gate that forces me to define the target metric and
evaluation thresholds *before* any training code runs. Gates are mandatory — no
skipping — but they're not hardcoded into the framework."

```bash
bash scripts/gate-engine.sh current            # what gate am I on?
bash scripts/gate-engine.sh verify <gate-id>   # do this gate's checks pass?
```

### 3. Enforcement is an exit code, not a suggestion (2:30 – 4:30)

**Say:** "When a gate check fails, the PreToolUse hook exits with code 2 and the
model's next tool call is blocked. No amount of 'but I think it's done' changes
exit code 2. You cannot convince a bash script that the tests are passing when
they're not."

Trigger a failing verify (e.g. a gate whose test hook fails) and show the block.
Then run the independent evaluator:

```bash
/evaluate <gate-id>
```

**Say:** "This spawns the evaluator subagent in a fresh context with no memory of
what was built. It's told: 'You did not produce these artifacts. Do not praise.
Find what is wrong.' A score below 7.0 or any high-severity issue is a `fail`
verdict that blocks the gate. On my Hard Power Intelligence build, this caught a
gate where citation handling was stub code the agent had marked done — it blocked,
and citations got built as real infrastructure instead of shipping as debt."

### 4. Memory that can't be silently corrupted (4:30 – 5:45)

```bash
bash scripts/write-reflexion.sh \
  --gate backend_working --predicted 8 --actual 5 \
  --root-cause "API docs thorough; integration faster than modeled" \
  --action-next "Reduce API integration estimates by 35% for well-documented APIs"

/memory show
```

**Say:** "Three memory types persist across session resets as schema-validated
JSONL — patterns, session events, and predicted-vs-actual calibration. Every write
is validated at keystroke time. If memory is corrupt, the gate blocks. Over time
my estimate multiplier converges toward 1.0x because I'm measuring it, not
guessing."

### 5. Observability an engineer can grep (5:45 – 7:00)

```bash
bash scripts/health-report.sh          # calibration, gate pass rates, token cost
bash scripts/telemetry-query.sh errors # why did this fail three sessions ago?
```

**Say:** "Every gate transition, hook block, and evaluator verdict is structured
JSONL. I can answer 'why did this fail three sessions ago?' with a one-line jq
query — not by re-deriving it. That observability was the single biggest thing
missing from the framework this one forked from."

### 6. Close: assumptions are temporary (7:00 – 7:30)

**Say:** "Every rule the harness enforces encodes an assumption about what today's
models can't be trusted to do. Each one is documented with a review trigger, and
when a model update makes the weakness go away, the rule gets pruned. Meridian
makes a capable model reliable across a multi-week build. It doesn't make a weak
spec produce strong results — that part is still my job."

---

## Talking Points for Q&A

- **"Isn't this just prompting?"** No. The enforcement is a shell hook's exit code.
  Prompts are configuration; the boundary is mechanical.
- **"What did it come from?"** It began as a fork of Syntaris (brianonieal), a
  fellow JHU student's framework. The improvements are observability-first design,
  a composable gate DAG, schema-validated JSONL memory, and the generator-evaluator
  separation.
- **"Where's the proof it works?"** Dogfooded on two production projects (AeroIntel
  and Hard Power Intelligence, live at hardpowerintel.com), 238 tests across 18
  suites, all three recipes verified end-to-end.
