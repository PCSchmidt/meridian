#!/bin/bash
# test-integration-phase2.sh
# Phase 2 Integration Tests — cross-component verification (Gate 2.6)
#
# Covers cross-cutting interactions introduced in Phase 2.
# Unit tests live in test-security.sh, test-gate-enforcement.sh,
# test-memory-hooks.sh, and test-skills.sh.
#
# Sections:
#   A. Security blocking flows through PreToolUse end-to-end
#   B. Gate enforcement pipeline (verify runs hooks.pre, blocks on failure)
#   C. Memory hooks pipeline (reflexion write → validate → telemetry)
#   D. Skills layer (manifest valid, all 12 docs present with frontmatter)
#   E. Progressive disclosure (metadata budget is bounded)
#   F. Phase coherence (health + status + security + skills agree on state)

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export MERIDIAN_PROJECT_DIR="$PROJECT_DIR"

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

TESTS_RUN=0; TESTS_PASSED=0; TESTS_FAILED=0

pass()    { echo -e "  ${GREEN}✓${NC} $1"; TESTS_PASSED=$((TESTS_PASSED+1)); TESTS_RUN=$((TESTS_RUN+1)); }
fail()    { echo -e "  ${RED}✗${NC} $1"; TESTS_FAILED=$((TESTS_FAILED+1)); TESTS_RUN=$((TESTS_RUN+1)); }
section() { echo ""; echo -e "${BLUE}${BOLD}── $1 ──${NC}"; }

WORK=""
trap 'rm -rf "$WORK"' EXIT

# ─── A. Security blocking end-to-end through PreToolUse ──────────────────────

test_pretooluse_blocks_dangerous_command() {
    local rf="-r""f"
    local rc=0
    TOOL_NAME=Bash COMMAND="rm $rf /" bash "$PROJECT_DIR/.claude/hooks/PreToolUse.sh" \
        >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 2 ] \
        && pass "PreToolUse exits 2 on dangerous command (rm -rf /)" \
        || fail "PreToolUse should block dangerous command (got $rc)"
}

test_pretooluse_allows_safe_command() {
    local rc=0
    TOOL_NAME=Bash COMMAND="echo hello" bash "$PROJECT_DIR/.claude/hooks/PreToolUse.sh" \
        >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 0 ] \
        && pass "PreToolUse allows safe command (exit 0)" \
        || fail "PreToolUse should allow safe command (got $rc)"
}

test_security_rules_yaml_is_valid() {
    local rules="$PROJECT_DIR/.meridian/security-rules.yaml"
    local count
    count=$(awk '/^[[:space:]]*-[[:space:]]+id:/ {n++} END {print n+0}' "$rules")
    [ "$count" -ge 8 ] \
        && pass "security-rules.yaml present with $count rules" \
        || fail "Expected >=8 rules in security-rules.yaml (got $count)"
}

test_security_audit_runs_cleanly() {
    local rc=0
    bash "$PROJECT_DIR/scripts/security-audit.sh" full >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 0 ] \
        && pass "security-audit.sh full exits 0 on clean project" \
        || fail "security-audit.sh full failed (got $rc)"
}

# ─── B. Gate enforcement pipeline ────────────────────────────────────────────

test_gate_verify_passes_clean_gate() {
    WORK=$(mktemp -d); mkdir -p "$WORK/.meridian" "$WORK/.claude/hooks"
    printf '#!/bin/bash\nexit 0\n' > "$WORK/.claude/hooks/pass-hook.sh"
    cat > "$WORK/.meridian/gates.yaml" <<'YAML'
version: "1.0"
project:
  name: "test"
  recipe: "cli-tool"
gates:
  - id: clean_gate
    type: automated
    requires: []
    hooks:
      pre:
        - pass-hook.sh
YAML
    local rc=0
    MERIDIAN_PROJECT_DIR="$WORK" bash "$PROJECT_DIR/scripts/gate-engine.sh" \
        verify clean_gate >/dev/null 2>&1 || rc=$?
    rm -rf "$WORK"; WORK=$(mktemp -d)
    [ "$rc" -eq 0 ] \
        && pass "gate-engine verify exits 0 when all pre-hooks pass" \
        || fail "gate-engine verify should exit 0 on clean gate (got $rc)"
}

