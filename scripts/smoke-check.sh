#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

for f in scripts/*.sh; do
  bash -n "$f"
done

echo "bash -n ok"
bash "$PROJECT_ROOT/scripts/run-isolated-tests.sh"
