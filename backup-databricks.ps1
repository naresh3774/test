param (
    [string]$DatabricksProfile = "dev-databricks"
)

# Create timestamped backup folder
$BackupRoot = Join-Path $PWD ("Databricks-Full-Backup-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
Write-Host "Creating backup directory: $BackupRoot"
New-Item -Path $BackupRoot -ItemType Directory -Force | Out-Null

# Function to export workspace safely
function Export-WorkspaceSafe {
    param([string]$SourcePath, [string]$TargetPath)
    try {
        Write-Host "Exporting workspace path: $SourcePath"
        databricks workspace export-dir $SourcePath $TargetPath --profile $DatabricksProfile -o
    } catch {
        Write-Warning "Failed to export workspace path $SourcePath. Skipping. Error: $_"
    }
}

# Function to copy DBFS safely
function Copy-DbfsSafe {
    param([string]$DbfsPath, [string]$LocalPath)
    try {
        # Check if DBFS path exists
        $null = databricks fs ls $DbfsPath --profile $DatabricksProfile --output JSON 2>$null
        if ($?) {
            Write-Host "Copying DBFS path: $DbfsPath -> $LocalPath"
            databricks fs cp -r $DbfsPath $LocalPath --profile $DatabricksProfile
        } else {
            Write-Warning "DBFS path $DbfsPath does not exist, skipping..."
        }
    } catch {
        Write-Warning "Failed to copy DBFS path $DbfsPath. Error: $_"
    }
}

# -------------------
# Backup Workspace
# -------------------
$WorkspaceBackup = Join-Path $BackupRoot "workspace"
New-Item -Path $WorkspaceBackup -ItemType Directory -Force | Out-Null
Export-WorkspaceSafe "/" $WorkspaceBackup

# -------------------
# Backup Jobs
# -------------------
$JobsBackup = Join-Path $BackupRoot "jobs.json"
try {
    databricks jobs list --profile $DatabricksProfile --output JSON | Out-File $JobsBackup
} catch {
    Write-Warning "Failed to export jobs: $_"
}

# -------------------
# Backup Clusters
# -------------------
$ClustersBackup = Join-Path $BackupRoot "clusters.json"
try {
    databricks clusters list --profile $DatabricksProfile --output JSON | Out-File $ClustersBackup
} catch {
    Write-Warning "Failed to export clusters: $_"
}

# -------------------
# Backup Cluster Policies
# -------------------
$PoliciesBackup = Join-Path $BackupRoot "cluster-policies.json"
try {
    databricks cluster-policies list --profile $DatabricksProfile --output JSON | Out-File $PoliciesBackup
} catch {
    Write-Warning "Failed to export cluster policies: $_"
}

# -------------------
# Backup Secret Scopes and Secrets
# -------------------
$SecretsBackupRoot = Join-Path $BackupRoot "secrets"
New-Item -Path $SecretsBackupRoot -ItemType Directory -Force | Out-Null

try {
    $Scopes = databricks secrets list-scopes --profile $DatabricksProfile --output JSON | ConvertFrom-Json
    foreach ($scope in $Scopes) {
        $scopeName = $scope.name
        Write-Host "Exporting secrets from scope: $scopeName"
        try {
            $Secrets = databricks secrets list-secrets --scope $scopeName --profile $DatabricksProfile --output JSON | ConvertFrom-Json
            $Secrets | Out-File (Join-Path $SecretsBackupRoot "${scopeName}-secrets.json")
        } catch {
            Write-Warning "Failed to list secrets for scope ${scopeName}: $_"
        }
    }
} catch {
    Write-Warning "Failed to list secret scopes: $_"
}

# -------------------
# Backup DBFS
# -------------------
$DbfsBackup = Join-Path $BackupRoot "dbfs"
New-Item -Path $DbfsBackup -ItemType Directory -Force | Out-Null
Copy-DbfsSafe "/user" (Join-Path $DbfsBackup "user")

# -------------------
# Backup Repos
# -------------------
$ReposBackup = Join-Path $BackupRoot "repos.json"
try {
    databricks repos list --profile $DatabricksProfile --output JSON | Out-File $ReposBackup
} catch {
    Write-Warning "Failed to export repos: $_"
}

# -------------------
# Backup Instance Pools
# -------------------
$PoolsBackup = Join-Path $BackupRoot "instance-pools.json"
try {
    databricks instance-pools list --profile $DatabricksProfile --output JSON | Out-File $PoolsBackup
} catch {
    Write-Warning "Failed to export instance pools: $_"
}

# -------------------
# Backup Global Init Scripts
# -------------------
$InitScriptsBackup = Join-Path $BackupRoot "global-init-scripts"
New-Item -Path $InitScriptsBackup -ItemType Directory -Force | Out-Null
try {
    $Scripts = databricks global-init-scripts list --profile $DatabricksProfile --output JSON | ConvertFrom-Json
    foreach ($script in $Scripts) {
        $scriptName = $script.name
        databricks global-init-scripts get --script-id $script.id --profile $DatabricksProfile --output-file (Join-Path $InitScriptsBackup "${scriptName}.json")
    }
} catch {
    Write-Warning "Failed to backup global init scripts: $_"
}

Write-Host "`nFULL BACKUP COMPLETED"
Write-Host "Backup location: $BackupRoot"