test_gate_verify_blocks_failing_gate() {
    WORK=$(mktemp -d); mkdir -p "$WORK/.meridian" "$WORK/.claude/hooks"
    printf '#!/bin/bash\nexit 2\n' > "$WORK/.claude/hooks/fail-hook.sh"
    cat > "$WORK/.meridian/gates.yaml" <<'YAML'
version: "1.0"
project:
  name: "test"
  recipe: "cli-tool"
gates:
  - id: blocked_gate
    type: automated
    requires: []
    hooks:
      pre:
        - fail-hook.sh
YAML
    local rc=0
    MERIDIAN_PROJECT_DIR="$WORK" bash "$PROJECT_DIR/scripts/gate-engine.sh" \
        verify blocked_gate >/dev/null 2>&1 || rc=$?
    rm -rf "$WORK"; WORK=$(mktemp -d)
    [ "$rc" -eq 2 ] \
        && pass "gate-engine verify exits 2 when a pre-hook blocks" \
        || fail "gate-engine verify should exit 2 on blocking hook (got $rc)"
}

test_run_evaluator_blocks_without_verdict() {
    WORK=$(mktemp -d)
    local rc=0
    EVALUATOR_DIR="$WORK" bash "$PROJECT_DIR/.claude/hooks/run-evaluator.sh" \
        --check test-gate >/dev/null 2>&1 || rc=$?
    rm -rf "$WORK"; WORK=$(mktemp -d)
    [ "$rc" -eq 2 ] \
        && pass "run-evaluator.sh blocks (exit 2) when no verdict file exists" \
        || fail "run-evaluator.sh should block without verdict (got $rc)"
}

test_run_evaluator_passes_with_good_verdict() {
    WORK=$(mktemp -d)
    printf '{"gate":"test-gate","score":8.5,"verdict":"pass","notes":"ok"}\n' \
        > "$WORK/test-gate-verdict.json"
    local rc=0
    EVALUATOR_DIR="$WORK" bash "$PROJECT_DIR/.claude/hooks/run-evaluator.sh" \
        --check test-gate >/dev/null 2>&1 || rc=$?
    rm -rf "$WORK"; WORK=$(mktemp -d)
    [ "$rc" -eq 0 ] \
        && pass "run-evaluator.sh passes (exit 0) with a passing verdict file" \
        || fail "run-evaluator.sh should pass with good verdict (got $rc)"
}

# ─── C. Memory hooks pipeline ────────────────────────────────────────────────

test_reflexion_write_validates_and_appends() {
    WORK=$(mktemp -d); mkdir -p "$WORK/.meridian/memory"
    printf '{"session_id":"deadbeef","project":"inttest"}\n' \
        > "$WORK/.meridian/session.json"
    local rc=0
    MERIDIAN_PROJECT_DIR="$WORK" bash "$PROJECT_DIR/scripts/write-reflexion.sh" \
        --gate 9.9 --predicted 4 --actual 3 \
        --root-cause "integration test entry" --action-next "none" \
        >/dev/null 2>&1 || rc=$?
    local valid=1
    if [ "$rc" -eq 0 ] && [ -f "$WORK/.meridian/memory/corrections.jsonl" ]; then
        MERIDIAN_PROJECT_DIR="$WORK" bash "$PROJECT_DIR/scripts/validate-memory.sh" \
            corrections "$WORK/.meridian/memory/corrections.jsonl" \
            >/dev/null 2>&1 || valid=0
    fi
    rm -rf "$WORK"; WORK=$(mktemp -d)
    [ "$rc" -eq 0 ] && [ "$valid" -eq 1 ] \
        && pass "write-reflexion.sh appends a schema-valid corrections entry" \
        || fail "write-reflexion.sh failed or entry invalid (rc=$rc valid=$valid)"
}

