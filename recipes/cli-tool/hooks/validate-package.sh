#!/bin/bash
# validate-package.sh - pre-hook for the 'package_ready' gate (cli-tool recipe)
# MERIDIAN-STUB: replace this file with your project's check.
#
# What it should verify:
#   the built package installs into a clean environment and its entry point runs.
# For example:
#   python -m venv /tmp/v && /tmp/v/bin/pip install dist/*.whl && /tmp/v/bin/mytool --version || exit 2
#
# Contract: exit 0 to let the gate pass, exit 2 to block it. The gate id is in
# $MERIDIAN_GATE_ID; run from the project root. Delete the MERIDIAN-STUB line
# when the check is real, or `gate-engine.sh validate` keeps warning.
#
# This stub fails closed: until you write the check, the gate cannot pass as
# though it had run. To drop the check instead, remove it from gates.yaml.

echo "validate-package.sh: not implemented yet. It should verify: the built package installs into a clean environment and its entry point runs." >&2
echo "Edit .claude/hooks/validate-package.sh (see the comments) or remove it from .meridian/gates.yaml." >&2
exit 2
