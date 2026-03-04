# ================================
# Stable Databricks Backup Script
# ================================

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupRoot = "Databricks-Backup-$timestamp"

New-Item -ItemType Directory -Path $backupRoot | Out-Null

# 1. Workspace (DBC Archive)
Write-Host "Backing up workspace as DBC..."
databricks workspace export / "$backupRoot/workspace-backup.dbc" --format DBC

# 2. Jobs
Write-Host "Backing up jobs..."
databricks jobs list > "$backupRoot/jobs.txt"

# 3. Clusters
Write-Host "Backing up clusters..."
databricks clusters list > "$backupRoot/clusters.txt"

# 4. Secret Scopes
Write-Host "Backing up secret scopes..."
databricks secrets list-scopes > "$backupRoot/secrets.txt"

# 5. Repo List
Write-Host "Backing up repos..."
databricks repos list > "$backupRoot/repos.txt"

Write-Host "===== Backup Completed ====="
Write-Host "Location: $backupRoot"