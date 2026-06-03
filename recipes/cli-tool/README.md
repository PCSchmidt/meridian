# Meridian Recipe: cli-tool

A gate model and project templates for command-line interface tools.

**Reference implementation:** Python + Click  
**Also works with:** Rust + clap, Go + cobra, Node.js + commander, any CLI framework

---

## Install

```bash
bash path/to/meridian/install.sh <your-project-dir> --recipe cli-tool
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
confirmed ──► commands_approved ──► tests_passing ──► [usability_check] ──► package_ready
```

Gates in `[brackets]` are optional (warn on failure, don't block).

| Gate | Type | Artifacts required |
|------|------|--------------------|
| `confirmed` | human_approval | CONTRACT.md, SPEC.md, DECISIONS.md |
| `commands_approved` | human_approval | COMMANDS_SPEC.md, CLI_DESIGN.md |
| `tests_passing` | automated | — (runs test suite hook) |
| `usability_check` | human_approval (optional) | USABILITY_CHECKLIST.md |
| `package_ready` | human_approval | PACKAGE_CONFIG.md, CHANGELOG.md, README.md |

---

## Quick Start

**Step 1 — Install Meridian:**
```bash
bash install.sh <your-project-dir> --recipe cli-tool
```

**Step 2 — Write CONTRACT.md** (use `foundation/CONTRACT.md.template`)

Key sections:
- What the tool does and who runs it
- Target platforms (Linux/macOS/Windows)
- Distribution method (PyPI, Homebrew, Cargo, binary release)
- Out of scope

**Step 3 — Write SPEC.md** (use `foundation/SPEC.md.template`)

Use `##` headings for each command or major capability — they become FEATURES.json entries:
```bash
MERIDIAN_PROJECT_DIR=. bash path/to/meridian/scripts/features-init.sh
```

**Step 4 — Write COMMANDS_SPEC.md** (use `foundation/COMMANDS_SPEC.md.template`)

This is the most important artifact for CLI tools: every command, subcommand, flag,
argument, exit code, and output format locked down before implementation. Agents
cannot build a CLI correctly without it; this gate exists to enforce that constraint.

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

## CLI_DESIGN.md vs COMMANDS_SPEC.md

`commands_approved` requires both:

| File | What it captures |
|------|-----------------|
| `COMMANDS_SPEC.md` | Machine-readable contract: command tree, arg types, flags, exit codes, stdout/stderr format |
| `CLI_DESIGN.md` | Human-readable UX decisions: help text tone, error message style, color/no-color policy, interactive prompts |

Separation matters: the spec is for testing (does the command match the contract?), the design is for review (does the tool feel right?).

---

## Adapting for Your Stack

| Stack | Change |
|-------|--------|
| Rust + clap | Replace `run-tests.sh` with `cargo test`; update `validate-package.sh` to check `Cargo.toml` |
| Go + cobra | Same gates; `validate-package.sh` checks `go.mod` and build output |
| Node.js + commander | Add `package.json` to `package_ready` artifacts |
| No distribution yet | Remove `package_ready` or mark `required: false` |
| Multi-binary tool | Add one `commands_approved`-style gate per binary |

---

## Reference: cli-tool Gate Hooks

| Hook | Purpose |
|------|---------|
| `validate-contract.sh` | Checks CONTRACT.md has required sections |
| `validate-spec.sh` | Checks SPEC.md has `##` feature headings |
| `validate-commands.sh` | Checks COMMANDS_SPEC.md completeness |
| `run-tests.sh` | Runs your test suite (pytest, cargo test, go test, etc.) |
| `validate-package.sh` | Checks packaging config (pyproject.toml, Cargo.toml, etc.) |

The Meridian-provided hooks (`block-dangerous.sh`, `run-evaluator.sh`, etc.) run automatically.
The above are project-specific hooks you write.

---

## Why This Recipe Exists

The `cli-tool` recipe encodes the most common failure modes in CLI projects:

1. **Ambiguous command surface** — the `commands_approved` gate forces the full command tree (args, flags, exit codes, output format) to be written down before a single line of implementation. Without this, agents hallucinate flag names and argument shapes.
2. **"Works on my machine"** — `tests_passing` is automated and cannot be skipped; CLI integration tests invoke the real binary, not mocked internals.
3. **Silent scope creep** — drift sensor fires on every session, catching when the SPEC diverges from what's being built.
4. **Packaging surprises** — `package_ready` requires PACKAGE_CONFIG.md and CHANGELOG.md before any release; agents cannot "just push to PyPI" without this gate passing.
5. **Usability debt** — the optional `usability_check` gate surfaces help-text and error-message quality before users hit it; it's optional because small tools often skip it, but it's present to promote.
