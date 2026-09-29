#!/bin/bash
# test-dogfood.sh
# Tests for dogfood measurement: session ids outside Claude Code, JSON-safe
# telemetry, hook blocks as telemetry, and scripts/dogfood.sh.

set -euo pipefail

MERIDIAN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

pass() { echo -e "${GREEN}✓${NC} $1"; TESTS_PASSED=$((TESTS_PASSED+1)); TESTS_RUN=$((TESTS_RUN+1)); }
fail() { echo -e "${RED}✗${NC} $1"; TESTS_FAILED=$((TESTS_FAILED+1)); TESTS_RUN=$((TESTS_RUN+1)); }

# Fresh throwaway project with just the pieces under test.
new_project() {
    local dir
    dir=$(mktemp -d)
    mkdir -p "$dir/.meridian" "$dir/scripts" "$dir/.claude/hooks"
    cp "$MERIDIAN_DIR/scripts/log-event.sh" "$MERIDIAN_DIR/scripts/dogfood.sh" "$dir/scripts/"
    cp "$MERIDIAN_DIR/.claude/hooks/hook-wrapper.sh" "$dir/.claude/hooks/"
    # Installed session.json has no session_id (the HPI state).
    echo '{"project":"demo","installed_at":"2026-01-01T00:00:00Z"}' > "$dir/.meridian/session.json"
    echo "$dir"
}

log_event() { MERIDIAN_PROJECT_DIR="$1" bash "$1/scripts/log-event.sh" "${@:2}" >/dev/null 2>&1; }
dogfood() { MERIDIAN_PROJECT_DIR="$1" bash "$1/scripts/dogfood.sh" "${@:2}"; }

# Run block() from the hook wrapper in a subshell, as a real hook would.
hook_block() {
    local dir="$1" hook="$2" reason="$3"
    ( cd "$dir" && export MERIDIAN_PROJECT_DIR="$dir" && source .claude/hooks/hook-wrapper.sh >/dev/null 2>&1 \
        && HOOK_NAME="$hook" && block "$reason" ) >/dev/null 2>&1 || true
}

test_session_id_created_outside_claude_code() {
    echo ""
    echo "Test: events outside a Claude Code session get a real, persisted session id"
    local p
    p=$(new_project)
    log_event "$p" tool_used tool=meridian-verify outcome=passed
    log_event "$p" tool_used tool=meridian-verify outcome=passed
    local ids
    ids=$(jq -r '.session_id' "$p/.meridian/telemetry.jsonl" | sort -u)
    if [ "$(echo "$ids" | wc -l)" -eq 1 ] && [[ "$ids" =~ ^[a-f0-9]{8}$ ]] && [ "$ids" != "00000000" ]; then
        pass "both events share one non-zero session id ($ids)"
    else
        fail "expected one non-zero 8-hex session id, got: $ids"
    fi
    if [ "$(jq -r '.session_id' "$p/.meridian/session.json")" = "$ids" ] && [ "$(jq -r '.installed_at' "$p/.meridian/session.json")" = "2026-01-01T00:00:00Z" ]; then
        pass "session.json keeps existing fields and records the id"
    else
        fail "session.json was not updated correctly: $(cat "$p/.meridian/session.json")"
    fi
    rm -rf "$p"
}

test_existing_session_id_reused() {
    echo ""
    echo "Test: an existing session id is used as-is"
    local p
    p=$(new_project)
    echo '{"session_id":"abcdef12","project":"demo"}' > "$p/.meridian/session.json"
    log_event "$p" session_start current_gate=x
    if [ "$(jq -r '.session_id' "$p/.meridian/telemetry.jsonl")" = "abcdef12" ]; then
        pass "event uses session abcdef12"
    else
        fail "expected abcdef12, got $(jq -r '.session_id' "$p/.meridian/telemetry.jsonl")"
    fi
    rm -rf "$p"
}

test_telemetry_escapes_awkward_strings() {
    echo ""
    echo "Test: backslashes, quotes, newlines, and brackets produce valid JSON"
    local p reason
    p=$(new_project)
    reason=$'bad "path" C:\\dev\\x\nsecond line [not an array'
    log_event "$p" error "message=$reason" recoverable=true
    if jq -e '.message' "$p/.meridian/telemetry.jsonl" >/dev/null 2>&1; then
        pass "event written and parseable"
    else
        fail "event missing or invalid: $(cat "$p/.meridian/telemetry.jsonl" 2>/dev/null)"
    fi
    # Compare inside jq: Windows jq -r rewrites embedded \n as \r\n on stdout.
    if jq -e --arg r "$reason" '.message == $r' "$p/.meridian/telemetry.jsonl" >/dev/null 2>&1; then
        pass "message round-trips exactly"
    else
        fail "message changed: $(jq -r '.message' "$p/.meridian/telemetry.jsonl")"
    fi
    log_event "$p" tool_used 'artifacts=["a.md","b.md"]'
    if [ "$(jq -r 'select(.event_type=="tool_used") | .artifacts | type' "$p/.meridian/telemetry.jsonl")" = "array" ]; then
        pass "real JSON arrays still pass through as arrays"
    else
        fail "JSON array value was not preserved"
    fi
    rm -rf "$p"
}

