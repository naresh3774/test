param (
    [string]$DatabricksProfile = "dev-databricks",
    [string]$BackupRoot = "$(Join-Path $PWD ('Databricks-Full-Backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss')))"
)

# Create backup folder
New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
Write-Host "Backup root: $BackupRoot"

# Helper functions
function Export-WorkspaceSafe {
    param([string]$SourcePath, [string]$TargetPath)
    try {
        databricks workspace export-dir $SourcePath $TargetPath --profile $DatabricksProfile -o
    } catch {
        Write-Warning "Failed to export workspace path $SourcePath. Skipping. Error: $_"
    }
}

function Copy-DbfsSafe {
    param([string]$DbfsPath, [string]$LocalPath)
    try {
        # Check if DBFS path exists
        databricks fs ls $DbfsPath --profile $DatabricksProfile -o JSON | Out-Null
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
        $result = Invoke-Expression $Command
        $result | Out-File -FilePath $TargetFile -Encoding UTF8
    } catch {
        Write-Warning "Failed to export JSON for command '$Command'. Error: $_"
    }
}

# === BACKUP WORKSPACE ===
$WorkspaceBackup = Join-Path $BackupRoot "workspace"
New-Item -ItemType Directory -Force -Path $WorkspaceBackup | Out-Null
Write-Host "Exporting workspace..."
Export-WorkspaceSafe "/" $WorkspaceBackup

# === BACKUP DBFS ===
$DbfsBackup = Join-Path $BackupRoot "dbfs"
New-Item -ItemType Directory -Force -Path $DbfsBackup | Out-Null
Write-Host "Backing up DBFS /user..."
Copy-DbfsSafe "/user" (Join-Path $DbfsBackup "user")

# === BACKUP JOBS, CLUSTERS, POLICIES ===
$JobsBackup = Join-Path $BackupRoot "jobs.json"
Write-Host "Exporting jobs..."
Export-JsonSafe "databricks jobs list --profile $DatabricksProfile -o JSON" $JobsBackup

$ClustersBackup = Join-Path $BackupRoot "clusters.json"
Write-Host "Exporting clusters..."
Export-JsonSafe "databricks clusters list --profile $DatabricksProfile -o JSON" $ClustersBackup

$PoliciesBackup = Join-Path $BackupRoot "cluster-policies.json"
Write-Host "Exporting cluster policies..."
Export-JsonSafe "databricks cluster-policies list --profile $DatabricksProfile -o JSON" $PoliciesBackup

# === BACKUP SECRET SCOPES (names only, not values) ===
$SecretsBackup = Join-Path $BackupRoot "secrets.json"
Write-Host "Exporting secret scopes..."
Export-JsonSafe "databricks secrets list-scopes --profile $DatabricksProfile -o JSON" $SecretsBackup

# === BACKUP REPOS ===
$ReposBackup = Join-Path $BackupRoot "repos.json"
Write-Host "Exporting repos..."
Export-JsonSafe "databricks repos list --profile $DatabricksProfile -o JSON" $ReposBackup

# === COMPRESS INTO SINGLE FILE ===
$ZipFile = "$BackupRoot.zip"
Compress-Archive -Path $BackupRoot\* -DestinationPath $ZipFile
Write-Host "Backup completed: $ZipFile"