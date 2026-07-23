# The Memory System

Meridian's memory is **schema-validated JSONL**, not markdown the model can
quietly corrupt. It persists across sessions, is queryable with `jq`, and every
write is integrity-checked. Engineers grep it; the model reads rendered views.

## Three memory types

From Reflexion (Shinn et al., NeurIPS 2023) and Anthropic's harness research:

| Type | File | What it holds |
|------|------|---------------|
| **Semantic** | `.meridian/memory/semantic.json` | validated patterns across projects ("frontend > 8 components → 1.5x multiplier"), deduped by hash |
| **Episodic** | `.meridian/memory/episodic.jsonl` | append-only session/event log (what happened when) |
| **Corrections** | `.meridian/memory/corrections.jsonl` | reflexion entries — predicted vs actual, with root cause (calibration data) |

These are runtime state and are **gitignored** — they're per-developer, not
version-controlled.

## The corrections schema (calibration)

Each reflexion entry records a gate outcome. Required fields: `session_id`, `gate`,
`date`, `project`, `root_cause`, `action_next`, `errors_open`, `errors_close`.
Hours fields (`predicted_hours`, `actual_hours`, `delta_ratio`, `variance_percent`)
are optional — omit them when hours weren't tracked for a gate.

```json
{"session_id":"6a20b4e3","gate":"5.2","date":"2026-06-04T00:30:00Z",
 "project":"meridian","predicted_hours":10,"actual_hours":4,
 "delta_ratio":2.50,"variance_percent":-60.0,
 "root_cause":"...","action_next":"...","errors_open":0,"errors_close":0}
```

Over time these reveal patterns ("recipe-doc gates ≈ 2-4h, not 8-12h") and your
operator multiplier converges toward 1.0x. Write one after each gate.

## Validating writes

Every write is checked against `.meridian/memory-schema.json`:

```bash
bash scripts/validate-memory.sh corrections .meridian/memory/corrections.jsonl
bash scripts/validate-memory.sh semantic   .meridian/memory/semantic.json
bash scripts/validate-memory.sh episodic   .meridian/memory/episodic.jsonl
```

Exit 0 = valid. On Claude Code, `PostToolUse.sh` runs this automatically when a
memory file is written, so a malformed entry is caught at write time. The portable
verifier (`meridian-verify.sh`) re-checks all present memory files at the commit
boundary.

## Health and repair

```bash
bash scripts/memory-doctor.sh    # validate all three, report health + calibration
```

It reports counts, flags LOW-confidence or stale semantic patterns, and prints
your average calibration ratio. A validation failure is **CRITICAL** — fix the
entry before proceeding.

## Common gotcha — writing a reflexion

Use `scripts/write-reflexion.sh` — it validates before appending and handles the
session id and date automatically:

```bash
bash scripts/write-reflexion.sh \
  --gate 3.1 \
  --predicted 10 --actual 4 \
  --root-cause "Design was pre-specified" \
  --action-next "Cut estimate by 4x for enumerated deliverables"
```

Hours (`--predicted` / `--actual`) are optional; omit both when not tracking time.
If you hand-write JSON, include all required fields and validate first:

```bash
cat >> .meridian/memory/corrections.jsonl <<'EOF'
{"session_id":"...","gate":"...","date":"...","project":"...","root_cause":"...","action_next":"...","errors_open":0,"errors_close":0}
EOF
bash scripts/validate-memory.sh corrections .meridian/memory/corrections.jsonl
```

The validator will reject missing required fields or wrong field names.

## Engineer-legible vs LLM-legible

- **JSONL** is the source of truth — `jq`-queryable, dedupable, integrity-checked.
- **`/memory show`** renders human-readable views for the session.

You can answer "how has my calibration trended?" with a one-line `jq` over
`corrections.jsonl` — that's the point. Memory is data, not prose.

## Cross-project learning

Global patterns and the operator multiplier aggregate under `~/.meridian/global/`
(synced by `scripts/global-memory-sync.sh`), so calibration learned on one project
informs estimates on the next.

## Single-project confidence ceiling (F4)

Semantic patterns require cross-project validation to reach HIGH confidence. The
ceiling is intentional: a pattern observed only once, in one project, might be
project-specific noise rather than a generalizable rule.

| `validated_count` | Confidence ceiling | Requirement |
|-------------------|--------------------|-------------|
| 1 | LOW | First observation |
| 2–3 | MEDIUM | Validated in ≥ 2 projects |
| 4+ | HIGH | Validated across ≥ 3 projects |

**Within a single project**, a pattern stays LOW regardless of how many times it
appears, because all observations share the same codebase, stack, and working
conditions. Run `scripts/global-memory-sync.sh push` after completing a project to
contribute its patterns to the global pool, and `pull` on the next project to
import them — that cross-project pass is what lifts confidence.

If a pattern is demonstrably universal (e.g. "all Fly.io free-tier machines
cold-start in 2–5s"), you can manually bump its `validated_count` and
`source_projects` via a direct write to `semantic.json`, then validate:

```bash
bash scripts/validate-memory.sh semantic .meridian/memory/semantic.json
```
