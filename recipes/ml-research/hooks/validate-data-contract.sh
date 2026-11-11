#!/bin/bash
# validate-data-contract.sh - pre-hook for the 'data_contract' gate (ml-research recipe)
#
# A working, generic check. It blocks the gate unless DATA_CONTRACT.md:
#   - exists and is non-trivial
#   - has the sections that make a contract binding (target, split, success
#     metric, baseline)
#   - no longer contains the template's placeholders ("[e.g., ...]",
#     "[Project name]", "[YYYY-MM-DD]", ...)
# It cannot judge whether the thresholds are sensible. That is what the human
# approval on this gate is for. Extend it with project-specific rules (for
# example, recording the contract's checksum so later edits are detectable).
#
# Config (env):
#   DATA_CONTRACT_PATH               default: DATA_CONTRACT.md
#   DATA_CONTRACT_REQUIRED_SECTIONS  pipe-separated heading names, matched
#                                    case-insensitively against ## headings
#                                    (default "Target|Split|Success Metric|Baseline")
#   DATA_CONTRACT_MIN_LINES          default 20
#
# Exit codes: 0 = valid, 2 = block the gate.

set -uo pipefail

FILE="${DATA_CONTRACT_PATH:-${MERIDIAN_PROJECT_DIR:-.}/DATA_CONTRACT.md}"
REQUIRED="${DATA_CONTRACT_REQUIRED_SECTIONS:-Target|Split|Success Metric|Baseline}"
MIN_LINES="${DATA_CONTRACT_MIN_LINES:-20}"
problems=0

say() { echo "validate-data-contract: $1" >&2; }

if [ ! -s "$FILE" ]; then
    say "BLOCK - $FILE is missing or empty (start from recipes/ml-research/foundation/DATA_CONTRACT.md.template)"
    exit 2
fi

lines=$(grep -c . "$FILE" || true)
if [ "$lines" -lt "$MIN_LINES" ]; then
    say "BLOCK - $FILE has $lines non-empty lines; a binding contract needs at least $MIN_LINES"
    problems=$((problems + 1))
fi

headings=$(grep -E '^#{1,4}[[:space:]]' "$FILE" | tr '[:upper:]' '[:lower:]')
IFS='|' read -r -a sections <<< "$REQUIRED"
for s in "${sections[@]}"; do
    s_lc=$(echo "$s" | tr '[:upper:]' '[:lower:]')
    if ! echo "$headings" | grep -qF -- "$s_lc"; then
        say "BLOCK - no section heading containing '$s'"
        problems=$((problems + 1))
    fi
done

placeholders=$(grep -nE '\[(e\.g\.,|Project name\]|Your name\]|YYYY-MM-DD\]|One paragraph|Description|field_[0-9])' "$FILE" | head -5)
if [ -n "$placeholders" ]; then
    say "BLOCK - template placeholders are still in the contract (first few):"
    echo "$placeholders" | sed 's/^/    /' >&2
    problems=$((problems + 1))
fi

if [ "$problems" -gt 0 ]; then
    exit 2
fi
say "OK - $FILE has the required sections and no template placeholders"
exit 0
