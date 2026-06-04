#!/bin/bash
# test-detect.sh
# Tests scripts/detect-runtime.sh (G5.5) and its install.sh integration.
#
# Detection is best-effort: reliable env signal for Claude Code, heuristic
# project markers for editors, 'generic' otherwise. These tests pin that
# behavior and the precedence (env beats markers), then verify install.sh
# generates the right surface set for a declared platform.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DETECT="$REPO/scripts/detect-runtime.sh"
INSTALL="$REPO/install.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
TESTS_RUN=0; TESTS_PASSED=0; TESTS_FAILED=0

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

pass() { echo -e "${GREEN}✓${NC} $1"; TESTS_PASSED=$((TESTS_PASSED+1)); TESTS_RUN=$((TESTS_RUN+1)); }
fail() { echo -e "${RED}✗${NC} $1"; TESTS_FAILED=$((TESTS_FAILED+1)); TESTS_RUN=$((TESTS_RUN+1)); }
skip() { echo -e "  ○ SKIP: $1"; }

# Run detect with a clean editor env (Claude Code's own vars stripped) so marker
# detection can be exercised even though this suite runs inside Claude Code.
detect_clean() { env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT bash "$DETECT" "$1"; }

#######################################
test_claudecode_env() {
    echo ""; echo "Test: CLAUDECODE env → claude-code"
    local d="$TMP_ROOT/cc"; mkdir -p "$d"
    if [ "$(CLAUDECODE=1 bash "$DETECT" "$d")" = "claude-code" ]; then
        pass "CLAUDECODE=1 detected as claude-code"
    else
        fail "expected claude-code"
    fi
}

test_entrypoint_env() {
    echo ""; echo "Test: CLAUDE_CODE_ENTRYPOINT env → claude-code"
    local d="$TMP_ROOT/cc2"; mkdir -p "$d"
    if [ "$(env -u CLAUDECODE CLAUDE_CODE_ENTRYPOINT=cli bash "$DETECT" "$d")" = "claude-code" ]; then
        pass "CLAUDE_CODE_ENTRYPOINT detected as claude-code"
    else
        fail "expected claude-code"
    fi
}

test_cursor_marker() {
    echo ""; echo "Test: .cursor/ marker → cursor"
    local d="$TMP_ROOT/cur"; mkdir -p "$d/.cursor"
    if [ "$(detect_clean "$d")" = "cursor" ]; then pass "cursor detected via marker"; else fail "expected cursor"; fi
}

test_windsurf_marker() {
    echo ""; echo "Test: .windsurfrules marker → windsurf"
    local d="$TMP_ROOT/wind"; mkdir -p "$d"; touch "$d/.windsurfrules"
    if [ "$(detect_clean "$d")" = "windsurf" ]; then pass "windsurf detected via marker"; else fail "expected windsurf"; fi
}

test_cline_marker() {
    echo ""; echo "Test: .clinerules marker → cline"
    local d="$TMP_ROOT/cli"; mkdir -p "$d/.clinerules"
    if [ "$(detect_clean "$d")" = "cline" ]; then pass "cline detected via marker"; else fail "expected cline"; fi
}

test_generic_default() {
    echo ""; echo "Test: no signals → generic"
    local d="$TMP_ROOT/gen"; mkdir -p "$d"
    if [ "$(detect_clean "$d")" = "generic" ]; then pass "generic when nothing matches"; else fail "expected generic"; fi
}

test_env_beats_marker() {
    echo ""; echo "Test: env precedence over marker"
    local d="$TMP_ROOT/prec"; mkdir -p "$d/.cursor"
    if [ "$(CLAUDECODE=1 bash "$DETECT" "$d")" = "claude-code" ]; then
        pass "CLAUDECODE wins over a .cursor/ marker"
    else
        fail "expected claude-code to win"
    fi
}

#######################################
test_install_generates_declared_surface() {
    echo ""; echo "Test: install --platform cline generates only cline + advisory"
    if ! command -v yq >/dev/null 2>&1; then skip "yq not installed"; return 0; fi
    if ! command -v git >/dev/null 2>&1; then skip "git not installed"; return 0; fi
    local d="$TMP_ROOT/inst"; mkdir -p "$d"; git -C "$d" init -q
    env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT bash "$INSTALL" "$d" --recipe cli-tool --platform cline >/dev/null 2>&1
    if [ -f "$d/.clinerules/meridian.md" ] && [ -f "$d/MERIDIAN.md" ] && [ ! -d "$d/.cursor" ]; then
        pass "cline + advisory generated; cursor surface absent"
    else
        fail "expected .clinerules + MERIDIAN.md only (cursor=$( [ -d "$d/.cursor" ] && echo present || echo absent ))"
    fi
}

main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Meridian detect-runtime Tests (G5.5)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    test_claudecode_env
    test_entrypoint_env
    test_cursor_marker
    test_windsurf_marker
    test_cline_marker
    test_generic_default
    test_env_beats_marker
    test_install_generates_declared_surface

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
