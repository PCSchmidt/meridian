#!/bin/bash
# test-telemetry.sh
# Tests for Meridian's Gate 1.4 Telemetry System

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export MERIDIAN_PROJECT_DIR="$PROJECT_DIR"

# Use a temp telemetry file for tests
TEST_TELEMETRY="$PROJECT_DIR/.meridian/telemetry_test.jsonl"
export MERIDIAN_TEST_TELEMETRY="$TEST_TELEMETRY"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

pass() { echo -e "${GREEN}✓${NC} $1"; TESTS_PASSED=$((TESTS_PASSED+1)); TESTS_RUN=$((TESTS_RUN+1)); }
fail() { echo -e "${RED}✗${NC} $1"; TESTS_FAILED=$((TESTS_FAILED+1)); TESTS_RUN=$((TESTS_RUN+1)); }

setup() {
    rm -f "$TEST_TELEMETRY"
    # Redirect telemetry to test file
    ln -sf "$TEST_TELEMETRY" "$PROJECT_DIR/.meridian/telemetry.jsonl" 2>/dev/null || true
}

teardown() {
    rm -f "$TEST_TELEMETRY"
    # Remove symlink and restore real file if needed
    if [ -L "$PROJECT_DIR/.meridian/telemetry.jsonl" ]; then
        rm -f "$PROJECT_DIR/.meridian/telemetry.jsonl"
    fi
}

# ─── Tests ───────────────────────────────────────────────────────────────────

test_log_event_creates_file() {
    echo ""
    echo "Test: log-event.sh creates telemetry file"
    rm -f "$PROJECT_DIR/.meridian/telemetry.jsonl"

    bash "$PROJECT_DIR/scripts/log-event.sh" session_start current_gate=1.4 >/dev/null 2>&1

    if [ -f "$PROJECT_DIR/.meridian/telemetry.jsonl" ]; then
        pass "log-event.sh created telemetry.jsonl"
    else
        fail "telemetry.jsonl not created"
    fi
}

test_log_event_valid_json() {
    echo ""
    echo "Test: log-event.sh writes valid JSON"

    bash "$PROJECT_DIR/scripts/log-event.sh" gate_passed gate=1.4 predicted_hours=6 actual_hours=6 >/dev/null 2>&1

    local last_line
    last_line=$(tail -1 "$PROJECT_DIR/.meridian/telemetry.jsonl")

    if echo "$last_line" | jq empty 2>/dev/null; then
        pass "log-event.sh writes valid JSON"
    else
        fail "log-event.sh wrote invalid JSON: $last_line"
    fi
}

test_log_event_has_required_fields() {
    echo ""
    echo "Test: telemetry event has required fields"

    bash "$PROJECT_DIR/scripts/log-event.sh" tool_used tool=Edit hook=PostToolUse outcome=allowed >/dev/null 2>&1

    local last_line
    last_line=$(tail -1 "$PROJECT_DIR/.meridian/telemetry.jsonl")

    local has_timestamp has_event_type has_session has_project
    has_timestamp=$(echo "$last_line" | jq 'has("timestamp")')
    has_event_type=$(echo "$last_line" | jq 'has("event_type")')
    has_session=$(echo "$last_line" | jq 'has("session_id")')
    has_project=$(echo "$last_line" | jq 'has("project")')

    if [ "$has_timestamp" = "true" ] && [ "$has_event_type" = "true" ] && \
       [ "$has_session" = "true" ] && [ "$has_project" = "true" ]; then
        pass "All required fields present"
    else
        fail "Missing required fields: timestamp=$has_timestamp event_type=$has_event_type session=$has_session project=$has_project"
    fi
}

test_log_event_numeric_values() {
    echo ""
    echo "Test: log-event.sh handles numeric values correctly"

    bash "$PROJECT_DIR/scripts/log-event.sh" gate_passed gate=1.4 predicted_hours=6 actual_hours=5.5 >/dev/null 2>&1

    local last_line
    last_line=$(tail -1 "$PROJECT_DIR/.meridian/telemetry.jsonl")

    local predicted actual
    predicted=$(echo "$last_line" | jq '.predicted_hours')
    actual=$(echo "$last_line" | jq '.actual_hours')

    if [ "$predicted" = "6" ] && [ "$actual" = "5.5" ]; then
        pass "Numeric values stored correctly (predicted=$predicted, actual=$actual)"
    else
        fail "Numeric values wrong: predicted=$predicted actual=$actual"
    fi
}

test_session_creates_session_file() {
    echo ""
    echo "Test: session.sh start creates session.json"
    rm -f "$PROJECT_DIR/.meridian/session.json"

    bash "$PROJECT_DIR/scripts/session.sh" start project=test-project >/dev/null 2>&1

    if [ -f "$PROJECT_DIR/.meridian/session.json" ]; then
        pass "session.json created"
    else
        fail "session.json not created"
    fi
}

test_session_id_consistent() {
    echo ""
    echo "Test: session.sh id returns consistent ID"

    bash "$PROJECT_DIR/scripts/session.sh" start project=test-project >/dev/null 2>&1

    local id1 id2
    id1=$(bash "$PROJECT_DIR/scripts/session.sh" id)
    id2=$(bash "$PROJECT_DIR/scripts/session.sh" id)

    if [ "$id1" = "$id2" ] && [ -n "$id1" ]; then
        pass "Session ID consistent: $id1"
    else
        fail "Session ID inconsistent: '$id1' vs '$id2'"
    fi
}

test_telemetry_query_summary() {
    echo ""
    echo "Test: telemetry-query.sh summary runs without error"

    if bash "$PROJECT_DIR/scripts/telemetry-query.sh" summary >/dev/null 2>&1; then
        pass "telemetry-query.sh summary succeeded"
    else
        fail "telemetry-query.sh summary failed"
    fi
}

test_telemetry_query_gates() {
    echo ""
    echo "Test: telemetry-query.sh gates shows gate_passed event"

    bash "$PROJECT_DIR/scripts/log-event.sh" gate_passed gate=TEST predicted_hours=1 actual_hours=1 >/dev/null 2>&1

    local output
    output=$(bash "$PROJECT_DIR/scripts/telemetry-query.sh" gates 2>/dev/null)

    if echo "$output" | grep -q "gate=TEST"; then
        pass "telemetry-query.sh gates shows logged gate"
    else
        fail "Gate event not visible in query output"
    fi
}

# ─── Runner ──────────────────────────────────────────────────────────────────

main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Meridian Telemetry System Tests (Gate 1.4)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    test_log_event_creates_file
    test_log_event_valid_json
    test_log_event_has_required_fields
    test_log_event_numeric_values
    test_session_creates_session_file
    test_session_id_consistent
    test_telemetry_query_summary
    test_telemetry_query_gates

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Results: $TESTS_PASSED/$TESTS_RUN passed"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}$TESTS_FAILED test(s) failed${NC}"
        exit 1
    fi
}

main "$@"
