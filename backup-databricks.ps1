# ---------------------------
# Databricks Full Backup Script
# Works with: New CLI, Azure Gov, Windows
# ---------------------------

# ---------------------------
# 1. Set Profile
# ---------------------------
$env:DATABRICKS_CONFIG_PROFILE="dev-databricks"

# Timestamp for backup folder
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupRoot = "Databricks-Full-Backup-$timestamp"

Write-Host "Creating backup directory: $backupRoot"
New-Item -ItemType Directory -Path $backupRoot

# Subfolders for structured backup
$subfolders = @("workspace","jobs","clusters","repos","secrets","dbfs","pools","policies")
foreach ($f in $subfolders) {
    New-Item -ItemType Directory -Path "$backupRoot/$f" | Out-Null
}

# ---------------------------
# 2. Backup Workspace Notebooks
# ---------------------------
Write-Host "Backing up workspace notebooks..."
$workspaceBackupPath = "$backupRoot/workspace/workspace_backup.dbc"
databricks workspace export-dir / $workspaceBackupPath --format DBC

# ---------------------------
# 3. Backup Jobs
# ---------------------------
Write-Host "Backing up jobs..."
$jobsJson = databricks jobs list --output json
$jobsArray = $jobsJson | ConvertFrom-Json
foreach ($job in $jobsArray) {
    $jobId = $job.job_id
    databricks jobs get $jobId --output json | Out-File "$backupRoot/jobs/job-$jobId.json"
}

# ---------------------------
# 4. Backup Clusters
# ---------------------------
Write-Host "Backing up clusters..."
databricks clusters list --output json | Out-File "$backupRoot/clusters/clusters.json"

# ---------------------------
# 5. Backup Repos
# ---------------------------
Write-Host "Backing up repos..."
databricks repos list --output json | Out-File "$backupRoot/repos/repos.json"

# ---------------------------
# 6. Backup Secret Scopes & Secrets
# ---------------------------
Write-Host "Backing up secret scopes and secrets..."
$scopesJson = databricks secrets list-scopes --output json
$scopesArray = $scopesJson | ConvertFrom-Json

foreach ($scope in $scopesArray.scopes) {
    $scopeName = $scope.name
    databricks secrets list-secrets $scopeName --output json | Out-File "$backupRoot/secrets/$scopeName.json"
}

# ---------------------------
# 7. Backup DBFS
# ---------------------------
Write-Host "Backing up DBFS..."
databricks fs cp dbfs:/ "$backupRoot/dbfs" --recursive

# ---------------------------
# 8. Backup Instance Pools
# ---------------------------
Write-Host "Backing up instance pools..."
databricks instance-pools list --output json | Out-File "$backupRoot/pools/pools.json"

# ---------------------------
# 9. Backup Cluster Policies
# ---------------------------
Write-Host "Backing up cluster policies..."
databricks cluster-policies list --output json | Out-File "$backupRoot/policies/policies.json"

# ---------------------------
# 10. Backup Completed
# ---------------------------
Write-Host "Backup completed successfully!"
Write-Host "Backup location: $backupRoot"