---
name: ssh-train-remote-workflow
description: Use when Codex edits Python code on Windows while tests, training, inference, datasets, checkpoints, and logs live on a remote Linux server over SSH.
---

# ssh-train-remote-workflow

## Overview
Use this skill to set up a repeatable Windows-local, Linux-remote Python workflow: Codex edits only lightweight source files locally, synchronizes code with rsync, runs tests/training remotely, and commits small Git snapshots after verified stages.

## Applies When
- Windows local Codex modifies code.
- Linux server runs training, tests, or inference.
- Local machine has no GPU or data is too large.
- A `reference-project/` must be rebuilt into a standard Python project.
- Each change should be verified remotely and captured with Git.
- Remote logs need to be inspected after test or training runs.

## Required User Inputs
Create `project_config.json` from `examples/project_config.example.json` and set:

| Field | Purpose |
|---|---|
| `local_project_dir` | Lightweight Windows project, for example `E:/my-python-project` |
| `reference_project_dir` | Read-only reference code, for example `E:/my-python-project/reference-project` |
| `remote_host` | Server IP, default `192.168.120.215` |
| `remote_user` | Server account, default `y24.d01.user17` |
| `remote_project_dir` | Remote runtime dir, for example `/nfs10/data3/y24.d01.user17/my-python-project` |
| `remote_conda_env` | Conda env, for example `PISR2-2` |
| `test_command` | Remote test command, for example `pytest -q` |
| `train_command` | Remote train command, for example `python scripts/train.py` |
| `use_tmux` | Start training in tmux if available |
| `tmux_session` | tmux session name |
| `cwrsync_dir` | cwRsync install path when Windows has no native `rsync` |

Passwords must only be typed interactively during first SSH setup. Do not add `remote_password` to any config.

## Safety Rules
- Never save passwords in scripts, README, logs, configs, prompts, shell history, or Git.
- Never sync or commit `datasets/`, `checkpoints/`, `logs/`, `outputs/`, `cache/`, `tmp/`, model weights, or array dumps.
- Never run large training locally on Windows.
- Never overwrite remote result directories from a local empty directory.
- Treat `reference-project/` as read-only evidence only; it must never be the runtime path.
- Prefer append, backup, and idempotent creation over deletion.

## Standard Workflow
1. Run `scripts/bootstrap_windows.ps1 -ConfigPath .\project_config.json`.
2. Run `scripts/setup_ssh_key.ps1 -ConfigPath .\project_config.json` and type the remote password only if SSH prompts.
3. Run `scripts/init_project_workflow.ps1 -ConfigPath .\project_config.json` to create project folders, remote folders, templates, and Git.
4. Put legacy code in `reference-project/`.
5. Give Codex `prompts/rebuild_from_reference.md` and the project config.
6. After each migration stage, run `remote_test.ps1`.
7. When tests pass, run `scripts/create_git_snapshot.ps1 -ProjectDir <local_project_dir> -Message "<small change>"`.
8. Start remote training with `remote_train.ps1`; inspect logs with `remote_run.ps1 -Command "tail -n 100 logs/train/<log>"`.

## Rebuild Pattern
- Scan first, change second.
- Summarize training entrypoints, model modules, datasets, losses, physics code, inference entrypoints, configs, and hard-coded paths.
- Migrate in small slices: dataset, model, loss, physics, trainer, scripts, configs, tests.
- Put importable code under `src/`, commands under `scripts/`, configs under `configs/`, tests under `tests/`.
- Run remote tests and create a Git snapshot after every stage.

## Common Mistakes
- Copying the reference tree wholesale into runtime code. Instead, rebuild structure and port only understood behavior.
- Running `python train.py` locally. Use `remote_train.ps1`.
- Adding datasets or weights to Git. Keep them on the remote server only.
- Embedding passwords in config. SSH setup must remain interactive.
