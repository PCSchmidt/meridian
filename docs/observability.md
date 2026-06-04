# Observability

Observability is load-bearing infrastructure in Meridian, not a nice-to-have. If
you can't see what the harness did, you can't trust or debug it. Every gate
transition, hook block, evaluator verdict, and tool use is logged to structured
JSONL that engineers can grep — and rendered into dashboards humans can read.

## The telemetry log

`.meridian/telemetry.jsonl` is an append-only event stream. Each line is one
event validated against `.meridian/telemetry-schema.json`. Event types:

| `event_type` | Emitted when | Key fields |
|--------------|--------------|------------|
| `gate_passed` | a gate clears | `gate`, `predicted_hours`, `actual_hours` |
| `gate_blocked` | a gate/verify blocks | `gate`, `reason` |
| `tool_used` | a tool runs through a hook/verifier | `tool`, `hook`, `outcome` |
| `evaluator_verdict` | an evaluator scores a gate | `gate`, `score`, `verdict` |
| `memory_write` | a memory file is validated | `memory_type`, `validation` |
| `drift_score` | the drift sensor runs | `alignment_score`, `recommendation` |
| `session_start` / `session_end` | session boundaries | — |
| `error` | something recoverable fails | `message` |

It's gitignored (per-developer runtime). Events are written best-effort by
`scripts/log-event.sh`:

```bash
bash scripts/log-event.sh gate_passed gate=2.2 predicted_hours=6 actual_hours=5
```

## Reading it directly

Because it's JSONL, you can answer real questions with `jq`:

```bash
# how many blocks, by reason?
jq -r 'select(.event_type=="gate_blocked") | .reason' .meridian/telemetry.jsonl | sort | uniq -c

# evaluator score trend
jq -r 'select(.event_type=="evaluator_verdict") | "\(.gate)\t\(.score)"' .meridian/telemetry.jsonl

# every tool blocked this session
jq -r 'select(.outcome=="blocked")' .meridian/telemetry.jsonl
```

`scripts/telemetry-query.sh` wraps common queries if you prefer not to hand-write
`jq`.

## The dashboards

| Command | Skill | Shows |
|---------|-------|-------|
| `bash scripts/health-report.sh` | `/health` | gate pass/fail rates, token + cost trends, evaluator score trend, calibration accuracy |
| `bash scripts/status-report.sh` | `/status` | features done vs remaining, completion %, estimated time left |
| `bash scripts/cost-report.sh` | `/costs` | token usage and cost per session / per gate |

These read the same telemetry + memory the engine writes — the dashboard and the
enforcement see one source of truth.

## Cost tracking

Telemetry events carry optional `input_tokens` / `output_tokens` / `cost_usd`
fields. When a token source is available, `cost-report.sh` and the cost section of
`/health` summarize spend per session and per gate. Where no token source is
exposed, those fields are simply absent — the schema is forward-compatible and the
docs don't claim numbers that weren't captured.

## Hook feedback is visible to *you*

When a hook blocks, the reason goes to stderr (so you see it, not just the model)
**and** to telemetry (so you can analyze it later). "Why did this fail three
sessions ago?" is answerable because the block was logged with its reason.

## What good observability buys you

- **Trust** — you can confirm a gate actually ran, not that the model said so.
- **Debugging** — telemetry is the flight recorder.
- **Calibration** — predicted-vs-actual data drives better estimates over time
  (see [memory.md](memory.md)).
