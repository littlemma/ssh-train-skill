param(
  [string]$Gpu = "4,5,6,7",
  [int]$MaxIter = 20
)

$ErrorActionPreference = "Stop"

$VM_USER = "YOUR_SERVER_USERNAME"
$VM_HOST = "YOUR_SERVER_IP"
$REMOTE_DIR = "/path/to/remote/project/"
$TRAIN_LOG = "/path/to/remote/project/logs/train/smoke_train.log"
$SSH = "D:\path\to\cwrsync\bin\ssh.exe"

Write-Host "Sync code to VM..."
& "$PSScriptRoot\sync_to_vm.ps1"

Write-Host "Start remote smoke training..."
$RemoteCommand = @"
set -eo pipefail
source ~/.bashrc
source /path/to/miniconda/etc/profile.d/conda.sh
conda activate YOUR_CONDA_ENV
cd $REMOTE_DIR
mkdir -p logs/train
nvidia-smi
CUDA_VISIBLE_DEVICES=$Gpu nohup python -u train.py --config configs/train.yaml --max-iter $MaxIter --skip-eval > $TRAIN_LOG 2>&1 &
sleep 2
ps aux | grep "train.py" | grep -v grep
"@

& $SSH "${VM_USER}@${VM_HOST}" "bash -lc '$RemoteCommand'"