test_context_trim_archives_old_sessions() {
    WORK=$(mktemp -d); mkdir -p "$WORK/.meridian/memory"
    local ep="$WORK/.meridian/memory/episodic.jsonl"
    for i in $(seq 1 5); do
        printf '{"timestamp":"2026-06-%02dT01:00:00Z","event_type":"session_start","session_id":"s%05d","project":"t"}\n' \
            "$i" "$i" >> "$ep"
        printf '{"timestamp":"2026-06-%02dT02:00:00Z","event_type":"session_end","session_id":"s%05d","project":"t"}\n' \
            "$i" "$i" >> "$ep"
    done
    MERIDIAN_PROJECT_DIR="$WORK" bash "$PROJECT_DIR/scripts/context-trim.sh" -n 2 >/dev/null 2>&1
    local kept arch
    kept=$(wc -l < "$ep" | tr -d ' ')
    arch=$(wc -l < "$WORK/.meridian/memory/episodic-archive.jsonl" 2>/dev/null | tr -d ' ')
    rm -rf "$WORK"; WORK=$(mktemp -d)
    [ "$kept" -eq 4 ] && [ "$arch" -eq 6 ] \
        && pass "context-trim.sh keeps 2 sessions (4 events) and archives 6" \
        || fail "context-trim.sh unexpected result: kept=$kept archived=$arch"
}

test_global_sync_push_is_idempotent() {
    WORK=$(mktemp -d); local glob="$WORK/global"
    local p="$WORK/proj"; mkdir -p "$p/.meridian/memory"
    cp "$PROJECT_DIR/.meridian/memory/semantic.json" "$p/.meridian/memory/semantic.json"
    MERIDIAN_PROJECT_DIR="$p" MERIDIAN_GLOBAL_DIR="$glob" \
        bash "$PROJECT_DIR/scripts/global-memory-sync.sh" push >/dev/null 2>&1
    local n1; n1=$(wc -l < "$glob/corrections.jsonl" 2>/dev/null | tr -d ' '); n1=${n1:-0}
    MERIDIAN_PROJECT_DIR="$p" MERIDIAN_GLOBAL_DIR="$glob" \
        bash "$PROJECT_DIR/scripts/global-memory-sync.sh" push >/dev/null 2>&1
    local n2; n2=$(wc -l < "$glob/corrections.jsonl" 2>/dev/null | tr -d ' '); n2=${n2:-0}
    rm -rf "$WORK"
    [ "$n1" -eq "$n2" ] \
        && pass "global-memory-sync.sh push is idempotent (no duplicates on second push)" \
        || fail "global-memory-sync.sh: second push changed count ($n1 → $n2)"
}

# ─── D. Skills layer ─────────────────────────────────────────────────────────

test_all_12_skill_docs_present() {
    local missing="" s
    for s in start health memory status deploy security testing costs \
              rollback build-rules critical-thinker research; do
        [ -f "$PROJECT_DIR/.claude/skills/$s/$s.md" ] || missing="${missing:+$missing }$s"
    done
    [ -z "$missing" ] \
        && pass "All 12 core skill docs present in .claude/skills/" \
        || fail "Missing skill docs: $missing"
}

test_skill_manifest_validates() {
    local rc=0
    bash "$PROJECT_DIR/scripts/skill-manifest.sh" validate >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 0 ] \
        && pass "skill-manifest.sh validate passes (all 12 docs have required frontmatter)" \
        || fail "skill-manifest.sh validate failed (exit $rc)"
}

# ─── E. Progressive disclosure ───────────────────────────────────────────────

test_metadata_token_budget_bounded() {
    local total_meta=0
    while IFS=$'\t' read -r _name _trigger _type _load tmeta _btok _status _purpose; do
        [ "$tmeta" = "?" ] && continue
        total_meta=$((total_meta + tmeta))
    done < <(bash "$PROJECT_DIR/scripts/skill-manifest.sh" --json 2>/dev/null \
        | jq -r '.[] | [.name,.trigger,.type,.load,(.tokens_metadata|tostring),.body_tokens,.status,.purpose] | @tsv' \
        2>/dev/null || true)

    # 12 skills × ~65t declared ≈ 780t; enforce < 1500t as a meaningful ceiling
    [ "$total_meta" -gt 0 ] && [ "$total_meta" -lt 1500 ] \
        && pass "Progressive disclosure metadata budget bounded (total ~${total_meta}t < 1500t)" \
        || fail "Metadata budget out of range (got ${total_meta}t; expect 0 < x < 1500)"
}

