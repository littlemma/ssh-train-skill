param(
  [string]$ConfigPath = "$PSScriptRoot\..\project_config.json"
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
$Ssh = Resolve-Tool "ssh" $Config

$RemoteCommand = @"
set -eo pipefail
echo "host=`$(hostname)"
echo "user=`$(whoami)"
test -d "$($Config.remote_project_dir)" && echo "project_dir=ok" || echo "project_dir=missing"
source ~/.bashrc || true
if command -v conda >/dev/null 2>&1; then
  eval "`$(conda shell.bash hook)"
  conda activate $($Config.remote_conda_env)
  python --version || true
else
  echo "conda=missing"
fi
"@

& $Ssh "$($Config.remote_user)@$($Config.remote_host)" "bash -lc $(Convert-ToBashSingleQuoted $RemoteCommand)"
