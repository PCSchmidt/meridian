#!/bin/bash
# validate-api-spec.sh - pre-hook for the 'backend_approved' gate (fullstack-web recipe)
# MERIDIAN-STUB: replace this file with your project's check.
#
# What it should verify:
#   the API spec (e.g. openapi.yaml) parses and covers every route the frontend calls.
# For example:
#   npx @redocly/cli lint openapi.yaml || exit 2
#
# Contract: exit 0 to let the gate pass, exit 2 to block it. The gate id is in
# $MERIDIAN_GATE_ID; run from the project root. Delete the MERIDIAN-STUB line
# when the check is real, or `gate-engine.sh validate` keeps warning.
#
# This stub fails closed: until you write the check, the gate cannot pass as
# though it had run. To drop the check instead, remove it from gates.yaml.

echo "validate-api-spec.sh: not implemented yet. It should verify: the API spec (e.g. openapi.yaml) parses and covers every route the frontend calls." >&2
echo "Edit .claude/hooks/validate-api-spec.sh (see the comments) or remove it from .meridian/gates.yaml." >&2
exit 2
