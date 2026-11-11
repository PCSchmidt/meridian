#!/bin/bash
# validate-schema.sh - pre-hook for the 'pipeline_validated' gate (ml-research recipe)
# MERIDIAN-STUB: replace this file with your project's check.
#
# What it should verify:
#   the processed data matches the schema in DATA_CONTRACT.md (columns, types, ranges).
# For example:
#   python -m yourpkg.checks schema || exit 2
#
# Contract: exit 0 to let the gate pass, exit 2 to block it. The gate id is in
# $MERIDIAN_GATE_ID; run from the project root. Delete the MERIDIAN-STUB line
# when the check is real, or `gate-engine.sh validate` keeps warning.
#
# This stub fails closed: until you write the check, the gate cannot pass as
# though it had run. To drop the check instead, remove it from gates.yaml.

echo "validate-schema.sh: not implemented yet. It should verify: the processed data matches the schema in DATA_CONTRACT.md (columns, types, ranges)." >&2
echo "Edit .claude/hooks/validate-schema.sh (see the comments) or remove it from .meridian/gates.yaml." >&2
exit 2
