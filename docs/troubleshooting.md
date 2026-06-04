# Troubleshooting

Real problems and their fixes. Most of these were hit while building Meridian
itself, so the diagnoses are field-tested, not hypothetical. When in doubt, start
with the doctor:

```bash
bash scripts/meridian-doctor.sh
```

It checks dependencies, schemas, the gate DAG, the hook contract, and memory, and
tells you exactly what's wrong.

---

## `meridian-doctor` reports CRITICAL: yq not found

**Symptom:** doctor exits 1; gate detection prints `unknown`.

**Cause:** `yq` (mikefarah) isn't installed or isn't on `PATH`. Gate-DAG
validation, circular-dependency checking, and "current gate" all need it.

**Fix:**
```bash
winget install MikeFarah.yq   # or: brew install yq / choco install yq
```
Reopen the shell, then re-run the doctor. If it still can't find `yq`, the binary
isn't on this shell's `PATH` — restart your editor so it inherits the update.

---

## Hooks don't block anything / logs show `Tool: unknown`

**Symptom:** dangerous commands aren't blocked in a live session; `.meridian/hooks.log`
shows `Tool: unknown`.

**Cause:** an old `hook-wrapper.sh` that parsed the wrong stdin keys (`.tool` /
`.arguments.*`) instead of Claude Code's real contract (`.tool_name` /
`.tool_input.*`). Fixed in Phase 5 (G5.1).

**Fix:** re-install from the current Meridian repo to refresh the hooks:
```bash
bash install.sh /path/to/project --recipe <name>
```
Confirm with the contract test shape — see [tier1-verification.md](tier1-verification.md).

---

## Installed hooks error: `scripts/...sh: No such file or directory`

**Symptom:** hooks reference `$PROJECT_DIR/scripts/*.sh` that don't exist;
enforcement, memory validation, and telemetry are silently dead.

**Cause:** an install from before Phase 5 (G5.2). The old `install.sh` never
copied `scripts/` into the target.

**Fix:** re-install. The current installer copies `scripts/` (step 9) and the
git/CI boundary (step 10). Then:
```bash
bash scripts/meridian-doctor.sh   # should be GOOD
bash scripts/meridian-verify.sh   # should PASS
```

---

## Memory validation fails (`validate-memory` / `memory-doctor` CRITICAL)

**Symptom:** `corrections memory failed schema validation`, or a `PostToolUse`
block on a memory write.

**Cause:** a hand-written JSONL entry missing required fields or using wrong field
names (e.g. `ratio` instead of `delta_ratio`, or no `session_id`).

**Fix:** write entries with the heredoc-append pattern and validate before
committing:
```bash
cat >> .meridian/memory/corrections.jsonl <<'EOF'
{"session_id":"...","gate":"...","date":"...","project":"...","predicted_hours":2,"actual_hours":1,"delta_ratio":2.0,"variance_percent":-50.0,"root_cause":"...","action_next":"...","errors_open":0,"errors_close":0}
EOF
bash scripts/validate-memory.sh corrections .meridian/memory/corrections.jsonl
```
See [memory.md](memory.md) for the full schema.

---

## `gate-engine.sh`: gates.yaml not found

**Cause:** you're not in a recipe-initialized project, or you're running from the
wrong directory. Meridian's own repo has no `gates.yaml` (it dogfoods via the
ROADMAP), so this is expected there.

**Fix:** install a recipe (`install.sh ... --recipe <name>`), or set
`MERIDIAN_PROJECT_DIR` to the project root.

---

## A commit is unexpectedly blocked

**Symptom:** `git commit` fails with Meridian verify output.

**Cause:** the `pre-commit` hook ran `meridian-verify.sh` and a check failed —
read the output. Common causes: invalid `gates.yaml`, a corrupt memory file, or a
standing FAIL evaluator verdict.

**Fix:** resolve the reported issue, or — for a deliberate one-off — bypass:
```bash
git commit --no-verify
```
Don't make `--no-verify` a habit; it defeats the boundary.

---

## The security hook blocks a *commit message* that mentions a dangerous command

**Symptom:** you write a commit message describing a fix and the PreToolUse
security hook blocks the `git commit` because the message text contains a pattern
like a recursive force-delete of root.

**Cause:** the security blocklist scans the Bash command string, which includes
your commit message. It's matching the literal pattern in your prose.

**Fix:** reword the message to avoid the literal dangerous-command string (e.g.
"a destructive filesystem command" instead of the literal). This is the boundary
working as designed — it can't tell prose from intent.

---

## CI fails: yq not found

**Cause:** the CI runner doesn't have `yq`.

**Fix:** the installed `.github/workflows/meridian.yml` already installs `jq` and
`yq` before running the verifier. If you wrote a custom workflow, add that step.

---

## CRLF warnings on Windows

`LF will be replaced by CRLF` on staging is harmless. If a script ever fails on a
stray `\r`, pin shell files to LF with a `.gitattributes` — see
[windows-install.md](windows-install.md#line-endings-crlf).

---

## Still stuck?

- Read `.meridian/hooks.log` — every hook logs what it saw and did.
- Query `.meridian/telemetry.jsonl` with `jq` — blocks are logged with reasons
  ([observability.md](observability.md)).
- Run each engine directly (`gate-engine.sh validate`, `validate-memory.sh ...`,
  `meridian-verify.sh`) to isolate the failing layer.
