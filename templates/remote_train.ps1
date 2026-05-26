param(
  [string]$ConfigPath = "$PSScriptRoot\project_config.json",
  [string]$Command,
  [string]$Gpu = "",
  [string]$LogName = ""
)

$ErrorActionPreference = "Stop"

function Read-Config([string]$Path) {
  if (!(Test-Path -LiteralPath $Path)) { throw "Config not found: $Path" }
  return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
}

function Resolve-Tool([string]$Name, $Config) {
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  if ($Config.cwrsync_dir) {
    $candidate = Join-Path $Config.cwrsync_dir "bin\$Name.exe"
    if (Test-Path -LiteralPath $candidate) { return $candidate }
  }
  throw "$Name not found."
}

function Convert-ToBashSingleQuoted([string]$Value) {
  return "'" + ($Value -replace "'", "'\''") + "'"
}

$Config = Read-Config $ConfigPath
if (!$Command) { $Command = $Config.train_command }
if (!$LogName) { $LogName = "train_$(Get-Date -Format 'yyyyMMdd-HHmmss').log" }
$Ssh = Resolve-Tool "ssh" $Config

& "$PSScriptRoot\sync_to_vm.ps1" -ConfigPath $ConfigPath

$GpuPrefix = ""
if ($Gpu) { $GpuPrefix = "CUDA_VISIBLE_DEVICES=$Gpu " }
$Launch = "$GpuPrefix$Command"
$LogPath = "logs/train/$LogName"
$Session = $Config.tmux_session

if ($Config.use_tmux) {
  $Runner = "tmux new-session -d -s $Session '$Launch > $LogPath 2>&1'"
} else {
  $Runner = "nohup bash -lc '$Launch' > $LogPath 2>&1 &"
}

$RemoteCommand = @"
set -eo pipefail
source ~/.bashrc || true
if command -v conda >/dev/null 2>&1; then
  eval "`$(conda shell.bash hook)"
fi
conda activate $($Config.remote_conda_env)
cd "$($Config.remote_project_dir)"
mkdir -p logs/train checkpoints outputs cache tmp
echo "Starting remote training: $Launch"
$Runner
sleep 2
echo "Log: $($Config.remote_project_dir)/$LogPath"
ps aux | grep -E "python|torchrun" | grep -v grep || true
"@

& $Ssh "$($Config.remote_user)@$($Config.remote_host)" "bash -lc $(Convert-ToBashSingleQuoted $RemoteCommand)"
