#!/bin/bash
# test-skills.sh
# Tests for Meridian core skills (Gate 2.4)
#
# Covers:
#   - presence of all 12 skill docs
#   - the four backing scripts: start-session, rollback-gate,
#     security-audit, cost-report

set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS="$PROJECT_DIR/scripts"
SKILLS="$PROJECT_DIR/.claude/skills"

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
TESTS_RUN=0; TESTS_PASSED=0; TESTS_FAILED=0
pass() { echo -e "${GREEN}✓${NC} $1"; TESTS_PASSED=$((TESTS_PASSED+1)); TESTS_RUN=$((TESTS_RUN+1)); }
fail() { echo -e "${RED}✗${NC} $1"; TESTS_FAILED=$((TESTS_FAILED+1)); TESTS_RUN=$((TESTS_RUN+1)); }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
rc_of() { local rc=0; "$@" >/dev/null 2>&1 || rc=$?; echo "$rc"; }

#######################################
# Skill docs presence
#######################################
test_skill_docs_exist() {
    echo ""; echo "Test: all 12 core skill docs exist"
    local missing="" s
    for s in start health memory status deploy security testing costs rollback build-rules critical-thinker research; do
        [ -f "$SKILLS/$s/$s.md" ] || missing="${missing:+$missing }$s"
    done
    [ -z "$missing" ] && pass "All 12 skill docs present" || fail "Missing skill docs: $missing"
}

test_skill_docs_have_trigger() {
    echo ""; echo "Test: each skill doc declares a Trigger"
    local bad="" s
    for s in start deploy security testing costs rollback build-rules critical-thinker research; do
        grep -q '\*\*Trigger:\*\*' "$SKILLS/$s/$s.md" || bad="${bad:+$bad }$s"
    done
    [ -z "$bad" ] && pass "All new skill docs declare a Trigger" || fail "Missing Trigger in: $bad"
}

#######################################
# start-session.sh
#######################################
test_start_creates_session() {
    echo ""; echo "Test: start-session creates a session on a fresh project"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX"); mkdir -p "$p/.meridian"
    MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/start-session.sh" >/dev/null 2>&1
    [ -f "$p/.meridian/session.json" ] && pass "session.json created" || fail "session.json not created"
}

test_start_new_changes_id() {
    echo ""; echo "Test: start-session --new mints a different session id"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX"); mkdir -p "$p/.meridian"
    echo '{"session_id":"00000001","project":"x"}' > "$p/.meridian/session.json"
    MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/start-session.sh" --new >/dev/null 2>&1
    local newid; newid=$(jq -r '.session_id' "$p/.meridian/session.json" | tr -d '\r')
    [ "$newid" != "00000001" ] && pass "Fresh session id minted ($newid)" || fail "--new did not change id"
}

