# Remote Python Project

Codex edits source locally on Windows. Tests, training, inference, data, checkpoints, logs, outputs, and caches live on the remote Linux server.

## Layout

- `src/`: importable project code
- `scripts/`: command entrypoints
- `configs/`: configuration files
- `tests/`: smoke and unit tests
- `tools/`: maintenance tools
- `docs/`: project notes
- `notebooks/`: lightweight notebooks only
- `reference-project/`: read-only reference code, not a runtime path

## Commands

```powershell
.\sync_to_vm.ps1
.\remote_test.ps1
.\remote_train.ps1
.\remote_run.ps1 -Command "hostname && pwd"
```

Do not run large training locally. Do not commit data, checkpoints, logs, outputs, caches, or weights.
