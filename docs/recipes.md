# Recipe Adaptation Guide

Meridian ships three reference recipes. Each is a starting point, not a
prescription. This guide explains how to choose a recipe, substitute your
stack, and reshape the gate DAG for your project's workflow.

---

## Choosing a Recipe

| Recipe | Use when... |
|--------|-------------|
| `fullstack-web` | You're building a web app with a frontend, backend API, and database |
| `cli-tool` | You're building a command-line tool that gets distributed/packaged |
| `ml-research` | You're building an ML pipeline where methodology decisions matter |

When in doubt, start with the one closest to your project and remove gates
that don't apply. Adding gates is easy; so is removing them.

---

## Installing a Recipe

```bash
bash install.sh /path/to/your/project --recipe fullstack-web
# or: --recipe cli-tool
# or: --recipe ml-research
```

This copies `gates.yaml`, foundation templates, and the Meridian hooks into
your project. After installation, edit `.meridian/gates.yaml` to match your
stack before running any gates.

---

## Adapting the `fullstack-web` Recipe

**Reference stack:** Next.js + FastAPI + Supabase

The six-gate DAG is `confirmed → frontend_approved + backend_approved →
tests_passing → [security_scan] → deploy_ready`. Frontend and backend gates
run in parallel (both `require: [confirmed]`).

### Common stack substitutions

| Component | Default | Alternatives |
|-----------|---------|--------------|
| Frontend | Next.js | SvelteKit, Remix, Vue + Vite, plain React |
| Backend | FastAPI | Django, Express, Rails, Hono, tRPC |
| Database | Supabase | PostgreSQL, PlanetScale, Neon, SQLite |
| Deploy | Vercel + Railway | Fly.io, Render, AWS, GCP |
| Frontend tests | Vitest | Jest, Playwright, Cypress |
| Backend tests | Pytest | Vitest, Mocha, RSpec |

**No gates.yaml changes needed** for stack substitution — only your hook
scripts (e.g., `run-frontend-tests.sh`) need to call the right test runner.

### Collapsing to a simpler DAG (no separate frontend/backend)

If your stack has no distinct frontend (e.g., a server-rendered Rails app or
an API-only backend), remove `frontend_approved` and merge its artifact
requirements into `confirmed`:

```yaml
# Before (parallel frontend + backend gates):
- id: confirmed
  requires: []
- id: frontend_approved
  requires: [confirmed]
- id: backend_approved
  requires: [confirmed]
- id: tests_passing
  requires: [frontend_approved, backend_approved]

# After (single design gate):
- id: confirmed
  requires: []
- id: design_approved
  requires: [confirmed]
  requires_artifacts:
    - API_SPEC.md
    - DATABASE_SCHEMA.md
    - WIREFRAMES.md        # add anything relevant
- id: tests_passing
  requires: [design_approved]
```

### Adding a staging gate

Insert a `staging_verified` gate between `tests_passing` and `deploy_ready`
when you have a staging environment that humans must sign off:

```yaml
- id: staging_verified
  label: "Staging Verified"
  type: human_approval
  required: true
  approval_token: "STAGING OK"
  requires:
    - tests_passing
  requires_artifacts:
    - STAGING_CHECKLIST.md
  hooks:
    post:
      - write-reflexion.sh
      - emit-telemetry.sh
  on_fail: block_all_writes
```

Then update `deploy_ready.requires` to include `staging_verified`.

---

## Adapting the `cli-tool` Recipe

**Reference stack:** Python + Click

The five-gate DAG is `confirmed → commands_approved → tests_passing →
[usability_check] → package_ready`.

### Common stack substitutions

| Component | Default | Alternatives |
|-----------|---------|--------------|
| Language | Python + Click | Rust + clap, Go + cobra, Node.js + commander |
| Tests | Pytest | cargo test, `go test`, Vitest |
| Distribution | PyPI | Cargo, Homebrew, npm, binary release |
| Package config | PyPI metadata | Cargo.toml, package.json, `.goreleaser.yaml` |

Again, only hook scripts change — not gates.yaml structure.

### Making the usability gate required

`usability_check` ships as `required: false` (warn-only) because many
internal tools skip formal usability review. For a public CLI, make it
required:

```yaml
- id: usability_check
  required: true          # change from false
  on_fail: block_all_writes   # change from warn
```

### Adding an install-test gate

Useful for verifying the package actually installs cleanly from the
distribution channel before release:

```yaml
- id: install_test
  label: "Clean Install Verified"
  type: automated
  required: true
  requires:
    - tests_passing
  hooks:
    pre:
      - test-clean-install.sh   # pip install / cargo install in a temp env
  pass_condition: "exit_code == 0"
  emits: INSTALL_TEST.json
  on_fail: block_write
```

Put this before `package_ready` in the DAG (add `install_test` to
`package_ready.requires`).

---

## Adapting the `ml-research` Recipe

**Reference stack:** PyTorch + FastAPI

The six-gate DAG is `data_contract → pipeline_validated → model_eval →
[ablation_study, evidence_pdf] → deploy_ready`.

### Common stack substitutions

| Component | Default | Alternatives |
|-----------|---------|--------------|
| ML framework | PyTorch | scikit-learn, TensorFlow, JAX, XGBoost |
| Data | pandas | Polars, Spark |
| Experiment tracking | none | MLflow, W&B, DVC |
| Serving | FastAPI | Flask, AWS Lambda, batch job |

