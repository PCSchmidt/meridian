#!/bin/bash
# test-gate-enforcement.sh
# Tests for Meridian gate-enforcement hooks (Gate 2.2)
#
# Covers the five gate-transition validators and the gate-engine `verify`
# command:
#   - validate-contract.sh / validate-spec.sh / validate-roadmap.sh
#   - run-tests.sh
#   - run-evaluator.sh (generator-evaluator separation, A003)
#   - gate-engine.sh verify <gate>  (runs hooks.pre, blocks on failure)
#
# Convention under test: exit 0 = allow, exit 2 = block.

set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export MERIDIAN_PROJECT_DIR="$PROJECT_DIR"
HOOKS="$PROJECT_DIR/.claude/hooks"
ENGINE="$PROJECT_DIR/scripts/gate-engine.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
TESTS_RUN=0; TESTS_PASSED=0; TESTS_FAILED=0
pass() { echo -e "${GREEN}✓${NC} $1"; TESTS_PASSED=$((TESTS_PASSED+1)); TESTS_RUN=$((TESTS_RUN+1)); }
fail() { echo -e "${RED}✗${NC} $1"; TESTS_FAILED=$((TESTS_FAILED+1)); TESTS_RUN=$((TESTS_RUN+1)); }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Run a hook, echo its exit code (guards set -e)
rc_of() { local rc=0; "$@" >/dev/null 2>&1 || rc=$?; echo "$rc"; }

#######################################
# validate-contract.sh
#######################################
test_contract_missing() {
    echo ""; echo "Test: validate-contract blocks on missing file"
    local rc; rc=$(rc_of bash "$HOOKS/validate-contract.sh" "$WORK/nope.md")
    [ "$rc" -eq 2 ] && pass "Missing CONTRACT.md blocked (exit 2)" || fail "Expected 2, got $rc"
}

test_contract_good() {
    echo ""; echo "Test: validate-contract passes a complete contract"
    printf '# Contract\n\n## Purpose\nBuild X for users, clearly and well.\n\n## Scope\n- a\n- b\n\n## Out of Scope\nnone\n\n## Deployment\nvercel\n' > "$WORK/CONTRACT.md"
    local rc; rc=$(rc_of bash "$HOOKS/validate-contract.sh" "$WORK/CONTRACT.md")
    [ "$rc" -eq 0 ] && pass "Complete CONTRACT.md allowed (exit 0)" || fail "Expected 0, got $rc"
}

test_contract_missing_section() {
    echo ""; echo "Test: validate-contract blocks when a required section is absent"
    printf '# Contract\n\n## Overview\none\ntwo\nthree\nfour\nfive\nsix\nseven\neight\n' > "$WORK/c2.md"
    local rc; rc=$(rc_of bash "$HOOKS/validate-contract.sh" "$WORK/c2.md")
    [ "$rc" -eq 2 ] && pass "Missing required section blocked (exit 2)" || fail "Expected 2, got $rc"
}

test_contract_stub() {
    echo ""; echo "Test: validate-contract blocks a thin stub"
    printf '# Contract\n\n## Purpose\nx\n' > "$WORK/c3.md"
    local rc; rc=$(rc_of bash "$HOOKS/validate-contract.sh" "$WORK/c3.md")
    [ "$rc" -eq 2 ] && pass "Thin stub blocked (exit 2)" || fail "Expected 2, got $rc"
}

#######################################
# validate-spec.sh
#######################################
test_spec_good() {
    echo ""; echo "Test: validate-spec passes a structured spec"
    printf '# Spec\n\n## Feature A\nd1\nd2\nd3\n\n## Feature B\nm1\nm2\nm3\nm4\n' > "$WORK/SPEC.md"
    local rc; rc=$(rc_of bash "$HOOKS/validate-spec.sh" "$WORK/SPEC.md")
    [ "$rc" -eq 0 ] && pass "Structured SPEC.md allowed (exit 0)" || fail "Expected 0, got $rc"
}

test_spec_missing() {
    echo ""; echo "Test: validate-spec blocks on missing file"
    local rc; rc=$(rc_of bash "$HOOKS/validate-spec.sh" "$WORK/none.md")
    [ "$rc" -eq 2 ] && pass "Missing SPEC.md blocked (exit 2)" || fail "Expected 2, got $rc"
}

