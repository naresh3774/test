<#
.SYNOPSIS
Ultimate Databricks Backup Script (PowerShell)
Supports: Workspace, DBFS /user, jobs, clusters, cluster libraries, cluster policies, secret scopes, instance pools, global init scripts
Compatible with Databricks CLI v0.291.0
#>

param (
    [string]$DatabricksProfile = "dev-databricks"
)

# -----------------------------
# Create backup folder
# -----------------------------
$BackupRoot = Join-Path $PWD ("Databricks-Enterprise-Backup-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
Write-Host "Backup root folder: $BackupRoot"

# -----------------------------
# Helper functions
# -----------------------------
function Export-WorkspaceDBC {
    param([string]$SourcePath, [string]$TargetPath)
    try {
        # Export as DBC to preserve notebooks in binary format
        databricks workspace export_dir $SourcePath $TargetPath --profile $DatabricksProfile
    } catch {
        Write-Warning "Failed to export workspace path $SourcePath. Skipping. Error: $_"
    }
}

function Copy-DbfsSafe {
    param([string]$DbfsPath, [string]$LocalPath)
    try {
        # Check if path exists
        $exists = databricks fs ls $DbfsPath --profile $DatabricksProfile 2>$null
        if ($LASTEXITCODE -eq 0) {
            databricks fs cp -r $DbfsPath $LocalPath --profile $DatabricksProfile
        } else {
            Write-Warning "DBFS path $DbfsPath does not exist. Skipping..."
        }
    } catch {
        Write-Warning "Failed to copy DBFS path $DbfsPath. Error: $_"
    }
}

function Export-JsonRaw {
    param([string]$Command, [string]$TargetFile)
    try {
        Invoke-Expression $Command > $TargetFile
    } catch {
        Write-Warning "Failed to export JSON for command '$Command'. Error: $_"
    }
}

# -----------------------------
# 1. Backup Workspace
# -----------------------------
$WorkspaceBackup = Join-Path $BackupRoot "workspace"
New-Item -ItemType Directory -Force -Path $WorkspaceBackup | Out-Null
Write-Host "Exporting workspace notebooks (DBC)..."
Export-WorkspaceDBC "/" $WorkspaceBackup

# -----------------------------
# 2. Backup DBFS /user
# -----------------------------
$DbfsBackup = Join-Path $BackupRoot "dbfs"
New-Item -ItemType Directory -Force -Path $DbfsBackup | Out-Null
Write-Host "Backing up DBFS /user..."
Copy-DbfsSafe "/user" (Join-Path $DbfsBackup "user")

# -----------------------------
# 3. Backup Jobs, Clusters, Cluster Policies, Secret Scopes, Instance Pools, Global Init Scripts
# -----------------------------
$JobsBackup = Join-Path $BackupRoot "jobs.json"
$ClustersBackup = Join-Path $BackupRoot "clusters.json"
$PoliciesBackup = Join-Path $BackupRoot "cluster-policies.json"
$SecretsBackup = Join-Path $BackupRoot "secrets.json"
$InstancePoolsBackup = Join-Path $BackupRoot "instance-pools.json"
$GlobalInitBackup = Join-Path $BackupRoot "global-init-scripts.json"

Write-Host "Exporting jobs..."
Export-JsonRaw "databricks jobs list --profile $DatabricksProfile" $JobsBackup

Write-Host "Exporting clusters..."
Export-JsonRaw "databricks clusters list --profile $DatabricksProfile" $ClustersBackup

Write-Host "Exporting cluster policies..."
Export-JsonRaw "databricks cluster-policies list --profile $DatabricksProfile" $PoliciesBackup

Write-Host "Exporting secret scopes..."
Export-JsonRaw "databricks secrets list-scopes --profile $DatabricksProfile" $SecretsBackup

Write-Host "Exporting instance pools..."
Export-JsonRaw "databricks instance-pools list --profile $DatabricksProfile" $InstancePoolsBackup

Write-Host "Exporting global init scripts..."
Export-JsonRaw "databricks global-init-scripts list --profile $DatabricksProfile" $GlobalInitBackup

# -----------------------------
# 4. Backup Cluster Libraries
# -----------------------------
$ClustersJson = Get-Content $ClustersBackup
$ClusterIds = Select-String -InputObject $ClustersJson -Pattern '"cluster_id":\s*"([^"]+)"' | ForEach-Object {
    $_.Matches[0].Groups[1].Value
}

foreach ($ClusterId in $ClusterIds) {
    $LibFile = Join-Path $BackupRoot ("cluster-" + $ClusterId + "-libraries.json")
    Write-Host "Exporting libraries for cluster $ClusterId..."
    Export-JsonRaw "databricks libraries list --cluster-id $ClusterId --profile $DatabricksProfile" $LibFile
}

# -----------------------------
# 5. Compress everything into a single ZIP
# -----------------------------
$ZipFile = "$BackupRoot.zip"
Write-Host "Compressing backup into $ZipFile ..."
Compress-Archive -Path (Join-Path $BackupRoot "*") -DestinationPath $ZipFile -Force

Write-Host "`nUltimate Databricks backup complete!"
Write-Host "Backup location: $ZipFile"