#!/bin/bash
# test-memory-hooks.sh
# Tests for Meridian memory-management hooks (Gate 2.3)
#
# Covers:
#   - write-reflexion.sh     (delta/variance math, validation, append)
#   - global-memory-sync.sh  (push/pull/status, idempotency, compact JSONL)
#   - context-trim.sh        (dry-run, trim+archive, idempotency)

set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS="$PROJECT_DIR/scripts"

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
TESTS_RUN=0; TESTS_PASSED=0; TESTS_FAILED=0
pass() { echo -e "${GREEN}✓${NC} $1"; TESTS_PASSED=$((TESTS_PASSED+1)); TESTS_RUN=$((TESTS_RUN+1)); }
fail() { echo -e "${RED}✗${NC} $1"; TESTS_FAILED=$((TESTS_FAILED+1)); TESTS_RUN=$((TESTS_RUN+1)); }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Build an isolated project with seeded memory; echoes its root
new_project() {
    local root; root=$(mktemp -d "$WORK/proj.XXXXXX")
    mkdir -p "$root/.meridian/memory"
    echo '{"session_id":"deadbeef","project":"fixture"}' > "$root/.meridian/session.json"
    cp "$PROJECT_DIR/.meridian/memory/semantic.json" "$root/.meridian/memory/semantic.json"
    echo "$root"
}

rc_of() { local rc=0; "$@" >/dev/null 2>&1 || rc=$?; echo "$rc"; }

