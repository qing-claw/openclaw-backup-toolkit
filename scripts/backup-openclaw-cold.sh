#!/usr/bin/env bash
set -euo pipefail

ROOT="${OPENCLAW_ROOT:-$HOME/.openclaw}"
BACKUP_ROOT="$ROOT/backups/cold"
AUDIT_DIR="$ROOT/audit"
TS="$(date +%Y%m%d-%H%M%S)"
ARCHIVE="$BACKUP_ROOT/openclaw-cold-$TS.tar.gz"
MANIFEST="$BACKUP_ROOT/openclaw-cold-$TS.manifest.txt"

mkdir -p "$BACKUP_ROOT" "$AUDIT_DIR"

WORKSPACE_COUNT="$(find "$ROOT" -maxdepth 1 -mindepth 1 -type d -name 'workspace*' | wc -l | tr -d ' ')"
AGENT_COUNT="$(find "$ROOT/agents" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
OPENCLAW_VERSION="$(openclaw --version 2>/dev/null | head -n 1 || echo unknown)"
SYSTEM_NAME="$(uname -s 2>/dev/null || echo unknown)"
SYSTEM_ARCH="$(uname -m 2>/dev/null || echo unknown)"

(
  cd "$HOME"
  COPYFILE_DISABLE=1 tar \
    --exclude='.openclaw/backups/cold/*.tar.gz' \
    --exclude='.openclaw/backups/cold/*.manifest.txt' \
    --exclude='.openclaw/exec-approvals.sock' \
    --exclude='.openclaw/**/.DS_Store' \
    --exclude='._*' \
    -czf "$ARCHIVE" .openclaw
)

ARCHIVE_SIZE_BYTES="$(wc -c < "$ARCHIVE" | tr -d ' ')"
ARCHIVE_SHA256="$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')"

{
  echo "timestamp=$TS"
  echo "mode=cold-full"
  echo "archive=$ARCHIVE"
  echo "archive_name=$(basename "$ARCHIVE")"
  echo "archive_size_bytes=$ARCHIVE_SIZE_BYTES"
  echo "archive_sha256=$ARCHIVE_SHA256"
  echo "root=$ROOT"
  echo "contents=.openclaw (entire tree, excluding live sockets and cold-backup archives)"
  echo "workspaces=$WORKSPACE_COUNT"
  echo "agents=$AGENT_COUNT"
  echo "openclaw_version=$OPENCLAW_VERSION"
  echo "system=$SYSTEM_NAME"
  echo "arch=$SYSTEM_ARCH"
} > "$MANIFEST"

cat >> "$AUDIT_DIR/backup-log.md" <<EOF
## $TS
- mode: cold-full
- path: $ARCHIVE
- manifest: $MANIFEST
- sha256: $ARCHIVE_SHA256
- size_bytes: $ARCHIVE_SIZE_BYTES
EOF

echo "$ARCHIVE"
