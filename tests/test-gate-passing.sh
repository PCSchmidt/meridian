#!/bin/bash
# test-gate-passing.sh
# A gate can only be marked passed once it has been earned: dependencies,
# required artifacts, pre-hooks (missing hooks block), and operator approval
# for human_approval gates. The agent cannot approve or hand-edit gate state.

set -uo pipefail

MERIDIAN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENGINE="$MERIDIAN_DIR/scripts/gate-engine.sh"
VERIFY="$MERIDIAN_DIR/scripts/meridian-verify.sh"
PRE="$MERIDIAN_DIR/.claude/hooks/PreToolUse.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

pass() { echo -e "${GREEN}✓${NC} $1"; TESTS_PASSED=$((TESTS_PASSED+1)); TESTS_RUN=$((TESTS_RUN+1)); }
fail() { echo -e "${RED}✗${NC} $1"; TESTS_FAILED=$((TESTS_FAILED+1)); TESTS_RUN=$((TESTS_RUN+1)); }

# A small project: confirmed (human, token OK) -> build (automated, pre-hook) -> ship (automated, missing hook)
new_project() {
    local dir
    dir=$(mktemp -d)
    mkdir -p "$dir/.meridian" "$dir/scripts"
    cp "$MERIDIAN_DIR/scripts/log-event.sh" "$dir/scripts/"
    cat > "$dir/.meridian/gates.yaml" <<'EOF'
version: "1.0"
gates:
  - id: confirmed
    type: human_approval
    approval_token: "OK"
    requires: []
    requires_artifacts:
      - CONTRACT.md
    hooks:
      pre:
        - check-contract.sh
  - id: build
    type: automated
    requires:
      - confirmed
    hooks:
      pre:
        - check-build.sh
  - id: ship
    type: automated
    requires:
      - build
    hooks:
      pre:
        - not-written-yet.sh
EOF
    printf '#!/bin/bash\n[ -s CONTRACT.md ] || exit 2\n' > "$dir/scripts/check-contract.sh"
    printf '#!/bin/bash\n[ -f BUILD_OK ] || exit 2\n' > "$dir/scripts/check-build.sh"
    echo "$dir"
}

engine() { local dir="$1"; shift; ( cd "$dir" && MERIDIAN_PROJECT_DIR="$dir" bash "$ENGINE" "$@" ); }
passed() { jq -e --arg g "$2" '.passed_gates | index($g)' "$1/.meridian/gate-state.json" >/dev/null 2>&1; }

test_human_gate_needs_artifacts_hooks_and_approval() {
    echo ""
    echo "Test: human approval gate"
    local p rc
    p=$(new_project)

    rc=0; engine "$p" mark-passed confirmed --approve OK >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 2 ] && ! passed "$p" confirmed && pass "refused while CONTRACT.md is missing" || fail "missing artifact not refused (rc=$rc)"

    : > "$p/CONTRACT.md"
    rc=0; engine "$p" mark-passed confirmed --approve OK >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 2 ] && ! passed "$p" confirmed && pass "refused while the pre-hook fails (empty contract)" || fail "failing pre-hook not refused (rc=$rc)"

    echo "scope" > "$p/CONTRACT.md"
    rc=0; engine "$p" mark-passed confirmed >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 2 ] && ! passed "$p" confirmed && pass "refused without --approve" || fail "passed without approval (rc=$rc)"

    rc=0; engine "$p" mark-passed confirmed --approve WRONG >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 2 ] && ! passed "$p" confirmed && pass "refused with the wrong token" || fail "wrong token accepted (rc=$rc)"

    rc=0; engine "$p" mark-passed confirmed --approve OK >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 0 ] && passed "$p" confirmed && pass "passes with artifacts, pre-hook, and the right token" || fail "valid approval refused (rc=$rc)"

    jq -e '.approvals.confirmed.by and .approvals.confirmed.at' "$p/.meridian/gate-state.json" >/dev/null 2>&1 \
        && pass "approval recorded with approver and time" || fail "no approval record"
    jq -e 'select(.event_type=="gate_passed" and .gate=="confirmed")' "$p/.meridian/telemetry.jsonl" >/dev/null 2>&1 \
        && pass "gate_passed telemetry emitted" || fail "no gate_passed event"
    [ "$(jq -s '[.[] | select(.event_type=="gate_blocked")] | length' "$p/.meridian/telemetry.jsonl")" -eq 4 ] \
        && pass "each refusal logged as gate_blocked" || fail "refusals not all logged"
    rm -rf "$p"
}

test_automated_gate_and_dependencies() {
    echo ""
    echo "Test: automated gate, dependencies, missing hooks"
    local p rc
    p=$(new_project)

    rc=0; engine "$p" mark-passed build >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 2 ] && ! passed "$p" build && pass "refused while dependency 'confirmed' has not passed" || fail "unmet dependency not refused (rc=$rc)"

    echo "scope" > "$p/CONTRACT.md"
    engine "$p" mark-passed confirmed --approve OK >/dev/null 2>&1
    touch "$p/BUILD_OK"
    rc=0; engine "$p" mark-passed build >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 0 ] && passed "$p" build && pass "automated gate passes without --approve once earned" || fail "automated gate refused (rc=$rc)"
    jq -e '.approvals.build' "$p/.meridian/gate-state.json" >/dev/null 2>&1 \
        && fail "automated gate should not get an approval record" || pass "no approval record for an automated gate"

    rc=0; engine "$p" verify ship >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 2 ] && pass "verify blocks when a declared pre-hook is not installed" || fail "missing hook did not block verify (rc=$rc)"
    rc=0; engine "$p" mark-passed ship >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 2 ] && ! passed "$p" ship && pass "mark-passed refuses a gate with a missing pre-hook" || fail "missing hook passed (rc=$rc)"
    rc=0; ( cd "$p" && MERIDIAN_ALLOW_MISSING_HOOKS=1 MERIDIAN_PROJECT_DIR="$p" bash "$ENGINE" verify ship ) >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 0 ] && pass "MERIDIAN_ALLOW_MISSING_HOOKS=1 opts back into skipping" || fail "opt-out did not skip (rc=$rc)"

    engine "$p" validate 2>&1 | grep -q "not-written-yet.sh' is declared but not installed" \
        && pass "validate warns about the missing hook up front" || fail "validate did not warn"
    rm -rf "$p"
}

