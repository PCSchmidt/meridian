#!/bin/bash
# test-verdict-integrity.sh
# Verdict integrity: sealed verdicts, stale/edited/unsealed rejection, and the PreToolUse
# guard on .meridian/evaluator/ (scripts/write-verdict.sh + run-evaluator.sh --check).

set -uo pipefail

MERIDIAN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_EVAL="$MERIDIAN_DIR/.claude/hooks/run-evaluator.sh"
PRE="$MERIDIAN_DIR/.claude/hooks/PreToolUse.sh"
WRITE="$MERIDIAN_DIR/scripts/write-verdict.sh"

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
RUN=0; PASS=0; FAIL=0
pass() { echo -e "${GREEN}✓${NC} $1"; PASS=$((PASS+1)); RUN=$((RUN+1)); }
fail() { echo -e "${RED}✗${NC} $1"; FAIL=$((FAIL+1)); RUN=$((RUN+1)); }
check_rc() { # name expected actual
    [ "$3" -eq "$2" ] && pass "$1" || fail "$1 (expected rc=$2, got rc=$3)"
}

new_project() {
    local p; p=$(mktemp -d)
    mkdir -p "$p/.meridian/evaluator" "$p/docs" "$p/.claude/hooks" "$p/scripts"
    cp "$RUN_EVAL" "$MERIDIAN_DIR/.claude/hooks/hook-wrapper.sh" "$p/.claude/hooks/"
    echo "# spec v1" > "$p/docs/spec.md"
    echo "# plan v1" > "$p/docs/plan.md"
    echo "$p"
}

prepare() { MERIDIAN_PROJECT_DIR="$1" bash "$1/.claude/hooks/run-evaluator.sh" --prepare reviewed docs/spec.md docs/plan.md >/dev/null 2>&1; }
seal() { # project verdict-json
    echo "$2" | MERIDIAN_PROJECT_DIR="$1" bash "$WRITE" reviewed --model test-model-x >/dev/null 2>&1
}
check() { local rc=0; MERIDIAN_PROJECT_DIR="$1" bash "$1/.claude/hooks/run-evaluator.sh" --check reviewed >/dev/null 2>&1 || rc=$?; echo "$rc"; }

GOOD='{"gate":"reviewed","overall":8.5,"verdict":"pass","notes":"ok"}'

test_sealed_verdict_passes() {
    echo ""; echo "Test: a sealed verdict is accepted and carries integrity fields"
    local p; p=$(new_project); prepare "$p"
    seal "$p" "$GOOD"
    local f="$p/.meridian/evaluator/reviewed-verdict.json"
    [ -f "$f" ] && pass "write-verdict wrote the verdict" || fail "no verdict written"
    [ "$(jq -r '.evaluator_model' "$f" | tr -d '\r')" = "test-model-x" ] && pass "evaluator model recorded" || fail "model missing"
    [ "$(jq -r '.artifact_digests | length' "$f" | tr -d '\r')" = "2" ] && pass "both artifacts digested" || fail "digests missing"
    [ "$(jq -r '.score' "$f" | tr -d '\r')" = "8.5" ] && pass "overall mapped to score" || fail "score not set"
    check_rc "sealed verdict passes --check" 0 "$(check "$p")"
    rm -rf "$p"
}

test_stale_verdict_rejected() {
    echo ""; echo "Test: changing an evaluated artifact makes the verdict stale"
    local p; p=$(new_project); prepare "$p"; seal "$p" "$GOOD"
    echo "# spec v2 (changed after evaluation)" > "$p/docs/spec.md"
    check_rc "modified artifact is rejected as stale" 2 "$(check "$p")"
    echo "# spec v1" > "$p/docs/spec.md"
    check_rc "restoring the artifact restores validity" 0 "$(check "$p")"
    rm "$p/docs/plan.md"
    check_rc "deleted artifact is rejected as stale" 2 "$(check "$p")"
    rm -rf "$p"
}

test_edited_verdict_rejected() {
    echo ""; echo "Test: hand-editing a sealed verdict is detected"
    local p; p=$(new_project); prepare "$p"
    seal "$p" '{"gate":"reviewed","overall":4.0,"verdict":"fail","notes":"gaps"}'
    check_rc "sealed FAIL verdict blocks" 2 "$(check "$p")"
    local f="$p/.meridian/evaluator/reviewed-verdict.json"
    jq '.score = 9.9 | .verdict = "pass"' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    check_rc "forged pass over a FAIL is rejected (verdict_hash mismatch)" 2 "$(check "$p")"
    jq '.evaluator_model = "other"' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    check_rc "changed model id is rejected" 2 "$(check "$p")"
    rm -rf "$p"
}

test_unsealed_verdict_rejected() {
    echo ""; echo "Test: bare (unsealed) verdicts are rejected unless legacy mode is set"
    local p; p=$(new_project); prepare "$p"
    echo '{"gate":"reviewed","score":9.0,"verdict":"pass","notes":"self-written"}' > "$p/.meridian/evaluator/reviewed-verdict.json"
    check_rc "unsealed verdict blocks by default" 2 "$(check "$p")"
    local rc=0
    MERIDIAN_ALLOW_UNHASHED_VERDICTS=1 MERIDIAN_PROJECT_DIR="$p" bash "$p/.claude/hooks/run-evaluator.sh" --check reviewed >/dev/null 2>&1 || rc=$?
    check_rc "legacy mode accepts it with a warning" 0 "$rc"
    rm -rf "$p"
}

