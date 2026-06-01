#!/bin/bash
# test-integration-phase1.sh
# Phase 1 Integration Tests — all components working together
#
# Tests cross-component interactions, not individual units.
# Unit tests live in test-hooks.sh, test-telemetry.sh, test-health.sh, test-status.sh.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export MERIDIAN_PROJECT_DIR="$PROJECT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

pass() { echo -e "  ${GREEN}✓${NC} $1"; TESTS_PASSED=$((TESTS_PASSED+1)); TESTS_RUN=$((TESTS_RUN+1)); }
fail() { echo -e "  ${RED}✗${NC} $1"; TESTS_FAILED=$((TESTS_FAILED+1)); TESTS_RUN=$((TESTS_RUN+1)); }

section() {
    echo ""
    echo -e "${BLUE}${BOLD}── $1 ──${NC}"
}

# Temp dir for gate engine tests (isolated from real .meridian state)
GATE_TEST_DIR=""

setup_gate_test_dir() {
    GATE_TEST_DIR=$(mktemp -d)
    mkdir -p "$GATE_TEST_DIR/.meridian"
}

cleanup_gate_test_dir() {
    if [ -n "$GATE_TEST_DIR" ] && [ -d "$GATE_TEST_DIR" ]; then
        rm -rf "$GATE_TEST_DIR"
    fi
}

trap cleanup_gate_test_dir EXIT

# ─── Gate Engine ──────────────────────────────────────────────────────────────

test_gate_engine_validates_recipe() {
    setup_gate_test_dir
    cp "$PROJECT_DIR/recipes/cli-tool/gates.yaml" "$GATE_TEST_DIR/.meridian/gates.yaml"

    local result
    if MERIDIAN_PROJECT_DIR="$GATE_TEST_DIR" bash "$PROJECT_DIR/scripts/gate-engine.sh" validate >/dev/null 2>&1; then
        pass "gate engine validates cli-tool recipe gates.yaml"
    else
        fail "gate engine failed to validate a known-good gates.yaml"
    fi
}

test_gate_engine_mark_passed_creates_state() {
    setup_gate_test_dir
    cp "$PROJECT_DIR/recipes/cli-tool/gates.yaml" "$GATE_TEST_DIR/.meridian/gates.yaml"

    # mark-passed only needs jq (not yq) — always testable
    MERIDIAN_PROJECT_DIR="$GATE_TEST_DIR" bash "$PROJECT_DIR/scripts/gate-engine.sh" \
        mark-passed confirmed >/dev/null 2>&1

    local state_file="$GATE_TEST_DIR/.meridian/gate-state.json"

    if [ -f "$state_file" ] && jq empty "$state_file" 2>/dev/null; then
        local has_gate
        has_gate=$(jq '[.passed_gates[] | select(. == "confirmed")] | length' "$state_file" 2>/dev/null || echo 0)
        if [ "$has_gate" -gt 0 ]; then
            pass "gate engine mark-passed writes valid state file with gate recorded"
        else
            fail "gate 'confirmed' not found in state file after mark-passed"
        fi
    else
        fail "gate-state.json not created or is invalid JSON after mark-passed"
    fi
}

# ─── Session + Telemetry pipeline ────────────────────────────────────────────

test_session_start_logs_telemetry() {
    # Start a fresh session and verify session_start appears in telemetry
    bash "$PROJECT_DIR/scripts/session.sh" start project=integration-test >/dev/null 2>&1

    local found=false
    local all_events
    all_events=$(jq -c '.' "$PROJECT_DIR/.meridian/telemetry.jsonl" 2>/dev/null || true)

    if echo "$all_events" | grep -q '"session_start"'; then
        pass "session.sh start logs session_start event to telemetry"
    else
        fail "session_start event not found in telemetry after session.sh start"
    fi
}

test_log_event_appears_in_query() {
    # Log a distinct event and verify telemetry-query.sh can surface it
    local test_marker="integration-test-$(date +%s)"
    bash "$PROJECT_DIR/scripts/log-event.sh" error \
        "message=${test_marker}" "error_code=INT_TEST" >/dev/null 2>&1

    local query_output
    query_output=$(bash "$PROJECT_DIR/scripts/telemetry-query.sh" errors 2>/dev/null)

    if echo "$query_output" | grep -q "INT_TEST"; then
        pass "log-event.sh → telemetry-query.sh pipeline works end-to-end"
    else
        fail "event logged via log-event.sh not visible in telemetry-query.sh errors"
    fi
}

