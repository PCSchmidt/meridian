#!/bin/bash
# test-calibration.sh
# Tests for G3.4: Calibrate the Judge
#
# Asserts that the pre-computed evaluation verdicts in
# tests/fixtures/calibration/ demonstrate correct discrimination:
#   - aligned fixture scores high on both evaluators
#   - drifted fixture scores low with high-severity findings
#   - happy-path-only fixture gets warn (not pass, not fail)
#   - aligned scores strictly higher than drifted on both evaluators

set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURES="$PROJECT_DIR/tests/fixtures/calibration"

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
TESTS_RUN=0; TESTS_PASSED=0; TESTS_FAILED=0
pass() { echo -e "${GREEN}✓${NC} $1"; TESTS_PASSED=$((TESTS_PASSED+1)); TESTS_RUN=$((TESTS_RUN+1)); }
fail() { echo -e "${RED}✗${NC} $1"; TESTS_FAILED=$((TESTS_FAILED+1)); TESTS_RUN=$((TESTS_RUN+1)); }

# ─── Helpers ─────────────────────────────────────────────────────────────────

drift_score()   { jq -r '.alignment_score' "$FIXTURES/$1/drift-verdict.json" | tr -d '\r'; }
drift_rec()     { jq -r '.recommendation'  "$FIXTURES/$1/drift-verdict.json" | tr -d '\r'; }
drift_highs()   { jq '[.divergences[] | select(.severity=="high")] | length' \
                      "$FIXTURES/$1/drift-verdict.json" | tr -d '\r'; }
drift_count()   { jq '.divergences | length' "$FIXTURES/$1/drift-verdict.json" | tr -d '\r'; }
drift_types()   { jq -r '[.divergences[].type] | join(",")' \
                      "$FIXTURES/$1/drift-verdict.json" | tr -d '\r'; }

gate_overall()  { jq -r '.overall'  "$FIXTURES/$1/gate-verdict.json" | tr -d '\r'; }
gate_verdict()  { jq -r '.verdict'  "$FIXTURES/$1/gate-verdict.json" | tr -d '\r'; }
gate_highs()    { jq '[.issues[] | select(.severity=="high")] | length' \
                      "$FIXTURES/$1/gate-verdict.json" | tr -d '\r'; }

gt() { awk "BEGIN{exit !($1 > $2)}"; }   # float greater-than
gte(){ awk "BEGIN{exit !($1 >= $2)}"; }  # float greater-or-equal
lte(){ awk "BEGIN{exit !($1 <= $2)}"; }  # float less-or-equal

# ─── Fixture presence ─────────────────────────────────────────────────────────

test_fixtures_present() {
    echo ""; echo "Test: all three fixture directories with required files exist"
    local missing="" f
    for f in aligned drifted happy-path-only; do
        [ -f "$FIXTURES/$f/CONTRACT.md" ]      || missing="${missing:+$missing }$f/CONTRACT.md"
        [ -f "$FIXTURES/$f/SPEC.md" ]          || missing="${missing:+$missing }$f/SPEC.md"
        [ -f "$FIXTURES/$f/FEATURES.json" ]    || missing="${missing:+$missing }$f/FEATURES.json"
        [ -f "$FIXTURES/$f/drift-verdict.json" ] || missing="${missing:+$missing }$f/drift-verdict.json"
        [ -f "$FIXTURES/$f/gate-verdict.json" ]  || missing="${missing:+$missing }$f/gate-verdict.json"
    done
    [ -z "$missing" ] && pass "All fixture files present" || fail "Missing: $missing"
}

test_calibration_doc_exists() {
    echo ""; echo "Test: CALIBRATION.md exists"
    [ -f "$PROJECT_DIR/CALIBRATION.md" ] \
        && pass "CALIBRATION.md present" \
        || fail "CALIBRATION.md missing"
}

# ─── Drift sensor: aligned ─────────────────────────────────────────────────

test_aligned_drift_score_high() {
    echo ""; echo "Test: aligned drift alignment_score >= 7"
    local s; s=$(drift_score aligned)
    gte "$s" 7 && pass "Aligned drift score $s >= 7" || fail "Aligned drift score $s < 7"
}

