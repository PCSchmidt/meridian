#!/bin/bash
# validate-deployment.sh - pre-hook for the 'deploy_ready' gate (fullstack-web recipe)
# MERIDIAN-STUB: replace this file with your project's check.
#
# What it should verify:
#   the deployment config is complete: env vars documented, health check defined, rollback path written down.
# For example:
#   check DEPLOYMENT.md names every variable your app reads from the environment.
#
# Contract: exit 0 to let the gate pass, exit 2 to block it. The gate id is in
# $MERIDIAN_GATE_ID; run from the project root. Delete the MERIDIAN-STUB line
# when the check is real, or `gate-engine.sh validate` keeps warning.
#
# This stub fails closed: until you write the check, the gate cannot pass as
# though it had run. To drop the check instead, remove it from gates.yaml.

echo "validate-deployment.sh: not implemented yet. It should verify: the deployment config is complete: env vars documented, health check defined, rollback path written down." >&2
echo "Edit .claude/hooks/validate-deployment.sh (see the comments) or remove it from .meridian/gates.yaml." >&2
exit 2
