#==============================
# Enterprise Backup for Azure Databricks (Windows)
# Works with MCP-enabled workspaces
#==============================

param(
    [string]$PROFILE_NAME = "dev-databricks"
)

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BACKUP = "Databricks-Enterprise-Backup-$timestamp"

Write-Host "`nCreating backup directory $BACKUP..."
New-Item -ItemType Directory -Force -Path $BACKUP | Out-Null

#---------------------------------------
# Workspace Notebooks (DBC format)
#---------------------------------------
Write-Host "`nBacking up workspace notebooks..."
databricks workspace export-dir / "$BACKUP/workspace" `
    --format DBC `
    --overwrite `
    -p $PROFILE_NAME

#---------------------------------------
# Jobs
#---------------------------------------
Write-Host "`nBacking up jobs..."
databricks jobs list -p $PROFILE_NAME -o json | Out-File "$BACKUP/jobs.json"

#---------------------------------------
# Clusters
#---------------------------------------
Write-Host "`nBacking up clusters..."
databricks clusters list -p $PROFILE_NAME -o json | Out-File "$BACKUP/clusters.json"

#---------------------------------------
# Repos
#---------------------------------------
Write-Host "`nBacking up repos..."
databricks repos list -p $PROFILE_NAME -o json | Out-File "$BACKUP/repos.json"

#---------------------------------------
# Cluster Policies
#---------------------------------------
Write-Host "`nBacking up cluster policies..."
databricks cluster-policies list -p $PROFILE_NAME -o json | Out-File "$BACKUP/cluster-policies.json"

#---------------------------------------
# Instance Pools
#---------------------------------------
Write-Host "`nBacking up instance pools..."
databricks instance-pools list -p $PROFILE_NAME -o json | Out-File "$BACKUP/instance-pools.json"

#---------------------------------------
# Global Init Scripts
#---------------------------------------
Write-Host "`nBacking up global init scripts..."
databricks global-init-scripts list -p $PROFILE_NAME -o json | Out-File "$BACKUP/global-init-scripts.json"

#---------------------------------------
# Secret Scopes
#---------------------------------------
Write-Host "`nBacking up secret scopes..."
$scopes = databricks secrets list-scopes -p $PROFILE_NAME -o json | ConvertFrom-Json

if ($scopes.scopes) {
    foreach ($scope in $scopes.scopes) {
        $scopeName = $scope.name
        Write-Host "Exporting scope: $scopeName"
        $scopeDir="$BACKUP/secrets/$scopeName"
        New-Item -ItemType Directory -Force -Path $scopeDir | Out-Null
        databricks secrets list-secrets $scopeName -p $PROFILE_NAME -o json | Out-File "$scopeDir/secrets.json"
    }
} else {
    Write-Host "No secret scopes found."
}

#---------------------------------------
# DBFS Backup (User files)
#---------------------------------------
Write-Host "`nBacking up DBFS..."
New-Item -ItemType Directory -Force -Path "$BACKUP/dbfs" | Out-Null

try {
    databricks fs cp dbfs:/user "$BACKUP/dbfs/user" --recursive -p $PROFILE_NAME
} catch {
    Write-Host "DBFS /user not accessible."
}

try {
    databricks fs cp dbfs:/FileStore "$BACKUP/dbfs/FileStore" --recursive -p $PROFILE_NAME
} catch {
    Write-Host "DBFS /FileStore does not exist. Skipping."
}

#---------------------------------------
# Mount Points Metadata (Optional)
#---------------------------------------
Write-Host "`nBacking up mount points metadata..."
databricks fs mounts -p $PROFILE_NAME -o json | Out-File "$BACKUP/mounts.json"

#---------------------------------------
# Advanced: Unity Catalog / Metastore Backup
#---------------------------------------
Write-Host "`nBacking up Hive Metastore (Unity Catalog) metadata..."
# NOTE: Requires Databricks REST API token with UC permissions
# Export catalogs, schemas, and tables metadata
# Here, just placeholder JSON export
# You need to write REST API calls to fetch catalogs and schemas

#---------------------------------------
# Backup Complete
#---------------------------------------
Write-Host "`nBACKUP COMPLETE"
Write-Host "Backup location: $BACKUP"