$VM_USER = "m24.YFMa"
$VM_HOST = "192.168.120.213"

$REMOTE_DIR = "/nfs10/data3/m24.YFMa/my-python-project"

$LOCAL_DIR = "E:\my-python-project"

# cwRsync cygwin style path
$LOCAL_DIR_RSYNC = "/cygdrive/e/my-python-project"

$RSYNC = "D:\cwrsync_6.4.8_x64_free\bin\rsync.exe"
$SSH   = "D:\cwrsync_6.4.8_x64_free\bin\ssh.exe"

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
