param(
  [string]$ProjectDir = ".",
  [Parameter(Mandatory = $true)][string]$Message
)

$ErrorActionPreference = "Stop"
$ProjectDir = [System.IO.Path]::GetFullPath($ProjectDir)

if (!(Test-Path -LiteralPath $ProjectDir)) { throw "Project directory not found: $ProjectDir" }

Push-Location $ProjectDir
try {
  if (!(Test-Path -LiteralPath ".git")) {
    Write-Host "Initializing Git repository..."
    & git init
  }

  Write-Host "Checking for forbidden large/runtime files before staging..."
  $Forbidden = git status --short --untracked-files=all | Select-String -Pattern "(\s|/)(datasets|data|checkpoints|logs|outputs|runs|cache|tmp)/|\.npy$|\.npz$|\.pth$|\.pt$|\.ckpt$|\.onnx$|\.h5$|\.pkl$"
  if ($Forbidden) {
    Write-Host "Refusing to snapshot because forbidden runtime artifacts are present:"
    $Forbidden | ForEach-Object { Write-Host $_.Line }
    throw "Clean or ignore forbidden artifacts before committing."
  }

  & git add -A
  $Staged = git diff --cached --name-only
  if (!$Staged) {
    Write-Host "No staged changes; snapshot not created."
    exit 0
  }

  Write-Host "Creating Git snapshot: $Message"
  & git commit -m $Message
} finally {
  Pop-Location
}
