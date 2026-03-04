# ================================
# Databricks Backup Script (OLD CLI Compatible)
# Windows Safe
# ================================

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupRoot = "Databricks-Backup-$timestamp"

Write-Host "Creating backup folder: $backupRoot"
New-Item -ItemType Directory -Path $backupRoot | Out-Null

# --------------------------------
# 1. Backup Workspace
# --------------------------------
Write-Host "Backing up workspace..."
databricks workspace export_dir / "$backupRoot/workspace" --overwrite

# --------------------------------
# 2. Backup Jobs (Text Format)
# --------------------------------
Write-Host "Backing up jobs..."
New-Item -ItemType Directory -Path "$backupRoot/jobs" | Out-Null

databricks jobs list > "$backupRoot/jobs/jobs-list.txt"

# --------------------------------
# 3. Backup Clusters
# --------------------------------
Write-Host "Backing up clusters..."
databricks clusters list > "$backupRoot/clusters.txt"

# --------------------------------
# 4. Backup Secret Scopes (Metadata Only)
# --------------------------------
Write-Host "Backing up secret scopes..."
New-Item -ItemType Directory -Path "$backupRoot/secrets" | Out-Null

databricks secrets list-scopes > "$backupRoot/secrets/scopes.txt"

# --------------------------------
# 5. Backup DBFS
# --------------------------------
Write-Host "Backing up DBFS..."
databricks fs cp -r dbfs:/ "$backupRoot/dbfs"

# --------------------------------
# 6. Backup Repos List
# --------------------------------
Write-Host "Backing up repo list..."
databricks repos list > "$backupRoot/repos.txt"

Write-Host "================================="
Write-Host "Backup Completed"
Write-Host "Location: $backupRoot"
Write-Host "================================="