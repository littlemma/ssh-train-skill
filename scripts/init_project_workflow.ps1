param(
  [string]$ConfigPath = "$PSScriptRoot\..\project_config.json"
)

$ErrorActionPreference = "Stop"

function Read-Config([string]$Path) {
  if (!(Test-Path -LiteralPath $Path)) { throw "Config not found: $Path" }
  return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
}

function Backup-And-Copy([string]$Source, [string]$Destination) {
  if (Test-Path -LiteralPath $Destination) {
    $backup = "$Destination.bak.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Write-Host "Backing up existing file: $Destination -> $backup"
    Copy-Item -LiteralPath $Destination -Destination $backup -Force
  }
  Copy-Item -LiteralPath $Source -Destination $Destination -Force
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

$SkillRoot = Resolve-Path "$PSScriptRoot\.."
$TemplateDir = Join-Path $SkillRoot "templates"
$Config = Read-Config $ConfigPath
$ProjectDir = [System.IO.Path]::GetFullPath($Config.local_project_dir)

Write-Host "About to initialize local project workflow."
Write-Host "Project: $ProjectDir"
Write-Host "Remote:  $($Config.remote_user)@$($Config.remote_host):$($Config.remote_project_dir)"

New-Item -ItemType Directory -Force -Path $ProjectDir | Out-Null
foreach ($dir in @("src", "scripts", "configs", "tests", "tools", "docs", "notebooks", "reference-project")) {
  New-Item -ItemType Directory -Force -Path (Join-Path $ProjectDir $dir) | Out-Null
}

Backup-And-Copy $ConfigPath (Join-Path $ProjectDir "project_config.json")
foreach ($file in @("sync_to_vm.ps1", "remote_test.ps1", "remote_train.ps1", "remote_run.ps1", ".syncignore", ".gitignore", "README.project.md", "codex_project_instruction.md")) {
  $destName = if ($file -eq "README.project.md") { "README.md" } else { $file }
  Backup-And-Copy (Join-Path $TemplateDir $file) (Join-Path $ProjectDir $destName)
}

$Ssh = Resolve-Tool "ssh" $Config
$RemoteDirs = @("datasets", "checkpoints", "logs", "logs/train", "logs/test", "outputs", "cache", "tmp")
$RemoteMkdir = "mkdir -p '$($Config.remote_project_dir)' " + (($RemoteDirs | ForEach-Object { "'$($Config.remote_project_dir.TrimEnd('/'))/$_'" }) -join " ")
Write-Host "Creating remote runtime directories..."
& $Ssh "$($Config.remote_user)@$($Config.remote_host)" "bash -lc $(Convert-ToBashSingleQuoted $RemoteMkdir)"

Push-Location $ProjectDir
try {
  if (!(Test-Path -LiteralPath ".git")) {
    Write-Host "Initializing Git repository..."
    & git init
  } else {
    Write-Host "Git repository already exists."
  }
} finally {
  Pop-Location
}

Write-Host "Project workflow initialized."
