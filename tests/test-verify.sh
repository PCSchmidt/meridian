#!/bin/bash
# test-verify.sh
# Tests scripts/meridian-verify.sh — the portable enforcement boundary (G5.2).
#
# Per the G5.1 lesson, these exercise real paths end-to-end against temp project
# fixtures: a clean project passes, a broken gate DAG / invalid memory / standing
# FAIL verdict block, drift is advisory by default and blocking under opt-in, and
# an actual git pre-commit rejects a commit when verification fails.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERIFY="$REPO/scripts/meridian-verify.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
TESTS_RUN=0; TESTS_PASSED=0; TESTS_FAILED=0

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

pass() { echo -e "${GREEN}✓${NC} $1"; TESTS_PASSED=$((TESTS_PASSED+1)); TESTS_RUN=$((TESTS_RUN+1)); }
fail() { echo -e "${RED}✗${NC} $1"; TESTS_FAILED=$((TESTS_FAILED+1)); TESTS_RUN=$((TESTS_RUN+1)); }
skip() { echo -e "  ○ SKIP: $1"; }

# Create a minimal Meridian project at $1 with schemas and valid memory.
scaffold() {
    local dir="$1"
    mkdir -p "$dir/.meridian/memory"
    cp "$REPO/.meridian/"*-schema.json "$dir/.meridian/" 2>/dev/null || true
    cp "$REPO/.meridian/"*-schema.yaml "$dir/.meridian/" 2>/dev/null || true
    # a known-valid corrections file
    cp "$REPO/.meridian/memory/corrections.jsonl" "$dir/.meridian/memory/" 2>/dev/null || true
}

run_verify() {
    local dir="$1"; shift
    local rc=0
    MERIDIAN_PROJECT_DIR="$dir" bash "$VERIFY" "$@" >"$TMP_ROOT/out" 2>&1 || rc=$?
    echo "$rc"
}

#######################################
test_clean_passes() {
    echo ""; echo "Test: clean project passes (exit 0)"
    local d="$TMP_ROOT/clean"; scaffold "$d"
    cp "$REPO/recipes/cli-tool/gates.yaml" "$d/.meridian/gates.yaml"
    local rc; rc="$(run_verify "$d")"
    if [ "$rc" = "0" ]; then pass "clean project verified (exit 0)"; else fail "expected 0, got $rc ($(cat "$TMP_ROOT/out"))"; fi
}

#######################################
test_circular_gates_blocks() {
    echo ""; echo "Test: circular gate DAG blocks (exit 1)"
    if ! command -v yq >/dev/null 2>&1; then skip "yq not installed — gate DAG check requires it"; return 0; fi
    local d="$TMP_ROOT/circular"; scaffold "$d"
    cat > "$d/.meridian/gates.yaml" <<'YAML'
version: "1.0"
gates:
  - id: a
    type: automated
    requires:
      - b
  - id: b
    type: automated
    requires:
      - a
YAML
    local rc; rc="$(run_verify "$d")"
    if [ "$rc" = "1" ] && grep -q "circular" "$TMP_ROOT/out"; then
        pass "circular dependency blocked (exit 1)"
    else
        fail "expected 1 + 'circular', got $rc ($(cat "$TMP_ROOT/out"))"
    fi
}

#######################################
test_invalid_memory_blocks() {
    echo ""; echo "Test: invalid memory blocks (exit 1)"
    local d="$TMP_ROOT/badmem"; scaffold "$d"
    # corrupt corrections entry (missing required fields)
    echo '{"gate":"x"}' > "$d/.meridian/memory/corrections.jsonl"
    local rc; rc="$(run_verify "$d")"
    if [ "$rc" = "1" ] && grep -qi "memory failed" "$TMP_ROOT/out"; then
        pass "invalid memory blocked (exit 1)"
    else
        fail "expected 1 + memory failure, got $rc ($(cat "$TMP_ROOT/out"))"
    fi
}

#######################################
test_standing_fail_verdict_blocks() {
    echo ""; echo "Test: standing FAIL evaluator verdict blocks (exit 1)"
    if ! command -v jq >/dev/null 2>&1; then skip "jq not installed"; return 0; fi
    local d="$TMP_ROOT/verdict"; scaffold "$d"
    mkdir -p "$d/.meridian/evaluator"
    echo '{"gate":"2.2","score":3.0,"verdict":"fail","notes":"bad"}' > "$d/.meridian/evaluator/2.2-verdict.json"
    local rc; rc="$(run_verify "$d")"
    if [ "$rc" = "1" ] && grep -qi "FAIL verdict" "$TMP_ROOT/out"; then
        pass "standing FAIL verdict blocked (exit 1)"
    else
        fail "expected 1 + FAIL verdict, got $rc ($(cat "$TMP_ROOT/out"))"
    fi
}

