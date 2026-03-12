# OpenClaw 备份与恢复指南

> 面向多人使用、多 agent、多 workspace 场景的实用备份方案。
>
> 目标：让 OpenClaw 在配置误改、workspace 污染、agent 串味、升级失败、多人误操作等情况下，能够快速保存、快速恢复、可审计、可回退。

## 总览

推荐把备份分成三层：

1. 配置备份（config-only）
2. 运行态全量备份（runtime-full）
3. 整机冷备份（cold-full）

这套项目同时补足：
- config-only 回退
- agent-only 回退
- runtime-full 回退
- 整机级冷备
- 恢复前默认先保存当前快照
- 审计日志记录

## 官方内建备份

```bash
openclaw backup create --only-config --verify
openclaw backup create --verify
openclaw backup verify <archive>
```

## 本地脚本

### 配置备份
```bash
bash scripts/backup-openclaw.sh config
bash scripts/restore-openclaw.sh --config-only <snapshot>
```

### 运行态全量
```bash
bash scripts/backup-openclaw.sh all
bash scripts/restore-openclaw.sh --full <snapshot>
```

### 整机冷备
```bash
bash scripts/backup-openclaw-cold.sh
bash scripts/restore-openclaw-cold.sh --list
bash scripts/restore-openclaw-cold.sh --restore <archive.tar.gz>
```

冷备会额外生成一个 manifest，记录：
- 时间戳
- 归档名
- 归档大小
- SHA256
- workspace 数量
- agent 数量
- OpenClaw 版本
- 系统与架构

## 恢复安全性

所有恢复动作都默认会先保存当前快照，避免回退之后发现不对、却无法回到恢复前状态。

默认恢复策略是**保守覆盖**：
- 会覆盖快照里已有的目标
- 不会自动删除恢复点之外后来新增的文件

如果你明确希望清理这些“额外文件”，可以使用：

```bash
bash scripts/restore-openclaw.sh --prune-extra --full <snapshot>
```

脚本会先询问确认，再执行删除。

## 目录约定

- 备份目录：`~/.openclaw/backups`
- 冷备目录：`~/.openclaw/backups/cold`
- 审计目录：`~/.openclaw/audit`

## 适合场景

- 多 agent 共存
- 多 workspace 并行
- 多人共用一个 OpenClaw 环境
- 高频配置修改
- 升级前兜底
- 共享环境风险控制
