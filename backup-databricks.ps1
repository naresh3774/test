# ================================
# Azure Databricks Full Backup Script
# Azure Government Compatible
# ================================

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupRoot = "Databricks-Backup-$timestamp"

Write-Host "Creating backup folder: $backupRoot"
New-Item -ItemType Directory -Path $backupRoot | Out-Null

# --------------------------------
# 1. Backup Workspace (Notebooks)
# --------------------------------
Write-Host "Backing up workspace..."
databricks workspace export_dir / "$backupRoot/workspace" --overwrite

# --------------------------------
# 2. Backup Jobs
# --------------------------------
Write-Host "Backing up jobs..."
New-Item -ItemType Directory -Path "$backupRoot/jobs" | Out-Null

$jobs = databricks jobs list --output JSON | ConvertFrom-Json

foreach ($job in $jobs.jobs) {
    $jobId = $job.job_id
    Write-Host "Exporting Job ID: $jobId"
    databricks jobs get --job-id $jobId > "$backupRoot/jobs/job-$jobId.json"
}

# --------------------------------
# 3. Backup Clusters
# --------------------------------
Write-Host "Backing up clusters..."
databricks clusters list --output JSON > "$backupRoot/clusters.json"

# --------------------------------
# 4. Backup Secret Scopes (Metadata Only)
# --------------------------------
Write-Host "Backing up secret scopes..."
New-Item -ItemType Directory -Path "$backupRoot/secrets" | Out-Null

$scopes = databricks secrets list-scopes | ConvertFrom-Json

foreach ($scope in $scopes.scopes) {
    $scopeName = $scope.name
    Write-Host "Exporting Secret Scope: $scopeName"
    databricks secrets list --scope $scopeName > "$backupRoot/secrets/$scopeName.json"
}

# --------------------------------
# 5. Backup DBFS
# --------------------------------
Write-Host "Backing up DBFS..."
databricks fs cp -r dbfs:/ "$backupRoot/dbfs"

# --------------------------------
# 6. Backup Repos List
# --------------------------------
Write-Host "Backing up repo list..."
databricks repos list --output JSON > "$backupRoot/repos.json"

Write-Host "================================="
Write-Host "Backup Completed Successfully!"
Write-Host "Location: $backupRoot"
Write-Host "================================="