#######################################
test_drift_advisory_by_default() {
    echo ""; echo "Test: drift is advisory by default (exit 0)"
    if ! command -v jq >/dev/null 2>&1; then skip "jq not installed"; return 0; fi
    local d="$TMP_ROOT/drift"; scaffold "$d"
    mkdir -p "$d/.meridian/drift"
    echo '{"alignment_score":3,"recommendation":"drifted","divergences":[],"summary":"x"}' > "$d/.meridian/drift/drift-verdict.json"
    local rc; rc="$(run_verify "$d")"
    if [ "$rc" = "0" ] && grep -qi "advisory" "$TMP_ROOT/out"; then
        pass "drift warned but did not block (exit 0)"
    else
        fail "expected 0 + advisory, got $rc ($(cat "$TMP_ROOT/out"))"
    fi
}

#######################################
test_drift_blocks_when_promoted() {
    echo ""; echo "Test: drift blocks under MERIDIAN_DRIFT_BLOCK=1 (exit 1)"
    if ! command -v jq >/dev/null 2>&1; then skip "jq not installed"; return 0; fi
    local d="$TMP_ROOT/driftblock"; scaffold "$d"
    mkdir -p "$d/.meridian/drift"
    echo '{"alignment_score":3,"recommendation":"drifted","divergences":[],"summary":"x"}' > "$d/.meridian/drift/drift-verdict.json"
    local rc=0
    MERIDIAN_PROJECT_DIR="$d" MERIDIAN_DRIFT_BLOCK=1 bash "$VERIFY" >"$TMP_ROOT/out" 2>&1 || rc=$?
    if [ "$rc" = "1" ] && grep -qi "blocking" "$TMP_ROOT/out"; then
        pass "drift blocked under opt-in (exit 1)"
    else
        fail "expected 1 + blocking, got $rc ($(cat "$TMP_ROOT/out"))"
    fi
}

#######################################
test_precommit_hook_end_to_end() {
    echo ""; echo "Test: git pre-commit rejects a failing commit (end-to-end)"
    if ! command -v git >/dev/null 2>&1; then skip "git not installed"; return 0; fi
    local d="$TMP_ROOT/gitrepo"
    mkdir -p "$d"
    git -C "$d" init -q
    scaffold "$d"
    cp -r "$REPO/scripts" "$d/scripts"
    mkdir -p "$d/.git/hooks"
    cp "$REPO/templates/pre-commit" "$d/.git/hooks/pre-commit"
    chmod +x "$d/.git/hooks/pre-commit"
    # corrupt memory so verification fails
    echo '{"gate":"x"}' > "$d/.meridian/memory/corrections.jsonl"
    echo "hello" > "$d/file.txt"
    git -C "$d" add -A
    local rc=0
    git -C "$d" -c user.email=t@t -c user.name=t commit -q -m "should be blocked" >"$TMP_ROOT/out" 2>&1 || rc=$?
    if [ "$rc" != "0" ] && [ -z "$(git -C "$d" rev-parse --verify HEAD 2>/dev/null)" ]; then
        pass "pre-commit blocked the commit (no HEAD created)"
    else
        fail "expected commit to be blocked, rc=$rc, HEAD=$(git -C "$d" rev-parse --verify HEAD 2>/dev/null || echo none)"
    fi
}

#######################################
test_precommit_hook_allows_clean() {
    echo ""; echo "Test: git pre-commit allows a clean commit (end-to-end)"
    if ! command -v git >/dev/null 2>&1; then skip "git not installed"; return 0; fi
    local d="$TMP_ROOT/gitclean"
    mkdir -p "$d"
    git -C "$d" init -q
    scaffold "$d"
    cp -r "$REPO/scripts" "$d/scripts"
    mkdir -p "$d/.git/hooks"
    cp "$REPO/templates/pre-commit" "$d/.git/hooks/pre-commit"
    chmod +x "$d/.git/hooks/pre-commit"
    echo "hello" > "$d/file.txt"
    git -C "$d" add -A
    local rc=0
    git -C "$d" -c user.email=t@t -c user.name=t commit -q -m "clean" >"$TMP_ROOT/out" 2>&1 || rc=$?
    if [ "$rc" = "0" ] && [ -n "$(git -C "$d" rev-parse --verify HEAD 2>/dev/null)" ]; then
        pass "pre-commit allowed the clean commit (HEAD created)"
    else
        fail "expected clean commit to succeed, rc=$rc ($(cat "$TMP_ROOT/out"))"
    fi
}

main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Meridian Verify Tests (G5.2 — portable boundary)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    test_clean_passes
    test_circular_gates_blocks
    test_invalid_memory_blocks
    test_standing_fail_verdict_blocks
    test_drift_advisory_by_default
    test_drift_blocks_when_promoted
    test_precommit_hook_end_to_end
    test_precommit_hook_allows_clean

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
        echo -e "${GREEN}All tests passed!${NC}"; exit 0
    else
        echo -e "${RED}Some tests failed${NC}"; exit 1
    fi
}

main "$@"
