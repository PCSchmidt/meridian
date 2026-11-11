#!/bin/bash
# validate-commands.sh - pre-hook for the 'commands_approved' gate (cli-tool recipe)
# MERIDIAN-STUB: replace this file with your project's check.
#
# What it should verify:
#   COMMANDS_SPEC.md defines every command with its flags, exit codes and an example invocation.
# For example:
#   grep each command name from COMMANDS_SPEC.md in your --help output; exit 2 on any missing.
#
# Contract: exit 0 to let the gate pass, exit 2 to block it. The gate id is in
# $MERIDIAN_GATE_ID; run from the project root. Delete the MERIDIAN-STUB line
# when the check is real, or `gate-engine.sh validate` keeps warning.
#
# This stub fails closed: until you write the check, the gate cannot pass as
# though it had run. To drop the check instead, remove it from gates.yaml.

echo "validate-commands.sh: not implemented yet. It should verify: COMMANDS_SPEC.md defines every command with its flags, exit codes and an example invocation." >&2
echo "Edit .claude/hooks/validate-commands.sh (see the comments) or remove it from .meridian/gates.yaml." >&2
exit 2
