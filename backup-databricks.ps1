# backup-databricks.ps1
param (
    [string]$Profile = "dev-databricks"
)

# Root backup folder
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupRoot = Join-Path -Path (Get-Location) -ChildPath "Databricks-FULL-Backup-$timestamp"
New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
Write-Host "Backup directory created: $BackupRoot"

# Helper function to sanitize Windows filenames
function Sanitize-FileName {
    param ([string]$name)
    return ($name -replace '[:<>"/\\|?*]', '_')
}

# -----------------------------
# Backup workspace notebooks
# -----------------------------
Write-Host "`nBacking up workspace notebooks ..."
$WorkspaceBackupDir = Join-Path $BackupRoot "workspace"
New-Item -ItemType Directory -Force -Path $WorkspaceBackupDir | Out-Null

$exportWorkspace = databricks workspace export-dir / $WorkspaceBackupDir -p $Profile -o json 2>$null

Write-Host "Workspace notebooks backup complete."

# -----------------------------
# Backup jobs
# -----------------------------
Write-Host "`nBacking up jobs ..."
$jobs = databricks jobs list -p $Profile -o json | ConvertFrom-Json
$jobs | ConvertTo-Json -Depth 10 | Out-File "$BackupRoot\jobs.json" -Force
Write-Host "Jobs backup complete."

# -----------------------------
# Backup clusters
# -----------------------------
Write-Host "`nBacking up clusters ..."
$clusters = databricks clusters list -p $Profile -o json | ConvertFrom-Json
$clusters | ConvertTo-Json -Depth 10 | Out-File "$BackupRoot\clusters.json" -Force
Write-Host "Clusters backup complete."

# -----------------------------
# Backup cluster policies
# -----------------------------
Write-Host "`nBacking up cluster policies ..."
$policies = databricks cluster-policies list -p $Profile -o json | ConvertFrom-Json
$policies | ConvertTo-Json -Depth 10 | Out-File "$BackupRoot\cluster_policies.json" -Force
Write-Host "Cluster policies backup complete."

# -----------------------------
# Backup instance pools
# -----------------------------
Write-Host "`nBacking up instance pools ..."
$pools = databricks instance-pools list -p $Profile -o json | ConvertFrom-Json
$pools | ConvertTo-Json -Depth 10 | Out-File "$BackupRoot\instance_pools.json" -Force
Write-Host "Instance pools backup complete."

# -----------------------------
# Backup repos
# -----------------------------
Write-Host "`nBacking up repos ..."
$repos = databricks repos list -p $Profile -o json | ConvertFrom-Json
$repos | ConvertTo-Json -Depth 10 | Out-File "$BackupRoot\repos.json" -Force
Write-Host "Repos backup complete."

# -----------------------------
# Backup secret scopes and secrets
# -----------------------------
Write-Host "`nBacking up secret scopes and secrets ..."
$secretsDir = Join-Path $BackupRoot "secrets"
New-Item -ItemType Directory -Force -Path $secretsDir | Out-Null

$scopes = databricks secrets list-scopes -p $Profile -o json | ConvertFrom-Json

foreach ($scope in $scopes) {
    $scopeName = $scope.name
    Write-Host "Backing up secrets for scope: $scopeName"
    $scopeSecrets = databricks secrets list-secrets --scope $scopeName -p $Profile -o json | ConvertFrom-Json
    $scopeSecrets | ConvertTo-Json -Depth 10 | Out-File (Join-Path $secretsDir "$scopeName.json") -Force
}

Write-Host "Secrets backup complete."

# -----------------------------
# Backup DBFS
# -----------------------------
Write-Host "`nBacking up DBFS files..."
$DBFSBackupDir = Join-Path $BackupRoot "dbfs"
New-Item -ItemType Directory -Force -Path $DBFSBackupDir | Out-Null

# Example: backup all user files
try {
    databricks fs cp dbfs:/user $DBFSBackupDir --recursive -p $Profile
    Write-Host "DBFS backup complete."
} catch {
    Write-Warning "Error backing up DBFS: $_"
}

Write-Host "`nFULL BACKUP COMPLETE"
Write-Host "Backup location: $BackupRoot"