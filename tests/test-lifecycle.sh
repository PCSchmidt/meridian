#!/bin/bash
# test-lifecycle.sh
# Tests for Gate 3.2: Lifecycle-Aware Completion
#
# Covers:
#   - features-init.sh: seeds FEATURES.json from SPEC.md headings
#   - features-report.sh: computes happy-path % vs full-lifecycle %
#   - status-report.sh: shows lifecycle section when FEATURES.json present

set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS="$PROJECT_DIR/scripts"

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
TESTS_RUN=0; TESTS_PASSED=0; TESTS_FAILED=0
pass() { echo -e "${GREEN}✓${NC} $1"; TESTS_PASSED=$((TESTS_PASSED+1)); TESTS_RUN=$((TESTS_RUN+1)); }
fail() { echo -e "${RED}✗${NC} $1"; TESTS_FAILED=$((TESTS_FAILED+1)); TESTS_RUN=$((TESTS_RUN+1)); }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
rc_of() { local rc=0; "$@" >/dev/null 2>&1 || rc=$?; echo "$rc"; }

# ── Fixture builders ──────────────────────────────────────────────────────────

make_spec() {   # $1 = dir
    cat > "$1/SPEC.md" <<'EOF'
# Project Specification

## Authentication
## User Dashboard
## File Upload
## Search
## Notifications
## Settings
## Admin Panel
## Analytics
## API Integration
## Export
EOF
}

# 10 features; 9 have happy_path:true; 5 have all five states true.
# Written as inline JSON — no python3 dependency.
make_features() {   # $1 = dir (must have .meridian/ subdir)
    mkdir -p "$1/.meridian"
    cat > "$1/.meridian/FEATURES.json" <<'EOF'
[
  {"id":"authentication",  "name":"Authentication",   "source_section":"Authentication",   "lifecycle":{"happy_path":true, "integration":true, "edge_cases":true, "error_handling":true, "hardening":true}},
  {"id":"user-dashboard",  "name":"User Dashboard",   "source_section":"User Dashboard",   "lifecycle":{"happy_path":true, "integration":true, "edge_cases":true, "error_handling":true, "hardening":true}},
  {"id":"file-upload",     "name":"File Upload",      "source_section":"File Upload",      "lifecycle":{"happy_path":true, "integration":true, "edge_cases":true, "error_handling":true, "hardening":true}},
  {"id":"search",          "name":"Search",           "source_section":"Search",           "lifecycle":{"happy_path":true, "integration":true, "edge_cases":true, "error_handling":true, "hardening":true}},
  {"id":"notifications",   "name":"Notifications",    "source_section":"Notifications",    "lifecycle":{"happy_path":true, "integration":true, "edge_cases":true, "error_handling":true, "hardening":true}},
  {"id":"settings",        "name":"Settings",         "source_section":"Settings",         "lifecycle":{"happy_path":true, "integration":false,"edge_cases":false,"error_handling":false,"hardening":false}},
  {"id":"admin-panel",     "name":"Admin Panel",      "source_section":"Admin Panel",      "lifecycle":{"happy_path":true, "integration":false,"edge_cases":false,"error_handling":false,"hardening":false}},
  {"id":"analytics",       "name":"Analytics",        "source_section":"Analytics",        "lifecycle":{"happy_path":true, "integration":false,"edge_cases":false,"error_handling":false,"hardening":false}},
  {"id":"api-integration", "name":"Api Integration",  "source_section":"Api Integration",  "lifecycle":{"happy_path":true, "integration":false,"edge_cases":false,"error_handling":false,"hardening":false}},
  {"id":"export",          "name":"Export",           "source_section":"Export",           "lifecycle":{"happy_path":false,"integration":false,"edge_cases":false,"error_handling":false,"hardening":false}}
]
EOF
}

# ── features-init.sh tests ────────────────────────────────────────────────────

test_init_creates_features_json() {
    echo ""; echo "Test: features-init creates FEATURES.json from SPEC.md"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX"); mkdir -p "$p/.meridian"
    make_spec "$p"
    MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/features-init.sh" >/dev/null 2>&1
    [ -f "$p/.meridian/FEATURES.json" ] \
        && pass "FEATURES.json created" \
        || fail "FEATURES.json not created"
}

test_init_correct_count() {
    echo ""; echo "Test: features-init extracts correct feature count"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX"); mkdir -p "$p/.meridian"
    make_spec "$p"
    MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/features-init.sh" >/dev/null 2>&1
    local n; n=$(jq 'length' "$p/.meridian/FEATURES.json" | tr -d '\r')
    [ "$n" = "10" ] \
        && pass "10 features extracted" \
        || fail "Expected 10, got $n"
}

