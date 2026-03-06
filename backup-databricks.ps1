<#
.SYNOPSIS
Ultimate Databricks Backup Script
- Exports workspace notebooks as DBC
- Exports Jobs, Clusters, Cluster Policies, Instance Pools, Repos as JSON
- Exports Secret Scopes (names only)
- Copies DBFS user and FileStore folders
- Exports Cluster Libraries per cluster
- Compresses all backups into a single ZIP
#>

param (
    [string]$DatabricksProfile = "dev-databricks",
    [string]$BackupRoot = "$(Join-Path $PWD ('Databricks-Enterprise-Backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss')))"
)

# Create backup folder
New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
Write-Host "Databricks Enterprise Backup Starting"
Write-Host "Profile: $DatabricksProfile"
Write-Host "Backup folder: $BackupRoot"

# === Helper Functions ===
function Run-SafeCommand {
    param([string]$Command, [string]$OutputFile)
    try {
        $Result = Invoke-Expression $Command
        $Result | Out-File -FilePath $OutputFile -Encoding UTF8
    } catch {
        Write-Warning "Failed to run command: $Command. Error: $_"
    }
}

function Export-WorkspaceSafe {
    param([string]$SourcePath, [string]$TargetFile)
    try {
        databricks workspace export_dir $SourcePath $TargetFile --profile $DatabricksProfile --format DBC
    } catch {
        Write-Warning "Failed workspace export $SourcePath. Skipping. Error: $_"
    }
}

function Copy-DbfsSafe {
    param([string]$DbfsPath, [string]$LocalPath)
    try {
        databricks fs ls $DbfsPath --profile $DatabricksProfile | Out-Null
        if ($?) {
            databricks fs cp -r $DbfsPath $LocalPath --profile $DatabricksProfile
        } else {
            Write-Warning "DBFS path $DbfsPath does not exist, skipping..."
        }
    } catch {
        Write-Warning "Failed DBFS copy $DbfsPath. Error: $_"
    }
}

# === BACKUP WORKSPACE ===
$WorkspaceBackup = Join-Path $BackupRoot "workspace.dbc"
Write-Host "Exporting workspace as DBC ..."
Export-WorkspaceSafe "/" $WorkspaceBackup

# === BACKUP DBFS ===
$DbfsBackup = Join-Path $BackupRoot "dbfs"
New-Item -ItemType Directory -Force -Path $DbfsBackup | Out-Null
Write-Host "Backing up DBFS /user ..."
Copy-DbfsSafe "/user" (Join-Path $DbfsBackup "user")
Write-Host "Backing up DBFS /FileStore ..."
Copy-DbfsSafe "/FileStore" (Join-Path $DbfsBackup "FileStore")

# === BACKUP JOBS, CLUSTERS, CLUSTER POLICIES, INSTANCE POOLS ===
Write-Host "Exporting jobs ..."
$JobsBackup = Join-Path $BackupRoot "jobs.json"
Run-SafeCommand "databricks jobs list --profile $DatabricksProfile" $JobsBackup

Write-Host "Exporting clusters ..."
$ClustersBackup = Join-Path $BackupRoot "clusters.json"
Run-SafeCommand "databricks clusters list --profile $DatabricksProfile" $ClustersBackup

Write-Host "Exporting cluster policies ..."
$PoliciesBackup = Join-Path $BackupRoot "cluster-policies.json"
Run-SafeCommand "databricks cluster-policies list --profile $DatabricksProfile" $PoliciesBackup

Write-Host "Exporting instance pools ..."
$PoolsBackup = Join-Path $BackupRoot "instance-pools.json"
Run-SafeCommand "databricks instance-pools list --profile $DatabricksProfile" $PoolsBackup

# === BACKUP SECRET SCOPES (names only) ===
Write-Host "Exporting secret scopes ..."
$SecretsBackup = Join-Path $BackupRoot "secrets.json"
Run-SafeCommand "databricks secrets list-scopes --profile $DatabricksProfile" $SecretsBackup

# === BACKUP REPOS ===
Write-Host "Exporting repos ..."
$ReposBackup = Join-Path $BackupRoot "repos.json"
Run-SafeCommand "databricks repos list --profile $DatabricksProfile" $ReposBackup

# === BACKUP CLUSTER LIBRARIES ===
$ClustersJson = Join-Path $BackupRoot "clusters.json"
# Save raw output without parsing
databricks clusters list --profile $DatabricksProfile > $ClustersJson

# Extract cluster IDs manually without ConvertFrom-Json
$ClusterIds = databricks clusters list --profile $DatabricksProfile | ForEach-Object {
    if ($_ -match '"cluster_id":\s*"([^"]+)"') { $Matches[1] }
}

foreach ($ClusterId in $ClusterIds) {
    $LibFile = Join-Path $BackupRoot ("cluster-" + $ClusterId + "-libraries.json")
    Write-Host "Exporting libraries for cluster $ClusterId ..."
    databricks libraries list --cluster-id $ClusterId --profile $DatabricksProfile > $LibFile
}

# === COMPRESS BACKUP INTO SINGLE ZIP ===
$ZipFile = "$BackupRoot.zip"
Write-Host "Compressing backup ..."
Compress-Archive -Path "$BackupRoot\*" -DestinationPath $ZipFile -Force

Write-Host "`nUltimate Databricks backup complete!"
Write-Host "Backup ZIP: $ZipFile"