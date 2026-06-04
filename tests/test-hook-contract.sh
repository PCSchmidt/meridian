#!/bin/bash
# test-hook-contract.sh
# Tests the LIVE Claude Code hook stdin contract (G5.1).
#
# The other hook tests inject TOOL_NAME/COMMAND/CONTENT via environment
# variables, which never exercises stdin JSON parsing. Claude Code actually
# delivers a JSON object on stdin with keys .tool_name and .tool_input.* —
# NOT .tool / .arguments.*. This suite feeds real-shaped fixtures through the
# parser and through PreToolUse.sh end-to-end, proving the security boundary
# actually fires in a live session (and guarding against regressions to the
# legacy field-name bug).
#
# See docs/tier1-verification.md for the documented contract.

set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export MERIDIAN_PROJECT_DIR="$PROJECT_DIR"
WRAPPER="$PROJECT_DIR/.claude/hooks/hook-wrapper.sh"
PRE="$PROJECT_DIR/.claude/hooks/PreToolUse.sh"
FIX="$PROJECT_DIR/tests/fixtures/hook-stdin"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

pass() { echo -e "${GREEN}✓${NC} $1"; TESTS_PASSED=$((TESTS_PASSED + 1)); TESTS_RUN=$((TESTS_RUN + 1)); }
fail() { echo -e "${RED}✗${NC} $1"; TESTS_FAILED=$((TESTS_FAILED + 1)); TESTS_RUN=$((TESTS_RUN + 1)); }

# Parse a JSON payload (file or heredoc) through parse_tool_use and echo the
# resulting vars as KEY=VALUE lines. Runs in a clean subshell.
parse_payload() {
    local src="$1"
    HOOK_NAME=contract-test bash -c '
        source "'"$WRAPPER"'" >/dev/null 2>&1
        set +eu
        parse_tool_use >/dev/null 2>&1
        printf "TOOL_NAME=%s\n" "${TOOL_NAME:-}"
        printf "FILE_PATH=%s\n" "${FILE_PATH:-}"
        printf "COMMAND=%s\n"   "${COMMAND:-}"
        printf "CONTENT=%s\n"   "${CONTENT:-}"
    ' < "$src"
}

# Run PreToolUse.sh end-to-end with a fixture on stdin; echo exit code.
run_pre() {
    local fixture="$1" rc=0
    MERIDIAN_PROJECT_DIR="$PROJECT_DIR" bash "$PRE" < "$fixture" >/dev/null 2>&1 || rc=$?
    echo "$rc"
}

#######################################
# Parse: a Bash PreToolUse payload yields tool_name + command
#######################################
test_parse_bash() {
    echo ""
    echo "Test: parse live Bash payload (.tool_name / .tool_input.command)"
    local out
    out="$(parse_payload "$FIX/pretooluse-bash-clean.json")"
    if echo "$out" | grep -qx "TOOL_NAME=Bash"; then
        pass "TOOL_NAME parsed from .tool_name"
    else
        fail "TOOL_NAME not parsed (got: $(echo "$out" | grep TOOL_NAME=))"
    fi
    if echo "$out" | grep -qx "COMMAND=echo hello world"; then
        pass "COMMAND parsed from .tool_input.command"
    else
        fail "COMMAND not parsed (got: $(echo "$out" | grep COMMAND=))"
    fi
}

#######################################
# Parse: a Write payload yields file_path + content
#######################################
test_parse_write() {
    echo ""
    echo "Test: parse live Write payload (.tool_input.file_path / .content)"
    local out
    out="$(parse_payload "$FIX/pretooluse-write-secret.json")"
    if echo "$out" | grep -qx "TOOL_NAME=Write"; then
        pass "TOOL_NAME=Write parsed"
    else
        fail "TOOL_NAME not Write (got: $(echo "$out" | grep TOOL_NAME=))"
    fi
    if echo "$out" | grep -q "FILE_PATH=.*config.txt"; then
        pass "FILE_PATH parsed from .tool_input.file_path"
    else
        fail "FILE_PATH not parsed (got: $(echo "$out" | grep FILE_PATH=))"
    fi
    if echo "$out" | grep -q "CONTENT=.*BEGIN PRIVATE KEY"; then
        pass "CONTENT parsed from .tool_input.content"
    else
        fail "CONTENT not parsed (got: $(echo "$out" | grep CONTENT=))"
    fi
}

#######################################
# Backward compat: legacy .tool / .arguments.* shape still parses
#######################################
test_parse_legacy() {
    echo ""
    echo "Test: legacy .tool/.arguments shape still parses (fallback)"
    local tmp
    tmp="$(mktemp)"
    printf '%s\n' '{"tool":"Bash","arguments":{"command":"echo legacy"}}' > "$tmp"
    local out
    out="$(parse_payload "$tmp")"
    rm -f "$tmp"
    if echo "$out" | grep -qx "TOOL_NAME=Bash" && echo "$out" | grep -qx "COMMAND=echo legacy"; then
        pass "legacy shape still parses via fallback"
    else
        fail "legacy fallback broken (got: $(echo "$out" | grep -E 'TOOL_NAME=|COMMAND='))"
    fi
}

#######################################
# End-to-end: dangerous Bash command via real stdin is BLOCKED (exit 2)
#######################################
test_e2e_block_command() {
    echo ""
    echo "Test: dangerous command via live stdin is blocked (exit 2)"
    local rc
    rc="$(run_pre "$FIX/pretooluse-bash-dangerous.json")"
    if [ "$rc" = "2" ]; then
        pass "PreToolUse blocked 'rm -rf /' delivered via real stdin shape"
    else
        fail "expected exit 2, got $rc (security boundary did NOT fire on live stdin)"
    fi
}

#######################################
# End-to-end: a clean command via real stdin is ALLOWED (exit 0)
#######################################
test_e2e_allow_clean() {
    echo ""
    echo "Test: clean command via live stdin is allowed (exit 0)"
    local rc
    rc="$(run_pre "$FIX/pretooluse-bash-clean.json")"
    if [ "$rc" = "0" ]; then
        pass "PreToolUse allowed a clean command via real stdin shape"
    else
        fail "expected exit 0, got $rc"
    fi
}

#######################################
# End-to-end: secret content via real stdin is BLOCKED (exit 2)
#######################################
test_e2e_block_content() {
    echo ""
    echo "Test: secret content via live stdin is blocked (exit 2)"
    local rc
    rc="$(run_pre "$FIX/pretooluse-write-secret.json")"
    if [ "$rc" = "2" ]; then
        pass "PreToolUse blocked a private key in Write content via real stdin shape"
    else
        fail "expected exit 2, got $rc (content scan did NOT fire on live stdin)"
    fi
}

main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Meridian Hook Contract Tests (G5.1 — live stdin)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    test_parse_bash
    test_parse_write
    test_parse_legacy
    test_e2e_block_command
    test_e2e_allow_clean
    test_e2e_block_content

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