test_spec_unstructured() {
    echo ""; echo "Test: validate-spec blocks a spec with no sections"
    printf '# Spec\nline\nline\nline\nline\nline\nline\nline\nline\nline\nline\n' > "$WORK/s2.md"
    local rc; rc=$(rc_of bash "$HOOKS/validate-spec.sh" "$WORK/s2.md")
    [ "$rc" -eq 2 ] && pass "Unstructured SPEC.md blocked (exit 2)" || fail "Expected 2, got $rc"
}

#######################################
# validate-roadmap.sh
#######################################
test_roadmap_real() {
    echo ""; echo "Test: validate-roadmap passes the real ROADMAP.md"
    local rc; rc=$(rc_of bash "$HOOKS/validate-roadmap.sh" "$PROJECT_DIR/ROADMAP.md")
    [ "$rc" -eq 0 ] && pass "Real ROADMAP.md allowed (exit 0)" || fail "Expected 0, got $rc"
}

test_roadmap_empty() {
    echo ""; echo "Test: validate-roadmap blocks a roadmap with no gates"
    printf '# Roadmap\n\nSome prose with no gate entries and no status markers.\n' > "$WORK/RM.md"
    local rc; rc=$(rc_of bash "$HOOKS/validate-roadmap.sh" "$WORK/RM.md")
    [ "$rc" -eq 2 ] && pass "Gate-less ROADMAP.md blocked (exit 2)" || fail "Expected 2, got $rc"
}

#######################################
# run-tests.sh
#######################################
test_runtests_pass() {
    echo ""; echo "Test: run-tests passes when bash suites pass"
    mkdir -p "$WORK/proj_ok/tests"
    printf '#!/bin/bash\nexit 0\n' > "$WORK/proj_ok/tests/test-a.sh"
    local rc; rc=$(rc_of bash "$HOOKS/run-tests.sh" "$WORK/proj_ok")
    [ "$rc" -eq 0 ] && pass "Passing suites allowed (exit 0)" || fail "Expected 0, got $rc"
}

test_runtests_fail() {
    echo ""; echo "Test: run-tests blocks when a bash suite fails"
    mkdir -p "$WORK/proj_bad/tests"
    printf '#!/bin/bash\nexit 0\n' > "$WORK/proj_bad/tests/test-a.sh"
    printf '#!/bin/bash\nexit 1\n' > "$WORK/proj_bad/tests/test-b.sh"
    local rc; rc=$(rc_of bash "$HOOKS/run-tests.sh" "$WORK/proj_bad")
    [ "$rc" -eq 2 ] && pass "Failing suite blocked (exit 2)" || fail "Expected 2, got $rc"
}

test_runtests_none() {
    echo ""; echo "Test: run-tests is non-blocking when no runner is found"
    mkdir -p "$WORK/proj_empty"
    local rc; rc=$(rc_of bash "$HOOKS/run-tests.sh" "$WORK/proj_empty")
    [ "$rc" -eq 0 ] && pass "No runner -> allowed with warning (exit 0)" || fail "Expected 0, got $rc"
}

#######################################
# run-evaluator.sh (A003)
#######################################
test_eval_no_verdict() {
    echo ""; echo "Test: run-evaluator blocks without an independent verdict"
    local rc; rc=$(EVALUATOR_DIR="$WORK/ev1" rc_of bash "$HOOKS/run-evaluator.sh" --check 2.2)
    [ "$rc" -eq 2 ] && pass "No verdict blocked (exit 2, A003)" || fail "Expected 2, got $rc"
}

test_eval_prepare() {
    echo ""; echo "Test: run-evaluator --prepare writes a request payload"
    local dir="$WORK/ev2"
    local rc; rc=$(EVALUATOR_DIR="$dir" rc_of bash "$HOOKS/run-evaluator.sh" --prepare 2.2 foo.sh)
    if [ "$rc" -eq 0 ] && [ -f "$dir/2.2-request.json" ]; then
        pass "Request payload written (exit 0)"
    else
        fail "Expected request file + exit 0 (got $rc)"
    fi
}

