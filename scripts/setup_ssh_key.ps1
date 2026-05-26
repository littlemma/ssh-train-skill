param(
  [string]$ConfigPath = "$PSScriptRoot\..\project_config.json",
  [string]$RemoteHost,
  [string]$RemoteUser,
  [string]$KeyPath = "$HOME\.ssh\id_ed25519"
)

$ErrorActionPreference = "Stop"

function Read-Config([string]$Path) {
  if (!(Test-Path -LiteralPath $Path)) { throw "Config not found: $Path" }
  return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
}

function First-Value($A, $B, $Default) {
  if ($A) { return $A }
  if ($B) { return $B }
  return $Default
}

$Config = Read-Config $ConfigPath

$SshDir = Split-Path -Parent $KeyPath
$PubKey = "$KeyPath.pub"

Write-Host "About to configure passwordless SSH for $RemoteUser@$RemoteHost"
Write-Host "Password may be requested by ssh during first setup. It will not be saved."

if (!(Test-Path -LiteralPath $SshDir)) {
  New-Item -ItemType Directory -Force -Path $SshDir | Out-Null
}

if (!(Test-Path -LiteralPath $KeyPath)) {
  Write-Host "Generating SSH key: $KeyPath"
  & ssh-keygen -t ed25519 -f $KeyPath -N ""
} else {
  Write-Host "SSH key already exists, not overwriting: $KeyPath"
}

if (!(Test-Path -LiteralPath $PubKey)) { throw "Public key missing: $PubKey" }

$PublicKeyText = Get-Content -Raw -LiteralPath $PubKey
$PublicKeyText = $PublicKeyText.Trim()
$RemoteCommand = "umask 077; mkdir -p ~/.ssh; chmod 700 ~/.ssh; touch ~/.ssh/authorized_keys; grep -qxF '$PublicKeyText' ~/.ssh/authorized_keys || printf '%s\n' '$PublicKeyText' >> ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys"

Write-Host "Appending public key to remote authorized_keys if absent..."
& ssh "$RemoteUser@$RemoteHost" $RemoteCommand

Write-Host "Testing passwordless SSH..."
& ssh -o BatchMode=yes "$RemoteUser@$RemoteHost" "hostname"
Write-Host "SSH key setup complete."
