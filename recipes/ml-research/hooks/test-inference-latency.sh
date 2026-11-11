#!/bin/bash
# test-inference-latency.sh - pre-hook for the 'deploy_ready' gate (ml-research recipe)
# MERIDIAN-STUB: replace this file with your project's check.
#
# What it should verify:
#   inference meets the latency budget in DATA_CONTRACT.md on the target hardware.
# For example:
#   python -m yourpkg.latency --p95-ms 50 || exit 2
#
# Contract: exit 0 to let the gate pass, exit 2 to block it. The gate id is in
# $MERIDIAN_GATE_ID; run from the project root. Delete the MERIDIAN-STUB line
# when the check is real, or `gate-engine.sh validate` keeps warning.
#
# This stub fails closed: until you write the check, the gate cannot pass as
# though it had run. To drop the check instead, remove it from gates.yaml.

echo "test-inference-latency.sh: not implemented yet. It should verify: inference meets the latency budget in DATA_CONTRACT.md on the target hardware." >&2
echo "Edit .claude/hooks/test-inference-latency.sh (see the comments) or remove it from .meridian/gates.yaml." >&2
exit 2
