#!/bin/bash
# test-gen-rules.sh
# Tests scripts/gen-rules.sh — the Tier-2/3 rule generator (G5.3 / G5.4).
#
# Verifies the generator writes each platform adapter, that the content is
# rendered FROM the source files (not static), that regeneration is idempotent
# (surfaces can't silently drift from the hooks), and that the Cursor MDC
# frontmatter is present.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GEN="$REPO/scripts/gen-rules.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
TESTS_RUN=0; TESTS_PASSED=0; TESTS_FAILED=0

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

pass() { echo -e "${GREEN}✓${NC} $1"; TESTS_PASSED=$((TESTS_PASSED+1)); TESTS_RUN=$((TESTS_RUN+1)); }
fail() { echo -e "${RED}✗${NC} $1"; TESTS_FAILED=$((TESTS_FAILED+1)); TESTS_RUN=$((TESTS_RUN+1)); }
skip() { echo -e "  ○ SKIP: $1"; }

# Build a project with a real recipe gates.yaml + the security rules.
scaffold() {
    local dir="$1"
    mkdir -p "$dir/.meridian"
    cp "$REPO/recipes/cli-tool/gates.yaml" "$dir/.meridian/gates.yaml"
    cp "$REPO/.meridian/security-rules.yaml" "$dir/.meridian/"
}

has_yq() { command -v yq >/dev/null 2>&1; }

#######################################
test_writes_all_adapters() {
    echo ""; echo "Test: --platform all writes every adapter"
    if ! has_yq; then skip "yq not installed"; return 0; fi
    local d="$TMP_ROOT/all"; scaffold "$d"
    bash "$GEN" "$d" --platform all >/dev/null 2>&1
    local ok=1
    for f in ".cursor/rules/meridian.mdc" ".windsurf/rules/meridian.md" ".clinerules/meridian.md" "MERIDIAN.md"; do
        [ -f "$d/$f" ] || { fail "missing adapter: $f"; ok=0; }
    done
    [ "$ok" -eq 1 ] && pass "all four adapters written"
}

#######################################
test_content_from_source() {
    echo ""; echo "Test: content is rendered from source (gates + rules)"
    if ! has_yq; then skip "yq not installed"; return 0; fi
    local d="$TMP_ROOT/src"; scaffold "$d"
    bash "$GEN" "$d" --platform advisory >/dev/null 2>&1
    local f="$d/MERIDIAN.md"
    if grep -q "commands_approved" "$f" && grep -q "rm-rf-root" "$f"; then
        pass "rendered a gate id and a security rule id from source"
    else
        fail "expected gate id + rule id in output"
    fi
}

#######################################
test_reflects_source_changes() {
    echo ""; echo "Test: editing source changes the output (not static)"
    if ! has_yq; then skip "yq not installed"; return 0; fi
    local d="$TMP_ROOT/sync"; scaffold "$d"
    # add a sentinel gate to the source
    yq -i '.gates += [{"id":"sentinel_gate","label":"Sentinel","type":"automated","requires":[]}]' "$d/.meridian/gates.yaml"
    bash "$GEN" "$d" --platform advisory >/dev/null 2>&1
    if grep -q "sentinel_gate" "$d/MERIDIAN.md"; then
        pass "new source gate appears in generated output"
    else
        fail "generated output did not reflect a source change"
    fi
}

#######################################
test_cursor_frontmatter() {
    echo ""; echo "Test: Cursor adapter has MDC frontmatter"
    if ! has_yq; then skip "yq not installed"; return 0; fi
    local d="$TMP_ROOT/cur"; scaffold "$d"
    bash "$GEN" "$d" --platform cursor >/dev/null 2>&1
    local f="$d/.cursor/rules/meridian.mdc"
    if head -1 "$f" | grep -q "^---$" && grep -q "alwaysApply: true" "$f"; then
        pass "Cursor .mdc has alwaysApply frontmatter"
    else
        fail "Cursor frontmatter missing"
    fi
}

#######################################
test_idempotent() {
    echo ""; echo "Test: regeneration is byte-identical (no drift)"
    if ! has_yq; then skip "yq not installed"; return 0; fi
    local d="$TMP_ROOT/idem"; scaffold "$d"
    bash "$GEN" "$d" --platform all >/dev/null 2>&1
    cp "$d/MERIDIAN.md" "$TMP_ROOT/first.md"
    bash "$GEN" "$d" --platform all >/dev/null 2>&1
    if diff -q "$TMP_ROOT/first.md" "$d/MERIDIAN.md" >/dev/null 2>&1; then
        pass "second generation identical to first"
    else
        fail "regeneration produced a diff (not idempotent)"
    fi
}

#######################################
test_single_platform_isolation() {
    echo ""; echo "Test: single-platform mode writes only that platform"
    if ! has_yq; then skip "yq not installed"; return 0; fi
    local d="$TMP_ROOT/single"; scaffold "$d"
    bash "$GEN" "$d" --platform cline >/dev/null 2>&1
    if [ -f "$d/.clinerules/meridian.md" ] && [ ! -f "$d/MERIDIAN.md" ] && [ ! -d "$d/.cursor" ]; then
        pass "only .clinerules written"
    else
        fail "single-platform mode wrote extra files"
    fi
}

#######################################
test_missing_gates_errors() {
    echo ""; echo "Test: missing gates.yaml exits non-zero"
    if ! has_yq; then skip "yq not installed"; return 0; fi
    local d="$TMP_ROOT/nogates"; mkdir -p "$d/.meridian"
    local rc=0
    bash "$GEN" "$d" --platform advisory >/dev/null 2>&1 || rc=$?
    if [ "$rc" != "0" ]; then pass "errored without gates.yaml (rc=$rc)"; else fail "expected non-zero, got 0"; fi
}

main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Meridian gen-rules Tests (G5.3 — Tier 2/3 surfaces)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    test_writes_all_adapters
    test_content_from_source
    test_reflects_source_changes
    test_cursor_frontmatter
    test_idempotent
    test_single_platform_isolation
    test_missing_gates_errors

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