### When to keep `ablation_study` optional vs required

`ablation_study` (required: false) is appropriate for production ML systems
where systematic component removal is overkill. Make it required for:
- Academic/research publications
- Projects where the model complexity needs justification
- Any time the baseline comparison needs deeper analysis

```yaml
- id: ablation_study
  required: true
  on_fail: block_all_writes
```

### Removing `evidence_pdf` for production deployments

`evidence_pdf` is designed for academic contexts. For production deployments,
remove it from the DAG or set `required: false` and `on_fail: warn` (already
the default). You can also remove the `evidence_pdf` gate entirely — the
`deploy_ready` gate doesn't require it:

```yaml
# deploy_ready.requires already only requires model_eval:
- id: deploy_ready
  requires:
    - model_eval
    # ablation_study and evidence_pdf deliberately not required here
```

### Adding a data-drift monitoring gate

For production ML systems with periodic retraining, add a post-deploy gate:

```yaml
- id: drift_check
  label: "Data Drift Within Bounds"
  type: automated
  required: true
  requires:
    - deploy_ready
  hooks:
    pre:
      - run-drift-detection.sh   # compare live distribution vs training
  pass_condition: "exit_code == 0"
  emits: DRIFT_GATE.json
  on_fail: block_write
```

---

## Gate Customization Reference

### Gate fields

| Field | Required | Effect |
|-------|----------|--------|
| `id` | yes | Unique identifier; used in `requires` of downstream gates |
| `type` | yes | `human_approval` or `automated` |
| `required` | yes | `true` = blocks on failure; `false` = warns only |
| `approval_token` | human_approval only | String the human must type to pass |
| `requires` | no | List of gate ids that must be passed first |
| `requires_artifacts` | no | Files that must exist before gate is evaluated |
| `hooks.pre` | no | Scripts to run before gate evaluation |
| `hooks.post` | no | Scripts to run after gate passes |
| `pass_condition` | automated only | `"exit_code == 0"` is the standard |
| `on_fail` | no | `block_all_writes`, `block_write`, or `warn` |
| `emits` | no | Artifact file written on gate pass |

### `required: false` vs removing a gate

- `required: false` with `on_fail: warn` — gate runs, failure is visible but
  not blocking. Use when the check is valuable but not mandatory (e.g.,
  security scan on an internal tool).
- Removing a gate entirely — use when the gate genuinely doesn't apply to
  your project (e.g., removing `evidence_pdf` from a production deployment).

Don't keep a gate with `required: false` if you would never look at its
output. Dead gates add noise without value.

### Adding a gate between two existing gates

1. Give the new gate its own `id`.
2. Set `requires` to the upstream gate's id.
3. Update the downstream gate's `requires` to include the new gate's id.
4. Validate the DAG: `bash scripts/gate-engine.sh validate .meridian/gates.yaml`

### Renaming approval tokens

Approval tokens are arbitrary strings. They're what the human types to pass a
`human_approval` gate. Make them memorable and unambiguous:

```yaml
# Instead of generic "GO":
approval_token: "DEPLOY PROD"    # clearer intent
approval_token: "SHIP IT"        # works fine too
approval_token: "BETA APPROVED"  # stage-specific
```

Avoid tokens that could be typed accidentally in normal conversation (e.g.,
single words like "yes" or "ok").

---

## Writing Custom Hook Scripts

Hooks are shell scripts in `.claude/hooks/`. A `pre` hook runs before gate
evaluation; a `post` hook runs after the gate passes.

Minimal hook template:

```bash
#!/bin/bash
# hooks/my-custom-check.sh
set -euo pipefail

# Source the wrapper for consistent logging/exit behavior
source "$(dirname "${BASH_SOURCE[0]}")/hook-wrapper.sh"
HOOK_NAME="my-custom-check"

# Your validation logic here.
# Exit 0 = pass. Exit non-zero = gate blocked (if required: true).
if ! some_check; then
  echo "Check failed: <reason>" >&2
  exit 1
fi
```

Key rules:
- `source hook-wrapper.sh` — never execute it directly
- Always `set -euo pipefail`
- Write failure reasons to stderr, not stdout
- Exit 0 for pass, 1 for fail

---

## From Scratch: Defining a Custom Recipe

If none of the three recipes fits, copy the closest one as a starting point
and reshape the DAG. The gate engine has no opinion about recipe names — the
`project.recipe` field is metadata only.

A minimal valid gates.yaml:

```yaml
version: "1.0"

project:
  name: "my-project"
  recipe: "custom"
  description: "One-line description"

gates:
  - id: confirmed
    label: "Project Confirmed"
    type: human_approval
    required: true
    approval_token: "CONFIRMED"
    requires: []
    requires_artifacts:
      - CONTRACT.md
    on_fail: block_all_writes

  - id: deploy_ready
    label: "Ready to Deploy"
    type: human_approval
    required: true
    approval_token: "SHIP"
    requires:
      - confirmed
    on_fail: block_all_writes
```

Validate it before running anything:

```bash
bash scripts/gate-engine.sh validate .meridian/gates.yaml
```

The engine checks: all `requires` ids exist, no circular dependencies, all
required fields present.
