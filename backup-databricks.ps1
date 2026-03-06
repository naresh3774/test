param (
    [string]$DatabricksProfile = "dev-databricks",
    [string]$BackupRoot = "$(Join-Path $PWD ('Databricks-Full-Backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss')))"
)

Write-Host "Databricks Ultimate Backup Starting"
Write-Host "Profile: $DatabricksProfile"
Write-Host "Backup root folder: $BackupRoot"

# Create backup folder
New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null

# === Helper Functions ===

function Export-WorkspaceDBC {
    param([string]$SourcePath, [string]$TargetPath)
    try {
        # Correct CLI command with hyphen
        databricks workspace export-dir $SourcePath $TargetPath --profile $DatabricksProfile
        Write-Host "Exported workspace path: $SourcePath"
    } catch {
        Write-Warning "Failed to export workspace path $SourcePath. Error: $_"
    }
}

function Copy-DbfsSafe {
    param([string]$DbfsPath, [string]$LocalPath)
    try {
        # Check if DBFS path exists
        $exists = databricks fs ls $DbfsPath --profile $DatabricksProfile -o JSON 2>$null
        if ($LASTEXITCODE -eq 0) {
            databricks fs cp -r $DbfsPath $LocalPath --profile $DatabricksProfile
            Write-Host "Copied DBFS path: $DbfsPath"
        } else {
            Write-Warning "DBFS path $DbfsPath does not exist. Skipping..."
        }
    } catch {
        Write-Warning "Failed to copy DBFS path $DbfsPath. Error: $_"
    }
}

function Export-JsonSafe {
    param([string]$Command, [string]$TargetFile)
    try {
        $result = Invoke-Expression $Command
        if ($result) {
            $result | Out-File -FilePath $TargetFile -Encoding UTF8
            Write-Host "Exported JSON: $TargetFile"
        } else {
            Write-Warning "No data returned for command: $Command"
        }
    } catch {
        Write-Warning "Failed to export JSON for command '$Command'. Error: $_"
    }
}

# === BACKUP WORKSPACE (as DBC) ===
$WorkspaceBackup = Join-Path $BackupRoot "workspace"
New-Item -ItemType Directory -Force -Path $WorkspaceBackup | Out-Null
Write-Host "Exporting workspace notebooks..."
Export-WorkspaceDBC "/" $WorkspaceBackup

# === BACKUP DBFS ===
$DbfsBackup = Join-Path $BackupRoot "dbfs"
New-Item -ItemType Directory -Force -Path $DbfsBackup | Out-Null

# Typical DBFS paths
$DbfsPaths = @("/user", "/FileStore", "/mnt")
foreach ($path in $DbfsPaths) {
    $localPath = Join-Path $DbfsBackup ($path.TrimStart("/"))
    Copy-DbfsSafe $path $localPath
}

# === BACKUP JOBS, CLUSTERS, POLICIES, INSTANCE POOLS, GLOBAL INIT SCRIPTS ===
Export-JsonSafe "databricks jobs list --profile $DatabricksProfile" (Join-Path $BackupRoot "jobs.json")
Export-JsonSafe "databricks clusters list --profile $DatabricksProfile" (Join-Path $BackupRoot "clusters.json")
Export-JsonSafe "databricks cluster-policies list --profile $DatabricksProfile" (Join-Path $BackupRoot "cluster-policies.json")
Export-JsonSafe "databricks instance-pools list --profile $DatabricksProfile" (Join-Path $BackupRoot "instance-pools.json")
Export-JsonSafe "databricks global-init-scripts list --profile $DatabricksProfile" (Join-Path $BackupRoot "global-init-scripts.json")

# === BACKUP SECRET SCOPES (names only) ===
Export-JsonSafe "databricks secrets list-scopes --profile $DatabricksProfile" (Join-Path $BackupRoot "secrets.json")

# === BACKUP REPOS ===
Export-JsonSafe "databricks repos list --profile $DatabricksProfile" (Join-Path $BackupRoot "repos.json")

# === BACKUP CLUSTER LIBRARIES ===
$ClustersJson = Join-Path $BackupRoot "clusters.json"
if (Test-Path $ClustersJson) {
    try {
        $clusters = Get-Content $ClustersJson | ConvertFrom-Json
        $LibBackup = Join-Path $BackupRoot "cluster-libraries"
        New-Item -ItemType Directory -Force -Path $LibBackup | Out-Null

        foreach ($c in $clusters) {
            $clusterId = $c.cluster_id
            $libsFile = Join-Path $LibBackup "$($clusterId)_libraries.json"
            Export-JsonSafe "databricks libraries list --cluster-id $clusterId --profile $DatabricksProfile" $libsFile
        }
    } catch {
        Write-Warning "Failed to backup cluster libraries: $_"
    }
}

# === COMPRESS EVERYTHING INTO SINGLE ZIP ===
$ZipFile = "$BackupRoot.zip"
Compress-Archive -Path $BackupRoot\* -DestinationPath $ZipFile -Force
Write-Host "`nUltimate Databricks backup complete!"
Write-Host "Backup ZIP location: $ZipFile"