test_hook_block_logs_telemetry() {
    echo ""
    echo "Test: a hook block() still exits 2 and now writes a hook_blocked event"
    local p rc=0
    p=$(new_project)
    ( cd "$p" && export MERIDIAN_PROJECT_DIR="$p" && source .claude/hooks/hook-wrapper.sh >/dev/null 2>&1 \
        && HOOK_NAME=validate-contract && block "CONTRACT.md missing required section(s): Purpose" ) >/dev/null 2>&1 || rc=$?
    if [ "$rc" -eq 2 ]; then pass "block() exit code is still 2"; else fail "block() exited $rc, expected 2"; fi
    if jq -e 'select(.event_type=="hook_blocked" and .hook=="validate-contract")' "$p/.meridian/telemetry.jsonl" >/dev/null 2>&1; then
        pass "hook_blocked event recorded with hook name"
    else
        fail "no hook_blocked event: $(cat "$p/.meridian/telemetry.jsonl" 2>/dev/null)"
    fi
    if grep -q "\[BLOCK\] \[validate-contract\]" "$p/.meridian/hooks.log"; then
        pass "hooks.log still records the block"
    else
        fail "hooks.log lost the block line"
    fi
    rm -rf "$p"
}

test_stops_exclude_engine_duplicates() {
    echo ""
    echo "Test: stops = hook blocks + verify blocks; gate-engine duplicates are ignored"
    local p out
    p=$(new_project)
    log_event "$p" gate_blocked gate=verify "reason=meridian-verify: 1 blocking issue(s)"
    hook_block "$p" run-tests "2 tests failing"
    log_event "$p" gate_blocked gate=tests_passing "reason=pre-hook run-tests.sh failed"
    log_event "$p" tool_used tool=meridian-verify outcome=passed
    out=$(dogfood "$p" stops)
    if [ "$(echo "$out" | wc -l)" -eq 2 ] && echo "$out" | grep -q "verify" && echo "$out" | grep -q "hook:run-tests"; then
        pass "two stops listed (verify, hook:run-tests)"
    else
        fail "unexpected stops listing: $out"
    fi
    rm -rf "$p"
}

test_label_escape_overhead_report() {
    echo ""
    echo "Test: labels, escapes, overhead, and the report numbers"
    local p out
    p=$(new_project)
    hook_block "$p" validate-contract "missing Purpose"
    hook_block "$p" run-tests "flaky test"
    hook_block "$p" run-evaluator "score 5.0 below threshold"
    dogfood "$p" label 1 real "contract really was incomplete" >/dev/null
    dogfood "$p" label 2 false_alarm "flaky, unrelated" >/dev/null
    dogfood "$p" escape "table typo missed" --gate inventory_verified --severity high >/dev/null
    dogfood "$p" overhead 1.5 "gate setup" >/dev/null
    dogfood "$p" overhead 0.5 >/dev/null

    out=$(dogfood "$p" stops --unlabeled)
    if [ "$(echo "$out" | wc -l)" -eq 1 ] && echo "$out" | grep -q "run-evaluator"; then
        pass "--unlabeled shows only the remaining stop"
    else
        fail "unexpected unlabeled listing: $out"
    fi

    out=$(dogfood "$p" report --md)
    echo "$out" | grep -q "| Stops (blocks) | 3 |" && pass "report counts 3 stops" || fail "stop count wrong: $out"
    echo "$out" | grep -q "| Labelled real / false alarm / unclear | 1 / 1 / 0 |" && pass "report splits labels" || fail "label split wrong"
    echo "$out" | grep -q "| Precision (real ÷ real+false alarm) | 50% |" && pass "precision is 50%" || fail "precision wrong"
    echo "$out" | grep -q "| Escapes (missed by the gates) | 1 |" && pass "one escape" || fail "escape count wrong"
    echo "$out" | grep -q "| Overhead hours | 2 |" && pass "overhead sums to 2h" || fail "overhead wrong"

    # Relabelling: latest label wins.
    dogfood "$p" label 2 real "turned out to be real" >/dev/null
    out=$(dogfood "$p" report --md)
    echo "$out" | grep -q "| Labelled real / false alarm / unclear | 2 / 0 / 0 |" && pass "relabel replaces the earlier label" || fail "relabel not applied"

    # Labels stand alone after telemetry is gone.
    rm -f "$p/.meridian/telemetry.jsonl"
    out=$(dogfood "$p" report --md)
    echo "$out" | grep -q "| Labelled real / false alarm / unclear | 2 / 0 / 0 |" && pass "labels survive telemetry rotation" || fail "labels lost without telemetry"
    rm -rf "$p"
}

test_bad_input_rejected() {
    echo ""
    echo "Test: invalid commands are rejected"
    local p
    p=$(new_project)
    hook_block "$p" run-tests "x"
    if ! dogfood "$p" label 1 maybe >/dev/null 2>&1; then pass "bad label value rejected"; else fail "accepted label 'maybe'"; fi
    if ! dogfood "$p" label 9 real >/dev/null 2>&1; then pass "unknown stop number rejected"; else fail "accepted stop #9"; fi
    if ! dogfood "$p" overhead lots >/dev/null 2>&1; then pass "non-numeric hours rejected"; else fail "accepted hours 'lots'"; fi
    if [ ! -f "$p/.meridian/dogfood.jsonl" ]; then pass "nothing written on bad input"; else fail "dogfood.jsonl written on bad input"; fi
    rm -rf "$p"
}

main() {
    echo "━━━ Meridian dogfood measurement tests ━━━"
    test_session_id_created_outside_claude_code
    test_existing_session_id_reused
    test_telemetry_escapes_awkward_strings
    test_hook_block_logs_telemetry
    test_stops_exclude_engine_duplicates
    test_label_escape_overhead_report
    test_bad_input_rejected
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Tests run: $TESTS_RUN | Passed: $TESTS_PASSED | Failed: $TESTS_FAILED"
    [ "$TESTS_FAILED" -eq 0 ]
}

main "$@"
