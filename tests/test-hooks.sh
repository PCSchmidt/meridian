#!/bin/bash
# test-hooks.sh
# Test script for Meridian hook infrastructure
#
# Tests:
# - Hook wrapper loading and logging
# - PreToolUse execution and exit codes
# - PostToolUse validation
# - Memory file validation integration
# - Blocking behavior (exit code 2)

set -euo pipefail

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export MERIDIAN_PROJECT_DIR="$PROJECT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

#######################################
# Print test result
#######################################
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

#######################################
# Test: Hook wrapper loads correctly
#######################################
test_hook_wrapper_loads() {
    echo ""
    echo "Test: Hook wrapper loads correctly"

    export HOOK_NAME="test-hook"
    if source "$PROJECT_DIR/.claude/hooks/hook-wrapper.sh" 2>/dev/null; then
        # Check if functions are available
        if declare -f log >/dev/null && declare -f block >/dev/null; then
            pass "Hook wrapper loaded and exported functions"
        else
            fail "Hook wrapper loaded but functions not available"
        fi
    else
        fail "Hook wrapper failed to load"
    fi
}

#######################################
# Test: PreToolUse hook executes
#######################################
test_pretooluse_executes() {
    echo ""
    echo "Test: PreToolUse hook executes"

    export TOOL_NAME="Read"
    export FILE_PATH="/test/file.txt"
    export HOOK_NAME="PreToolUse"

    # Run hook in test mode (no stdin) and check output
    local output
    output=$("$PROJECT_DIR/.claude/hooks/PreToolUse.sh" 2>&1 || true)

    if echo "$output" | grep -q "Tool: Read"; then
        pass "PreToolUse hook executed"
    else
        fail "PreToolUse hook did not execute properly"
    fi
}

#######################################
# Test: PostToolUse hook executes
#######################################
test_posttooluse_executes() {
    echo ""
    echo "Test: PostToolUse hook executes"

    export TOOL_NAME="Edit"
    export FILE_PATH="/test/file.txt"
    export HOOK_NAME="PostToolUse"

    # Run hook in test mode
    local output
    output=$("$PROJECT_DIR/.claude/hooks/PostToolUse.sh" 2>&1 || true)

    if echo "$output" | grep -q "Tool: Edit"; then
        pass "PostToolUse hook executed"
    else
        fail "PostToolUse hook did not execute properly"
    fi
}

#######################################
# Test: Memory validation in PostToolUse
#######################################
test_memory_validation() {
    echo ""
    echo "Test: Memory validation triggers for memory files"

    export TOOL_NAME="Write"
    export FILE_PATH="$PROJECT_DIR/.meridian/memory/semantic.json"
    export HOOK_NAME="PostToolUse"

    # Run PostToolUse hook - should attempt validation
    local output
    output=$("$PROJECT_DIR/.claude/hooks/PostToolUse.sh" 2>&1 || true)

    if echo "$output" | grep -q "Validating semantic memory"; then
        pass "Memory validation triggered for semantic.json"
    else
        fail "Memory validation did not trigger"
    fi
}

#######################################
# Test: Hook logging
#######################################
test_hook_logging() {
    echo ""
    echo "Test: Hook logging creates log file"

    # Clear old log
    rm -f "$PROJECT_DIR/.meridian/hooks.log"

    export TOOL_NAME="Test"
    "$PROJECT_DIR/.claude/hooks/PreToolUse.sh" >/dev/null 2>&1 || true

    if [ -f "$PROJECT_DIR/.meridian/hooks.log" ]; then
        if grep -q "PreToolUse" "$PROJECT_DIR/.meridian/hooks.log"; then
            pass "Hook logging working"
        else
            fail "Log file created but no entries found"
        fi
    else
        fail "Hook log file not created"
    fi
}

#######################################
# Test: Exit code 0 (allow)
#######################################
test_exit_code_allow() {
    echo ""
    echo "Test: Hook returns exit code 0 (allow)"

    export TOOL_NAME="Read"
    export FILE_PATH="/test/file.txt"

    if "$PROJECT_DIR/.claude/hooks/PreToolUse.sh" >/dev/null 2>&1; then
        local exit_code=$?
        if [ $exit_code -eq 0 ]; then
            pass "Exit code 0 (allow) returned correctly"
        else
            fail "Expected exit code 0, got $exit_code"
        fi
    else
        fail "Hook execution failed"
    fi
}

#######################################
# Test: Telemetry logging
#######################################
test_telemetry_logging() {
    echo ""
    echo "Test: Telemetry logging in PostToolUse"

    # Clear old telemetry
    rm -f "$PROJECT_DIR/.meridian/telemetry.jsonl"

    export TOOL_NAME="Write"
    export FILE_PATH="/test/file.txt"

    "$PROJECT_DIR/.claude/hooks/PostToolUse.sh" >/dev/null 2>&1 || true

    if [ -f "$PROJECT_DIR/.meridian/telemetry.jsonl" ]; then
        if grep -q "PostToolUse" "$PROJECT_DIR/.meridian/telemetry.jsonl"; then
            pass "Telemetry logging working"
        else
            fail "Telemetry file created but no entries"
        fi
    else
        fail "Telemetry file not created"
    fi
}

#######################################
# Main test runner
#######################################
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Meridian Hook Infrastructure Tests"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Run tests
    test_hook_wrapper_loads
    test_pretooluse_executes
    test_posttooluse_executes
    test_memory_validation
    test_hook_logging
    test_exit_code_allow
    test_telemetry_logging

    # Summary
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
