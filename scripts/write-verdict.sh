#!/bin/bash
# write-verdict.sh
# The sanctioned way to write an evaluator verdict (verdict integrity, Gate 2.2).
#
# Usage:
#   write-verdict.sh <gate> --model <evaluator-model-id> [--file verdict.json]
#   (verdict JSON is read from --file, or from stdin)
#
# What it does:
#   * reads the evaluator's JSON (needs a score/overall and a verdict of pass|warn|fail)
#   * reads the artifact list from .meridian/evaluator/<gate>-request.json (written by
#     `run-evaluator.sh --prepare`) and records a SHA-256 digest of every artifact
#   * records the evaluator model id (required), a timestamp, an artifact_hash over the
#     digests, and a verdict_hash over the decisive fields
#   * writes <gate>-verdict.json atomically
#
# run-evaluator.sh --check then rejects a verdict that is unsealed, whose fields were edited
# after writing, or whose artifacts have changed since evaluation (stale).
#
# HONEST BOUNDARY: this makes forgery by hand-editing, and staleness, mechanically detectable.
# It cannot prove WHO ran it: any agent that can run this script can seal a fabricated
# verdict. PreToolUse blocks direct writes to the verdict files so the script is the only path
# for tools running under Meridian's hooks, but real evaluator independence needs the verdict
# produced by a process the generator does not control (see ROADMAP: --invoke path).
#
# Exit codes: 0 written, 1 usage/validation error.

set -euo pipefail

PROJECT_DIR="${MERIDIAN_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
EVAL_DIR="${EVALUATOR_DIR:-$PROJECT_DIR/.meridian/evaluator}"

die() { echo "write-verdict: $*" >&2; exit 1; }

sha256_file() {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1
    else shasum -a 256 "$1" | cut -d' ' -f1; fi
}
sha256_text() {
    if command -v sha256sum >/dev/null 2>&1; then printf '%s' "$1" | sha256sum | cut -d' ' -f1
    else printf '%s' "$1" | shasum -a 256 | cut -d' ' -f1; fi
}

command -v jq >/dev/null 2>&1 || die "jq is required"

GATE="${1:-}"; shift || true
[ -n "$GATE" ] || die "usage: write-verdict.sh <gate> --model <id> [--file verdict.json]"
[[ "$GATE" =~ ^[A-Za-z0-9._-]+$ ]] || die "invalid gate id '$GATE'"

MODEL=""; SRC=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --model) MODEL="${2:-}"; shift 2 ;;
        --file)  SRC="${2:-}"; shift 2 ;;
        *) die "unknown argument: $1" ;;
    esac
done
[ -n "$MODEL" ] || die "--model <evaluator-model-id> is required"

if [ -n "$SRC" ]; then RAW="$(cat "$SRC")"; else RAW="$(cat)"; fi
echo "$RAW" | jq -e . >/dev/null 2>&1 || die "verdict input is not valid JSON"

SCORE="$(echo "$RAW" | jq -r '(.score // .overall) // empty')"
VERDICT="$(echo "$RAW" | jq -r '.verdict // empty')"
[ -n "$SCORE" ] && [[ "$SCORE" =~ ^[0-9]+(\.[0-9]+)?$ ]] || die "verdict needs a numeric score (or overall)"
case "$VERDICT" in pass|warn|fail) : ;; *) die "verdict must be pass|warn|fail" ;; esac

REQ="$EVAL_DIR/${GATE}-request.json"
[ -f "$REQ" ] || die "no request file $REQ (run: run-evaluator.sh --prepare $GATE <artifacts...>)"
mapfile -t ARTS < <(jq -r '.artifacts[]?' "$REQ" | tr -d '\r')
[ "${#ARTS[@]}" -gt 0 ] || die "request lists no artifacts; a verdict must be bound to specific files"

DIGESTS='{}'
LINES=""
# Sorted so the artifact_hash does not depend on listing order.
while IFS= read -r art; do
    [ -n "$art" ] || continue
    case "$art" in /*|*..*) die "artifact path must be relative to the project and not contain '..': $art" ;; esac
    [ -f "$PROJECT_DIR/$art" ] || die "artifact not found: $art"
    d="$(sha256_file "$PROJECT_DIR/$art")"
    DIGESTS="$(echo "$DIGESTS" | jq -c --arg k "$art" --arg v "$d" '. + {($k): $v}')"
    LINES+="${art}:${d}"$'\n'
done < <(printf '%s\n' "${ARTS[@]}" | LC_ALL=C sort)

ART_HASH="$(sha256_text "$LINES")"
TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
VERDICT_HASH="$(sha256_text "${GATE}|${SCORE}|${VERDICT}|${ART_HASH}|${MODEL}")"

OUT="$EVAL_DIR/${GATE}-verdict.json"
TMP="$(mktemp "$EVAL_DIR/.verdict.XXXXXX")"
echo "$RAW" | jq --arg gate "$GATE" --arg score "$SCORE" --arg model "$MODEL" --arg ts "$TS" \
    --arg ah "$ART_HASH" --arg vh "$VERDICT_HASH" --argjson dg "$DIGESTS" \
    '.gate = $gate | .score = ($score|tonumber) | .evaluator_model = $model | .written_at = $ts
     | .artifact_digests = $dg | .artifact_hash = $ah | .verdict_hash = $vh' > "$TMP"
mv "$TMP" "$OUT"

LOG_EVENT="$PROJECT_DIR/scripts/log-event.sh"
[ -f "$LOG_EVENT" ] && bash "$LOG_EVENT" verdict_written gate="$GATE" verdict="$VERDICT" score="$SCORE" \
    evaluator_model="$MODEL" >/dev/null 2>&1 || true

echo "write-verdict: sealed $OUT (gate=$GATE verdict=$VERDICT score=$SCORE model=$MODEL artifacts=${#ARTS[@]})"