test_eval_pass() {
    echo ""; echo "Test: run-evaluator allows a passing verdict above threshold"
    local dir="$WORK/ev3"; mkdir -p "$dir"
    echo '{"gate":"2.2","score":8.5,"verdict":"pass","notes":"good"}' > "$dir/2.2-verdict.json"
    local rc; rc=$(EVALUATOR_DIR="$dir" rc_of bash "$HOOKS/run-evaluator.sh" --check 2.2)
    [ "$rc" -eq 0 ] && pass "Passing verdict allowed (exit 0)" || fail "Expected 0, got $rc"
}

test_eval_fail() {
    echo ""; echo "Test: run-evaluator blocks a fail verdict"
    local dir="$WORK/ev4"; mkdir -p "$dir"
    echo '{"gate":"2.2","score":3,"verdict":"fail","notes":"gaps"}' > "$dir/2.2-verdict.json"
    local rc; rc=$(EVALUATOR_DIR="$dir" rc_of bash "$HOOKS/run-evaluator.sh" --check 2.2)
    [ "$rc" -eq 2 ] && pass "Fail verdict blocked (exit 2)" || fail "Expected 2, got $rc"
}

test_eval_below_threshold() {
    echo ""; echo "Test: run-evaluator blocks a pass verdict below threshold"
    local dir="$WORK/ev5"; mkdir -p "$dir"
    echo '{"gate":"2.2","score":6.5,"verdict":"pass","notes":"meh"}' > "$dir/2.2-verdict.json"
    local rc; rc=$(EVALUATOR_DIR="$dir" rc_of bash "$HOOKS/run-evaluator.sh" --check 2.2)
    [ "$rc" -eq 2 ] && pass "Below-threshold score blocked (exit 2)" || fail "Expected 2, got $rc"
}

#######################################
# gate-engine.sh verify
#######################################
setup_verify_fixture() {
    local root="$WORK/gp"
    mkdir -p "$root/.meridian" "$root/.claude/hooks" "$root/scripts"
    printf '#!/bin/bash\nexit 0\n' > "$root/.claude/hooks/pass-hook.sh"
    printf '#!/bin/bash\nexit 2\n' > "$root/.claude/hooks/fail-hook.sh"
    # reuse the real log-event.sh so telemetry calls do not error
    cp "$PROJECT_DIR/scripts/log-event.sh" "$root/scripts/log-event.sh" 2>/dev/null || true
    cat > "$root/.meridian/gates.yaml" <<'YAML'
version: "1.0"
project:
  name: "fixture"
  recipe: "cli-tool"
gates:
  - id: clean_gate
    type: automated
    requires: []
    hooks:
      pre:
        - pass-hook.sh
  - id: blocked_gate
    type: automated
    requires: []
    hooks:
      pre:
        - pass-hook.sh
        - fail-hook.sh
YAML
    echo "$root"
}

test_verify_clean() {
    echo ""; echo "Test: gate-engine verify passes a clean gate"
    local root; root=$(setup_verify_fixture)
    local rc; rc=$(MERIDIAN_PROJECT_DIR="$root" rc_of bash "$ENGINE" verify clean_gate)
    [ "$rc" -eq 0 ] && pass "Clean gate verified (exit 0)" || fail "Expected 0, got $rc"
}

test_verify_blocked() {
    echo ""; echo "Test: gate-engine verify blocks a gate with a failing pre-hook"
    local root; root=$(setup_verify_fixture)
    local rc; rc=$(MERIDIAN_PROJECT_DIR="$root" rc_of bash "$ENGINE" verify blocked_gate)
    [ "$rc" -eq 2 ] && pass "Gate with failing pre-hook blocked (exit 2)" || fail "Expected 2, got $rc"
}

#######################################
# Runner
#######################################
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Meridian Gate Enforcement Tests (Gate 2.2)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    test_contract_missing
    test_contract_good
    test_contract_missing_section
    test_contract_stub
    test_spec_good
    test_spec_missing
    test_spec_unstructured
    test_roadmap_real
    test_roadmap_empty
    test_runtests_pass
    test_runtests_fail
    test_runtests_none
    test_eval_no_verdict
    test_eval_prepare
    test_eval_pass
    test_eval_fail
    test_eval_below_threshold
    test_verify_clean
    test_verify_blocked

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Results: $TESTS_PASSED/$TESTS_RUN passed"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"; exit 0
    else
        echo -e "${RED}$TESTS_FAILED test(s) failed${NC}"; exit 1
    fi
}

main "$@"
