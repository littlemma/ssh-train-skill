# SR_PINN

This repository is the local Windows code workspace for SR_PINN. Codex edits code here only; datasets, checkpoints, logs, outputs, and caches live on the server.

Reference source is kept in `reference-project/` as read-only material and must not be used as a runtime path.

## Remote Workflow

Sync code:

```powershell
powershell -ExecutionPolicy Bypass -File .\sync_to_vm.ps1
```

Run remote tests:

```powershell
powershell -ExecutionPolicy Bypass -File .\remote_test.ps1
```

Start the default 20-iteration smoke train:

```powershell
powershell -ExecutionPolicy Bypass -File .\remote_train.ps1
```

Specify GPUs and smoke iterations:

```powershell
powershell -ExecutionPolicy Bypass -File .\remote_train.ps1 -Gpu "4,5,6,7" -MaxIter 20
```

The training command uses `nohup` and writes logs to:

```text
/path/to/remote/my-python-project/logs/train/smoke_train.log
```

Check training processes on the server:

```bash
ps aux | grep "train.py" | grep -v grep
```

Run inference:

```powershell
powershell -ExecutionPolicy Bypass -File .\remote_run.ps1
```

Do not run training locally on Windows. Use `python train.py --config configs/train.yaml` only inside the remote `YOUR_CONDA_ENV` conda environment.

## Entrypoints

Training:

```bash
python train.py --config configs/train.yaml --max-iter 20 --skip-eval
```

Single-GPU debug:

```bash
CUDA_VISIBLE_DEVICES=2 python -u train.py --config configs/train.yaml --max-iter 20 --skip-eval
```

Multi-GPU DDP smoke:

```bash
CUDA_VISIBLE_DEVICES=2,3,4,5 torchrun --nproc_per_node=4 train.py --config configs/train.yaml --max-iter 100 --skip-eval
```

Multi-GPU DDP training:

```bash
CUDA_VISIBLE_DEVICES=2,3,4,5 torchrun --nproc_per_node=4 train.py --config configs/train.yaml
```

Inference:

```bash
python infer.py --config configs/train.yaml
```

## Important Note

`sync_to_vm.ps1` is intentionally not modified here. It must sync this workspace to:

```text
/path/to/remote/my-python-project/
```

If it still points elsewhere, update it only after explicit approval.