test_start_resumes() {
    echo ""; echo "Test: start-session resumes an existing session"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX"); mkdir -p "$p/.meridian"
    echo '{"session_id":"abcdef12","project":"x"}' > "$p/.meridian/session.json"
    local out; out=$(MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/start-session.sh" 2>&1)
    echo "$out" | grep -q "Resuming session abcdef12" && pass "Resumed existing session" || fail "Did not resume"
}

#######################################
# rollback-gate.sh
#######################################
new_state() {  # $1 = root
    local p="$1"; mkdir -p "$p/.meridian"
    echo '{"passed_gates":["1.1","1.2","1.3","2.1"]}' > "$p/.meridian/gate-state.json"
}

test_rollback_no_state() {
    echo ""; echo "Test: rollback errors when no gate-state exists"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX"); mkdir -p "$p/.meridian"
    local rc; rc=$(rc_of env MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/rollback-gate.sh")
    [ "$rc" -ne 0 ] && pass "No state -> error (exit $rc)" || fail "Expected non-zero, got $rc"
}

test_rollback_removes_latest() {
    echo ""; echo "Test: rollback removes the most-recent gate"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX"); new_state "$p"
    MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/rollback-gate.sh" >/dev/null 2>&1
    local rem; rem=$(jq -c '.passed_gates' "$p/.meridian/gate-state.json")
    [ "$rem" = '["1.1","1.2","1.3"]' ] && pass "2.1 removed, rest kept" || fail "Unexpected state: $rem"
}

test_rollback_to_gate() {
    echo ""; echo "Test: rollback --to keeps target and removes everything after"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX"); new_state "$p"
    MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/rollback-gate.sh" --to 1.2 >/dev/null 2>&1
    local rem; rem=$(jq -c '.passed_gates' "$p/.meridian/gate-state.json")
    [ "$rem" = '["1.1","1.2"]' ] && pass "Rolled back to 1.2" || fail "Unexpected state: $rem"
}

test_rollback_dryrun() {
    echo ""; echo "Test: rollback --dry-run does not modify state"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX"); new_state "$p"
    MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/rollback-gate.sh" --dry-run >/dev/null 2>&1
    local rem; rem=$(jq -c '.passed_gates' "$p/.meridian/gate-state.json")
    [ "$rem" = '["1.1","1.2","1.3","2.1"]' ] && pass "State unchanged by dry-run" || fail "dry-run modified state: $rem"
}

test_rollback_bad_target() {
    echo ""; echo "Test: rollback --to a nonexistent gate errors"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX"); new_state "$p"
    local rc; rc=$(rc_of env MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/rollback-gate.sh" --to 9.9)
    [ "$rc" -ne 0 ] && pass "Bad target rejected (exit $rc)" || fail "Expected non-zero, got $rc"
}

#######################################
# security-audit.sh
#######################################
test_audit_rules() {
    echo ""; echo "Test: security-audit rules lists the active rules"
    local out; out=$(MERIDIAN_PROJECT_DIR="$PROJECT_DIR" bash "$SCRIPTS/security-audit.sh" rules 2>&1)
    echo "$out" | grep -q "rm-rf-root" && echo "$out" | grep -qE "total: 1[0-9]" \
        && pass "Rules listed (incl rm-rf-root)" || fail "Rules not listed correctly"
}

test_audit_full() {
    echo ""; echo "Test: security-audit full runs cleanly"
    local rc; rc=$(rc_of env MERIDIAN_PROJECT_DIR="$PROJECT_DIR" bash "$SCRIPTS/security-audit.sh" full)
    [ "$rc" -eq 0 ] && pass "Full audit exit 0" || fail "Expected 0, got $rc"
}

#######################################
# cost-report.sh
#######################################
test_cost_json() {
    echo ""; echo "Test: cost-report --json is valid and honest about capture"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX"); mkdir -p "$p/.meridian"
    printf '{"timestamp":"2026-06-02T01:00:00Z","event_type":"tool_used","session_id":"deadbeef","project":"t"}\n' > "$p/.meridian/telemetry.jsonl"
    local out; out=$(MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/cost-report.sh" --json 2>/dev/null)
    if echo "$out" | jq empty 2>/dev/null && [ "$(echo "$out" | jq -r '.captured')" = "false" ]; then
        pass "Valid JSON, captured=false (no cost data)"
    else
        fail "cost-report --json invalid or wrong: $out"
    fi
}

test_cost_sums_when_present() {
    echo ""; echo "Test: cost-report sums cost fields when events carry them"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX"); mkdir -p "$p/.meridian"
    {
      printf '{"timestamp":"2026-06-02T01:00:00Z","event_type":"tool_used","session_id":"deadbeef","project":"t","input_tokens":100,"output_tokens":50,"cost_usd":0.01}\n'
      printf '{"timestamp":"2026-06-02T01:00:01Z","event_type":"tool_used","session_id":"deadbeef","project":"t","input_tokens":200,"output_tokens":25,"cost_usd":0.02}\n'
    } > "$p/.meridian/telemetry.jsonl"
    local out; out=$(MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/cost-report.sh" --json 2>/dev/null)
    local intok captured
    intok=$(echo "$out" | jq -r '.input_tokens'); captured=$(echo "$out" | jq -r '.captured')
    [ "$intok" = "300" ] && [ "$captured" = "true" ] && pass "Summed input_tokens=300, captured=true" \
        || fail "Expected 300/true (got $intok/$captured)"
}

#######################################
# Runner
#######################################
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Meridian Core Skills Tests (Gate 2.4)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    test_skill_docs_exist
    test_skill_docs_have_trigger
    test_start_creates_session
    test_start_new_changes_id
    test_start_resumes
    test_rollback_no_state
    test_rollback_removes_latest
    test_rollback_to_gate
    test_rollback_dryrun
    test_rollback_bad_target
    test_audit_rules
    test_audit_full
    test_cost_json
    test_cost_sums_when_present

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
