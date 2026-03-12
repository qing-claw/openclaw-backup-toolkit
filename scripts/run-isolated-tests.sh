#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT="${TMPDIR:-/tmp}/openclaw-backup-toolkit-test-$$"
FAKE_ROOT="$TEST_ROOT/.openclaw"
export OPENCLAW_ROOT="$FAKE_ROOT"
export HOME="$TEST_ROOT"
mkdir -p "$HOME/.acpx" "$FAKE_ROOT" "$FAKE_ROOT/agents/demo" "$FAKE_ROOT/workspace-demo/memory" "$FAKE_ROOT/skills" "$FAKE_ROOT/extensions"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

# seed fake environment
cat > "$FAKE_ROOT/openclaw.json" <<'EOF'
{"hello":"world","version":1}
EOF
cat > "$FAKE_ROOT/exec-approvals.json" <<'EOF'
{"approved":[]}
EOF
cat > "$HOME/.acpx/config.json" <<'EOF'
{"profile":"test"}
EOF
cat > "$FAKE_ROOT/workspace-demo/AGENTS.md" <<'EOF'
# demo
EOF
cat > "$FAKE_ROOT/workspace-demo/memory/2026-03-12.md" <<'EOF'
- note a
EOF
cat > "$FAKE_ROOT/agents/demo/info.txt" <<'EOF'
agent demo
EOF
cat > "$FAKE_ROOT/skills/demo.txt" <<'EOF'
skill
EOF
cat > "$FAKE_ROOT/extensions/demo.txt" <<'EOF'
extension
EOF

# config backup + restore
SNAP_CONFIG="$(bash "$PROJECT_ROOT/scripts/backup-openclaw.sh" config)"
[ -d "$SNAP_CONFIG" ]
echo '{"hello":"changed","version":2}' > "$FAKE_ROOT/openclaw.json"
bash "$PROJECT_ROOT/scripts/restore-openclaw.sh" --config-only "$(basename "$SNAP_CONFIG")" >/dev/null
grep -q '"version":1' "$FAKE_ROOT/openclaw.json"
ls -1 "$FAKE_ROOT/backups" | grep -q '^pre-restore-'

# full backup + restore
SNAP_FULL="$(bash "$PROJECT_ROOT/scripts/backup-openclaw.sh" all)"
echo 'mutated' > "$FAKE_ROOT/agents/demo/info.txt"
echo 'mutated note' > "$FAKE_ROOT/workspace-demo/memory/2026-03-12.md"
mkdir -p "$FAKE_ROOT/workspace-extra"
echo 'extra' > "$FAKE_ROOT/workspace-extra/file.txt"
bash "$PROJECT_ROOT/scripts/restore-openclaw.sh" --full "$(basename "$SNAP_FULL")" >/dev/null
grep -q 'agent demo' "$FAKE_ROOT/agents/demo/info.txt"
grep -q 'note a' "$FAKE_ROOT/workspace-demo/memory/2026-03-12.md"
[ -e "$FAKE_ROOT/workspace-extra/file.txt" ]
printf 'y\n' | bash "$PROJECT_ROOT/scripts/restore-openclaw.sh" --prune-extra --full "$(basename "$SNAP_FULL")" >/dev/null
[ ! -e "$FAKE_ROOT/workspace-extra" ]

# cold backup + restore
COLD_ARCHIVE="$(bash "$PROJECT_ROOT/scripts/backup-openclaw-cold.sh")"
[ -f "$COLD_ARCHIVE" ]
echo '{"hello":"cold-mutated"}' > "$FAKE_ROOT/openclaw.json"
bash "$PROJECT_ROOT/scripts/restore-openclaw-cold.sh" --restore "$COLD_ARCHIVE" >/dev/null
grep -q '"version":1' "$FAKE_ROOT/openclaw.json"
ls -1 "$FAKE_ROOT/backups/cold" | grep -q '^pre-restore-.*\.tar\.gz$'

echo "isolated tests passed"
