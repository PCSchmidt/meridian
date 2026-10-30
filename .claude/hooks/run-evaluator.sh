#!/bin/bash
# run-evaluator.sh
# Meridian Gate Evaluator contract + enforcement (Gate 2.2)
#
# Enforces the generator-evaluator separation (ASSUMPTIONS.md A003): a gate
# cannot be marked passed until a SEPARATE evaluator subagent has scored the
# work and written a verdict that clears the threshold.
#
# Honest boundary: the evaluator subagent itself is invoked by the harness /
# skill layer (Claude Code's Task/Agent tool) -- a bash hook cannot spawn a
# subagent. This script owns the *contract* around that subagent:
#   --prepare <gate> [artifact ...]  Write the evaluator request payload
#                                    (gate, artifacts, adversarial system
#                                    prompt) to .meridian/evaluator/<gate>-request.json
#   --check   <gate>   (default)     Read .meridian/evaluator/<gate>-verdict.json
#                                    and block unless it clears the bar.
#
# The verdict file must be sealed by scripts/write-verdict.sh, which adds evaluator_model,
# artifact digests and integrity hashes to the evaluator's JSON:
#   {"gate":"2.2","score":8.0,"verdict":"pass","evaluator":"gate-evaluator","notes":"...",
#    "evaluator_model":"...","artifact_digests":{...},"artifact_hash":"...","verdict_hash":"..."}
# Unsealed, edited or stale verdicts are rejected (MERIDIAN_ALLOW_UNHASHED_VERDICTS=1 = legacy).
#
# Config (env):
#   EVALUATOR_THRESHOLD   minimum passing score, 0-10 (default 7.0)
#   EVALUATOR_DIR         verdict/request directory (default $PROJECT_DIR/.meridian/evaluator)
#
# Exit codes:
#   0 = verdict clears the bar (or --prepare succeeded)
#   2 = no verdict, malformed verdict, or score/verdict below bar (block)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/hook-wrapper.sh"
HOOK_NAME="run-evaluator"

LOG_EVENT="$PROJECT_DIR/scripts/log-event.sh"
EVAL_DIR="${EVALUATOR_DIR:-$PROJECT_DIR/.meridian/evaluator}"
THRESHOLD="${EVALUATOR_THRESHOLD:-7.0}"

# Adversarial system prompt that every evaluator request carries (A003).
EVALUATOR_PROMPT="You did not produce the artifacts you are reviewing. Do not praise. Do not explain. Score the work 0-10 against the gate's spec and flag every gap. Return only JSON: {\"gate\":\"<id>\",\"score\":<0-10>,\"verdict\":\"pass|fail|warn\",\"notes\":\"<terse>\"}."

usage() { echo "Usage: run-evaluator.sh [--prepare|--check] <gate> [artifact ...]" >&2; }

prepare() {
    local gate="$1"; shift
    [ -n "$gate" ] || { usage; block "prepare requires a gate id"; }
    mkdir -p "$EVAL_DIR"
    local req="$EVAL_DIR/${gate}-request.json"
    local ts
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%S")

    if command -v jq >/dev/null 2>&1; then
        local artifacts_json="[]"
        if [ "$#" -gt 0 ]; then
            artifacts_json=$(printf '%s\n' "$@" | jq -R . | jq -cs .)
        fi
        jq -n --arg gate "$gate" --arg ts "$ts" --arg prompt "$EVALUATOR_PROMPT" \
              --argjson artifacts "$artifacts_json" \
              '{gate:$gate, requested_at:$ts, system_prompt:$prompt, artifacts:$artifacts, verdict_path:("\($gate)-verdict.json")}' \
              > "$req"
    else
        # Minimal fallback without jq
        printf '{"gate":"%s","requested_at":"%s","verdict_path":"%s-verdict.json"}\n' \
               "$gate" "$ts" "$gate" > "$req"
    fi

    info "Evaluator request written: $req"
    info "The evaluator must seal its verdict: bash scripts/write-verdict.sh $gate --model <id>  (writes $EVAL_DIR/${gate}-verdict.json)"
    timer_end
    exit 0
}

sha256_file() {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1
    else shasum -a 256 "$1" | cut -d' ' -f1; fi
}
sha256_text() {
    if command -v sha256sum >/dev/null 2>&1; then printf '%s' "$1" | sha256sum | cut -d' ' -f1
    else printf '%s' "$1" | shasum -a 256 | cut -d' ' -f1; fi
}

