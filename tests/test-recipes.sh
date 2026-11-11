#!/bin/bash
# test-recipes.sh
# Every pre-hook a recipe declares must ship with Meridian: a core script, or a
# file under recipes/<recipe>/hooks/ that install.sh copies into the project.
# Project-specific checks ship as fail-closed stubs (exit 2, MERIDIAN-STUB) so a
# gate can never pass as though a check ran that nobody wrote.

set -uo pipefail

MERIDIAN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENGINE="$MERIDIAN_DIR/scripts/gate-engine.sh"
INSTALL="$MERIDIAN_DIR/install.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

pass() { echo -e "${GREEN}✓${NC} $1"; TESTS_PASSED=$((TESTS_PASSED+1)); TESTS_RUN=$((TESTS_RUN+1)); }
fail() { echo -e "${RED}✗${NC} $1"; TESTS_FAILED=$((TESTS_FAILED+1)); TESTS_RUN=$((TESTS_RUN+1)); }

shipped() {
    local recipe="$1" hook="$2"
    [ -f "$MERIDIAN_DIR/scripts/$hook" ] || [ -f "$MERIDIAN_DIR/.claude/hooks/$hook" ] \
        || [ -f "$MERIDIAN_DIR/recipes/$recipe/hooks/$hook" ]
}

