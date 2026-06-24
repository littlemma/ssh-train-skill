param(
  [string]$ConfigPath = "$PSScriptRoot\project_config.json"
)

$ErrorActionPreference = "Stop"

function Read-Config([string]$Path) {
  if (!(Test-Path -LiteralPath $Path)) { throw "Config not found: $Path" }
  return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
}

function Convert-ToRsyncPath([string]$Path) {
  $full = [System.IO.Path]::GetFullPath($Path).Replace("\", "/")
  if ($full -match "^([A-Za-z]):/(.*)$") {
    return "/cygdrive/$($Matches[1].ToLower())/$($Matches[2])"
  }
  return $full
}

function Resolve-Tool([string]$Name, $Config) {
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  if ($Config.cwrsync_dir) {
    $candidate = Join-Path $Config.cwrsync_dir "bin\$Name.exe"
    if (Test-Path -LiteralPath $candidate) { return $candidate }
  }
  throw "$Name not found. Install cwRsync or add Git Bash rsync to PATH."
}

$Config = Read-Config $ConfigPath
$LocalDir = [System.IO.Path]::GetFullPath($Config.local_project_dir)
$SyncIgnore = Join-Path $LocalDir ".syncignore"
$Rsync = Resolve-Tool "rsync" $Config
$Ssh = Resolve-Tool "ssh" $Config
$Remote = "$($Config.remote_user)@$($Config.remote_host):$($Config.remote_project_dir.TrimEnd('/'))/"
$LocalRsync = Convert-ToRsyncPath $LocalDir
$Suffix = "." + (Get-Date -Format "yyyyMMdd-HHmmss") + ".bak"

if (!(Test-Path -LiteralPath $SyncIgnore)) { throw ".syncignore not found: $SyncIgnore" }

Write-Host "About to sync local code to remote."
Write-Host "Local:  $LocalDir"
Write-Host "Remote: $Remote"
Write-Host "Exclude file: $SyncIgnore"
Write-Host "Remote deletions are protected with rsync --backup suffix $Suffix"

& $Rsync -az --delete --backup --backup-dir=".rsync-deleted" --suffix="$Suffix" `
  --exclude-from="$SyncIgnore" `
  -e "`"$Ssh`"" `
  "$LocalRsync/" `
  "$Remote"

Write-Host "Sync finished."
