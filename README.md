[ssh-train-remote-workflow 使用指南.md](https://github.com/user-attachments/files/29282183/ssh-train-remote-workflow.md)
---
title: "ssh-train-remote-workflow Skill 使用指南"
aliases:
  - ssh-train
  - remote-workflow
  - 远程训练工作流
tags:
  - reference-note
  - workflow
  - codex-skill
  - remote-training
  - ssh
  - rsync
created: "2026-06-24"
updated:

source: "E:/ssh-train SKILL.md + README.md"
category: "工具使用指南"

canonical_tags:
  - remote-training
  - ssh
  - rsync
  - codex-workflow
candidate_tags:
  - windows-linux
  - gpu-server
  - experiment-management

theme: "Codex AI 编程助手在 Windows 本地编辑、Linux 远程训练的标准化工作流"
relevance: "用于黑洞图像重建项目中远程 GPU 训练、测试和实验管理"
---

# ssh-train-remote-workflow Skill 使用指南

> 是什么:
> 一个 Codex/Superpower AI 编程助手的 **Skill**，实现 **Windows 本地编辑代码，Linux GPU 服务器远程训练** 的标准化工作流。Skill 位于 `E:\ssh-train\`。

---

## 核心场景

Windows 上写 Python 代码 → `rsync` 自动同步到 GPU 服务器 → 远程跑测试/训练 → Git 版本控制每一步。

```
Windows (Codex 编辑)              Linux GPU 服务器
     │                                  │
     ├─ 修改 src/models/unet.py ───→ rsync ──→ 同步到远程
     ├─ .\remote_test.ps1 ────────→ SSH ────→ pytest
     ├─ git commit (测试通过)           │
     ├─ .\remote_train.ps1 ────────→ SSH ────→ nohup / tmux 训练
     └─ .\remote_run.ps1 ──────────→ SSH ────→ tail 日志
```

---

## 首次使用（新电脑 / 新项目）

### 1. 填写配置

```powershell
copy E:\ssh-train\examples\project_config.example.json E:\ssh-train\project_config.json
```

编辑 `project_config.json`：

```json
{
  "local_project_dir": "E:/my-python-project",
  "reference_project_dir": "E:/my-python-project/reference-project",
  "remote_host": "YOUR_SERVER_IP",
  "remote_user": "YOUR_SERVER_USERNAME",
  "remote_project_dir": "/your/remote/project/path",
  "remote_conda_env": "YOUR_REMOTE_CONDA_ENV",
  "test_command": "pytest -q",
  "train_command": "python scripts/train.py",
  "use_tmux": true,
  "tmux_session": "train",
  "cwrsync_dir": "D:/path/to/cwrsync"
}
```

| 字段 | 说明 |
|------|------|
| `local_project_dir` | Windows 本地项目路径 |
| `reference_project_dir` | 只读参考代码路径 |
| `remote_host` | 服务器 IP |
| `remote_user` | 服务器账户 |
| `remote_project_dir` | 远程运行时目录 |
| `remote_conda_env` | 远程 Conda 环境名 |
| `test_command` | 远程测试命令 |
| `train_command` | 远程训练命令 |
| `use_tmux` | 是否用 tmux 启动训练 |
| `tmux_session` | tmux 会话名 |
| `cwrsync_dir` | cwRsync 安装路径 (Windows 无原生 rsync) |

> [!warning]
> 密码只允许在 SSH 交互式终端中输入，**禁止写入任何配置文件、脚本、日志或 Git 提交**。

### 2. 环境自检

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap_windows.ps1
```

检查 Git / SSH / rsync / Python 是否就绪。

### 3. 配置免密 SSH

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup_ssh_key.ps1
```

首次会提示输入远程密码，之后不再需要。

### 4. 初始化项目骨架

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\init_project_workflow.ps1
```

自动创建标准目录结构并部署模板脚本：

```text
<项目>/
├── src/            # 可导入的项目代码
├── scripts/        # 命令行入口
├── configs/        # 配置文件
├── tests/          # 测试
├── tools/          # 工具脚本
├── docs/           # 项目文档
├── notebooks/      # 轻量 notebook
├── reference-project/  # 只读参考代码
├── sync_to_vm.ps1      # ← 以下由 init 自动复制
├── remote_test.ps1
├── remote_train.ps1
├── remote_run.ps1
├── .syncignore
├── .gitignore
└── project_config.json
```

### 5. 放入参考代码

将旧版/下载的代码放到 `<项目>/reference-project/` 下。该目录仅作只读参考，**不作为运行时路径**。

### 6. 让 Codex 重构项目

在 Codex 中给 prompt：`prompts/rebuild_from_reference.md`

Codex 会按阶段执行：

| 阶段 | 内容 |
|------|------|
| Phase 0 | 扫描 `reference-project/`，输出代码清单 |
| Phase 1 | 创建 package skeleton + smoke tests |
| Phase 2 | 迁移 dataset 层（替换硬编码路径） |
| Phase 3 | 迁移 model 层 |
| Phase 4 | 迁移 loss / physics / metrics |
| Phase 5 | 迁移 trainer + configs |
| Phase 6 | 创建 `scripts/` 命令行入口 |
| Phase 7 | 远程 smoke run 验证 |

每个阶段结束后自动运行 `.\remote_test.ps1`，通过则 Git commit。

---

## 日常使用命令

迁移完成后，在项目目录下直接使用：

| 命令 | 作用 |
|------|------|
| `.\sync_to_vm.ps1` | rsync 同步代码到服务器（排除数据/日志/权重） |
| `.\remote_test.ps1` | 同步 + 远程跑 pytest |
| `.\remote_train.ps1` | 同步 + 远程启动训练（tmux / nohup） |
| `.\remote_run.ps1 -Command "<cmd>"` | 在远程执行自定义命令 |
| `.\remote_run.ps1 -Command "tail -100 logs/train/xxx.log"` | 查看远程训练日志 |

### 进阶用法

```powershell
# 指定 GPU
.\remote_train.ps1 -Gpu "2,3"

# 自定义训练命令
.\remote_train.ps1 -Command "python scripts/train.py --lr 0.001 -b 8"

# 指定日志名
.\remote_train.ps1 -LogName "exp_v200_smoke.log"

# 仅执行远程命令（不同步）
.\remote_run.ps1 -Command "nvidia-smi && ls logs/train/"
```

---

## Git 快照

```powershell
powershell -ExecutionPolicy Bypass -File E:\ssh-train\scripts\create_git_snapshot.ps1 -ProjectDir . -Message "stage: 数据集迁移完成"
```

> [!warning]
> 自动拒绝提交以下类型文件：`.npy` `.npz` `.pth` `.pt` `.ckpt` `.onnx` `.h5` `.pkl`，以及 `datasets/` `checkpoints/` `logs/` `outputs/` `cache/` 目录。

---

## 安全规则

- ❌ 禁止在任何文件中保存密码
- ❌ 禁止同步/提交 `datasets/` `checkpoints/` `logs/` `outputs/` `cache/` `tmp/`、模型权重、数组数据
- ❌ 禁止在 Windows 本地运行大规模训练
- ❌ 禁止用本地空目录覆盖远程结果目录
- ✅ `reference-project/` 仅作只读参考
- ✅ 优先 append、backup、幂等创建，避免删除操作

---

## Skill 文件结构

```text
E:\ssh-train\
├── SKILL.md                  # Skill 定义（Codex 识别入口）
├── README.md                 # 使用说明
├── project_config.json       # 项目配置（需手动填写）
├── examples/
│   └── project_config.example.json  # 配置模板
├── prompts/                  # Codex prompt 模板
│   ├── rebuild_from_reference.md    # 从参考代码重建项目
│   ├── migrate_stage_by_stage.md    # 逐阶段迁移
│   ├── git_snapshot_flow.md         # Git 快照流程
│   └── remote_debug_loop.md         # 远程调试循环
├── scripts/                  # 工作流脚本
│   ├── bootstrap_windows.ps1        # Windows 环境自检
│   ├── setup_ssh_key.ps1            # SSH 免密配置
│   ├── init_project_workflow.ps1    # 项目初始化
│   ├── create_git_snapshot.ps1      # Git 快照
│   └── validate_remote.ps1          # 远程环境验证
├── templates/                # 项目模板（复制到目标项目）
│   ├── sync_to_vm.ps1
│   ├── remote_test.ps1
│   ├── remote_train.ps1
│   ├── remote_run.ps1
│   ├── .syncignore
│   ├── .gitignore
│   ├── README.project.md
│   └── codex_project_instruction.md
└── reference/                # 原始单项目脚本（只读参考）
    ├── README.md
    ├── remote_train.ps1
    ├── sync_to_vm.ps1
    └── enable_remote_control.ps1
```
