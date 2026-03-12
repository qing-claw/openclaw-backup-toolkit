#!/usr/bin/env bash
set -euo pipefail

ROOT="${OPENCLAW_ROOT:-$HOME/.openclaw}"
BACKUP_ROOT="$ROOT/backups"
AUDIT_DIR="$ROOT/audit"
TS="$(date +%Y%m%d-%H%M%S)"
DEST="$BACKUP_ROOT/$TS"
MODE="${1:-all}"

mkdir -p "$DEST" "$AUDIT_DIR"

copy_if_exists() {
  local src="$1"
  local dst="$2"
  if [ -e "$src" ]; then
    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"
  fi
}

backup_config() {
  copy_if_exists "$ROOT/openclaw.json" "$DEST/openclaw.json"
  copy_if_exists "$ROOT/exec-approvals.json" "$DEST/exec-approvals.json"
  copy_if_exists "$HOME/.acpx/config.json" "$DEST/acpx-config.json"
  copy_if_exists "$ROOT/skills" "$DEST/skills"
  copy_if_exists "$ROOT/extensions" "$DEST/extensions"
}

backup_workspaces() {
  local d
  for d in "$ROOT"/workspace*; do
    [ -e "$d" ] || continue
    copy_if_exists "$d" "$DEST/$(basename "$d")"
  done
}

backup_agents() {
  copy_if_exists "$ROOT/agents" "$DEST/agents"
}

case "$MODE" in
  config)
    backup_config
    ;;
  agents)
    backup_workspaces
    backup_agents
    ;;
  all)
    backup_config
    backup_workspaces
    backup_agents
    ;;
  *)
    echo "Usage: $0 [config|agents|all]" >&2
    exit 2
    ;;
esac

cat >> "$AUDIT_DIR/backup-log.md" <<EOF
## $TS
- mode: $MODE
- path: $DEST
EOF

echo "$DEST"
