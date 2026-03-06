param (
    [string]$DatabricksProfile = "dev-databricks",
    [string]$BackupRoot = "$(Join-Path $PWD ('Databricks-Enterprise-Backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss')))"
)

Write-Host "Databricks Enterprise Backup Starting"
Write-Host "Profile: $DatabricksProfile"
Write-Host "Backup folder: $BackupRoot"

# Create backup folder
New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null

# --- Helper functions ---
function Export-WorkspaceSafe {
    param([string]$SourcePath, [string]$TargetPath)
    try {
        databricks workspace export-dir $SourcePath $TargetPath --profile $DatabricksProfile
    } catch {
        Write-Warning "Failed to export workspace path $SourcePath. Skipping. Error: $_"
    }
}

function Copy-DbfsSafe {
    param([string]$DbfsPath, [string]$LocalPath)
    try {
        $exists = databricks fs ls $DbfsPath --profile $DatabricksProfile | Out-Null
        if ($?) {
            databricks fs cp -r $DbfsPath $LocalPath --profile $DatabricksProfile
        } else {
            Write-Warning "DBFS path $DbfsPath does not exist, skipping..."
        }
    } catch {
        Write-Warning "Failed to copy DBFS path $DbfsPath. Error: $_"
    }
}

function Export-JsonSafe {
    param([string]$Command, [string]$TargetFile)
    try {
        Invoke-Expression $Command | Out-File -FilePath $TargetFile -Encoding UTF8
    } catch {
        Write-Warning "Failed to export JSON for command '$Command'. Error: $_"
    }
}

# === BACKUP WORKSPACE (.dbc) ===
$WorkspaceBackup = Join-Path $BackupRoot "workspace"
New-Item -ItemType Directory -Force -Path $WorkspaceBackup | Out-Null
Write-Host "Exporting workspace notebooks..."
Export-WorkspaceSafe "/" (Join-Path $WorkspaceBackup "all_notebooks.dbc")

# === BACKUP DBFS ===
$DbfsBackup = Join-Path $BackupRoot "dbfs"
New-Item -ItemType Directory -Force -Path $DbfsBackup | Out-Null
Write-Host "Backing up DBFS /user..."
Copy-DbfsSafe "/user" (Join-Path $DbfsBackup "user")
Write-Host "Backing up DBFS /FileStore..."
Copy-DbfsSafe "/FileStore" (Join-Path $DbfsBackup "FileStore")
Write-Host "Backing up DBFS /mnt..."
Copy-DbfsSafe "/mnt" (Join-Path $DbfsBackup "mnt")

# === BACKUP JOBS ===
$JobsBackup = Join-Path $BackupRoot "jobs_full.json"
Write-Host "Exporting jobs..."
Export-JsonSafe "databricks jobs list --profile $DatabricksProfile -o JSON" $JobsBackup

# === BACKUP CLUSTERS & LIBRARIES ===
$ClustersBackup = Join-Path $BackupRoot "clusters_full.json"
Write-Host "Exporting full cluster configurations..."
$ClustersSummary = databricks clusters list --profile $DatabricksProfile -o JSON | ConvertFrom-Json
$FullClusters = @()
foreach ($c in $ClustersSummary) {
    try {
        $full = databricks clusters get --cluster-id $c.cluster_id --profile $DatabricksProfile -o JSON
        $FullClusters += $full
    } catch {
        Write-Warning "Failed to get cluster $($c.cluster_id): $_"
    }
}
$FullClusters | Out-File -FilePath $ClustersBackup -Encoding UTF8

# === BACKUP CLUSTER POLICIES ===
$PoliciesBackup = Join-Path $BackupRoot "cluster-policies_full.json"
Write-Host "Exporting cluster policies..."
$PoliciesSummary = databricks cluster-policies list --profile $DatabricksProfile -o JSON | ConvertFrom-Json
$FullPolicies = @()
foreach ($p in $PoliciesSummary) {
    try {
        $full = databricks cluster-policies get --policy-id $p.policy_id --profile $DatabricksProfile -o JSON
        $FullPolicies += $full
    } catch {
        Write-Warning "Failed to get policy $($p.policy_id): $_"
    }
}
$FullPolicies | Out-File -FilePath $PoliciesBackup -Encoding UTF8

# === BACKUP SECRET SCOPES (names only) ===
$SecretsBackup = Join-Path $BackupRoot "secrets.json"
Write-Host "Exporting secret scopes..."
Export-JsonSafe "databricks secrets list-scopes --profile $DatabricksProfile -o JSON" $SecretsBackup

# === BACKUP USERS & GROUPS ===
$UsersBackup = Join-Path $BackupRoot "users_full.json"
Write-Host "Exporting users (SCIM API)..."
Export-JsonSafe "databricks scim users list --profile $DatabricksProfile -o JSON" $UsersBackup

$GroupsBackup = Join-Path $BackupRoot "groups_full.json"
Write-Host "Exporting groups (SCIM API)..."
Export-JsonSafe "databricks scim groups list --profile $DatabricksProfile -o JSON" $GroupsBackup

# === BACKUP INSTANCE POOLS ===
$PoolsBackup = Join-Path $BackupRoot "instance-pools_full.json"
Write-Host "Exporting instance pools..."
Export-JsonSafe "databricks instance-pools list --profile $DatabricksProfile -o JSON" $PoolsBackup

# === BACKUP GLOBAL INIT SCRIPTS ===
$InitScriptsBackup = Join-Path $BackupRoot "global-init-scripts.json"
Write-Host "Exporting global init scripts..."
Export-JsonSafe "databricks global-init-scripts list --profile $DatabricksProfile -o JSON" $InitScriptsBackup

# === COMPRESS EVERYTHING INTO A SINGLE ZIP ===
$ZipFile = "$BackupRoot.zip"
Compress-Archive -Path $BackupRoot\* -DestinationPath $ZipFile -Force
Write-Host "Ultimate Databricks backup complete!"
Write-Host "Backup location: $ZipFile"