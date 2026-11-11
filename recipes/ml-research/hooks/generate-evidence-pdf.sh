#!/bin/bash
# generate-evidence-pdf.sh - pre-hook for the 'evidence_pdf' gate (ml-research recipe)
# MERIDIAN-STUB: replace this file with your project's check.
#
# What it should verify:
#   the results compile into a single portable PDF.
# For example:
#   pandoc EVAL_RESULTS.md MODEL_CARD.md -o EVIDENCE.pdf || exit 2
#
# Contract: exit 0 to let the gate pass, exit 2 to block it. The gate id is in
# $MERIDIAN_GATE_ID; run from the project root. Delete the MERIDIAN-STUB line
# when the check is real, or `gate-engine.sh validate` keeps warning.
#
# This stub fails closed: until you write the check, the gate cannot pass as
# though it had run. To drop the check instead, remove it from gates.yaml.

echo "generate-evidence-pdf.sh: not implemented yet. It should verify: the results compile into a single portable PDF." >&2
echo "Edit .claude/hooks/generate-evidence-pdf.sh (see the comments) or remove it from .meridian/gates.yaml." >&2
exit 2
