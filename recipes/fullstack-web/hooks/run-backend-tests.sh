#!/bin/bash
# run-backend-tests.sh - pre-hook for the 'tests_passing' gate (fullstack-web recipe)
# MERIDIAN-STUB: replace this file with your project's check.
#
# What it should verify:
#   the backend test suite passes.
# For example:
#   pytest -q || exit 2
#
# Contract: exit 0 to let the gate pass, exit 2 to block it. The gate id is in
# $MERIDIAN_GATE_ID; run from the project root. Delete the MERIDIAN-STUB line
# when the check is real, or `gate-engine.sh validate` keeps warning.
#
# This stub fails closed: until you write the check, the gate cannot pass as
# though it had run. To drop the check instead, remove it from gates.yaml.

echo "run-backend-tests.sh: not implemented yet. It should verify: the backend test suite passes." >&2
echo "Edit .claude/hooks/run-backend-tests.sh (see the comments) or remove it from .meridian/gates.yaml." >&2
exit 2
