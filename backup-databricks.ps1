param (
    [string]$DbProfile = "dev-databricks"
)

# Generate timestamped backup root folder
$BackupRoot = Join-Path $PWD ("Databricks-Full-Backup-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null

# Subfolders
$WorkspaceBackup = Join-Path $BackupRoot "workspace"
$JobsBackup      = Join-Path $BackupRoot "jobs"
$ClustersBackup  = Join-Path $BackupRoot "clusters"
$PoliciesBackup  = Join-Path $BackupRoot "cluster-policies"
$SecretsBackup   = Join-Path $BackupRoot "secrets"
$ReposBackup     = Join-Path $BackupRoot "repos"
$DbfsBackup      = Join-Path $BackupRoot "dbfs"
$PoolsBackup     = Join-Path $BackupRoot "instance-pools"
$GlobalInitBackup= Join-Path $BackupRoot "global-init-scripts"

# Create subfolders
$folders = @($WorkspaceBackup, $JobsBackup, $ClustersBackup, $PoliciesBackup, $SecretsBackup, $ReposBackup, $DbfsBackup, $PoolsBackup, $GlobalInitBackup)
foreach ($f in $folders) { New-Item -ItemType Directory -Path $f -Force | Out-Null }

# -----------------------------
# Helper functions
# -----------------------------
function Safe-ExportWorkspace {
    param([string]$SourcePath, [string]$TargetPath)
    try {
        databricks workspace export-dir $SourcePath $TargetPath --profile $DbProfile
    } catch {
        Write-Warning "Failed to export workspace path '$SourcePath'. Skipping. Error: $_"
    }
}

function Safe-CopyDbfs {
    param([string]$DbfsPath, [string]$LocalPath)
    try {
        databricks fs cp -r $DbfsPath $LocalPath --profile $DbProfile
    } catch {
        Write-Warning "Failed to copy DBFS path '$DbfsPath'. Skipping. Error: $_"
    }
}

# -----------------------------
# Backup Workspace
# -----------------------------
Write-Host "Exporting workspace notebooks ..."
Safe-ExportWorkspace "/" $WorkspaceBackup

# -----------------------------
# Backup Jobs
# -----------------------------
Write-Host "Exporting jobs ..."
try {
    $jobs = databricks jobs list --profile $DbProfile | ConvertFrom-Json
    $jobs | ConvertTo-Json -Depth 10 | Out-File (Join-Path $JobsBackup "jobs.json") -Encoding UTF8
} catch {
    Write-Warning "Failed to backup jobs: $_"
}

# -----------------------------
# Backup Clusters
# -----------------------------
Write-Host "Exporting clusters ..."
try {
    $clusters = databricks clusters list --profile $DbProfile | ConvertFrom-Json
    $clusters | ConvertTo-Json -Depth 10 | Out-File (Join-Path $ClustersBackup "clusters.json") -Encoding UTF8
} catch {
    Write-Warning "Failed to backup clusters: $_"
}

# -----------------------------
# Backup Cluster Policies
# -----------------------------
Write-Host "Exporting cluster policies ..."
try {
    $policies = databricks cluster-policies list --profile $DbProfile | ConvertFrom-Json
    $policies | ConvertTo-Json -Depth 10 | Out-File (Join-Path $PoliciesBackup "cluster-policies.json") -Encoding UTF8
} catch {
    Write-Warning "Failed to backup cluster policies: $_"
}

# -----------------------------
# Backup Secret Scopes & Secrets
# -----------------------------
Write-Host "Exporting secret scopes and secrets ..."
try {
    $scopes = databricks secrets list-scopes --profile $DbProfile | ConvertFrom-Json
    foreach ($scope in $scopes) {
        $scopeName = $scope.name
        try {
            $secrets = databricks secrets list-secrets --scope $scopeName --profile $DbProfile | ConvertFrom-Json
            $secrets | ConvertTo-Json -Depth 10 | Out-File (Join-Path $SecretsBackup ("scope_" + $scopeName + ".json")) -Encoding UTF8
        } catch {
            Write-Warning "Error listing secrets for scope '$scopeName': $_"
        }
    }
} catch {
    Write-Warning "Failed to list secret scopes: $_"
}

# -----------------------------
# Backup Repos
# -----------------------------
Write-Host "Exporting repos ..."
try {
    $repos = databricks repos list --profile $DbProfile | ConvertFrom-Json
    $repos | ConvertTo-Json -Depth 10 | Out-File (Join-Path $ReposBackup "repos.json") -Encoding UTF8
} catch {
    Write-Warning "Failed to backup repos: $_"
}

# -----------------------------
# Backup DBFS
# -----------------------------
Write-Host "Copying DBFS user files ..."
Safe-CopyDbfs "/user" (Join-Path $DbfsBackup "user")

# -----------------------------
# Backup Instance Pools
# -----------------------------
Write-Host "Exporting instance pools ..."
try {
    $pools = databricks instance-pools list --profile $DbProfile | ConvertFrom-Json
    $pools | ConvertTo-Json -Depth 10 | Out-File (Join-Path $PoolsBackup "instance-pools.json") -Encoding UTF8
} catch {
    Write-Warning "Failed to backup instance pools: $_"
}

# -----------------------------
# Backup Global Init Scripts
# -----------------------------
Write-Host "Exporting global init scripts ..."
try {
    $scripts = databricks global-init-scripts list --profile $DbProfile | ConvertFrom-Json
    $scripts | ConvertTo-Json -Depth 10 | Out-File (Join-Path $GlobalInitBackup "global-init-scripts.json") -Encoding UTF8
} catch {
    Write-Warning "Failed to backup global init scripts: $_"
}

Write-Host "FULL BACKUP COMPLETE"
Write-Host "Backup location: $BackupRoot"