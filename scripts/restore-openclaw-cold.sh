#!/usr/bin/env bash
set -euo pipefail

ROOT="${OPENCLAW_ROOT:-$HOME/.openclaw}"
AUDIT_DIR="$ROOT/audit"

usage() {
  cat <<EOF
Usage:
  $0 --list
  $0 --restore <archive.tar.gz>

Examples:
  $0 --list
  $0 --restore ~/.openclaw/backups/cold/openclaw-cold-20260312-201500.tar.gz
EOF
}

if [ "${1:-}" = "--list" ]; then
  ls -1 "$ROOT/backups/cold"/*.tar.gz 2>/dev/null || true
  exit 0
fi

if [ "${1:-}" != "--restore" ] || [ -z "${2:-}" ]; then
  usage
  exit 2
fi

ARCHIVE="$2"
[ -f "$ARCHIVE" ] || { echo "archive not found: $ARCHIVE" >&2; exit 1; }

TS="$(date +%Y%m%d-%H%M%S)"
PRE_RESTORE="$ROOT/backups/cold/pre-restore-$TS.tar.gz"
mkdir -p "$ROOT/backups/cold" "$AUDIT_DIR"

(
  cd "$HOME"
  COPYFILE_DISABLE=1 tar \
    --exclude='.openclaw/backups/cold/*.tar.gz' \
    --exclude='.openclaw/backups/cold/*.manifest.txt' \
    --exclude='.openclaw/exec-approvals.sock' \
    --exclude='.openclaw/**/.DS_Store' \
    --exclude='._*' \
    -czf "$PRE_RESTORE" .openclaw
)

(
  cd "$HOME"
  tar -xzf "$ARCHIVE"
)

cat >> "$AUDIT_DIR/restore-log.md" <<EOF
## $TS
- mode: cold-full
- archive: $ARCHIVE
- pre_restore_snapshot: $PRE_RESTORE
EOF

echo "restore complete: $ARCHIVE"
