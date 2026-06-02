#!/bin/bash
# install.sh — install Meridian into a target project
# Usage: bash install.sh <target-project-dir> [--recipe fullstack-web|cli-tool|ml-research]
#
# What this installs:
#   .claude/hooks/    — PreToolUse / PostToolUse enforcement hooks
#   .claude/skills/   — slash-command skill docs
#   .claude/agents/   — subagent docs (gate-evaluator, drift-evaluator, spec-reviewer)
#   .meridian/        — tracked schemas + security-rules.yaml + runtime skeleton
#   gates.yaml        — starter gate DAG (if --recipe provided)
#
# Does NOT install Meridian's own test suite. The target project provides its own.

set -euo pipefail

MERIDIAN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET=""
RECIPE=""

# ─── Arg parse ────────────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
    case "$1" in
        --recipe) RECIPE="$2"; shift 2 ;;
        --help|-h)
            echo "Usage: bash install.sh <target-project-dir> [--recipe fullstack-web|cli-tool|ml-research]"
            exit 0 ;;
        *)
            if [ -z "$TARGET" ]; then TARGET="$1"; shift
            else echo "Unexpected argument: $1"; exit 1; fi ;;
    esac
done

[ -z "$TARGET" ] && { echo "Usage: bash install.sh <target-project-dir> [--recipe ...]"; exit 1; }
[ -d "$TARGET" ] || { echo "Error: '$TARGET' is not a directory"; exit 1; }

TARGET="$(cd "$TARGET" && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Meridian Installer"
echo "Target: $TARGET"
[ -n "$RECIPE" ] && echo "Recipe: $RECIPE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ERRORS=0

ok()   { echo "  ✓ $1"; }
warn() { echo "  ⚠ $1"; }
err()  { echo "  ✗ $1"; ERRORS=$((ERRORS+1)); }

# ─── 1. .claude/hooks/ ────────────────────────────────────────────────────────

echo "[1/7] Copying .claude/hooks/"
if [ -d "$MERIDIAN_DIR/.claude/hooks" ]; then
    mkdir -p "$TARGET/.claude/hooks"
    cp -r "$MERIDIAN_DIR/.claude/hooks/." "$TARGET/.claude/hooks/"
    ok "Hooks installed ($(ls "$TARGET/.claude/hooks/" | wc -l | tr -d ' ') files)"
else
    err ".claude/hooks/ not found in Meridian source"
fi

# ─── 2. .claude/skills/ ───────────────────────────────────────────────────────

echo "[2/7] Copying .claude/skills/"
if [ -d "$MERIDIAN_DIR/.claude/skills" ]; then
    mkdir -p "$TARGET/.claude/skills"
    cp -r "$MERIDIAN_DIR/.claude/skills/." "$TARGET/.claude/skills/"
    ok "Skills installed ($(ls "$TARGET/.claude/skills/" | wc -l | tr -d ' ') skills)"
else
    err ".claude/skills/ not found in Meridian source"
fi

# ─── 3. .claude/agents/ ───────────────────────────────────────────────────────

echo "[3/7] Copying .claude/agents/"
if [ -d "$MERIDIAN_DIR/.claude/agents" ]; then
    mkdir -p "$TARGET/.claude/agents"
    cp -r "$MERIDIAN_DIR/.claude/agents/." "$TARGET/.claude/agents/"
    ok "Agents installed ($(ls "$TARGET/.claude/agents/" | wc -l | tr -d ' ') agents)"
else
    err ".claude/agents/ not found in Meridian source"
fi

# ─── 4. .meridian/ tracked schemas + security rules ──────────────────────────

echo "[4/7] Installing .meridian/ skeleton"
mkdir -p "$TARGET/.meridian"

# Copy tracked schema files
SCHEMAS_COPIED=0
for f in "$MERIDIAN_DIR/.meridian/"*-schema.json "$MERIDIAN_DIR/.meridian/"*-schema.yaml; do
    [ -f "$f" ] || continue
    cp "$f" "$TARGET/.meridian/"
    SCHEMAS_COPIED=$((SCHEMAS_COPIED+1))
done
ok "Schemas installed ($SCHEMAS_COPIED files)"

# Copy security rules
if [ -f "$MERIDIAN_DIR/.meridian/security-rules.yaml" ]; then
    cp "$MERIDIAN_DIR/.meridian/security-rules.yaml" "$TARGET/.meridian/"
    ok "security-rules.yaml installed"
