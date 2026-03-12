# OpenClaw Backup Toolkit

面向多 agent、多 workspace、多人/半多人共享 OpenClaw 环境的备份与恢复工具集。

如果你已经把 OpenClaw 用成一个持续演化的系统，而不只是单人玩具环境，那么：

> 备份和回退不是附加项，而是基础设施。

OpenClaw 已经有官方内建 backup 能力；这个项目的定位是**补足更偏运维和回退流程的部分**。

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
- 也就是不仅覆盖已有文件，还会删除目标快照之外的额外文件

这样更接近“回到那个快照当时的状态”。

### 如果你不想删额外文件
可以显式使用：

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

这样你拿到备份包时，不解压也能先判断它是什么。

## 和官方 backup 的关系

官方能力：

```bash
openclaw backup create --only-config --verify
openclaw backup create --verify
openclaw backup verify <archive>
```

这个项目不是替代官方，而是**补足分层恢复、pre-restore 快照、agent 粒度恢复、cold backup manifest 等运维细节**。

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

## 包含文件

- `scripts/backup-openclaw.sh`
- `scripts/restore-openclaw.sh`
- `scripts/backup-openclaw-cold.sh`
- `scripts/restore-openclaw-cold.sh`
- `scripts/run-isolated-tests.sh`
- `scripts/smoke-check.sh`
- `docs/OPENCLAW_BACKUP_GUIDE.md`

## 推荐使用方式

- 改全局配置前 → 先做 config-only backup
- 改 agent / workspace / memory 前 → 先做 runtime snapshot
- 升级 / 风险操作前 → 先做 cold backup
- 恢复时 → 默认依赖 pre-restore 快照兜底

## 后续方向

见：`ROADMAP.md`

当前比较值得继续补的方向包括：
- 更丰富的 manifest
- retention / rotation（先不默认启用）
- dry-run restore
- 恢复后健康检查
- Linux 验证
- 更完整的恢复演练矩阵

## 许可证

MIT
