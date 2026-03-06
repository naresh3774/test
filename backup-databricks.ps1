param (
    [string]$DatabricksProfile = "dev-databricks",
    [string]$BackupRoot = "$(Join-Path $PWD ('Databricks-Enterprise-Backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss')))"
)

# Create backup root folder
New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
Write-Host "Backup root: $BackupRoot"

# Helper function to export workspace
function Export-WorkspaceComplete {
    param([string]$SourcePath, [string]$LocalFolder)

    New-Item -ItemType Directory -Force -Path $LocalFolder | Out-Null

    try { databricks workspace export-dir $SourcePath $LocalFolder --profile $DatabricksProfile -o } catch { Write-Warning "Failed export folder $SourcePath. $_" }

    try {
        $items = databricks workspace list $SourcePath --profile $DatabricksProfile -o JSON | ConvertFrom-Json
        foreach ($item in $items) {
            if ($item.object_type -eq "NOTEBOOK") {
                $dbcFile = Join-Path $LocalFolder ($item.path.TrimStart('/') -replace '/', '_') + ".dbc"
                databricks workspace export $item.path $dbcFile --profile $DatabricksProfile --format DBC
            } elseif ($item.object_type -eq "DIRECTORY") {
                $subFolder = Join-Path $LocalFolder ($item.path.TrimStart('/') -replace '/', '_')
                Export-WorkspaceComplete $item.path $subFolder
            }
        }
    } catch { Write-Warning "Failed notebook export: $_" }
}

# Backup DBFS path
function Backup-Dbfs { param([string]$DbfsPath, [string]$LocalFolder)
    try { databricks fs cp -r $DbfsPath $LocalFolder --profile $DatabricksProfile } catch { Write-Warning "Skipping DBFS ${DbfsPath}: $_" }
}

# Export JSON config
function Export-Json { param([string]$Command, [string]$TargetFile)
    try { Invoke-Expression $Command | Out-File -FilePath $TargetFile -Encoding UTF8 } catch { Write-Warning "Failed JSON export '$Command': $_" }
}

# --- Workspace ---
$WorkspaceFolder = Join-Path $BackupRoot "workspace"
Export-WorkspaceComplete "/" $WorkspaceFolder

# --- DBFS ---
$DbfsFolder = Join-Path $BackupRoot "dbfs"
Backup-Dbfs "/user" (Join-Path $DbfsFolder "user")
Backup-Dbfs "/FileStore" (Join-Path $DbfsFolder "FileStore")

# --- Jobs, Clusters, Policies, Pools, Init Scripts ---
Export-Json "databricks jobs list --profile $DatabricksProfile -o JSON" (Join-Path $BackupRoot "jobs.json")
$ClustersJson = Join-Path $BackupRoot "clusters.json"
Export-Json "databricks clusters list --profile $DatabricksProfile -o JSON" $ClustersJson
Export-Json "databricks cluster-policies list --profile $DatabricksProfile -o JSON" (Join-Path $BackupRoot "cluster-policies.json")
Export-Json "databricks instance-pools list --profile $DatabricksProfile -o JSON" (Join-Path $BackupRoot "instance-pools.json")
Export-Json "databricks global-init-scripts list --profile $DatabricksProfile -o JSON" (Join-Path $BackupRoot "global-init-scripts.json")

# --- Cluster Libraries ---
$LibrariesBackup = Join-Path $BackupRoot "cluster-libraries"
New-Item -ItemType Directory -Force -Path $LibrariesBackup | Out-Null
$clusters = (Get-Content $ClustersJson | ConvertFrom-Json)
foreach ($cluster in $clusters) {
    try {
        $libFile = Join-Path $LibrariesBackup ($cluster.cluster_id + ".json")
        Export-Json "databricks libraries list --cluster-id $($cluster.cluster_id) --profile $DatabricksProfile -o JSON" $libFile
    } catch { Write-Warning "Failed libraries for cluster $($cluster.cluster_id)" }
}

# --- Secret Scopes ---
Export-Json "databricks secrets list-scopes --profile $DatabricksProfile -o JSON" (Join-Path $BackupRoot "secret-scopes.json")

# --- Users and Groups (requires admin token) ---
Export-Json "databricks scim list-users --profile $DatabricksProfile -o JSON" (Join-Path $BackupRoot "users.json")
Export-Json "databricks scim list-groups --profile $DatabricksProfile -o JSON" (Join-Path $BackupRoot "groups.json")

# --- Repos ---
Export-Json "databricks repos list --profile $DatabricksProfile -o JSON" (Join-Path $BackupRoot "repos.json")

# --- Compress ---
$ZipFile = "$BackupRoot.zip"
Compress-Archive -Path $BackupRoot\* -DestinationPath $ZipFile
Write-Host "Ultimate backup complete: $ZipFile"