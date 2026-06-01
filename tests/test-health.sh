#!/bin/bash
# test-health.sh
# Tests for Meridian's Gate 1.5 Health Report

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export MERIDIAN_PROJECT_DIR="$PROJECT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

pass() { echo -e "${GREEN}✓${NC} $1"; TESTS_PASSED=$((TESTS_PASSED+1)); TESTS_RUN=$((TESTS_RUN+1)); }
fail() { echo -e "${RED}✗${NC} $1"; TESTS_FAILED=$((TESTS_FAILED+1)); TESTS_RUN=$((TESTS_RUN+1)); }

HEALTH_SCRIPT="$PROJECT_DIR/scripts/health-report.sh"

# ─── Tests ───────────────────────────────────────────────────────────────────

test_full_report_succeeds() {
    echo ""
    echo "Test: health-report.sh full runs without error"

    if bash "$HEALTH_SCRIPT" full >/dev/null 2>&1; then
        pass "health-report.sh full succeeded"
    else
        fail "health-report.sh full failed with non-zero exit"
    fi
}

test_full_report_has_sections() {
    echo ""
    echo "Test: full report contains all four section headers"

    local output
    output=$(bash "$HEALTH_SCRIPT" full 2>/dev/null)

    local missing=""
    echo "$output" | grep -q "Session"      || missing="${missing}Session "
    echo "$output" | grep -q "Gate Calibration" || missing="${missing}GateCalibration "
    echo "$output" | grep -q "Memory Health"  || missing="${missing}MemoryHealth "
    echo "$output" | grep -q "Telemetry"     || missing="${missing}Telemetry "

    if [ -z "$missing" ]; then
        pass "All four sections present in full report"
    else
        fail "Missing sections: $missing"
    fi
}

test_gates_section_shows_corrections() {
    echo ""
    echo "Test: gates section shows data from corrections.jsonl"

    local output
    output=$(bash "$HEALTH_SCRIPT" gates 2>/dev/null)

    # corrections.jsonl has gate 1.1 through 1.4
    if echo "$output" | grep -q "1.1"; then
        pass "gates section shows gate data from corrections.jsonl"
    else
        fail "gates section did not show gate 1.1 data"
    fi
}

test_gates_shows_operator_multiplier() {
    echo ""
    echo "Test: gates section shows operator multiplier"

    local output
    output=$(bash "$HEALTH_SCRIPT" gates 2>/dev/null)

    if echo "$output" | grep -q "operator mult"; then
        pass "gates section shows operator multiplier"
    else
        fail "operator multiplier not shown in gates output"
    fi
}

test_gates_shows_calibration_assessment() {
    echo ""
    echo "Test: gates section shows calibration assessment"

    local output
    output=$(bash "$HEALTH_SCRIPT" gates 2>/dev/null)

    if echo "$output" | grep -q "Calibration:"; then
        pass "gates section shows calibration assessment"
    else
        fail "calibration assessment not shown"
    fi
}

test_memory_section_shows_patterns() {
    echo ""
    echo "Test: memory section shows semantic pattern count"

    local output
    output=$(bash "$HEALTH_SCRIPT" memory 2>/dev/null)

    if echo "$output" | grep -q "Semantic patterns"; then
        pass "memory section shows semantic pattern count"
    else
        fail "memory section did not show pattern data"
    fi
}

test_memory_section_shows_corrections_count() {
    echo ""
    echo "Test: memory section shows corrections entry count"

    local output
    output=$(bash "$HEALTH_SCRIPT" memory 2>/dev/null)

    if echo "$output" | grep -q "Corrections"; then
        pass "memory section shows corrections count"
    else
        fail "memory section did not show corrections count"
    fi
}

test_telemetry_section_succeeds() {
    echo ""
    echo "Test: telemetry section runs without error"

    if bash "$HEALTH_SCRIPT" telemetry >/dev/null 2>&1; then
        pass "telemetry section succeeded"
    else
        fail "telemetry section failed"
    fi
}

test_json_output_valid() {
    echo ""
    echo "Test: --json outputs valid JSON"

    local output
    output=$(bash "$HEALTH_SCRIPT" --json 2>/dev/null)

    if echo "$output" | jq empty 2>/dev/null; then
        pass "--json outputs valid JSON"
    else
        fail "--json output is not valid JSON: $output"
    fi
}

test_json_has_calibration_field() {
    echo ""
    echo "Test: JSON output has calibration.avg_operator_multiplier"

    local output
    output=$(bash "$HEALTH_SCRIPT" --json 2>/dev/null)

    local has_field
    has_field=$(echo "$output" | jq 'has("calibration")' 2>/dev/null || echo "false")

    if [ "$has_field" = "true" ]; then
        pass "JSON output has calibration field"
    else
        fail "JSON output missing calibration field"
    fi
}

test_json_has_required_top_level_fields() {
    echo ""
    echo "Test: JSON output has project, timestamp, session_id fields"

    local output
    output=$(bash "$HEALTH_SCRIPT" --json 2>/dev/null)

    local has_project has_timestamp has_session
    has_project=$(echo "$output" | jq 'has("project")' 2>/dev/null || echo "false")
    has_timestamp=$(echo "$output" | jq 'has("timestamp")' 2>/dev/null || echo "false")
    has_session=$(echo "$output" | jq 'has("session_id")' 2>/dev/null || echo "false")

    if [ "$has_project" = "true" ] && [ "$has_timestamp" = "true" ] && [ "$has_session" = "true" ]; then
        pass "JSON output has all required top-level fields"
    else
        fail "JSON missing fields: project=$has_project timestamp=$has_timestamp session_id=$has_session"
    fi
}

test_json_calibration_is_numeric() {
    echo ""
    echo "Test: JSON calibration.avg_operator_multiplier is a number (not null) when corrections exist"

    local output
    output=$(bash "$HEALTH_SCRIPT" --json 2>/dev/null)

    local mult_type
    mult_type=$(echo "$output" | jq '.calibration.avg_operator_multiplier | type' 2>/dev/null || echo '"null"')

    if [ "$mult_type" = '"number"' ]; then
        pass "avg_operator_multiplier is numeric"
    else
        fail "avg_operator_multiplier has wrong type: $mult_type (expected \"number\")"
    fi
}

# ─── Runner ──────────────────────────────────────────────────────────────────

main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Meridian Health Report Tests (Gate 1.5)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    test_full_report_succeeds
    test_full_report_has_sections
    test_gates_section_shows_corrections
    test_gates_shows_operator_multiplier
    test_gates_shows_calibration_assessment
    test_memory_section_shows_patterns
    test_memory_section_shows_corrections_count
    test_telemetry_section_succeeds
    test_json_output_valid
    test_json_has_calibration_field
    test_json_has_required_top_level_fields
    test_json_calibration_is_numeric

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
