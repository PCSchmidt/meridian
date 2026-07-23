# Quickstart — Meridian in 10 minutes

This gets you from zero to a Meridian-enforced project. Meridian is an agent
harness: it wraps your AI coding agent with **mechanical** gates, schema-validated
memory, and engineer-legible telemetry. The point is enforcement you can't
hallucinate past, not prompt suggestions.

## Prerequisites

| Tool | Why | Install |
|------|-----|---------|
| **bash ≥ 4** | hooks + scripts | Git Bash on Windows (`git` for Windows), or WSL2 |
| **jq** | JSON memory/telemetry/state | `winget install jqlang.jq` · `brew install jq` |
| **yq** (mikefarah) | YAML gate DAG parsing | `winget install MikeFarah.yq` · `brew install yq` |
| **git** | the commit/CI enforcement boundary | already installed |

Verify after install with `bash scripts/meridian-doctor.sh` (see step 4).

## 1. Install into your project

From the Meridian repo:

```bash
bash install.sh /path/to/your/project --recipe fullstack-web
# recipes: fullstack-web | cli-tool | ml-research
```

This copies the hooks, skills, agents, the `scripts/` engines, a starter
`gates.yaml`, the schemas, a git `pre-commit` hook, a CI workflow, and generates
platform context rules for your editor. It preserves any existing `gates.yaml`,
`CLAUDE.md`, memory, and session state.

If your project isn't a git repo yet, run `git init` first so the pre-commit
boundary installs.

## 2. Hooks are wired automatically (Claude Code)

`install.sh` creates `.claude/settings.json` and registers `SessionStart`,
`PreToolUse`, and `PostToolUse` with Claude Code. Nothing extra needed.

On Cursor/Windsurf/Cline there are no hooks — the generated editor rules guide the
model and the git/CI boundary enforces. See [platform-tiers.md](platform-tiers.md).

## 3. Define scope, then features

Meridian works from your intent, not guesses:

```bash
# 1. Write CONTRACT.md  — scope, out-of-scope, acceptance criteria
# 2. Write SPEC.md      — features as `##` headings
# 3. Seed feature tracking from the spec:
bash scripts/features-init.sh --spec SPEC.md
```

`FEATURES.json` now tracks one feature `in_progress` at a time (Assumption A001).

## 4. Check installation health

```bash
bash scripts/meridian-doctor.sh
```

Expect **GOOD**. A **CRITICAL** for missing `yq` means gate detection is degraded —
install yq and re-run. The doctor checks deps, schemas, the gate DAG, the
hook sourced-not-executed contract, and memory validity.

## 5. Work a gate, then verify before committing

Gates are defined in `.meridian/gates.yaml` as a dependency graph. To see where
you are and run a gate's checks:

```bash
bash scripts/gate-engine.sh current          # which gate is active
bash scripts/gate-engine.sh verify <gate-id>  # run that gate's pre-hooks
```

Before every commit, the portable verifier runs the same engines and blocks on
failure — it's wired into your `pre-commit` hook automatically:

```bash
bash scripts/meridian-verify.sh   # gate DAG + memory + evaluator + drift
git commit -m "..."               # pre-commit runs the verifier; non-zero blocks
```

To intentionally bypass once: `git commit --no-verify`.

## 6. See what's happening

```bash
bash scripts/status-report.sh   # features done vs remaining, completion %
bash scripts/health-report.sh   # gate pass rates, costs, evaluator + calibration
```

Or the slash-command equivalents in-session: `/status`, `/health`.

## What you get

- **Mechanical gates** — the model can't declare a gate passed without the
  evidence ([gate-model.md](gate-model.md))
- **Schema-validated memory** that persists across sessions ([memory.md](memory.md))
- **Telemetry** you can grep and a dashboard you can read ([observability.md](observability.md))
- **A commit/CI boundary** that enforces on any platform ([platform-tiers.md](platform-tiers.md))

## Next steps

- Adapt the recipe to your stack → [recipes.md](recipes.md)
- Understand the gate DAG → [gate-model.md](gate-model.md)
- How memory + observability work → [memory.md](memory.md), [observability.md](observability.md)
- Windows specifics → [windows-install.md](windows-install.md)
- Common problems → [troubleshooting.md](troubleshooting.md)