test_init_all_states_false() {
    echo ""; echo "Test: features-init sets all lifecycle states to false"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX"); mkdir -p "$p/.meridian"
    make_spec "$p"
    MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/features-init.sh" >/dev/null 2>&1
    local trues; trues=$(jq '[.[] | .lifecycle | to_entries[] | select(.value==true)] | length' \
        "$p/.meridian/FEATURES.json" | tr -d '\r')
    [ "$trues" = "0" ] \
        && pass "All lifecycle states false (0 true values)" \
        || fail "Expected 0 true values, got $trues"
}

test_init_no_overwrite_without_force() {
    echo ""; echo "Test: features-init refuses to overwrite without --force"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX"); mkdir -p "$p/.meridian"
    make_spec "$p"
    echo "[]" > "$p/.meridian/FEATURES.json"
    local rc; rc=$(rc_of env MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/features-init.sh")
    [ "$rc" -ne 0 ] \
        && pass "Refused overwrite without --force (exit $rc)" \
        || fail "Expected non-zero, got $rc"
}

test_init_force_overwrites() {
    echo ""; echo "Test: features-init --force overwrites existing FEATURES.json"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX"); mkdir -p "$p/.meridian"
    make_spec "$p"
    echo "[]" > "$p/.meridian/FEATURES.json"
    MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/features-init.sh" --force >/dev/null 2>&1
    local n; n=$(jq 'length' "$p/.meridian/FEATURES.json" | tr -d '\r')
    [ "$n" = "10" ] \
        && pass "--force overwrote with 10 features" \
        || fail "Expected 10 after --force, got $n"
}

test_init_no_spec_errors() {
    echo ""; echo "Test: features-init errors when SPEC.md is missing"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX"); mkdir -p "$p/.meridian"
    local rc; rc=$(rc_of env MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/features-init.sh")
    [ "$rc" -ne 0 ] \
        && pass "Missing SPEC.md -> error (exit $rc)" \
        || fail "Expected non-zero, got $rc"
}

test_init_ids_are_slugs() {
    echo ""; echo "Test: features-init generates slug ids (no spaces)"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX"); mkdir -p "$p/.meridian"
    make_spec "$p"
    MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/features-init.sh" >/dev/null 2>&1
    local spaces; spaces=$(jq '[.[] | select(.id | test(" "))] | length' \
        "$p/.meridian/FEATURES.json" | tr -d '\r')
    [ "$spaces" = "0" ] \
        && pass "All ids are space-free slugs" \
        || fail "$spaces ids contain spaces"
}

test_init_boilerplate_filter() {
    echo ""; echo "Test: features-init excludes boilerplate section headings"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX"); mkdir -p "$p/.meridian"
    cat > "$p/SPEC.md" <<'EOF'
# Spec

## Feature List

These are the features.

## Features

More boilerplate.

## Feature Overview

Also boilerplate.

## Real Feature One

A real feature.

## Real Feature Two

Another real feature.
EOF
    MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/features-init.sh" >/dev/null 2>&1
    local n; n=$(jq 'length' "$p/.meridian/FEATURES.json" | tr -d '\r')
    [ "$n" = "2" ] \
        && pass "Boilerplate headings excluded: 2 real features extracted (not 5)" \
        || fail "Expected 2 features, got $n (boilerplate filter may be broken)"
}

# ── features-report.sh tests ──────────────────────────────────────────────────

test_report_short_happy_path_pct() {
    echo ""; echo "Test: features-report --short shows 90% happy-path"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX")
    make_features "$p"
    local out; out=$(MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/features-report.sh" --short 2>/dev/null)
    echo "$out" | grep -q "^90% happy-path" \
        && pass "Happy-path = 90% (9/10)" \
        || fail "Expected '90% happy-path ...', got: $out"
}

test_report_short_full_lifecycle_pct() {
    echo ""; echo "Test: features-report --short shows 50% full-lifecycle"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX")
    make_features "$p"
    local out; out=$(MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/features-report.sh" --short 2>/dev/null)
    echo "$out" | grep -q "/ 50% full-lifecycle" \
        && pass "Full-lifecycle = 50% (5/10)" \
        || fail "Expected '/ 50% full-lifecycle', got: $out"
}

test_report_json_fields() {
    echo ""; echo "Test: features-report --json has required fields"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX")
    make_features "$p"
    local out; out=$(MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/features-report.sh" --json 2>/dev/null)
    if echo "$out" | jq empty 2>/dev/null \
       && [ "$(echo "$out" | jq '.total_features'    | tr -d '\r')" = "10" ] \
       && [ "$(echo "$out" | jq '.happy_path_pct'    | tr -d '\r')" = "90" ] \
       && [ "$(echo "$out" | jq '.full_lifecycle_pct' | tr -d '\r')" = "50" ]; then
        pass "JSON: total=10, happy_path_pct=90, full_lifecycle_pct=50"
    else
        fail "JSON fields incorrect: $out"
    fi
}

test_report_json_per_state() {
    echo ""; echo "Test: features-report --json per_state counts correct"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX")
    make_features "$p"
    local out; out=$(MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/features-report.sh" --json 2>/dev/null)
    local hp intg
    hp=$(echo "$out"   | jq '.per_state.happy_path'  | tr -d '\r')
    intg=$(echo "$out" | jq '.per_state.integration' | tr -d '\r')
    [ "$hp" = "9" ] && [ "$intg" = "5" ] \
        && pass "per_state: happy_path=9, integration=5" \
        || fail "per_state wrong: happy_path=$hp integration=$intg"
}

test_report_no_features_errors() {
    echo ""; echo "Test: features-report errors when FEATURES.json absent"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX"); mkdir -p "$p/.meridian"
    local rc; rc=$(rc_of env MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/features-report.sh")
    [ "$rc" -ne 0 ] \
        && pass "Missing FEATURES.json -> error (exit $rc)" \
        || fail "Expected non-zero, got $rc"
}

test_report_full_two_numbers() {
    echo ""; echo "Test: features-report (full) prints both distinct percentages"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX")
    make_features "$p"
    local out; out=$(MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/features-report.sh" --full 2>/dev/null)
    echo "$out" | grep -q "90%" && echo "$out" | grep -q "50%" \
        && pass "Full report contains both 90% and 50%" \
        || fail "Full report missing numbers: $(echo "$out" | tr '\n' '|')"
}

# ── status-report.sh lifecycle integration ────────────────────────────────────

test_status_shows_lifecycle_when_present() {
    echo ""; echo "Test: status-report shows lifecycle line when FEATURES.json exists"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX")
    make_features "$p"
    mkdir -p "$p/.meridian/memory"
    local out; out=$(MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/status-report.sh" full 2>/dev/null)
    echo "$out" | grep -q "happy-path" \
        && pass "Lifecycle section appears in status" \
        || fail "No lifecycle line in status output"
}

test_status_lifecycle_numbers() {
    echo ""; echo "Test: status-report lifecycle shows correct percentages"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX")
    make_features "$p"
    mkdir -p "$p/.meridian/memory"
    local out; out=$(MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/status-report.sh" full 2>/dev/null)
    echo "$out" | grep -q "90%" && echo "$out" | grep -q "50%" \
        && pass "Status lifecycle shows 90% happy-path / 50% full-lifecycle" \
        || fail "Status missing expected percentages: $(echo "$out" | tr '\n' '|')"
}

test_status_graceful_without_features() {
    echo ""; echo "Test: status-report runs cleanly without FEATURES.json"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX"); mkdir -p "$p/.meridian/memory"
    local rc; rc=$(rc_of env MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/status-report.sh" full)
    [ "$rc" -eq 0 ] \
        && pass "status-report exits 0 without FEATURES.json" \
        || fail "status-report failed without FEATURES.json (exit $rc)"
}

test_status_json_lifecycle_present() {
    echo ""; echo "Test: status-report --json includes lifecycle field when FEATURES.json exists"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX")
    make_features "$p"
    mkdir -p "$p/.meridian/memory"
    local out; out=$(MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/status-report.sh" --json 2>/dev/null)
    local hp
    hp=$(echo "$out" | jq '.lifecycle.happy_path_pct // empty' 2>/dev/null | tr -d '\r')
    [ "$hp" = "90" ] \
        && pass "JSON lifecycle.happy_path_pct = 90" \
        || fail "JSON lifecycle.happy_path_pct wrong: $(echo "$out" | jq '.lifecycle')"
}

test_status_json_lifecycle_null_without_features() {
    echo ""; echo "Test: status-report --json lifecycle is null without FEATURES.json"
    local p; p=$(mktemp -d "$WORK/p.XXXXXX"); mkdir -p "$p/.meridian/memory"
    local out; out=$(MERIDIAN_PROJECT_DIR="$p" bash "$SCRIPTS/status-report.sh" --json 2>/dev/null)
    local lc; lc=$(echo "$out" | jq '.lifecycle' 2>/dev/null | tr -d '\r')
    [ "$lc" = "null" ] \
        && pass "JSON lifecycle = null without FEATURES.json" \
        || fail "Expected null, got: $lc"
}

#######################################
# Runner
#######################################
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Meridian Lifecycle Tests (Gate 3.2)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    test_init_creates_features_json
    test_init_correct_count
    test_init_all_states_false
    test_init_no_overwrite_without_force
    test_init_force_overwrites
    test_init_no_spec_errors
    test_init_ids_are_slugs
    test_init_boilerplate_filter

    test_report_short_happy_path_pct
    test_report_short_full_lifecycle_pct
    test_report_json_fields
    test_report_json_per_state
    test_report_no_features_errors
    test_report_full_two_numbers

    test_status_shows_lifecycle_when_present
    test_status_lifecycle_numbers
    test_status_graceful_without_features
    test_status_json_lifecycle_present
    test_status_json_lifecycle_null_without_features

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
