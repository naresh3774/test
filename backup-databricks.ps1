# backup-databricks-full.ps1
# Full Databricks Workspace Backup Script
# Works with CLI v0.291.0 on Windows
# Replace <profile> with your Databricks CLI profile

param (
    [string]$Profile = "dev-databricks",
    [string]$BackupRoot = "$PWD\Databricks-Full-Backup-$(Get-Date -Format yyyyMMdd-HHmmss)"
)

# Create backup folder
Write-Host "Creating backup directory: $BackupRoot"
New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null

# =======================
# 1. Backup Workspace Notebooks
# =======================
Write-Host "`nBacking up workspace notebooks ..."
$workspaceItems = databricks workspace list / -p $Profile | ForEach-Object {
    $_.Trim()
} | Where-Object { $_ -ne "" }

foreach ($item in $workspaceItems) {
    # Skip non-notebook files like .bash_history
    if ($item -like "*.py" -or $item -like "*.scala" -or $item -like "*.sql" -or $item -like "*.dbc" -or $item -like "*.ipynb" -or $item -like "*.sh") {
        # Sanitize filename
        $SafePath = ($item -replace '[:<>|?*]', '_') -replace '\\', '_'
        $TargetPath = Join-Path $BackupRoot "workspace\$SafePath"
        $dir = Split-Path $TargetPath
        if (!(Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
        databricks workspace export $item $TargetPath -p $Profile -o
    } else {
        # Export directory recursively
        $SafeDir = ($item -replace '[:<>|?*]', '_') -replace '\\', '_'
        $TargetDir = Join-Path $BackupRoot "workspace\$SafeDir"
        New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
        databricks workspace export-dir $item $TargetDir -p $Profile
    }
}

# =======================
# 2. Backup Jobs
# =======================
Write-Host "`nBacking up jobs ..."
$jobs = databricks jobs list -p $Profile | ConvertFrom-Json
$jobs | ConvertTo-Json -Depth 10 | Out-File "$BackupRoot\jobs.json" -Force

# =======================
# 3. Backup Clusters
# =======================
Write-Host "`nBacking up clusters ..."
$clusters = databricks clusters list -p $Profile | ConvertFrom-Json
$clusters | ConvertTo-Json -Depth 10 | Out-File "$BackupRoot\clusters.json" -Force

# =======================
# 4. Backup Cluster Policies
# =======================
Write-Host "`nBacking up cluster policies ..."
$policies = databricks cluster-policies list -p $Profile | ConvertFrom-Json
$policies | ConvertTo-Json -Depth 10 | Out-File "$BackupRoot\cluster_policies.json" -Force

# =======================
# 5. Backup Instance Pools
# =======================
Write-Host "`nBacking up instance pools ..."
$pools = databricks instance-pools list -p $Profile | ConvertFrom-Json
$pools | ConvertTo-Json -Depth 10 | Out-File "$BackupRoot\instance_pools.json" -Force

# =======================
# 6. Backup Repos
# =======================
Write-Host "`nBacking up repos ..."
$repos = databricks repos list -p $Profile | ConvertFrom-Json
$repos | ConvertTo-Json -Depth 10 | Out-File "$BackupRoot\repos.json" -Force

# =======================
# 7. Backup Secret Scopes and Secrets
# =======================
Write-Host "`nBacking up secret scopes and secrets ..."
$scopes = databricks secrets list-scopes -p $Profile | ConvertFrom-Json
$BackupSecretsDir = Join-Path $BackupRoot "secrets"
New-Item -ItemType Directory -Force -Path $BackupSecretsDir | Out-Null

foreach ($scope in $scopes) {
    $scopeName = $scope.name
    $scopeSecrets = databricks secrets list-secrets -p $Profile --scope $scopeName | ConvertFrom-Json
    $scopeSecrets | ConvertTo-Json -Depth 10 | Out-File "$BackupSecretsDir\$scopeName.json" -Force
}

# =======================
# 8. Backup Global Init Scripts
# =======================
Write-Host "`nBacking up global init scripts ..."
$initScripts = databricks global-init-scripts list -p $Profile | ConvertFrom-Json
$initScripts | ConvertTo-Json -Depth 10 | Out-File "$BackupRoot\global_init_scripts.json" -Force

# =======================
# 9. Backup DBFS (user files only)
# =======================
Write-Host "`nBacking up DBFS user files ..."
$DBFSPath = "/user"
$DBFSTarget = Join-Path $BackupRoot "dbfs"
New-Item -ItemType Directory -Force -Path $DBFSTarget | Out-Null
try {
    databricks fs cp -r $DBFSPath $DBFSTarget -p $Profile
} catch {
    Write-Warning "Error copying DBFS path $DBFSPath. Skipping."
}

Write-Host "`nFULL BACKUP COMPLETE"
Write-Host "Backup location: $BackupRoot"