test_write_verdict_validation() {
    echo ""; echo "Test: write-verdict.sh refuses bad input"
    local p rc; p=$(new_project)
    rc=0; echo "$GOOD" | MERIDIAN_PROJECT_DIR="$p" bash "$WRITE" reviewed --model m >/dev/null 2>&1 || rc=$?
    check_rc "no request file -> refused" 1 "$rc"
    prepare "$p"
    rc=0; echo "$GOOD" | MERIDIAN_PROJECT_DIR="$p" bash "$WRITE" reviewed >/dev/null 2>&1 || rc=$?
    check_rc "missing --model -> refused" 1 "$rc"
    rc=0; echo 'not json' | MERIDIAN_PROJECT_DIR="$p" bash "$WRITE" reviewed --model m >/dev/null 2>&1 || rc=$?
    check_rc "invalid JSON -> refused" 1 "$rc"
    rc=0; echo '{"overall":8,"verdict":"great"}' | MERIDIAN_PROJECT_DIR="$p" bash "$WRITE" reviewed --model m >/dev/null 2>&1 || rc=$?
    check_rc "unknown verdict value -> refused" 1 "$rc"
    rc=0; echo "$GOOD" | MERIDIAN_PROJECT_DIR="$p" bash "$WRITE" "../evil" --model m >/dev/null 2>&1 || rc=$?
    check_rc "path-like gate id -> refused" 1 "$rc"
    MERIDIAN_PROJECT_DIR="$p" bash "$p/.claude/hooks/run-evaluator.sh" --prepare reviewed ../outside.md >/dev/null 2>&1
    rc=0; echo "$GOOD" | MERIDIAN_PROJECT_DIR="$p" bash "$WRITE" reviewed --model m >/dev/null 2>&1 || rc=$?
    check_rc "artifact path with .. -> refused" 1 "$rc"
    rm -rf "$p"
}

test_pretooluse_guard() {
    echo ""; echo "Test: PreToolUse blocks direct writes to verdict files, allows the sanctioned writer"
    local rc
    export MERIDIAN_PROJECT_DIR="$MERIDIAN_DIR"
    rc=0; TOOL_NAME=Write FILE_PATH="$MERIDIAN_DIR/.meridian/evaluator/reviewed-verdict.json" bash "$PRE" >/dev/null 2>&1 || rc=$?
    check_rc "Write tool to a verdict file is blocked" 2 "$rc"
    rc=0; TOOL_NAME=Edit FILE_PATH="$MERIDIAN_DIR/.meridian/evaluator/reviewed-verdict.json" bash "$PRE" >/dev/null 2>&1 || rc=$?
    check_rc "Edit tool to a verdict file is blocked" 2 "$rc"
    rc=0; TOOL_NAME=Bash COMMAND="echo '{}' > .meridian/evaluator/reviewed-verdict.json" bash "$PRE" >/dev/null 2>&1 || rc=$?
    check_rc "shell redirect into the evaluator dir is blocked" 2 "$rc"
    rc=0; TOOL_NAME=Bash COMMAND="cp /tmp/x .meridian/evaluator/reviewed-verdict.json" bash "$PRE" >/dev/null 2>&1 || rc=$?
    check_rc "cp into the evaluator dir is blocked" 2 "$rc"
    rc=0; TOOL_NAME=Bash COMMAND="python -c \"open('.meridian/evaluator/a-verdict.json','w')\"" bash "$PRE" >/dev/null 2>&1 || rc=$?
    check_rc "python writing into the evaluator dir is blocked" 2 "$rc"
    rc=0; TOOL_NAME=Bash COMMAND="cat verdict.json | bash scripts/write-verdict.sh reviewed --model m" bash "$PRE" >/dev/null 2>&1 || rc=$?
    check_rc "the sanctioned writer is allowed" 0 "$rc"
    rc=0; TOOL_NAME=Bash COMMAND="jq . .meridian/evaluator/reviewed-verdict.json" bash "$PRE" >/dev/null 2>&1 || rc=$?
    check_rc "reading a verdict is allowed" 0 "$rc"
    rc=0; TOOL_NAME=Write FILE_PATH="$MERIDIAN_DIR/.meridian/evaluator/reviewed-request.json" bash "$PRE" >/dev/null 2>&1 || rc=$?
    check_rc "request files are not guarded" 0 "$rc"
}

main() {
    echo "━━━ Meridian verdict integrity tests ━━━"
    command -v jq >/dev/null 2>&1 || { echo "jq required"; exit 1; }
    test_sealed_verdict_passes
    test_stale_verdict_rejected
    test_edited_verdict_rejected
    test_unsealed_verdict_rejected
    test_write_verdict_validation
    test_pretooluse_guard
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Tests run: $RUN | Passed: $PASS | Failed: $FAIL"
    [ "$FAIL" -eq 0 ]
}
main "$@"
