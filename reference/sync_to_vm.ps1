$VM_USER = "YOUR_SERVER_USERNAME"
$VM_HOST = "YOUR_SERVER_IP"

$REMOTE_DIR = "/path/to/remote/project"

$LOCAL_DIR = "E:\your-project-name"

# cwRsync cygwin style path
$LOCAL_DIR_RSYNC = "/cygdrive/e/your-project-name"

$RSYNC = "D:\path\to\cwrsync\bin\rsync.exe"
$SSH   = "D:\path\to\cwrsync\bin\ssh.exe"

$REMOTE = "${VM_USER}@${VM_HOST}:${REMOTE_DIR}/"

$DEL_TIME = Get-Date -Format "yyyyMMdd-HHmmss"

Write-Host "Sync code to VM..."
Write-Host "Local:  $LOCAL_DIR"
Write-Host "Remote: $REMOTE"
Write-Host "Deleted files backup dir on remote: $BACKUP_DIR"

& $RSYNC -avz `
  --delete `
  -e "`"$SSH`"" `
  --exclude=".git/" `
  --exclude="__pycache__/" `
  --exclude="*.pyc" `
  --exclude=".venv/" `
  --exclude="venv/" `
  --exclude=".env" `
  --exclude="data/" `
  --exclude="datasets/" `
  --exclude="logs/" `
  --exclude="outputs/" `
  --exclude="runs/" `
  --exclude="checkpoints/" `
  --exclude="tmp/" `
  "$LOCAL_DIR_RSYNC/" `
  "$REMOTE"

Write-Host "Sync finished."
