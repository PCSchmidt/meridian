# Meridian Recipe: fullstack-web

A gate model and project templates for full-stack web applications.

**Reference implementation:** Next.js + FastAPI (Python) + relational DB (Supabase, PostgreSQL, etc.)  
**Validated on:** AeroIntel (Next.js + FastAPI + Fly.io, 2026-06-02)

---

## Install

```bash
bash path/to/meridian/install.sh <your-project-dir> --recipe fullstack-web
```

This installs:
- `.claude/hooks/` — enforcement hooks (PreToolUse, PostToolUse)
- `.claude/skills/` — 15 slash-command skills
- `.claude/agents/` — gate-evaluator, drift-evaluator, spec-reviewer
- `.meridian/gates.yaml` — this recipe's gate DAG
- `.meridian/` — schema files, security-rules.yaml, runtime skeleton
- `CLAUDE.md` — session-start context for agents

---

## Gate DAG

```
confirmed ──► frontend_approved ──►┐
          ──► backend_approved  ──►┼──► tests_passing ──► security_scan ──► deploy_ready
```

| Gate | Type | Artifacts required |
|------|------|--------------------|
| `confirmed` | human_approval | CONTRACT.md, SPEC.md, DECISIONS.md |
| `frontend_approved` | human_approval | FRONTEND_SPEC.md, DESIGN_SYSTEM.md, COMPONENT_REGISTRY.md |
| `backend_approved` | human_approval | API_SPEC.md, DATABASE_SCHEMA.md |
| `tests_passing` | automated | — (runs frontend + backend test hooks) |
| `security_scan` | automated (optional) | — (runs OWASP audit hook) |
| `deploy_ready` | human_approval | DEPLOYMENT_CONFIG.md, CHANGELOG.md |

Gates `frontend_approved` and `backend_approved` are parallel (both require `confirmed`).

---

## Quick Start

**Step 1 — Install Meridian:**
```bash
bash install.sh <your-project-dir> --recipe fullstack-web
```

**Step 2 — Write CONTRACT.md** (use `foundation/CONTRACT.md.template` as starting point)

Key sections to fill in:
- Stack (frontend, backend, DB, hosting)
- In scope / Out of scope
- Acceptance criteria

**Step 3 — Write SPEC.md** (use `foundation/SPEC.md.template`)

Use `##` headings for each feature — they become FEATURES.json entries:
```bash
MERIDIAN_PROJECT_DIR=. bash path/to/meridian/scripts/features-init.sh
```

**Step 4 — Customize gates.yaml** (`.meridian/gates.yaml`)

The recipe installs a working gate DAG. Adapt it:
- Remove `frontend_approved`/`backend_approved` if your stack doesn't have that split
- Replace hook script names with your actual test commands
- Change `approval_token` strings to whatever fits your workflow

**Step 5 — Work gate-by-gate**

```bash
# Check current gate
MERIDIAN_PROJECT_DIR=. bash path/to/meridian/scripts/gate-engine.sh current

# Check lifecycle completion
MERIDIAN_PROJECT_DIR=. bash path/to/meridian/scripts/features-report.sh --full

# Run drift check
MERIDIAN_PROJECT_DIR=. bash path/to/meridian/scripts/drift-check.sh
```

---

## Adapting for Your Stack

The `fullstack-web` recipe is stack-agnostic. Adapt it for:

| Stack | Change |
|-------|--------|
| React (no Next.js) | Same gates — just different hook scripts |
| Django backend | Replace `run-backend-tests.sh` with `pytest` invocation |
| MongoDB | Update DATABASE_SCHEMA.md expectations in gate `backend_approved` |
| No separate deploy step | Remove `deploy_ready` gate or mark `required: false` |
| Monorepo | Merge `frontend_approved` and `backend_approved` into one gate |

---

## Reference: fullstack-web Gate Hooks

The following hook scripts are referenced in `gates.yaml`. You'll need to create them
or adapt them for your project's test runner:

| Hook | Purpose |
|------|---------|
| `validate-contract.sh` | Checks CONTRACT.md has required sections |
| `validate-spec.sh` | Checks SPEC.md has ## feature headings |
| `validate-frontend-spec.sh` | Checks FRONTEND_SPEC.md completeness |
| `validate-api-spec.sh` | Checks API_SPEC.md completeness |
| `run-frontend-tests.sh` | Runs your frontend test suite |
| `run-backend-tests.sh` | Runs your backend test suite |
| `run-security-audit.sh` | Runs OWASP security checks |
| `validate-deployment.sh` | Checks DEPLOYMENT_CONFIG.md |

The Meridian-provided hooks (`block-dangerous.sh`, `run-evaluator.sh`, etc.) run automatically.
The above are project-specific hooks you write. They can be as simple as:

```bash
#!/bin/bash
cd "$(git rev-parse --show-toplevel)" && npm test
```

---

## Why This Recipe Exists

The `fullstack-web` recipe encodes the most common failure modes in web projects:

1. **Backend and frontend specs written in isolation** — the parallel `frontend_approved`/`backend_approved` gates force both to be approved before tests run
2. **"It works on my machine"** — `tests_passing` is automated and cannot be skipped
3. **Scope creep between phases** — drift sensor fires on every session with a FEATURES.json
4. **Shipping without security review** — `security_scan` is optional but present; promotes to required easily
5. **Deployment surprises** — `deploy_ready` requires DEPLOYMENT_CONFIG.md and CHANGELOG.md before any prod push