test_aligned_drift_recommendation() {
    echo ""; echo "Test: aligned drift recommendation = aligned"
    local r; r=$(drift_rec aligned)
    [ "$r" = "aligned" ] && pass "Aligned drift recommendation: aligned" \
        || fail "Aligned drift recommendation: $r (expected aligned)"
}

test_aligned_drift_no_divergences() {
    echo ""; echo "Test: aligned drift has no divergences"
    local n; n=$(drift_count aligned)
    [ "$n" -eq 0 ] && pass "Aligned drift: 0 divergences" \
        || fail "Aligned drift: $n divergences (expected 0)"
}

# ─── Drift sensor: drifted ─────────────────────────────────────────────────

test_drifted_drift_score_low() {
    echo ""; echo "Test: drifted drift alignment_score <= 5"
    local s; s=$(drift_score drifted)
    lte "$s" 5 && pass "Drifted drift score $s <= 5" || fail "Drifted drift score $s > 5"
}

test_drifted_drift_recommendation() {
    echo ""; echo "Test: drifted drift recommendation = drifted"
    local r; r=$(drift_rec drifted)
    [ "$r" = "drifted" ] && pass "Drifted drift recommendation: drifted" \
        || fail "Drifted drift recommendation: $r (expected drifted)"
}

test_drifted_drift_has_high_severity() {
    echo ""; echo "Test: drifted drift has at least one high-severity divergence"
    local n; n=$(drift_highs drifted)
    [ "$n" -ge 1 ] && pass "Drifted drift: $n high-severity divergence(s)" \
        || fail "Drifted drift: no high-severity divergences"
}

test_drifted_drift_has_scope_creep() {
    echo ""; echo "Test: drifted drift divergences include scope_creep type"
    local types; types=$(drift_types drifted)
    echo "$types" | grep -q "scope_creep" \
        && pass "Drifted drift: scope_creep divergence present" \
        || fail "Drifted drift: no scope_creep divergence (types: $types)"
}

# ─── Drift sensor: happy-path-only ────────────────────────────────────────

test_happy_path_drift_recommendation() {
    echo ""; echo "Test: happy-path-only drift recommendation = warn (not aligned, not drifted)"
    local r; r=$(drift_rec happy-path-only)
    [ "$r" = "warn" ] && pass "Happy-path-only drift recommendation: warn" \
        || fail "Happy-path-only drift recommendation: $r (expected warn)"
}

test_happy_path_drift_has_feature_lag() {
    echo ""; echo "Test: happy-path-only drift divergences include feature_lag"
    local types; types=$(drift_types happy-path-only)
    echo "$types" | grep -q "feature_lag" \
        && pass "Happy-path-only drift: feature_lag divergence present" \
        || fail "Happy-path-only drift: no feature_lag divergence (types: $types)"
}

# ─── Gate evaluator: aligned ──────────────────────────────────────────────

test_aligned_gate_score_high() {
    echo ""; echo "Test: aligned gate overall >= 7.0"
    local s; s=$(gate_overall aligned)
    gte "$s" 7.0 && pass "Aligned gate overall $s >= 7.0" \
        || fail "Aligned gate overall $s < 7.0"
}

test_aligned_gate_verdict_pass() {
    echo ""; echo "Test: aligned gate verdict = pass"
    local v; v=$(gate_verdict aligned)
    [ "$v" = "pass" ] && pass "Aligned gate verdict: pass" \
        || fail "Aligned gate verdict: $v (expected pass)"
}

# ─── Gate evaluator: drifted ──────────────────────────────────────────────

test_drifted_gate_score_low() {
    echo ""; echo "Test: drifted gate overall <= 5.0"
    local s; s=$(gate_overall drifted)
    lte "$s" 5.0 && pass "Drifted gate overall $s <= 5.0" \
        || fail "Drifted gate overall $s > 5.0"
}