# Verdict integrity (sealed by scripts/write-verdict.sh):
#   * evaluator_model, artifact_digests, artifact_hash and verdict_hash must be present
#   * verdict_hash must match the decisive fields (detects hand-edited scores/verdicts)
#   * every recorded artifact must still hash to its recorded digest (detects stale verdicts)
# MERIDIAN_ALLOW_UNHASHED_VERDICTS=1 accepts legacy unsealed verdicts with a warning.
# Boundary: this detects edits and staleness; it cannot prove who ran write-verdict.sh.
verify_integrity() {
    local gate="$1" vf="$2"
    local model ah vh dg
    ah=$(jq -r '.artifact_hash // empty' "$vf" | tr -d '\r')
    if [ -z "$ah" ] && [ "${MERIDIAN_ALLOW_UNHASHED_VERDICTS:-0}" = "1" ]; then
        warn "Gate '$gate' verdict is unsealed (MERIDIAN_ALLOW_UNHASHED_VERDICTS=1) - legacy mode"
        return 0
    fi
    model=$(jq -r '.evaluator_model // empty' "$vf" | tr -d '\r')
    vh=$(jq -r '.verdict_hash // empty' "$vf" | tr -d '\r')
    dg=$(jq -c '.artifact_digests // empty' "$vf" | tr -d '\r')
    if [ -z "$model" ] || [ -z "$ah" ] || [ -z "$vh" ] || [ -z "$dg" ] || [ "$dg" = "{}" ]; then
        block "Gate '$gate' verdict is unsealed (needs evaluator_model, artifact_digests, artifact_hash, verdict_hash). Write verdicts with: bash scripts/write-verdict.sh $gate --model <id>"
    fi

    local score verdict expect
    score=$(jq -r '.score' "$vf" | tr -d '\r')
    verdict=$(jq -r '.verdict' "$vf" | tr -d '\r')
    expect=$(sha256_text "${gate}|${score}|${verdict}|${ah}|${model}")
    if [ "$expect" != "$vh" ]; then
        block "Gate '$gate' verdict fields were modified after it was written (verdict_hash mismatch)"
    fi

    local lines="" art want have
    while IFS=$'\t' read -r art want; do
        art=${art%$'\r'}; want=${want%$'\r'}
        [ -n "$art" ] || continue
        if [ ! -f "$PROJECT_DIR/$art" ]; then
            block "Gate '$gate' verdict is stale: artifact '$art' no longer exists"
        fi
        have=$(sha256_file "$PROJECT_DIR/$art")
        if [ "$have" != "$want" ]; then
            block "Gate '$gate' verdict is stale: artifact '$art' changed since it was evaluated - re-run the evaluator"
        fi
        lines+="${art}:${have}"$'\n'
    done < <(echo "$dg" | jq -r 'to_entries | sort_by(.key)[] | [.key, .value] | @tsv')
    if [ "$(sha256_text "$lines")" != "$ah" ]; then
        block "Gate '$gate' verdict artifact_hash does not match its recorded digests"
    fi
}

check() {
    local gate="$1"
    [ -n "$gate" ] || { usage; block "check requires a gate id"; }
    local verdict_file="$EVAL_DIR/${gate}-verdict.json"

    if [ ! -f "$verdict_file" ]; then
        block "No evaluator verdict for gate '$gate' - independent evaluation is required (A003). Expected: $verdict_file"
    fi

    if ! command -v jq >/dev/null 2>&1; then
        warn "jq not found - cannot validate verdict; allowing (permissive without jq)"
        timer_end
        exit 0
    fi

    if ! jq empty "$verdict_file" >/dev/null 2>&1; then
        block "Evaluator verdict for gate '$gate' is not valid JSON: $verdict_file"
    fi

    verify_integrity "$gate" "$verdict_file"

    local score verdict notes
    score=$(jq -r '.score // empty' "$verdict_file")
    verdict=$(jq -r '.verdict // empty' "$verdict_file")
    notes=$(jq -r '.notes // ""' "$verdict_file")

    if [ -z "$score" ] || [ -z "$verdict" ]; then
        block "Evaluator verdict for gate '$gate' missing required field(s) score/verdict"
    fi

    # Record the verdict to telemetry (evaluator_verdict event type).
    if [ -f "$LOG_EVENT" ]; then
        bash "$LOG_EVENT" evaluator_verdict gate="$gate" score="$score" \
            verdict="$verdict" evaluator="gate-evaluator" >/dev/null 2>&1 || true
    fi

    case "$verdict" in
        fail)
            block "Gate '$gate' evaluator verdict: FAIL (score $score) - $notes"
            ;;
        warn)
            warn "Gate '$gate' evaluator verdict: WARN (score $score) - $notes"
            ;;
        pass) : ;;
        *)
            block "Gate '$gate' evaluator verdict has unknown value '$verdict' (expected pass|fail|warn)"
            ;;
    esac

    # Threshold check (float-safe via awk; no bc on Git Bash).
    if awk -v s="$score" -v t="$THRESHOLD" 'BEGIN{exit !((s+0) < (t+0))}'; then
        block "Gate '$gate' score $score is below threshold $THRESHOLD - $notes"
    fi

    info "Gate '$gate' evaluator verdict: $verdict (score $score >= $THRESHOLD)"
    timer_end
    exit 0
}

main() {
    local gate=""
    case "${1:-}" in
        --prepare) shift; gate="${1:-}"; shift || true; prepare "$gate" "$@" ;;
        --check)   shift; gate="${1:-}"; check "$gate" ;;
        "" )       # As a gate pre-hook: gate-engine verify exports MERIDIAN_GATE_ID
                   [ -n "${MERIDIAN_GATE_ID:-}" ] || { usage; block "a gate id is required"; }
                   check "$MERIDIAN_GATE_ID" ;;
        *)         gate="$1"; check "$gate" ;;   # bare gate id -> check
    esac
}

main "$@"
