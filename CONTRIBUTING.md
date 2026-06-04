# Contributing to Meridian

Meridian is built the way it asks you to build: gate-by-gate, with tests, honest
calibration, and reflexion. This guide covers how to contribute after v0.1.0.

## The development model

Work proceeds one gate at a time (`G6.1`, `G6.2`, …). Each gate:

1. **Build** the deliverable.
2. **Test** — add/extend a `tests/test-*.sh`; all suites must pass.
3. **Update `ROADMAP.md`** — gate status, predicted vs actual hours, variance.
4. **Write a reflexion** to `.meridian/memory/corrections.jsonl` (validate it).
5. **Commit** with the Co-Authored-By trailer.

One gate per change keeps the codebase always-shippable and the calibration data
clean. Don't batch unrelated gates into one commit.

## Before you commit

- Run the relevant suites: `bash tests/test-<area>.sh` (or all of `tests/test-*.sh`).
- All must pass. The full suite runs on Windows / Git Bash and in CI.
- Update `ROADMAP.md` and write the reflexion entry.
- Commit messages end with:
  ```
  Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
  ```

## Bash compatibility (Windows / Git Bash)

Meridian targets bash ≥ 4 on Git Bash and WSL2. The portability rules (also in
`CLAUDE.md`):

- Use `$(( ))` for arithmetic, never `(( ))`.
- Use `$(...)`, never backticks.
- No `bc` — use `awk` for float math.
- Guard `while read` loops with `|| [ -n "$line" ]` to catch a last line with no
  trailing newline.
- Normalize mixed JSONL with `jq -c '.'` before querying.
- Don't rely on `yq`/`jq` being present in low-level fallbacks where a parser is
  optional; where they're required, surface it loudly (see `meridian-doctor.sh`).

## Code standards

- **Match the surrounding code.** New scripts mirror the existing house style:
  `set -euo pipefail` (or `set -uo pipefail` for runners), a header comment block
  with purpose + usage + exit codes, color helpers, and a `main` dispatcher.
- **Test harnesses** follow the `pass`/`fail` counter + `Results:` block format so
  the aggregate tally script can read them.
- **Hooks** source `hook-wrapper.sh` (never execute it) and honor the 0/1/2 exit
  contract.
- **Test the real contract end-to-end**, not a mock. The two worst bugs in
  Meridian's history (the live hook stdin shape; the missing `scripts/` on install)
  hid behind tests that exercised a convenience path instead of reality.

## Adding a component

| Adding a… | Do |
|-----------|----|
| **script** | put it in `scripts/`, header + `main`, add a `tests/test-*.sh` |
| **hook** | source the wrapper, honor 0/1/2, add it to a gate's `hooks.pre/post` |
| **skill** | `.claude/skills/<name>/<name>.md` with progressive-disclosure frontmatter |
| **recipe** | `recipes/<name>/` with `gates.yaml` + `README.md` + `foundation/` |
| **assumption** | follow `docs/assumptions.md` — failure mode, source, rule, review trigger |
| **doc** | link it from `README.md`; don't merge a component without its doc |

## Assumptions discipline

If your change relies on the model *not* being able to do something reliably,
document it in `ASSUMPTIONS.md` with a review trigger. If your change removes a
need (because models improved), deprecate the assumption. The goal is for the
number of assumptions to *decrease* over time. See [docs/assumptions.md](docs/assumptions.md).

## PR process

1. Branch from `main`.
2. Make the change for a single gate; keep the diff focused.
3. Ensure `bash tests/test-*.sh` all pass and `meridian-doctor.sh` is GOOD.
4. Update `ROADMAP.md` + reflexion.
5. Open a PR describing the gate, the test evidence, and the predicted-vs-actual
   calibration.

## What not to do

- Don't claim enforcement that isn't wired. Meridian's credibility is that it
  doesn't overstate — keep it that way in code and docs.
- Don't bypass the verifier (`--no-verify`) in committed history.
- Don't add a feature without a doc and a test.

See [PHILOSOPHY.md](PHILOSOPHY.md) for the principles every change is measured
against.
