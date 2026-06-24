# 路径
$DB_PATH = "$env:USERPROFILE\.codex\sqlite\codex-dev.db"
$BACKUP_DIR = "$env:USERPROFILE\.codex\sqlite\backup"
$SQLITE = "sqlite3.exe"

# 创建备份目录
if (!(Test-Path $BACKUP_DIR)) {
    New-Item -ItemType Directory -Path $BACKUP_DIR
}

# 备份数据库
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"
$BACKUP_FILE = Join-Path $BACKUP_DIR "codex-dev_$TIMESTAMP.db"
Copy-Item -Path $DB_PATH -Destination $BACKUP_FILE -Force
Write-Host "数据库已备份到： $BACKUP_FILE"

# 创建临时 SQL 文件
$TMP_SQL_FILE = Join-Path $env:TEMP "codex_enable_remote.sql"
@"
INSERT INTO local_app_server_feature_enablement(feature_name, enabled, updated_at)
VALUES('remote_control', 1, strftime('%s','now')*1000)
ON CONFLICT(feature_name) DO UPDATE
SET enabled=1, updated_at=strftime('%s','now')*1000;

SELECT feature_name, enabled, updated_at FROM local_app_server_feature_enablement WHERE feature_name='remote_control';
"@ | Set-Content -Path $TMP_SQL_FILE -Encoding UTF8

# 执行 SQL
& $SQLITE $DB_PATH ".read $TMP_SQL_FILE"

# 删除临时文件
Remove-Item $TMP_SQL_FILE -Force

Write-Host "remote_control feature enabled and verified."