test_declared_hooks_ship() {
    echo ""
    echo "Test: every declared pre-hook ships"
    local dir recipe hook missing declared
    for dir in "$MERIDIAN_DIR"/recipes/*/; do
        recipe=$(basename "$dir")
        missing=""
        declared=$(yq eval '.gates[].hooks.pre[]?' "$dir/gates.yaml" | tr -d '\r' | sort -u)
        while IFS= read -r hook || [ -n "$hook" ]; do
            [ -n "$hook" ] || continue
            shipped "$recipe" "$hook" || missing="$missing $hook"
        done <<< "$declared"
        [ -z "$missing" ] && pass "$recipe: all pre-hooks ship" || fail "$recipe: declared but not shipped:$missing"

        local orphans="" f
        for f in "$dir"hooks/*.sh; do
            [ -f "$f" ] || continue
            echo "$declared" | grep -qx "$(basename "$f")" || orphans="$orphans $(basename "$f")"
        done
        [ -z "$orphans" ] && pass "$recipe: no undeclared files in hooks/" || fail "$recipe: hooks/ files no gate declares:$orphans"

        grep -q "emit-telemetry.sh" "$dir/gates.yaml" \
            && fail "$recipe: still declares emit-telemetry.sh (mark-passed already emits gate_passed)" \
            || pass "$recipe: no emit-telemetry.sh (telemetry comes from mark-passed)"
    done
}

test_stubs_fail_closed() {
    echo ""
    echo "Test: stubs block their gate and say what to write"
    local f rc out bad="" count=0 tmp
    tmp=$(mktemp -d)
    for f in "$MERIDIAN_DIR"/recipes/*/hooks/*.sh; do
        [ -x "$f" ] || bad="$bad $(basename "$f"):not-executable"
        grep -q "MERIDIAN-STUB" "$f" || continue
        count=$((count+1))
        rc=0; out=$(cd "$tmp" && bash "$f" 2>&1) || rc=$?
        [ "$rc" -eq 2 ] || bad="$bad $(basename "$f"):rc=$rc"
        echo "$out" | grep -q "It should verify" || bad="$bad $(basename "$f"):no-guidance"
    done
    [ "$count" -gt 0 ] && pass "found $count stubs" || fail "no stubs found"
    [ -z "$bad" ] && pass "every hook is executable; every stub exits 2 with guidance" || fail "bad hooks:$bad"
    rm -rf "$tmp"
}

test_data_contract_hook() {
    echo ""
    echo "Test: ml-research validate-data-contract.sh is a working check"
    local hook="$MERIDIAN_DIR/recipes/ml-research/hooks/validate-data-contract.sh" d rc
    grep -q "MERIDIAN-STUB" "$hook" && fail "validate-data-contract.sh should be a real check, not a stub" || pass "not a stub"
    d=$(mktemp -d)
    rc=0; ( cd "$d" && bash "$hook" ) >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 2 ] && pass "blocks when DATA_CONTRACT.md is missing" || fail "missing contract not blocked (rc=$rc)"
    cp "$MERIDIAN_DIR/recipes/ml-research/foundation/DATA_CONTRACT.md.template" "$d/DATA_CONTRACT.md"
    rc=0; ( cd "$d" && bash "$hook" ) >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 2 ] && pass "blocks the unfilled template" || fail "template accepted (rc=$rc)"
    {
        echo "# DATA_CONTRACT.md"; echo "**Project:** Demo"
        for s in "Problem Statement" "Target" "Train / Val / Test Split" "Success Metric" "Baseline"; do
            echo ""; echo "## $s"; echo "Filled in with real content for $s."; echo "More detail."; echo "And a threshold: 0.8."
        done
    } > "$d/DATA_CONTRACT.md"
    rc=0; ( cd "$d" && bash "$hook" ) >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 0 ] && pass "passes a filled contract" || fail "filled contract blocked (rc=$rc)"
    sed -i '/## Baseline/d' "$d/DATA_CONTRACT.md"
    rc=0; ( cd "$d" && bash "$hook" ) >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 2 ] && pass "blocks a contract with no Baseline section" || fail "missing section accepted (rc=$rc)"
    rm -rf "$d"
}

test_install_ships_hooks() {
    echo ""
    echo "Test: install.sh copies recipe hooks and keeps the project's own"
    local d rc out
    d=$(mktemp -d)
    mkdir -p "$d/.claude/hooks"
    printf '#!/bin/bash\nexit 0\n' > "$d/.claude/hooks/run-benchmark.sh"
    env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT bash "$INSTALL" "$d" --recipe ml-research --platform cline >/dev/null 2>&1
    [ -f "$d/.claude/hooks/validate-splits.sh" ] && [ -f "$d/.claude/hooks/validate-data-contract.sh" ] \
        && pass "recipe hooks installed to .claude/hooks/" || fail "recipe hooks not installed"
    grep -q "MERIDIAN-STUB" "$d/.claude/hooks/run-benchmark.sh" \
        && fail "overwrote the project's own run-benchmark.sh" || pass "existing hook kept"

    out=$(cd "$d" && MERIDIAN_PROJECT_DIR="$d" bash "$ENGINE" validate 2>&1)
    echo "$out" | grep -q "is declared but not installed" \
        && fail "validate still reports missing hooks after install" || pass "validate finds every declared hook"
    echo "$out" | grep -q "'validate-splits.sh' is still the recipe stub" \
        && pass "validate names stubs still to implement" || fail "validate did not flag stubs"
    echo "$out" | grep -q "'run-benchmark.sh' is still the recipe stub" \
        && fail "validate flagged the project's own hook as a stub" || pass "validate does not flag a real hook"

    rc=0; ( cd "$d" && MERIDIAN_PROJECT_DIR="$d" bash "$ENGINE" verify pipeline_validated ) >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 2 ] && pass "a gate with stub hooks blocks" || fail "stub gate did not block (rc=$rc)"
    rm -rf "$d"
}

main() {
    echo "━━━ Meridian recipe tests ━━━"
    command -v yq >/dev/null 2>&1 && yq --version 2>&1 | grep -q "mikefarah" || { echo "yq (mikefarah v4) required"; exit 1; }
    test_declared_hooks_ship
    test_stubs_fail_closed
    test_data_contract_hook
    test_install_ships_hooks
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Tests run: $TESTS_RUN | Passed: $TESTS_PASSED | Failed: $TESTS_FAILED"
    [ "$TESTS_FAILED" -eq 0 ]
}

main "$@"
