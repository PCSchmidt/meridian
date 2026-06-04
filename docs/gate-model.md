# The Gate Model

Meridian projects advance through **gates** — checkpoints that must be cleared in
dependency order. Gates are not a fixed ladder; they're a directed acyclic graph
(DAG) you define in `.meridian/gates.yaml`. The discipline is mandatory (no
skipping); the shape is yours.

## Why a DAG, not a checklist

A linear 5-step ladder breaks for anything that isn't a SaaS app. An ML project
gates on `DATA_CONTRACT → PIPELINE_VALIDATED → MODEL_EVAL → DEPLOY`; a CLI tool
gates on `confirmed → commands_approved → tests_passing → package_ready`. Gates
encode *your* workflow's real dependencies, and the engine enforces them.

## `gates.yaml` structure

```yaml
version: "1.0"

project:
  name: "my-project"
  recipe: "fullstack-web"

gates:
  - id: tests_passing            # unique id
    label: "Tests Passing"       # human label
    type: automated              # automated | human_approval
    required: true               # required gates cannot be skipped
    requires:                    # dependency edges (other gate ids)
      - commands_approved
    requires_artifacts:          # files that must exist
      - TESTS.md
    hooks:
      pre:                       # run by `gate-engine.sh verify`; exit 2 = block
        - run-tests.sh
      post:                      # run after the gate clears
        - write-reflexion.sh
        - emit-telemetry.sh
    emits: TESTS_GATE.json       # artifact written when the gate passes
    on_fail: block_all_writes
```

**Gate types:**
- `automated` — cleared when its pre-hooks pass.
- `human_approval` — also needs an explicit approval token (e.g. `CONFIRMED`),
  so a human signs off, not the model.

## The engine

`scripts/gate-engine.sh` reads `gates.yaml` and enforces it:

| Command | Does |
|---------|------|
| `validate` | structural check of `gates.yaml` |
| `check-circular` | rejects cycles in the DAG |
| `current` | the next gate whose dependencies are all met |
| `can-proceed <id>` | whether a gate's deps are satisfied |
| `verify <id>` | run the gate's `hooks.pre`; **exit 2 blocks** on failure |
| `mark-passed <id>` | record the gate as passed (after a clean verify) |

`current` and `check-circular` require `yq`. `meridian-doctor.sh` surfaces a
missing `yq` as CRITICAL precisely because gate detection silently degrades
without it.

## How enforcement actually happens

Two boundaries, both mechanical:

1. **Keystroke (Claude Code only).** `PreToolUse.sh` runs a gate's checks and
   `block-dangerous.sh`; a non-zero exit 2 prevents the tool call. This is the
   tightest loop but only Claude Code exposes it.
2. **Commit / CI (every platform).** `scripts/meridian-verify.sh` runs the gate
   DAG validation, memory checks, evaluator verdicts, and the drift sensor. It's
   wired into a `pre-commit` hook and a CI workflow by `install.sh`. A non-zero
   exit rejects the commit / fails the build — on Cursor, Windsurf, Cline, Aider,
   or plain git. See [platform-tiers.md](platform-tiers.md).

The principle (PHILOSOPHY.md #1): *if the model can hallucinate past it, it's not
a real boundary.* Gates are shell exit codes, not prompt text.

## The Evaluator gate

A `human_approval` or quality gate can require an independent **evaluator
verdict**. `run-evaluator.sh` enforces the contract: the gate stays blocked until
a *separate* evaluator subagent writes a verdict file that clears
`verdict == pass` and `score ≥ EVALUATOR_THRESHOLD` (default 7.0). The generator
never grades its own work (Assumption A003). `meridian-verify.sh` also blocks on
any *standing* FAIL verdict.

## Editing the DAG

Add, remove, or re-wire gates by editing `gates.yaml`, then:

```bash
bash scripts/gate-engine.sh validate
bash scripts/gate-engine.sh check-circular
bash scripts/gen-rules.sh --platform all   # regenerate editor rules from source
```

Regenerating keeps your editor's context rules in sync with the enforced DAG —
they're rendered from the same file. For worked examples (collapse a fullstack
DAG, add a staging gate, add a drift-check gate), see [recipes.md](recipes.md).

## Rules of the road

- **No skipping required gates** — that's the whole point.
- **Optional gates** (`required: false`) warn but don't block.
- **One feature at a time** through the gates (A001); `FEATURES.json` tracks state.
- **Gates are evidence-gated**, not vibe-gated — a gate passes when its hooks pass.