test_drifted_gate_verdict_fail() {
    echo ""; echo "Test: drifted gate verdict = fail"
    local v; v=$(gate_verdict drifted)
    [ "$v" = "fail" ] && pass "Drifted gate verdict: fail" \
        || fail "Drifted gate verdict: $v (expected fail)"
}

test_drifted_gate_has_high_issues() {
    echo ""; echo "Test: drifted gate has at least one high-severity issue"
    local n; n=$(gate_highs drifted)
    [ "$n" -ge 1 ] && pass "Drifted gate: $n high-severity issue(s)" \
        || fail "Drifted gate: no high-severity issues"
}

# ─── Gate evaluator: happy-path-only ────────────────────────────────────

test_happy_path_gate_verdict_warn() {
    echo ""; echo "Test: happy-path-only gate verdict = warn"
    local v; v=$(gate_verdict happy-path-only)
    [ "$v" = "warn" ] && pass "Happy-path-only gate verdict: warn" \
        || fail "Happy-path-only gate verdict: $v (expected warn)"
}

test_happy_path_gate_score_between() {
    echo ""; echo "Test: happy-path-only gate overall in [4.0, 7.0)"
    local s; s=$(gate_overall happy-path-only)
    gte "$s" 4.0 && ! gte "$s" 7.0 \
        && pass "Happy-path-only gate overall $s in [4.0, 7.0)" \
        || fail "Happy-path-only gate overall $s outside [4.0, 7.0)"
}

# ─── Discrimination assertions ────────────────────────────────────────────

test_discrimination_drift() {
    echo ""; echo "Test: drift sensor — aligned score strictly > drifted score"
    local a d; a=$(drift_score aligned); d=$(drift_score drifted)
    gt "$a" "$d" && pass "Drift discrimination: aligned $a > drifted $d" \
        || fail "Drift: aligned $a not > drifted $d (no discrimination)"
}

test_discrimination_gate() {
    echo ""; echo "Test: gate evaluator — aligned overall strictly > drifted overall"
    local a d; a=$(gate_overall aligned); d=$(gate_overall drifted)
    gt "$a" "$d" && pass "Gate discrimination: aligned $a > drifted $d" \
        || fail "Gate: aligned $a not > drifted $d (no discrimination)"
}

test_discrimination_gate_catches_lifecycle_gap() {
    echo ""; echo "Test: gate evaluator scores happy-path-only lower than aligned (lifecycle gap visible)"
    local a h; a=$(gate_overall aligned); h=$(gate_overall happy-path-only)
    gt "$a" "$h" && pass "Gate catches lifecycle gap: aligned $a > happy-path-only $h" \
        || fail "Gate fails to discriminate: aligned $a not > happy-path-only $h"
}

# ─── Runner ───────────────────────────────────────────────────────────────────

main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Meridian Calibration Tests (Gate 3.4)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    echo ""; echo "=== Fixture presence ==="
    test_fixtures_present
    test_calibration_doc_exists

    echo ""; echo "=== Drift sensor: aligned ==="
    test_aligned_drift_score_high
    test_aligned_drift_recommendation
    test_aligned_drift_no_divergences

    echo ""; echo "=== Drift sensor: drifted ==="
    test_drifted_drift_score_low
    test_drifted_drift_recommendation
    test_drifted_drift_has_high_severity
    test_drifted_drift_has_scope_creep

    echo ""; echo "=== Drift sensor: happy-path-only ==="
    test_happy_path_drift_recommendation
    test_happy_path_drift_has_feature_lag

    echo ""; echo "=== Gate evaluator: aligned ==="
    test_aligned_gate_score_high
    test_aligned_gate_verdict_pass

    echo ""; echo "=== Gate evaluator: drifted ==="
    test_drifted_gate_score_low
    test_drifted_gate_verdict_fail
    test_drifted_gate_has_high_issues

    echo ""; echo "=== Gate evaluator: happy-path-only ==="
    test_happy_path_gate_verdict_warn
    test_happy_path_gate_score_between

    echo ""; echo "=== Discrimination ==="
    test_discrimination_drift
    test_discrimination_gate
    test_discrimination_gate_catches_lifecycle_gap

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
