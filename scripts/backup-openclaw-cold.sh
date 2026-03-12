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

{
  echo "timestamp=$TS"
  echo "archive=$ARCHIVE"
  echo "root=$ROOT"
  echo "contents=.openclaw (entire tree, excluding live sockets and cold-backup archives)"
  echo "workspaces=$WORKSPACE_COUNT"
  echo "agents=$AGENT_COUNT"
} > "$MANIFEST"

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

cat >> "$AUDIT_DIR/backup-log.md" <<EOF
## $TS
- mode: cold-full
- path: $ARCHIVE
- manifest: $MANIFEST
EOF

echo "$ARCHIVE"
