# OpenClaw Backup Toolkit

[English](#english) | [中文](#中文)

---

## English

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
- `README.zh-CN.md`

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

---

## 中文

面向多 agent、多 workspace、多人/半多人共享 OpenClaw 环境的备份与恢复工具集。

这个项目的核心想法很简单：

> 如果你把 OpenClaw 当成一个持续演化的系统来用，备份和回退就不是附加项，而是基础设施。

OpenClaw 已经有官方内建 backup；这个项目的定位是补足更偏运维和回退流程的部分。

## 这个项目补了什么

- config-only 备份 / 恢复
- runtime-full 运行态快照备份 / 恢复
- 整个 `~/.openclaw` 的 cold backup 冷备
- 恢复前默认自动保存当前快照
- 轻量审计日志
- agent 粒度恢复
- cold backup 的 manifest + SHA256

## 适合谁

如果你有这些场景，这个项目会比较有用：
- 多个 agent 共存
- 多个 workspace 并行
- 多人或半多人共用同一个 OpenClaw 环境
- 高频修改 `openclaw.json` / bindings / accounts / skills
- 想保留记忆、人格、工作流和当前状态
- 想在出错时能快速回退

## 当前状态

这是一个**早期可用版本**，不是“完全 battle-tested 的生产级产品”。

目前已经做过的验证：
- 脚本通过 `bash -n`
- 冷备脚本在真实 OpenClaw 环境里产出过归档
- 恢复前自动 `pre-restore` 快照已实测
- 默认 prune 恢复逻辑已在隔离环境里测试
- 在临时 fake `.openclaw` 环境里跑通过完整 smoke test
- 在真实 `.openclaw` 的影子副本上完成过恢复演练（未碰现网）

还没有完全验证的部分：
- 大规模历史数据 / 超多 session 的长尾情况
- Linux / 其他系统兼容性
- 多个 OpenClaw 版本矩阵

所以更准确的说法是：

> **已经可用，但还在继续打磨。**

## 三层备份模型

### 快速示例

```bash
# 改全局配置前
bash scripts/backup-openclaw.sh config

# 保存当前运行态
bash scripts/backup-openclaw.sh all

# 升级前 / 高风险操作前做冷备
bash scripts/backup-openclaw-cold.sh

# 从快照恢复（恢复前会自动保存当前快照）
bash scripts/restore-openclaw.sh --config-only <snapshot>

# 如果你只想覆盖、不想删额外文件
bash scripts/restore-openclaw.sh --keep-extra --full <snapshot>
```

### 1. 配置备份（config-only）
适合：修改 `openclaw.json`、bindings、channel accounts、skills、extensions 前。

```bash
bash scripts/backup-openclaw.sh config
bash scripts/restore-openclaw.sh --config-only <snapshot>
```

### 2. 运行态全量（runtime-full）
适合：你想保留 config + workspaces + agents 的当前可运行状态。

```bash
bash scripts/backup-openclaw.sh all
bash scripts/restore-openclaw.sh --full <snapshot>
```

### 3. 整机冷备（cold-full）
适合：升级前、大改前、多人环境试验前、灾难恢复。

```bash
bash scripts/backup-openclaw-cold.sh
bash scripts/restore-openclaw-cold.sh --list
bash scripts/restore-openclaw-cold.sh --restore <archive.tar.gz>
```

## 默认恢复策略

现在的默认恢复策略是：
- 恢复前先自动保存当前快照
- 然后执行**带清理的恢复**
- 不仅覆盖已有文件，还会删除目标快照之外的额外文件

这样更接近“回到那个快照本身的状态”。

如果你不想删额外文件，可以显式使用：

```bash
bash scripts/restore-openclaw.sh --keep-extra --full <snapshot>
```

同理也支持：

```bash
bash scripts/restore-openclaw.sh --keep-extra --config-only <snapshot>
bash scripts/restore-openclaw.sh --keep-extra --agent <agentId> <snapshot>
```

## cold backup 的 manifest

cold backup 会生成一个额外的 `manifest.txt`，记录：
- 时间戳
- 归档路径 / 文件名
- 文件大小
- SHA256
- workspace 数量
- agent 数量
- OpenClaw 版本
- 系统和架构

这样拿到备份包时，不解压也能先判断它是什么。

## 和官方 backup 的关系

官方能力：

```bash
openclaw backup create --only-config --verify
openclaw backup create --verify
openclaw backup verify <archive>
```

这个项目不是替代官方，而是补足分层恢复、pre-restore 快照、agent 粒度恢复、cold backup manifest 等运维细节。

## 目录约定

默认目录：
- OpenClaw 根目录：`~/.openclaw`
- 备份目录：`~/.openclaw/backups`
- 冷备目录：`~/.openclaw/backups/cold`
- 审计目录：`~/.openclaw/audit`

也可以通过环境变量覆盖：

```bash
OPENCLAW_ROOT=/path/to/.openclaw bash scripts/backup-openclaw.sh all
```

## 许可证

MIT