#######################################
# write-reflexion.sh
#######################################
test_reflexion_append() {
    echo ""; echo "Test: write-reflexion appends a valid entry"
    local p; p=$(new_project)
    local rc; rc=$(rc_of env MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/write-reflexion.sh" \
        --gate 9.9 --predicted 6 --actual 5 --root-cause "rc" --action-next "an")
    if [ "$rc" -eq 0 ] && [ -f "$p/.meridian/memory/corrections.jsonl" ]; then
        pass "Entry appended (exit 0)"
    else
        fail "Expected append + exit 0 (got $rc)"
    fi
}

test_reflexion_delta_math() {
    echo ""; echo "Test: write-reflexion computes delta_ratio and variance"
    local p; p=$(new_project)
    MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/write-reflexion.sh" \
        --gate 9.9 --predicted 6 --actual 5 --root-cause "rc" --action-next "an" >/dev/null 2>&1
    local delta var
    delta=$(jq -r '.delta_ratio' "$p/.meridian/memory/corrections.jsonl" | tail -1 | tr -d '\r')
    var=$(jq -r '.variance_percent' "$p/.meridian/memory/corrections.jsonl" | tail -1 | tr -d '\r')
    # jq 1.7 preserves the numeric literal, so 6/5 serializes as "1.20"
    if [ "$delta" = "1.20" ] && [ "$var" = "-16.7" ]; then
        pass "delta_ratio=1.20, variance=-16.7 computed correctly"
    else
        fail "Expected delta 1.20 / var -16.7 (got $delta / $var)"
    fi
}

test_reflexion_missing_arg() {
    echo ""; echo "Test: write-reflexion errors on missing required arg"
    local p; p=$(new_project)
    local rc; rc=$(rc_of env MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/write-reflexion.sh" \
        --gate 1.0 --predicted 2)
    if [ "$rc" -ne 0 ] && [ ! -f "$p/.meridian/memory/corrections.jsonl" ]; then
        pass "Missing arg rejected, nothing written"
    else
        fail "Expected non-zero + no file (got $rc)"
    fi
}

test_reflexion_bad_actual() {
    echo ""; echo "Test: write-reflexion rejects non-positive actual hours"
    local p; p=$(new_project)
    local rc; rc=$(rc_of env MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/write-reflexion.sh" \
        --gate 1.0 --predicted 2 --actual 0 --root-cause x --action-next y)
    [ "$rc" -ne 0 ] && pass "Zero actual rejected (exit $rc)" || fail "Expected non-zero, got $rc"
}

test_reflexion_validates() {
    echo ""; echo "Test: appended reflexion passes validate-memory corrections"
    local p; p=$(new_project)
    MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/write-reflexion.sh" \
        --gate 9.9 --predicted 4 --actual 4 --root-cause "rc" --action-next "an" >/dev/null 2>&1
    local rc; rc=$(rc_of env MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/validate-memory.sh" \
        corrections "$p/.meridian/memory/corrections.jsonl")
    [ "$rc" -eq 0 ] && pass "Reflexion entry is schema-valid" || fail "validate-memory rejected entry (got $rc)"
}

#######################################
# global-memory-sync.sh
#######################################
seed_corrections() {  # $1 = project root
    MERIDIAN_PROJECT_DIR="$1" bash "$SCRIPTS/write-reflexion.sh" \
        --gate 1.1 --predicted 8 --actual 6 --root-cause "a" --action-next "b" >/dev/null 2>&1
    MERIDIAN_PROJECT_DIR="$1" bash "$SCRIPTS/write-reflexion.sh" \
        --gate 1.2 --predicted 4 --actual 4 --root-cause "c" --action-next "d" >/dev/null 2>&1
}

test_sync_status() {
    echo ""; echo "Test: global-memory-sync status runs"
    local p; p=$(new_project); local g="$WORK/g_status"
    local rc; rc=$(rc_of env MERIDIAN_PROJECT_DIR="$p" MERIDIAN_GLOBAL_DIR="$g" \
        bash "$SCRIPTS/global-memory-sync.sh" status)
    [ "$rc" -eq 0 ] && pass "status exits 0" || fail "status failed (got $rc)"
}

test_sync_push() {
    echo ""; echo "Test: global-memory-sync push creates and populates global"
    local p; p=$(new_project); local g="$WORK/g_push"; seed_corrections "$p"
    MERIDIAN_PROJECT_DIR="$p" MERIDIAN_GLOBAL_DIR="$g" bash "$SCRIPTS/global-memory-sync.sh" push >/dev/null 2>&1
    if [ -f "$g/corrections.jsonl" ] && [ "$(jq -s 'length' "$g/corrections.jsonl")" -eq 2 ] \
       && [ "$(jq '.patterns|length' "$g/semantic.json")" -eq 2 ]; then
        pass "Global populated (2 corrections, 2 patterns)"
    else
        fail "Global not populated as expected"
    fi
}

test_sync_idempotent() {
    echo ""; echo "Test: global-memory-sync push is idempotent"
    local p; p=$(new_project); local g="$WORK/g_idem"; seed_corrections "$p"
    MERIDIAN_PROJECT_DIR="$p" MERIDIAN_GLOBAL_DIR="$g" bash "$SCRIPTS/global-memory-sync.sh" push >/dev/null 2>&1
    MERIDIAN_PROJECT_DIR="$p" MERIDIAN_GLOBAL_DIR="$g" bash "$SCRIPTS/global-memory-sync.sh" push >/dev/null 2>&1
    [ "$(jq -s 'length' "$g/corrections.jsonl")" -eq 2 ] \
        && pass "Repeated push kept 2 corrections (no duplicates)" \
        || fail "Idempotency broken: $(jq -s 'length' "$g/corrections.jsonl") entries"
}

test_sync_compact_jsonl() {
    echo ""; echo "Test: global corrections stay one-object-per-line"
    local p; p=$(new_project); local g="$WORK/g_compact"; seed_corrections "$p"
    MERIDIAN_PROJECT_DIR="$p" MERIDIAN_GLOBAL_DIR="$g" bash "$SCRIPTS/global-memory-sync.sh" push >/dev/null 2>&1
    local phys obj
    phys=$(grep -cve '^[[:space:]]*$' "$g/corrections.jsonl")
    obj=$(jq -s 'length' "$g/corrections.jsonl")
    [ "$phys" -eq "$obj" ] && pass "Physical lines == JSON objects ($phys)" || fail "Pretty-printed: $phys lines vs $obj objects"
}

test_sync_pull() {
    echo ""; echo "Test: global-memory-sync pull merges patterns into fresh local"
    local p; p=$(new_project); local g="$WORK/g_pull"
    MERIDIAN_PROJECT_DIR="$p" MERIDIAN_GLOBAL_DIR="$g" bash "$SCRIPTS/global-memory-sync.sh" push >/dev/null 2>&1
    local p2; p2=$(mktemp -d "$WORK/proj2.XXXXXX"); mkdir -p "$p2/.meridian/memory"
    MERIDIAN_PROJECT_DIR="$p2" MERIDIAN_GLOBAL_DIR="$g" bash "$SCRIPTS/global-memory-sync.sh" pull >/dev/null 2>&1
    [ "$(jq '.patterns|length' "$p2/.meridian/memory/semantic.json")" -eq 2 ] \
        && pass "Pulled 2 patterns into fresh local" || fail "Pull did not merge patterns"
}

#######################################
# context-trim.sh
#######################################
make_episodic() {  # $1 = project root, $2 = number of sessions
    local root="$1" n="$2" i
    local ep="$root/.meridian/memory/episodic.jsonl"
    for i in $(seq 1 "$n"); do
        printf '{"timestamp":"2026-06-%02dT01:00:00Z","event_type":"session_start","session_id":"sess%05d","project":"t"}\n' "$i" "$i" >> "$ep"
        printf '{"timestamp":"2026-06-%02dT02:00:00Z","event_type":"session_end","session_id":"sess%05d","project":"t"}\n' "$i" "$i" >> "$ep"
    done
}

test_trim_dryrun() {
    echo ""; echo "Test: context-trim --dry-run does not modify the file"
    local p; p=$(new_project); make_episodic "$p" 5
    local before; before=$(wc -l < "$p/.meridian/memory/episodic.jsonl")
    MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/context-trim.sh" -n 2 --dry-run >/dev/null 2>&1
    local after; after=$(wc -l < "$p/.meridian/memory/episodic.jsonl")
    [ "$before" -eq "$after" ] && pass "File unchanged by dry-run ($after lines)" || fail "dry-run modified file"
}

test_trim_archives() {
    echo ""; echo "Test: context-trim keeps last N sessions and archives the rest"
    local p; p=$(new_project); make_episodic "$p" 5
    MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/context-trim.sh" -n 2 >/dev/null 2>&1
    local kept arch sessions
    kept=$(wc -l < "$p/.meridian/memory/episodic.jsonl")
    arch=$(wc -l < "$p/.meridian/memory/episodic-archive.jsonl")
    sessions=$(jq -r '.session_id' "$p/.meridian/memory/episodic.jsonl" | tr -d '\r' | sort -u | tr '\n' ' ')
    if [ "$kept" -eq 4 ] && [ "$arch" -eq 6 ] && [ "$sessions" = "sess00004 sess00005 " ]; then
        pass "Kept 2 newest sessions (4 events), archived 6"
    else
        fail "Unexpected trim: kept=$kept arch=$arch sessions=[$sessions]"
    fi
}

test_trim_idempotent() {
    echo ""; echo "Test: context-trim is a no-op when sessions <= N"
    local p; p=$(new_project); make_episodic "$p" 2
    local before; before=$(wc -l < "$p/.meridian/memory/episodic.jsonl")
    MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/context-trim.sh" -n 5 >/dev/null 2>&1
    local after; after=$(wc -l < "$p/.meridian/memory/episodic.jsonl")
    [ "$before" -eq "$after" ] && [ ! -f "$p/.meridian/memory/episodic-archive.jsonl" ] \
        && pass "No-op when under limit" || fail "Unexpectedly trimmed under limit"
}

test_trim_no_file() {
    echo ""; echo "Test: context-trim is safe with no episodic.jsonl"
    local p; p=$(new_project)
    local rc; rc=$(rc_of env MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/context-trim.sh" -n 3)
    [ "$rc" -eq 0 ] && pass "Missing episodic handled (exit 0)" || fail "Expected exit 0, got $rc"
}

#######################################
# Runner
#######################################
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Meridian Memory Management Hook Tests (Gate 2.3)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    test_reflexion_append
    test_reflexion_delta_math
    test_reflexion_missing_arg
    test_reflexion_bad_actual
    test_reflexion_validates
    test_sync_status
    test_sync_push
    test_sync_idempotent
    test_sync_compact_jsonl
    test_sync_pull
    test_trim_dryrun
    test_trim_archives
    test_trim_idempotent
    test_trim_no_file

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
