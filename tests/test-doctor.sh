#!/bin/bash
# test-doctor.sh
# Tests for scripts/meridian-doctor.sh (Meridian installation validator, G5.0)
#
# Tests:
# - Script runs and emits all report sections
# - Dependency checks run (jq/yq surfaced regardless of presence)
# - Missing .meridian/ is reported CRITICAL with non-zero exit
# - A present gates.yaml is detected (branch differs by yq availability)
# - The healthy repo passes structure/hook/memory checks

set -euo pipefail

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCTOR="$PROJECT_DIR/scripts/meridian-doctor.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Temp fixtures (cleaned on exit)
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

pass() {
    echo -e "${GREEN}✓${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
}

# Run the doctor against a project dir; capture combined output and exit code.
# Sets DOCTOR_OUT and DOCTOR_RC. Never aborts the suite (set -e safe).
run_doctor() {
    local dir="$1"
    DOCTOR_OUT="$(MERIDIAN_PROJECT_DIR="$dir" bash "$DOCTOR" 2>&1)" && DOCTOR_RC=0 || DOCTOR_RC=$?
}

#######################################
# Test: script exists and is runnable
#######################################
test_script_exists() {
    echo ""
    echo "Test: meridian-doctor.sh exists"
    if [ -f "$DOCTOR" ]; then
        pass "meridian-doctor.sh present"
    else
        fail "meridian-doctor.sh missing at $DOCTOR"
    fi
}

#######################################
# Test: all report sections are emitted
#######################################
test_reports_sections() {
    echo ""
    echo "Test: report emits all sections"
    run_doctor "$PROJECT_DIR"

    local section ok=1
    for section in "Dependencies" "Project Structure" "Gate Configuration" "Hook Integrity" "Memory Integrity"; do
        if ! echo "$DOCTOR_OUT" | grep -q "$section"; then
            fail "report missing section: $section"
            ok=0
        fi
    done
    [ "$ok" -eq 1 ] && pass "all five report sections present"
}

#######################################
# Test: dependency checks run (jq + yq surfaced)
#######################################
test_dependency_checks() {
    echo ""
    echo "Test: dependency checks surface jq and yq"
    run_doctor "$PROJECT_DIR"

    if echo "$DOCTOR_OUT" | grep -q "jq"; then
        pass "jq dependency reported"
    else
        fail "jq dependency not reported"
    fi

    # yq is either "present" or "not found" — either way it must be surfaced,
    # never silently skipped (the whole point of G5.0).
    if echo "$DOCTOR_OUT" | grep -qi "yq"; then
        pass "yq dependency surfaced (present or missing)"
    else
        fail "yq dependency not surfaced"
    fi
}

#######################################
# Test: missing .meridian/ is CRITICAL and exits non-zero
#######################################
test_missing_meridian_is_critical() {
    echo ""
    echo "Test: missing .meridian/ reported CRITICAL"
    local empty="$TMP_ROOT/empty"
    mkdir -p "$empty"
    run_doctor "$empty"

    if [ "$DOCTOR_RC" -ne 0 ]; then
        pass "non-zero exit on missing .meridian/ (rc=$DOCTOR_RC)"
    else
        fail "expected non-zero exit on missing .meridian/, got 0"
    fi

    if echo "$DOCTOR_OUT" | grep -q "not found"; then
        pass "reports .meridian/ not found"
    else
        fail "did not report missing .meridian/"
    fi
}

#######################################
# Test: a present gates.yaml is detected (branch depends on yq)
#######################################
test_gates_yaml_detected() {
    echo ""
    echo "Test: present gates.yaml is detected"
    local proj="$TMP_ROOT/proj"
    mkdir -p "$proj/.meridian"
    cp "$PROJECT_DIR/recipes/cli-tool/gates.yaml" "$proj/.meridian/gates.yaml"

    run_doctor "$proj"

    # Whichever branch runs (yq present → validates; yq missing → critical),
    # the "No .meridian/gates.yaml" note must NOT appear, and the gates file
    # must be referenced.
    if echo "$DOCTOR_OUT" | grep -q "No .meridian/gates.yaml"; then
        fail "gates.yaml present but doctor reported it missing"
    elif echo "$DOCTOR_OUT" | grep -q "gates.yaml"; then
        pass "gates.yaml detected and processed"
    else
        fail "gates.yaml not referenced in Gate Configuration"
    fi
}

#######################################
# Test: healthy repo passes structure, hooks, and memory checks
#######################################
test_repo_core_checks_pass() {
    echo ""
    echo "Test: repo passes structure/hook/memory checks"
    run_doctor "$PROJECT_DIR"

    local ok=1
    echo "$DOCTOR_OUT" | grep -q ".meridian/ present" || { fail "structure: .meridian/ not detected"; ok=0; }
    echo "$DOCTOR_OUT" | grep -q "hook-wrapper.sh guards against direct execution" || { fail "hooks: guard not detected"; ok=0; }
    echo "$DOCTOR_OUT" | grep -q "corrections memory valid" || { fail "memory: corrections not validated"; ok=0; }
    [ "$ok" -eq 1 ] && pass "structure, hook guard, and memory checks pass on the repo"
}

#######################################
# Main test runner
#######################################
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Meridian Doctor Tests (G5.0)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    test_script_exists
    test_reports_sections
    test_dependency_checks
    test_missing_meridian_is_critical
    test_gates_yaml_detected
    test_repo_core_checks_pass

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Test Results:"
    echo "  Total:  $TESTS_RUN"
    echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
    else
        echo -e "  ${GREEN}Failed: $TESTS_FAILED${NC}"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed${NC}"
        exit 1
    fi
}

main "$@"