test_verify_catches_hand_edited_state() {
    echo ""
    echo "Test: meridian-verify rejects a human gate passed without approval"
    local p rc
    p=$(new_project)
    cp "$MERIDIAN_DIR/scripts/gate-engine.sh" "$p/scripts/"
    echo '{"passed_gates":["confirmed"]}' > "$p/.meridian/gate-state.json"
    rc=0; bash "$VERIFY" "$p" --quiet --no-drift >/dev/null 2>&1 || rc=$?
    [ "$rc" -ne 0 ] && pass "verify fails: 'confirmed' passed with no approval record" || fail "hand-edited approval not caught"
    echo '{"passed_gates":["confirmed"],"approvals":{"confirmed":{"by":"Chris","at":"2026-09-29T00:00:00Z"}}}' > "$p/.meridian/gate-state.json"
    rc=0; bash "$VERIFY" "$p" --quiet --no-drift >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 0 ] && pass "verify passes once the approval is recorded" || fail "recorded approval still failed (rc=$rc)"
    echo '{"passed_gates":["ghost"]}' > "$p/.meridian/gate-state.json"
    rc=0; bash "$VERIFY" "$p" --quiet --no-drift >/dev/null 2>&1 || rc=$?
    [ "$rc" -ne 0 ] && pass "verify fails on a passed gate that gates.yaml doesn't define" || fail "unknown gate not caught"
    rm -rf "$p"
}

test_agent_cannot_approve_or_edit_state() {
    echo ""
    echo "Test: PreToolUse stops the agent from approving or editing gate state"
    local rc
    export MERIDIAN_PROJECT_DIR="$MERIDIAN_DIR"
    rc=0; TOOL_NAME=Bash COMMAND="bash scripts/gate-engine.sh mark-passed confirmed --approve CONFIRMED" bash "$PRE" >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 2 ] && pass "agent-run --approve is blocked" || fail "agent approval allowed (rc=$rc)"
    rc=0; TOOL_NAME=Bash COMMAND="bash scripts/gate-engine.sh mark-passed tests_passing" bash "$PRE" >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 0 ] && pass "agent may mark an automated gate (engine still checks it)" || fail "automated mark-passed blocked (rc=$rc)"
    rc=0; TOOL_NAME=Bash COMMAND="echo '{\"passed_gates\":[\"x\"]}' > .meridian/gate-state.json" bash "$PRE" >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 2 ] && pass "shell redirect into gate-state.json is blocked" || fail "redirect allowed (rc=$rc)"
    rc=0; TOOL_NAME=Bash COMMAND="jq . .meridian/gate-state.json" bash "$PRE" >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 0 ] && pass "reading gate-state.json is allowed" || fail "read blocked (rc=$rc)"
    rc=0; TOOL_NAME=Write FILE_PATH="$MERIDIAN_DIR/.meridian/gate-state.json" bash "$PRE" >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 2 ] && pass "Write tool on gate-state.json is blocked" || fail "Write allowed (rc=$rc)"
}

test_evaluator_as_pre_hook() {
    echo ""
    echo "Test: run-evaluator.sh works as a gate pre-hook (gate id from verify)"
    local p rc
    p=$(new_project)
    mkdir -p "$p/.claude/hooks" "$p/.meridian/evaluator"
    cp "$MERIDIAN_DIR/.claude/hooks/run-evaluator.sh" "$MERIDIAN_DIR/.claude/hooks/hook-wrapper.sh" "$p/.claude/hooks/"
    cat > "$p/.meridian/gates.yaml" <<'EOF'
version: "1.0"
gates:
  - id: reviewed
    type: automated
    requires: []
    hooks:
      pre:
        - run-evaluator.sh
EOF
    rc=0; engine "$p" verify reviewed >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 2 ] && pass "blocks when the gate has no evaluator verdict" || fail "no-verdict did not block (rc=$rc)"
    echo '{"gate":"reviewed","score":5.0,"verdict":"fail","notes":"gaps"}' > "$p/.meridian/evaluator/reviewed-verdict.json"
    rc=0; engine "$p" verify reviewed >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 2 ] && pass "blocks on a failing verdict" || fail "failing verdict did not block (rc=$rc)"
    echo '{"gate":"reviewed","score":8.0,"verdict":"pass","notes":""}' > "$p/.meridian/evaluator/reviewed-verdict.json"
    rc=0; engine "$p" verify reviewed >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 0 ] && pass "passes on a passing verdict for this gate" || fail "passing verdict blocked (rc=$rc)"
    rm -rf "$p"
}

main() {
    echo "━━━ Meridian gate passing tests ━━━"
    command -v yq >/dev/null 2>&1 || { echo "yq required"; exit 1; }
    test_human_gate_needs_artifacts_hooks_and_approval
    test_automated_gate_and_dependencies
    test_verify_catches_hand_edited_state
    test_agent_cannot_approve_or_edit_state
    test_evaluator_as_pre_hook
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Tests run: $TESTS_RUN | Passed: $TESTS_PASSED | Failed: $TESTS_FAILED"
    [ "$TESTS_FAILED" -eq 0 ]
}

main "$@"
