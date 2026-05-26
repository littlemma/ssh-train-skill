param(
  [string]$ConfigPath = "$PSScriptRoot\..\project_config.json",
  [string]$LocalProjectDir,
  [string]$RemoteHost,
  [string]$RemoteUser,
  [string]$CwRsyncDir
)

$ErrorActionPreference = "Stop"

function Read-Config([string]$Path) {
  if (Test-Path -LiteralPath $Path) {
    return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
  }
  return [pscustomobject]@{}
}

function First-Value($A, $B, $Default) {
  if ($A) { return $A }
  if ($B) { return $B }
  return $Default
}

function Test-CommandOrCandidate([string]$Name, [string]$Candidate) {
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  if ($Candidate -and (Test-Path -LiteralPath $Candidate)) { return $Candidate }
  return $null
}

$Config = Read-Config $ConfigPath
$LocalProjectDir = First-Value $LocalProjectDir $Config.local_project_dir "E:/my-python-project"
$RemoteHost = First-Value $RemoteHost $Config.remote_host "192.168.120.215"
$RemoteUser = First-Value $RemoteUser $Config.remote_user "y24.d01.user17"
$CwRsyncDir = First-Value $CwRsyncDir $Config.cwrsync_dir ""

$Git = Test-CommandOrCandidate "git" $null
$Ssh = Test-CommandOrCandidate "ssh" $(if ($CwRsyncDir) { Join-Path $CwRsyncDir "bin\ssh.exe" })
$Rsync = Test-CommandOrCandidate "rsync" $(if ($CwRsyncDir) { Join-Path $CwRsyncDir "bin\rsync.exe" })
$Python = Test-CommandOrCandidate "python" $null

Write-Host "Windows bootstrap check"
Write-Host "Config: $ConfigPath"
Write-Host "Local project: $LocalProjectDir"
Write-Host "Remote: $RemoteUser@$RemoteHost"
Write-Host ""
Write-Host "Git:    $(if ($Git) { $Git } else { 'MISSING' })"
Write-Host "SSH:    $(if ($Ssh) { $Ssh } else { 'MISSING' })"
Write-Host "rsync:  $(if ($Rsync) { $Rsync } else { 'MISSING' })"
Write-Host "Python: $(if ($Python) { $Python } else { 'optional, not required for local training' })"
Write-Host ""

if (!$Git) { Write-Host "Install Git for Windows before initializing snapshots." }
if (!$Ssh) { Write-Host "Install or enable OpenSSH Client in Windows Optional Features." }
if (!$Rsync) {
  Write-Host "Install cwRsync or provide Git Bash rsync, then set cwrsync_dir or update PATH."
  Write-Host "This script does not download software automatically."
}

Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Copy examples/project_config.example.json to project_config.json and edit paths."
Write-Host "2. Run scripts/setup_ssh_key.ps1 -ConfigPath project_config.json."
Write-Host "3. Run scripts/init_project_workflow.ps1 -ConfigPath project_config.json."
