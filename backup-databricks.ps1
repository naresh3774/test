param(
    [string]$PROFILE_NAME = "dev-databricks"
)

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BACKUP_DIR = "Databricks-FULL-Backup-$timestamp"
Write-Host "`nCreating backup directory: $BACKUP_DIR"
New-Item -ItemType Directory -Force -Path $BACKUP_DIR | Out-Null

#---------------------------------------
# 1. Workspace Notebooks (DBC format)
#---------------------------------------
Write-Host "`nBacking up workspace notebooks..."
$workspaceBackup = Join-Path $BACKUP_DIR "workspace"
New-Item -ItemType Directory -Force -Path $workspaceBackup | Out-Null
databricks workspace export-dir "/" $workspaceBackup -p $PROFILE_NAME --format DBC --overwrite

#---------------------------------------
# 2. Jobs
#---------------------------------------
Write-Host "`nBacking up jobs..."
$jobs = databricks jobs list -p $PROFILE_NAME -o json
$jobs | Out-File (Join-Path $BACKUP_DIR "jobs.json")

#---------------------------------------
# 3. Clusters
#---------------------------------------
Write-Host "`nBacking up clusters..."
$clusters = databricks clusters list -p $PROFILE_NAME -o json
$clusters | Out-File (Join-Path $BACKUP_DIR "clusters.json")

#---------------------------------------
# 4. Repos
#---------------------------------------
Write-Host "`nBacking up repos..."
$repos = databricks repos list -p $PROFILE_NAME -o json
$repos | Out-File (Join-Path $BACKUP_DIR "repos.json")

#---------------------------------------
# 5. Cluster Policies
#---------------------------------------
Write-Host "`nBacking up cluster policies..."
$policies = databricks cluster-policies list -p $PROFILE_NAME -o json
$policies | Out-File (Join-Path $BACKUP_DIR "cluster-policies.json")

#---------------------------------------
# 6. Instance Pools
#---------------------------------------
Write-Host "`nBacking up instance pools..."
$pools = databricks instance-pools list -p $PROFILE_NAME -o json
$pools | Out-File (Join-Path $BACKUP_DIR "instance-pools.json")

#---------------------------------------
# 7. Global Init Scripts
#---------------------------------------
Write-Host "`nBacking up global init scripts..."
$initScripts = databricks global-init-scripts list -p $PROFILE_NAME -o json
$initScripts | Out-File (Join-Path $BACKUP_DIR "global-init-scripts.json")

#---------------------------------------
# 8. Secret Scopes & Keys
#---------------------------------------
Write-Host "`nBacking up secret scopes..."
$scopesJson = databricks secrets list-scopes -p $PROFILE_NAME -o json | ConvertFrom-Json
$secretsDir = Join-Path $BACKUP_DIR "secrets"
New-Item -ItemType Directory -Force -Path $secretsDir | Out-Null

foreach ($scope in $scopesJson.scopes) {
    $scopeName = $scope.name
    Write-Host "Backing up scope: $scopeName"
    $scopePath = Join-Path $secretsDir $scopeName
    New-Item -ItemType Directory -Force -Path $scopePath | Out-Null
    $keysJson = databricks secrets list-secrets $scopeName -p $PROFILE_NAME -o json
    $keysJson | Out-File (Join-Path $scopePath "secrets.json")
}

#---------------------------------------
# 9. DBFS Backup
#---------------------------------------
Write-Host "`nBacking up DBFS /user..."
$dbfsUser = Join-Path $BACKUP_DIR "dbfs\user"
New-Item -ItemType Directory -Force -Path $dbfsUser | Out-Null
try {
    databricks fs cp dbfs:/user $dbfsUser --recursive -p $PROFILE_NAME
} catch {
    Write-Host "DBFS /user path not accessible"
}

Write-Host "`nBacking up DBFS /FileStore..."
$dbfsFileStore = Join-Path $BACKUP_DIR "dbfs\FileStore"
New-Item -ItemType Directory -Force -Path $dbfsFileStore | Out-Null
try {
    databricks fs cp dbfs:/FileStore $dbfsFileStore --recursive -p $PROFILE_NAME
} catch {
    Write-Host "DBFS /FileStore path does not exist. Skipping."
}

#---------------------------------------
# 10. Mount Points metadata
#---------------------------------------
Write-Host "`nBacking up mount points metadata..."
$mounts = databricks fs mounts -p $PROFILE_NAME -o json
$mounts | Out-File (Join-Path $BACKUP_DIR "mounts.json")

Write-Host "`nFULL BACKUP COMPLETE"
Write-Host "Backup location: $BACKUP_DIR"