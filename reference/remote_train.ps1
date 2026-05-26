param(
  [string]$Gpu = "4,5,6,7",
  [int]$MaxIter = 20
)

$ErrorActionPreference = "Stop"

$VM_USER = "user"
$VM_HOST = "192.168.xxx.xxx"
$REMOTE_DIR = "/nfs10/data3/m24.YFMa/my-python-project/"
$TRAIN_LOG = "/nfs10/data3/m24.YFMa/my-python-project/logs/train/smoke_train.log"
$SSH = "D:\cwrsync_6.4.8_x64_free\bin\ssh.exe"

Write-Host "Sync code to VM..."
& "$PSScriptRoot\sync_to_vm.ps1"

Write-Host "Start remote smoke training..."
$RemoteCommand = @"
set -eo pipefail
source ~/.bashrc
source /nfs06/share/software/miniconda/py312_24.9.2.0/etc/profile.d/conda.sh
conda activate PISR2-2
cd $REMOTE_DIR
mkdir -p logs/train
nvidia-smi
CUDA_VISIBLE_DEVICES=$Gpu nohup python -u train.py --config configs/train.yaml --max-iter $MaxIter --skip-eval > $TRAIN_LOG 2>&1 &
sleep 2
ps aux | grep "train.py" | grep -v grep
"@

& $SSH "${VM_USER}@${VM_HOST}" "bash -lc '$RemoteCommand'"
