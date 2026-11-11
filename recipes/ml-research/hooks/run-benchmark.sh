#!/bin/bash
# run-benchmark.sh - pre-hook for the 'model_eval' gate (ml-research recipe)
# MERIDIAN-STUB: replace this file with your project's check.
#
# What it should verify:
#   the model and the contract's baseline were scored on the frozen test set by the pre-registered procedure, once.
# For example:
#   python -m yourpkg.benchmark --config configs/eval.yaml || exit 2
#
# Contract: exit 0 to let the gate pass, exit 2 to block it. The gate id is in
# $MERIDIAN_GATE_ID; run from the project root. Delete the MERIDIAN-STUB line
# when the check is real, or `gate-engine.sh validate` keeps warning.
#
# This stub fails closed: until you write the check, the gate cannot pass as
# though it had run. To drop the check instead, remove it from gates.yaml.

echo "run-benchmark.sh: not implemented yet. It should verify: the model and the contract's baseline were scored on the frozen test set by the pre-registered procedure, once." >&2
echo "Edit .claude/hooks/run-benchmark.sh (see the comments) or remove it from .meridian/gates.yaml." >&2
exit 2