else
    warn "security-rules.yaml not found in Meridian source"
fi

# ─── 5. .meridian/ runtime skeleton ──────────────────────────────────────────

echo "[5/7] Creating runtime skeleton"

# telemetry.jsonl — empty, append-only event log
if [ ! -f "$TARGET/.meridian/telemetry.jsonl" ]; then
    touch "$TARGET/.meridian/telemetry.jsonl"
    ok "Created telemetry.jsonl"
else
    ok "telemetry.jsonl already exists (preserved)"
fi

# memory/ directory
mkdir -p "$TARGET/.meridian/memory"
ok "Created .meridian/memory/"

# session.json — bootstrap if not already present
if [ ! -f "$TARGET/.meridian/session.json" ]; then
    PROJECT_NAME="$(basename "$TARGET")"
    INSTALLED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "unknown")"
    printf '{"project":"%s","installed_at":"%s","current_gate":null,"phase":null}\n' \
        "$PROJECT_NAME" "$INSTALLED_AT" > "$TARGET/.meridian/session.json"
    ok "Created session.json"
else
    ok "session.json already exists (preserved)"
fi

# ─── 6. gates.yaml recipe ─────────────────────────────────────────────────────

echo "[6/7] gates.yaml"
if [ -n "$RECIPE" ]; then
    RECIPE_FILE="$MERIDIAN_DIR/recipes/$RECIPE/gates.yaml"
    if [ -f "$RECIPE_FILE" ]; then
        if [ -f "$TARGET/.meridian/gates.yaml" ]; then
            warn ".meridian/gates.yaml already exists — not overwriting (delete it to reinstall)"
        else
            cp "$RECIPE_FILE" "$TARGET/.meridian/gates.yaml"
            ok "gates.yaml installed from recipe '$RECIPE' → .meridian/gates.yaml"
        fi
    else
        err "Recipe '$RECIPE' not found (looked for $RECIPE_FILE)"
        echo "     Available recipes: $(ls "$MERIDIAN_DIR/recipes/" | tr '\n' ' ')"
    fi
else
    warn "No --recipe specified; gates.yaml not installed"
    echo "     Run: bash install.sh $TARGET --recipe fullstack-web|cli-tool|ml-research"
fi

# ─── 7. .gitignore entries ────────────────────────────────────────────────────

echo "[7/7] .gitignore"
GITIGNORE="$TARGET/.gitignore"
MERIDIAN_BLOCK="# Meridian runtime state (auto-generated, not for version control)
.meridian/memory/
.meridian/telemetry.jsonl
.meridian/session.json"

if [ -f "$GITIGNORE" ]; then
    if grep -q "\.meridian/memory" "$GITIGNORE" 2>/dev/null; then
        ok ".gitignore already has Meridian entries"
    else
        printf "\n%s\n" "$MERIDIAN_BLOCK" >> "$GITIGNORE"
        ok "Added Meridian entries to .gitignore"
    fi
else
    printf "%s\n" "$MERIDIAN_BLOCK" > "$GITIGNORE"
    ok "Created .gitignore with Meridian entries"
fi

# ─── Validate ─────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "$TARGET/.meridian/gates.yaml" ]; then
    echo "Validating .meridian/gates.yaml..."
    if MERIDIAN_PROJECT_DIR="$TARGET" \
           bash "$MERIDIAN_DIR/scripts/gate-engine.sh" validate 2>&1 | sed 's/^/  /'; then
        ok "gate-engine validate passed"
    else
        warn "gate-engine validate returned non-zero — review .meridian/gates.yaml"
    fi
else
    warn "No .meridian/gates.yaml — skipping gate-engine validate"
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
    echo "✓ Meridian installed successfully into $TARGET"
else
    echo "✗ Install completed with $ERRORS error(s) — review above"
    exit 1
fi

echo ""
echo "Next steps:"
echo "  1. Write CONTRACT.md  — scope, out-of-scope, acceptance criteria"
echo "  2. Write SPEC.md      — feature list (## headers become FEATURES.json entries)"
echo "  3. Seed FEATURES.json — bash $MERIDIAN_DIR/scripts/features-init.sh --spec SPEC.md"
if [ -z "$RECIPE" ]; then
    echo "  4. Install a recipe   — bash install.sh $TARGET --recipe fullstack-web"
fi
echo ""
