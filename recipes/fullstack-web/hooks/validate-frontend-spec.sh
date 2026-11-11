#!/bin/bash
# validate-frontend-spec.sh - pre-hook for the 'frontend_approved' gate (fullstack-web recipe)
# MERIDIAN-STUB: replace this file with your project's check.
#
# What it should verify:
#   the frontend spec lists every screen, its route and its states (loading, empty, error).
# For example:
#   check FRONTEND_SPEC.md has a section per route in your router config.
#
# Contract: exit 0 to let the gate pass, exit 2 to block it. The gate id is in
# $MERIDIAN_GATE_ID; run from the project root. Delete the MERIDIAN-STUB line
# when the check is real, or `gate-engine.sh validate` keeps warning.
#
# This stub fails closed: until you write the check, the gate cannot pass as
# though it had run. To drop the check instead, remove it from gates.yaml.

echo "validate-frontend-spec.sh: not implemented yet. It should verify: the frontend spec lists every screen, its route and its states (loading, empty, error)." >&2
echo "Edit .claude/hooks/validate-frontend-spec.sh (see the comments) or remove it from .meridian/gates.yaml." >&2
exit 2