# ─── Memory system ────────────────────────────────────────────────────────────

test_memory_validation_on_real_files() {
    # validate-memory.sh should pass on the actual project memory files
    local semantic_ok episodic_ok corrections_ok
    semantic_ok=true
    episodic_ok=true
    corrections_ok=true

    bash "$PROJECT_DIR/scripts/validate-memory.sh" \
        semantic "$PROJECT_DIR/.meridian/memory/semantic.json" >/dev/null 2>&1 || semantic_ok=false

    bash "$PROJECT_DIR/scripts/validate-memory.sh" \
        episodic "$PROJECT_DIR/.meridian/memory/episodic.jsonl" >/dev/null 2>&1 || episodic_ok=false

    bash "$PROJECT_DIR/scripts/validate-memory.sh" \
        corrections "$PROJECT_DIR/.meridian/memory/corrections.jsonl" >/dev/null 2>&1 || corrections_ok=false

    if $semantic_ok && $episodic_ok && $corrections_ok; then
        pass "validate-memory.sh passes on all three real memory files"
    else
        fail "memory validation failed: semantic=$semantic_ok episodic=$episodic_ok corrections=$corrections_ok"
    fi
}

test_memory_doctor_reports_healthy() {
    # memory-doctor.sh should report no CRITICAL status
    local output
    output=$(bash "$PROJECT_DIR/scripts/memory-doctor.sh" 2>/dev/null)

    if ! echo "$output" | grep -q "CRITICAL"; then
        pass "memory-doctor.sh reports no CRITICAL issues"
    else
        fail "memory-doctor.sh reported CRITICAL status: $(echo "$output" | grep CRITICAL | head -1)"
    fi
}

# ─── Health + Status coherence ────────────────────────────────────────────────

test_health_report_shows_all_data_sources() {
    # health report should pull from session, corrections, memory, and telemetry
    local output
    output=$(bash "$PROJECT_DIR/scripts/health-report.sh" full 2>/dev/null)

    local ok=true
    echo "$output" | grep -q "Session"      || ok=false
    echo "$output" | grep -q "Gate Calibration" || ok=false
    echo "$output" | grep -q "Memory Health" || ok=false
    echo "$output" | grep -q "Telemetry"    || ok=false

    if $ok; then
        pass "health report aggregates all four data sources"
    else
        fail "health report missing one or more sections"
    fi
}

test_health_and_status_gate_count_match() {
    # gates_completed in /status JSON should equal gates_tracked in /health JSON
    local health_json status_json
    health_json=$(bash "$PROJECT_DIR/scripts/health-report.sh" --json 2>/dev/null)
    status_json=$(bash "$PROJECT_DIR/scripts/status-report.sh" --json 2>/dev/null)

    local health_count status_count
    health_count=$(echo "$health_json" | jq '.calibration.gates_tracked' 2>/dev/null || echo -1)
    status_count=$(echo "$status_json" | jq '.gates_completed' 2>/dev/null || echo -2)

    if [ "$health_count" -eq "$status_count" ] && [ "$health_count" -gt 0 ]; then
        pass "health and status agree on gate count ($health_count gates)"
    else
        fail "gate count mismatch: health=$health_count status=$status_count"
    fi
}

# ─── Runner ──────────────────────────────────────────────────────────────────

main() {
    echo ""
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}${BOLD}  Meridian Phase 1 Integration Tests (Gate 1.7)${NC}"
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    section "Gate Engine"
    test_gate_engine_validates_recipe
    test_gate_engine_mark_passed_creates_state

    section "Session → Telemetry Pipeline"
    test_session_start_logs_telemetry
    test_log_event_appears_in_query

    section "Memory System"
    test_memory_validation_on_real_files
    test_memory_doctor_reports_healthy

    section "Health + Status Coherence"
    test_health_report_shows_all_data_sources
    test_health_and_status_gate_count_match

    echo ""
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "Results: $TESTS_PASSED/$TESTS_RUN passed"
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All integration tests passed! Phase 1 complete.${NC}"
        exit 0
    else
        echo -e "${RED}$TESTS_FAILED test(s) failed${NC}"
        exit 1
    fi
}

main "$@"
