# OpenClaw Backup Toolkit

[中文说明 / Chinese README](./README.zh-CN.md)

Practical backup and restore scripts for multi-agent, multi-workspace OpenClaw setups.

This project exists for one simple reason:

> if you are using OpenClaw as an evolving system, backup and rollback are not optional.

OpenClaw already has built-in backup support. This toolkit complements that with more operator-focused workflows for shared, experimental, or multi-agent environments.

## What this toolkit adds

- config-only backup / restore
- runtime snapshot backup / restore
- cold backup of the entire `~/.openclaw`
- pre-restore safety snapshots by default
- lightweight audit logs
- agent-scoped restore flows
- cold-backup manifests with SHA256 and archive metadata

This project is aimed at people who are treating OpenClaw like a small evolving system instead of a single-user toy setup.

## Who this is for

This is especially useful if you have any of these:
- multiple agents
- multiple workspaces
- shared or semi-shared OpenClaw environments
- risky config iteration
- a strong desire to be able to undo mistakes

## Status

Early but usable.

What has been checked so far:
- scripts were written against a real OpenClaw installation
- backup scripts were exercised on a live environment
- cold backup produced a real archive successfully
- restore flows include automatic pre-restore snapshots
- default restore pruning is covered in isolated smoke tests
- scripts pass `bash -n`
- isolated end-to-end smoke tests run against a temporary fake `.openclaw` tree (not the live environment)

What has **not** been fully proven yet:
- large-scale or long-history restore drills
- cross-platform validation beyond macOS
- compatibility across many OpenClaw versions

So: this is **reasonable and practical**, but not yet something I would call battle-hardened.

## Backup layers

### Quick examples

```bash
# before editing global config
bash scripts/backup-openclaw.sh config

# preserve current runtime state
bash scripts/backup-openclaw.sh all

# create a cold backup before upgrades / risky changes
bash scripts/backup-openclaw-cold.sh

# restore config from a snapshot (automatically creates a pre-restore snapshot first)
bash scripts/restore-openclaw.sh --config-only <snapshot>

# if you want overwrite-without-deleting-extra-files
bash scripts/restore-openclaw.sh --keep-extra --full <snapshot>
```

### 1. Config-only
Use before editing `openclaw.json`, bindings, channels, skills, or extensions.

```bash
bash scripts/backup-openclaw.sh config
bash scripts/restore-openclaw.sh --config-only <snapshot>
```

### 2. Runtime-full
Use when you want to preserve the current working state of config + workspaces + agents.

```bash
bash scripts/backup-openclaw.sh all
bash scripts/restore-openclaw.sh --full <snapshot>
```

### 3. Cold-full
Use before upgrades, major experiments, or as disaster-recovery insurance.

```bash
bash scripts/backup-openclaw-cold.sh
bash scripts/restore-openclaw-cold.sh --list
bash scripts/restore-openclaw-cold.sh --restore <archive.tar.gz>
```

## Important safety rule

All restore flows in this toolkit take a **pre-restore snapshot by default**.

That means if you roll back and then realize you picked the wrong snapshot, you still have a path back to the exact pre-restore state.

Restore behavior is **pruning by default**:
- it overwrites files that exist in the target snapshot
- it also removes extra files that are not present in the target snapshot

Before any restore, the toolkit first creates a **pre-restore snapshot** of the current state.
That is the safety net that makes default-pruning reasonable.

If you want a less aggressive restore, use `--keep-extra`.

Cold backups also emit a small `manifest.txt` file that records metadata such as:
- timestamp
- archive path and name
- archive size
- SHA256 checksum
- workspace count
- agent count
- OpenClaw version
- host OS / architecture

## Directory expectations

By default the scripts assume:

- OpenClaw root: `~/.openclaw`
- audit logs: `~/.openclaw/audit`
- snapshots: `~/.openclaw/backups`

You can override the root with:

```bash
OPENCLAW_ROOT=/path/to/.openclaw bash scripts/backup-openclaw.sh all
```

## Included files

- `scripts/backup-openclaw.sh`
- `scripts/restore-openclaw.sh`
- `scripts/backup-openclaw-cold.sh`
- `scripts/restore-openclaw-cold.sh`
- `docs/OPENCLAW_BACKUP_GUIDE.md`

## Relationship to official backup support

Official OpenClaw backup is still the primary built-in path:

```bash
openclaw backup create --only-config --verify
openclaw backup create --verify
openclaw backup verify <archive>
```

This toolkit is intentionally complementary. It focuses more on operator ergonomics and layered restore workflows.

## Suggested usage pattern

- before config edits → config-only backup
- before agent/workspace changes → runtime snapshot backup
- before upgrades / risky changes → cold backup
- before every restore → automatic pre-restore snapshot already happens

## License

MIT
