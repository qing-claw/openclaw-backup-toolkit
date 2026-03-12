#!/usr/bin/env bash
set -euo pipefail

ROOT="${OPENCLAW_ROOT:-$HOME/.openclaw}"
BACKUP_ROOT="$ROOT/backups"
AUDIT_DIR="$ROOT/audit"

usage() {
  cat <<EOF
Usage:
  $0 --list
  $0 --config-only <snapshot>
  $0 --agent <agentId> <snapshot>
  $0 --full <snapshot>

Examples:
  $0 --list
  $0 --config-only 20260312-193000
  $0 --agent chuxian 20260312-193000
  $0 --full 20260312-193000
EOF
}

copy_back() {
  local src="$1"
  local dst="$2"
  [ -e "$src" ] || return 0
  mkdir -p "$(dirname "$dst")"
  rm -rf "$dst"
  cp -a "$src" "$dst"
}

snapshot_current() {
  local mode="$1"
  local agent="${2:-}"
  local ts snap
  ts="$(date +%Y%m%d-%H%M%S)"
  snap="$BACKUP_ROOT/pre-restore-$ts"
  mkdir -p "$snap"

  copy_back "$ROOT/openclaw.json" "$snap/openclaw.json"
  copy_back "$ROOT/exec-approvals.json" "$snap/exec-approvals.json"
  copy_back "$ROOT/skills" "$snap/skills"
  copy_back "$ROOT/extensions" "$snap/extensions"
  [ -e "$HOME/.acpx/config.json" ] && copy_back "$HOME/.acpx/config.json" "$snap/acpx-config.json"

  case "$mode" in
    config-only)
      ;;
    agent)
      shopt -s nullglob
      for d in "$ROOT"/workspace*; do
        base="$(basename "$d")"
        case "$base" in
          "workspace-$agent"|"workspace-${agent^}"|"workspace")
            if [ "$agent" = "main" ] && [ "$base" = "workspace" ] || [ "$base" != "workspace" ]; then
              copy_back "$d" "$snap/$base"
            fi
            ;;
        esac
      done
      shopt -u nullglob
      copy_back "$ROOT/agents/$agent" "$snap/agents/$agent"
      copy_back "$ROOT/agents/${agent^}" "$snap/agents/${agent^}"
      ;;
    full)
      shopt -s nullglob
      for d in "$ROOT"/workspace*; do
        copy_back "$d" "$snap/$(basename "$d")"
      done
      shopt -u nullglob
      copy_back "$ROOT/agents" "$snap/agents"
      ;;
  esac

  echo "$snap"
}

if [ "${1:-}" = "--list" ]; then
  ls -1 "$BACKUP_ROOT" | sort
  exit 0
fi

MODE="${1:-}"
PRE_SNAPSHOT=""
case "$MODE" in
  --config-only)
    SNAP="${2:-}"
    [ -n "$SNAP" ] || { usage; exit 2; }
    SRC="$BACKUP_ROOT/$SNAP"
    [ -d "$SRC" ] || { echo "snapshot not found: $SNAP" >&2; exit 1; }
    PRE_SNAPSHOT="$(snapshot_current config-only)"
    copy_back "$SRC/openclaw.json" "$ROOT/openclaw.json"
    copy_back "$SRC/exec-approvals.json" "$ROOT/exec-approvals.json"
    copy_back "$SRC/skills" "$ROOT/skills"
    copy_back "$SRC/extensions" "$ROOT/extensions"
    if [ -e "$SRC/acpx-config.json" ]; then
      mkdir -p "$HOME/.acpx"
      cp -a "$SRC/acpx-config.json" "$HOME/.acpx/config.json"
    fi
    ;;
  --agent)
    AGENT="${2:-}"
    SNAP="${3:-}"
    [ -n "$AGENT" ] && [ -n "$SNAP" ] || { usage; exit 2; }
    SRC="$BACKUP_ROOT/$SNAP"
    [ -d "$SRC" ] || { echo "snapshot not found: $SNAP" >&2; exit 1; }
    PRE_SNAPSHOT="$(snapshot_current agent "$AGENT")"
    shopt -s nullglob
    for d in "$SRC"/workspace*; do
      base="$(basename "$d")"
      case "$base" in
        "workspace-$AGENT"|"workspace-${AGENT^}"|"workspace")
          if [ "$AGENT" = "main" ] && [ "$base" = "workspace" ] || [ "$base" != "workspace" ]; then
            copy_back "$d" "$ROOT/$base"
          fi
          ;;
      esac
    done
    shopt -u nullglob
    copy_back "$SRC/agents/$AGENT" "$ROOT/agents/$AGENT"
    copy_back "$SRC/agents/${AGENT^}" "$ROOT/agents/${AGENT^}"
    ;;
  --full)
    SNAP="${2:-}"
    [ -n "$SNAP" ] || { usage; exit 2; }
    SRC="$BACKUP_ROOT/$SNAP"
    [ -d "$SRC" ] || { echo "snapshot not found: $SNAP" >&2; exit 1; }
    PRE_SNAPSHOT="$(snapshot_current full)"
    [ -e "$SRC/openclaw.json" ] && copy_back "$SRC/openclaw.json" "$ROOT/openclaw.json"
    [ -e "$SRC/exec-approvals.json" ] && copy_back "$SRC/exec-approvals.json" "$ROOT/exec-approvals.json"
    [ -e "$SRC/skills" ] && copy_back "$SRC/skills" "$ROOT/skills"
    [ -e "$SRC/extensions" ] && copy_back "$SRC/extensions" "$ROOT/extensions"
    shopt -s nullglob
    for d in "$SRC"/workspace*; do
      copy_back "$d" "$ROOT/$(basename "$d")"
    done
    shopt -u nullglob
    [ -e "$SRC/agents" ] && copy_back "$SRC/agents" "$ROOT/agents"
    if [ -e "$SRC/acpx-config.json" ]; then
      mkdir -p "$HOME/.acpx"
      cp -a "$SRC/acpx-config.json" "$HOME/.acpx/config.json"
    fi
    ;;
  *)
    usage
    exit 2
    ;;
esac

TS="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$AUDIT_DIR"
cat >> "$AUDIT_DIR/restore-log.md" <<EOF
## $TS
- mode: ${MODE#--}
- snapshot: ${SNAP:-}
- agent: ${AGENT:-}
- pre_restore_snapshot: ${PRE_SNAPSHOT:-}
EOF

echo "restore complete"
