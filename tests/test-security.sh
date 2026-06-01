#!/bin/bash
# test-security.sh
# Tests for Meridian security hooks (Gate 2.1)
#
# Covers:
# - block-dangerous.sh rule engine (parse, match, severity)
# - Destructive commands  -> exit 2 (block)
# - Hardcoded secrets     -> exit 2 (block)
# - SQL injection         -> exit 0 (warn, heuristic)
# - Clean inputs          -> exit 0, no warning
# - PreToolUse propagates the block
#
# Dangerous strings are assembled from fragments so the literal does not appear
# in any command this test issues (Meridian/Claude Code's own outer hooks scan
# command strings, not file contents).

set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export MERIDIAN_PROJECT_DIR="$PROJECT_DIR"
HOOK="$PROJECT_DIR/.claude/hooks/block-dangerous.sh"
PRE="$PROJECT_DIR/.claude/hooks/PreToolUse.sh"
RULES="$PROJECT_DIR/.meridian/security-rules.yaml"
ERR="$(mktemp)"
trap 'rm -f "$ERR"' EXIT

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

pass() { echo -e "${GREEN}✓${NC} $1"; TESTS_PASSED=$((TESTS_PASSED + 1)); TESTS_RUN=$((TESTS_RUN + 1)); }
fail() { echo -e "${RED}✗${NC} $1"; TESTS_FAILED=$((TESTS_FAILED + 1)); TESTS_RUN=$((TESTS_RUN + 1)); }

# Run block-dangerous with a command input; echoes exit code, stderr -> $ERR
scan_command() {
    local rc=0
    TOOL_NAME=Bash COMMAND="$1" CONTENT="" TOOL_ARGS="" bash "$HOOK" >/dev/null 2>"$ERR" || rc=$?
    echo "$rc"
}

# Run block-dangerous with content input (simulating Write); echoes exit code
scan_content() {
    local rc=0
    TOOL_NAME=Write CONTENT="$1" COMMAND="" TOOL_ARGS="" bash "$HOOK" >/dev/null 2>"$ERR" || rc=$?
    echo "$rc"
}

err_has_rule() { grep -q "Security rule '$1'" "$ERR"; }

#######################################
# Setup / parsing
#######################################
test_files_exist() {
    echo ""; echo "Test: security hook + rules files exist"
    if [ -f "$HOOK" ] && [ -f "$RULES" ]; then
        pass "block-dangerous.sh and security-rules.yaml present"
    else
        fail "Missing block-dangerous.sh or security-rules.yaml"
    fi
}

test_rules_parse() {
    echo ""; echo "Test: rules file parses to >=1 rule (awk fallback)"
    local count
    count=$(awk '/^[[:space:]]*-[[:space:]]+id:/ {n++} END {print n+0}' "$RULES")
    if [ "$count" -ge 1 ]; then
        pass "Parsed $count rules from security-rules.yaml"
    else
        fail "No rules parsed from security-rules.yaml"
    fi
}

#######################################
# Destructive commands -> block (exit 2)
#######################################
test_block_recursive_delete() {
    echo ""; echo "Test: recursive force-delete of root is blocked"
    local rf="-r""f"
    local rc; rc=$(scan_command "rm $rf /")
    if [ "$rc" -eq 2 ] && err_has_rule "rm-rf-root"; then
        pass "Recursive delete blocked (exit 2, rm-rf-root)"
    else
        fail "Expected block on recursive delete (got exit $rc)"
    fi
}

test_block_disk_overwrite() {
    echo ""; echo "Test: raw disk write (dd if=) is blocked"
    local rc; rc=$(scan_command "dd if=/dev/zero of=/dev/sda bs=1M")
    if [ "$rc" -eq 2 ] && err_has_rule "disk-overwrite"; then
        pass "Disk overwrite blocked (exit 2, disk-overwrite)"
    else
        fail "Expected block on dd disk write (got exit $rc)"
    fi
}

test_block_fork_bomb() {
    echo ""; echo "Test: shell fork bomb is blocked"
    local rc; rc=$(scan_command ':(){ :|: & };:')
    if [ "$rc" -eq 2 ] && err_has_rule "fork-bomb"; then
        pass "Fork bomb blocked (exit 2, fork-bomb)"
    else
        fail "Expected block on fork bomb (got exit $rc)"
    fi
}

test_warn_git_hard_reset() {
    echo ""; echo "Test: git reset --hard warns but does not block"
    local rc; rc=$(scan_command "git reset --hard HEAD~3")
    if [ "$rc" -eq 0 ] && err_has_rule "git-hard-reset"; then
        pass "git reset --hard warned, allowed (exit 0)"
    else
        fail "Expected warn+allow on git reset --hard (got exit $rc)"
    fi
}

