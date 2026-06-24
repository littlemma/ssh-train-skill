# Prompt: Rebuild Python Project from reference-project/

You are working in a Windows-local Codex project whose tests, training, inference, data, checkpoints, logs, outputs, and caches live on a remote Linux server. Follow the local project instructions and never run large training locally.

## Non-Negotiable Rules

- First scan `reference-project/`; do not immediately perform large edits.
- Treat `reference-project/` as read-only evidence. Never import from it, execute it as the runtime path, or sync it as project code.
- Do not save, request, print, or write remote passwords.
- Do not sync or commit datasets, checkpoints, logs, outputs, cache, tmp files, model weights, `.npy`, `.npz`, `.pth`, `.pt`, `.ckpt`, or `.onnx`.
- Do not run training locally on Windows.
- After every migration stage, run `remote_test.ps1`.
- If tests pass, create a Git commit for that stage.

## Phase 0: Scan and Report

Inspect `reference-project/` and produce a short inventory before changing code:

- training entrypoint and CLI arguments;
- inference entrypoint;
- model definitions and import graph;
- dataset/data loader implementation;
- loss functions;
- physics or domain-specific computation modules;
- trainer/evaluation loop;
- config files and default values;
- hard-coded local paths, server paths, dataset paths, checkpoint paths, and output paths;
- external dependencies;
- files that are data, weights, generated outputs, IDE metadata, or caches and must not be migrated as source.

Then propose the target structure:

```text
src/<package_name>/
scripts/
configs/
tests/
tools/
docs/
```

## Phase 1: Minimal Package Skeleton

Create or update:

- `src/<package_name>/__init__.py`
- a minimal config loader if needed;
- `scripts/` entrypoint placeholders;
- smoke tests under `tests/`.

Run:

```powershell
.\remote_test.ps1
```

Commit:

```powershell
powershell -ExecutionPolicy Bypass -File <skill_dir>\scripts\create_git_snapshot.ps1 -ProjectDir . -Message "stage: project skeleton"
```

## Phase 2: Dataset Layer

Migrate dataset classes, transforms, and data-loading utilities into `src/<package_name>/data/`. Replace hard-coded paths with config values. Tests must use tiny synthetic data or mocks, never real datasets.

Run `.\remote_test.ps1`, fix failures remotely, then commit.

## Phase 3: Model Layer

Migrate model modules into `src/<package_name>/models/`. Preserve architecture behavior, but remove runtime assumptions about local files and checkpoints. Add import and shape smoke tests.

Run `.\remote_test.ps1`, fix failures remotely, then commit.

## Phase 4: Loss, Physics, Metrics

Migrate loss functions, physics/domain-specific functions, and metrics into focused modules. Add small deterministic tests for tensor shapes, finite values, and expected simple cases.

Run `.\remote_test.ps1`, fix failures remotely, then commit.

## Phase 5: Trainer and Configs

Migrate the training loop into `src/<package_name>/training/`. Put YAML/JSON configs in `configs/`. Keep data, checkpoints, logs, outputs, cache, and tmp paths remote-only and configurable.

Run `.\remote_test.ps1`, fix failures remotely, then commit.

## Phase 6: Scripts

Create command entrypoints in `scripts/`, such as:

- `scripts/train.py`
- `scripts/evaluate.py`
- `scripts/infer.py`

Entrypoints should import package code from `src/`; they must not import from `reference-project/`.

Run `.\remote_test.ps1`, fix failures remotely, then commit.

## Phase 7: Remote Smoke Run

Use `remote_train.ps1` only for a short smoke training command configured in `project_config.json`. Inspect logs with:

```powershell
.\remote_run.ps1 -Command "tail -n 100 logs/train/<log-name>"
```

Do not copy remote checkpoints or datasets back into Git. Commit only source/config/test updates if the smoke run exposes necessary code fixes.
