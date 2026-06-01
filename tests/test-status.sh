#!/bin/bash
# test-status.sh
# Tests for Meridian's Gate 1.6 Status Report

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

STATUS_SCRIPT="$PROJECT_DIR/scripts/status-report.sh"

# ─── Tests ───────────────────────────────────────────────────────────────────

test_full_report_succeeds() {
    echo ""
    echo "Test: status-report.sh full runs without error"

    if bash "$STATUS_SCRIPT" full >/dev/null 2>&1; then
        pass "status-report.sh full succeeded"
    else
        fail "status-report.sh full failed with non-zero exit"
    fi
}

test_full_report_shows_project() {
    echo ""
    echo "Test: full report shows project name"

    local output
    output=$(bash "$STATUS_SCRIPT" full 2>/dev/null)

    if echo "$output" | grep -q "Project:"; then
        pass "full report shows project name"
    else
        fail "project name not shown in full report"
    fi
}

test_full_report_shows_completed_gates() {
    echo ""
    echo "Test: full report shows completed gates from corrections.jsonl"

    local output
    output=$(bash "$STATUS_SCRIPT" full 2>/dev/null)

    # corrections.jsonl has gate 1.1 through 1.5
    if echo "$output" | grep -q "1.1"; then
        pass "full report shows completed gate data"
    else
        fail "completed gates not shown in full report"
    fi
}

test_full_report_shows_calibration_summary() {
    echo ""
    echo "Test: full report shows calibration summary"

    local output
    output=$(bash "$STATUS_SCRIPT" full 2>/dev/null)

    if echo "$output" | grep -q "calibration"; then
        pass "full report shows calibration summary"
    else
        fail "calibration summary not shown"
    fi
}

test_short_report_succeeds() {
    echo ""
    echo "Test: status-report.sh --short runs without error"

    if bash "$STATUS_SCRIPT" --short >/dev/null 2>&1; then
        pass "status-report.sh --short succeeded"
    else
        fail "status-report.sh --short failed"
    fi
}

test_short_report_is_one_line() {
    echo ""
    echo "Test: --short output is a single line"

    local output line_count
    output=$(bash "$STATUS_SCRIPT" --short 2>/dev/null)
    line_count=$(echo "$output" | wc -l | tr -d ' ')

    if [ "$line_count" -eq 1 ]; then
        pass "--short output is one line"
    else
        fail "--short output has $line_count lines (expected 1)"
    fi
}

test_short_report_has_gate_info() {
    echo ""
    echo "Test: --short output contains gate and calibration info"

    local output
    output=$(bash "$STATUS_SCRIPT" --short 2>/dev/null)

    if echo "$output" | grep -q "cal"; then
        pass "--short output contains calibration info"
    else
        fail "--short output missing calibration info: $output"
    fi
}

test_json_output_valid() {
    echo ""
    echo "Test: --json outputs valid JSON"

    local output
    output=$(bash "$STATUS_SCRIPT" --json 2>/dev/null)

    if echo "$output" | jq empty 2>/dev/null; then
        pass "--json outputs valid JSON"
    else
        fail "--json output is not valid JSON: $output"
    fi
}

test_json_has_required_fields() {
    echo ""
    echo "Test: JSON has project, current_gate, gates_completed fields"

    local output
    output=$(bash "$STATUS_SCRIPT" --json 2>/dev/null)

    local has_project has_gate has_count
    has_project=$(echo "$output" | jq 'has("project")' 2>/dev/null || echo "false")
    has_gate=$(echo "$output" | jq 'has("current_gate")' 2>/dev/null || echo "false")
    has_count=$(echo "$output" | jq 'has("gates_completed")' 2>/dev/null || echo "false")

    if [ "$has_project" = "true" ] && [ "$has_gate" = "true" ] && [ "$has_count" = "true" ]; then
        pass "JSON has all required fields"
    else
        fail "JSON missing fields: project=$has_project current_gate=$has_gate gates_completed=$has_count"
    fi
}

test_json_completed_gates_is_array() {
    echo ""
    echo "Test: JSON completed_gates is an array"

    local output
    output=$(bash "$STATUS_SCRIPT" --json 2>/dev/null)

    local is_array
    is_array=$(echo "$output" | jq '.completed_gates | type' 2>/dev/null || echo '"null"')

    if [ "$is_array" = '"array"' ]; then
        pass "completed_gates is an array"
    else
        fail "completed_gates is not an array: type=$is_array"
    fi
}

test_json_gates_count_matches_corrections() {
    echo ""
    echo "Test: JSON gates_completed matches corrections.jsonl line count"

    local output json_count file_count
    output=$(bash "$STATUS_SCRIPT" --json 2>/dev/null)
    json_count=$(echo "$output" | jq '.gates_completed' 2>/dev/null || echo "-1")
    file_count=$(wc -l < "$PROJECT_DIR/.meridian/memory/corrections.jsonl" | tr -d ' ')

    if [ "$json_count" -eq "$file_count" ]; then
        pass "gates_completed matches corrections.jsonl ($json_count gates)"
    else
        fail "gates_completed mismatch: JSON=$json_count file=$file_count"
    fi
}

# ─── Runner ──────────────────────────────────────────────────────────────────

main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Meridian Status Report Tests (Gate 1.6)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    test_full_report_succeeds
    test_full_report_shows_project
    test_full_report_shows_completed_gates
    test_full_report_shows_calibration_summary
    test_short_report_succeeds
    test_short_report_is_one_line
    test_short_report_has_gate_info
    test_json_output_valid
    test_json_has_required_fields
    test_json_completed_gates_is_array
    test_json_gates_count_matches_corrections

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