#######################################
# Secrets -> block (exit 2)
#######################################
test_block_aws_key() {
    echo ""; echo "Test: hardcoded AWS access key is blocked"
    # Assemble so the literal AKIA... key never appears verbatim in our command
    local key="AKIA""IOSFODNN7EXAMPLE"
    local rc; rc=$(scan_content "aws_key = \"$key\"")
    if [ "$rc" -eq 2 ] && err_has_rule "aws-access-key"; then
        pass "AWS access key blocked (exit 2, aws-access-key)"
    else
        fail "Expected block on AWS key (got exit $rc)"
    fi
}

test_block_private_key() {
    echo ""; echo "Test: hardcoded private key material is blocked"
    local hdr="-----BEGIN RSA PRIVATE KEY-----"
    local rc; rc=$(scan_content "$hdr"$'\n'"MIIEvg...")
    if [ "$rc" -eq 2 ] && err_has_rule "private-key-block"; then
        pass "Private key blocked (exit 2, private-key-block)"
    else
        fail "Expected block on private key (got exit $rc)"
    fi
}

#######################################
# SQL injection -> warn (exit 0, heuristic)
#######################################
test_warn_sql_concat() {
    echo ""; echo "Test: SQL string concatenation warns (heuristic)"
    local rc; rc=$(scan_content 'q = "SELECT * FROM users WHERE id = " + uid')
    if [ "$rc" -eq 0 ] && err_has_rule "sql-string-concat"; then
        pass "SQL concat warned, allowed (exit 0)"
    else
        fail "Expected warn on SQL concat (got exit $rc)"
    fi
}

test_warn_sql_format() {
    echo ""; echo "Test: SQL via .format()/f-string warns (heuristic)"
    local rc; rc=$(scan_content 'cursor.execute(f"SELECT * FROM t WHERE x={v}")')
    if [ "$rc" -eq 0 ] && err_has_rule "sql-fstring-format"; then
        pass "SQL f-string warned, allowed (exit 0)"
    else
        fail "Expected warn on SQL f-string (got exit $rc)"
    fi
}

#######################################
# Clean inputs -> allow, no warning
#######################################
test_allow_clean_command() {
    echo ""; echo "Test: benign command is allowed with no warning"
    local rc; rc=$(scan_command "ls -la && echo done")
    if [ "$rc" -eq 0 ] && ! grep -q "Security rule" "$ERR"; then
        pass "Clean command allowed, no warnings (exit 0)"
    else
        fail "Clean command should pass cleanly (got exit $rc)"
    fi
}

test_allow_clean_content() {
    echo ""; echo "Test: parameterized query content is allowed cleanly"
    local rc; rc=$(scan_content 'cursor.execute("SELECT * FROM t WHERE x = ?", (v,))')
    if [ "$rc" -eq 0 ] && ! grep -q "Security rule" "$ERR"; then
        pass "Parameterized query allowed, no warnings (exit 0)"
    else
        fail "Parameterized query should pass cleanly (got exit $rc)"
    fi
}

#######################################
# Integration: PreToolUse propagates the block
#######################################
test_pretooluse_propagates_block() {
    echo ""; echo "Test: PreToolUse propagates security block (exit 2)"
    local rf="-r""f" rc=0
    TOOL_NAME=Bash COMMAND="rm $rf ~" bash "$PRE" >/dev/null 2>&1 || rc=$?
    if [ "$rc" -eq 2 ]; then
        pass "PreToolUse returned exit 2 on dangerous command"
    else
        fail "PreToolUse should block dangerous command (got exit $rc)"
    fi
}

test_pretooluse_allows_clean() {
    echo ""; echo "Test: PreToolUse allows a clean command (exit 0)"
    local rc=0
    TOOL_NAME=Bash COMMAND="echo hello" bash "$PRE" >/dev/null 2>&1 || rc=$?
    if [ "$rc" -eq 0 ]; then
        pass "PreToolUse returned exit 0 on clean command"
    else
        fail "PreToolUse should allow clean command (got exit $rc)"
    fi
}

#######################################
# Runner
#######################################
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Meridian Security Hook Tests (Gate 2.1)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    test_files_exist
    test_rules_parse
    test_block_recursive_delete
    test_block_disk_overwrite
    test_block_fork_bomb
    test_warn_git_hard_reset
    test_block_aws_key
    test_block_private_key
    test_warn_sql_concat
    test_warn_sql_format
    test_allow_clean_command
    test_allow_clean_content
    test_pretooluse_propagates_block
    test_pretooluse_allows_clean

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
