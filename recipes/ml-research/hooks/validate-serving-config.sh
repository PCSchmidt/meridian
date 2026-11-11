#!/bin/bash
# validate-serving-config.sh - pre-hook for the 'deploy_ready' gate (ml-research recipe)
# MERIDIAN-STUB: replace this file with your project's check.
#
# What it should verify:
#   DEPLOYMENT_CONFIG.md names the model artifact, its checksum, the serving entry point and monitoring.
# For example:
#   check the checksum in DEPLOYMENT_CONFIG.md matches the exported model file.
#
# Contract: exit 0 to let the gate pass, exit 2 to block it. The gate id is in
# $MERIDIAN_GATE_ID; run from the project root. Delete the MERIDIAN-STUB line
# when the check is real, or `gate-engine.sh validate` keeps warning.
#
# This stub fails closed: until you write the check, the gate cannot pass as
# though it had run. To drop the check instead, remove it from gates.yaml.

echo "validate-serving-config.sh: not implemented yet. It should verify: DEPLOYMENT_CONFIG.md names the model artifact, its checksum, the serving entry point and monitoring." >&2
echo "Edit .claude/hooks/validate-serving-config.sh (see the comments) or remove it from .meridian/gates.yaml." >&2
exit 2