test_body_tokens_exceed_metadata() {
    local json
    json=$(bash "$PROJECT_DIR/scripts/skill-manifest.sh" --json 2>/dev/null)
    local total_meta total_body
    total_meta=$(echo "$json" | jq '[.[] | .tokens_metadata // 0] | add' 2>/dev/null || echo 0)
    total_body=$(echo  "$json" | jq '[.[] | (.body_tokens // 0 | tonumber)] | add' 2>/dev/null || echo 0)
    total_meta=$(echo "$total_meta" | tr -d '\r')
    total_body=$(echo "$total_body" | tr -d '\r')
    awk -v m="$total_meta" -v b="$total_body" 'BEGIN{exit !(b > m*2)}' \
        && pass "Body tokens (${total_body}t) far exceed metadata (${total_meta}t) — disclosure savings proven" \
        || fail "Expected body>>metadata; got body=${total_body}t meta=${total_meta}t"
}

# ─── F. Phase coherence ──────────────────────────────────────────────────────

test_health_reflects_phase2_gates() {
    local json
    json=$(bash "$PROJECT_DIR/scripts/health-report.sh" --json 2>/dev/null)
    local gates
    gates=$(echo "$json" | jq '.calibration.gates_tracked // 0' 2>/dev/null | tr -d '\r')
    [ "$gates" -ge 9 ] \
        && pass "health report tracks ≥9 gate calibration entries (Phase 1 + Phase 2)" \
        || fail "Expected >=9 gate entries in health report (got $gates)"
}

test_status_shows_completed_gates() {
    local json
    json=$(bash "$PROJECT_DIR/scripts/status-report.sh" --json 2>/dev/null)
    local completed
    completed=$(echo "$json" | jq '.gates_completed // 0' 2>/dev/null | tr -d '\r')
    [ "$completed" -ge 9 ] \
        && pass "status report shows ≥9 completed gates" \
        || fail "Expected >=9 completed gates in status (got $completed)"
}

test_cost_report_runs_cleanly() {
    local rc=0
    bash "$PROJECT_DIR/scripts/cost-report.sh" --json >/dev/null 2>&1 || rc=$?
    [ "$rc" -eq 0 ] \
        && pass "cost-report.sh --json runs cleanly (honest zero until token source wired)" \
        || fail "cost-report.sh failed (exit $rc)"
}

test_all_test_suites_pass() {
    local failed=0 suite
    for suite in \
        test-hooks.sh test-telemetry.sh test-health.sh test-status.sh \
        test-security.sh test-gate-enforcement.sh test-memory-hooks.sh \
        test-skills.sh test-integration-phase1.sh; do
        bash "$PROJECT_DIR/tests/$suite" >/dev/null 2>&1 || { failed=$((failed+1)); }
    done
    [ "$failed" -eq 0 ] \
        && pass "All 9 existing test suites pass (regression clean)" \
        || fail "$failed existing suite(s) failing — Phase 2 has regressions"
}

# ─── Runner ──────────────────────────────────────────────────────────────────

main() {
    WORK=$(mktemp -d)

    echo ""
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}${BOLD}  Meridian Phase 2 Integration Tests (Gate 2.6)${NC}"
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    section "A. Security blocking (end-to-end through PreToolUse)"
    test_pretooluse_blocks_dangerous_command
    test_pretooluse_allows_safe_command
    test_security_rules_yaml_is_valid
    test_security_audit_runs_cleanly

    section "B. Gate enforcement pipeline"
    test_gate_verify_passes_clean_gate
    test_gate_verify_blocks_failing_gate
    test_run_evaluator_blocks_without_verdict
    test_run_evaluator_passes_with_good_verdict

    section "C. Memory hooks pipeline"
    test_reflexion_write_validates_and_appends
    test_context_trim_archives_old_sessions
    test_global_sync_push_is_idempotent

    section "D. Skills layer"
    test_all_12_skill_docs_present
    test_skill_manifest_validates

    section "E. Progressive disclosure"
    test_metadata_token_budget_bounded
    test_body_tokens_exceed_metadata

    section "F. Phase coherence"
    test_health_reflects_phase2_gates
    test_status_shows_completed_gates
    test_cost_report_runs_cleanly
    test_all_test_suites_pass

    echo ""
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "Results: $TESTS_PASSED/$TESTS_RUN passed"
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All Phase 2 integration tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}$TESTS_FAILED test(s) failed${NC}"
        exit 1
    fi
}

main "$@"
