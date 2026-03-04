# ============================================
# FULL CONFIGURATION BACKUP - Databricks
# Safe for Delete + Rebuild Scenario
# ============================================

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupRoot = "Databricks-FULL-Backup-$timestamp"

New-Item -ItemType Directory -Path $backupRoot | Out-Null
New-Item -ItemType Directory -Path "$backupRoot/jobs" | Out-Null
New-Item -ItemType Directory -Path "$backupRoot/clusters" | Out-Null
New-Item -ItemType Directory -Path "$backupRoot/policies" | Out-Null
New-Item -ItemType Directory -Path "$backupRoot/secrets" | Out-Null

# --------------------------------------------
# 1. Workspace (Complete)
# --------------------------------------------
Write-Host "Exporting workspace DBC..."
databricks workspace export / "$backupRoot/workspace-backup.dbc" --format DBC

# --------------------------------------------
# 2. Jobs (FULL JSON EXPORT)
# --------------------------------------------
Write-Host "Exporting all jobs..."
$jobsRaw = databricks jobs list
$jobIds = ($jobsRaw | Select-String -Pattern '^\d+' | ForEach-Object {
    ($_ -split '\s+')[0]
})

foreach ($jobId in $jobIds) {
    Write-Host "Exporting Job $jobId"
    databricks jobs get --job-id $jobId > "$backupRoot/jobs/job-$jobId.json"
}

# --------------------------------------------
# 3. Clusters (FULL JSON EXPORT)
# --------------------------------------------
Write-Host "Exporting clusters..."
$clustersRaw = databricks clusters list
$clusterIds = ($clustersRaw | Select-String -Pattern '^\d' | ForEach-Object {
    ($_ -split '\s+')[0]
})

foreach ($clusterId in $clusterIds) {
    Write-Host "Exporting Cluster $clusterId"
    databricks clusters get --cluster-id $clusterId > "$backupRoot/clusters/cluster-$clusterId.json"
}

# --------------------------------------------
# 4. Cluster Policies
# --------------------------------------------
Write-Host "Exporting cluster policies..."
databricks cluster-policies list > "$backupRoot/policies/policies-list.txt"

# --------------------------------------------
# 5. Secret Scopes (definitions only)
# --------------------------------------------
Write-Host "Exporting secret scopes..."
$scopes = databricks secrets list-scopes

$scopes | Out-File "$backupRoot/secrets/scopes-list.txt"

# --------------------------------------------
# 6. Instance Pools
# --------------------------------------------
Write-Host "Exporting instance pools..."
databricks instance-pools list > "$backupRoot/instance-pools.txt"

# --------------------------------------------
# 7. Global Init Scripts
# --------------------------------------------
Write-Host "Exporting global init scripts..."
databricks global-init-scripts list > "$backupRoot/global-init-scripts.txt"

Write-Host "=========================================="
Write-Host " FULL BACKUP COMPLETE"
Write-Host " Location: $backupRoot"
Write-Host "=========================================="