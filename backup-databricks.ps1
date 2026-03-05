param (
    [string]$DbProfile = "dev-databricks",
    [string]$BackupRoot = "$(Join-Path $PWD ('Databricks-Full-Backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss')))"
)

# Create backup directory
Write-Host "Creating backup directory: $BackupRoot"
New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null

# =============================
# Helper functions
# =============================

function Export-WorkspaceSafe {
    param([string]$SourcePath, [string]$TargetPath)
    try {
        Write-Host "Exporting workspace: $SourcePath -> $TargetPath"
        databricks workspace export-dir $SourcePath $TargetPath --profile $DbProfile
    } catch {
        Write-Warning "Failed to export $SourcePath. Skipping. Error: $_"
    }
}

function Copy-DbfsSafe {
    param ([string]$DbfsPath, [string]$LocalPath)
    try {
        Write-Host "Copying DBFS path: $DbfsPath -> $LocalPath"
        databricks fs cp -r $DbfsPath $LocalPath --profile $DbProfile
    } catch {
        Write-Warning "Failed to copy DBFS path $DbfsPath. Skipping. Error: $_"
    }
}

# =============================
# Backup Workspace Notebooks
# =============================
$WorkspaceBackup = Join-Path $BackupRoot "workspace"
New-Item -ItemType Directory -Path $WorkspaceBackup -Force | Out-Null
Export-WorkspaceSafe "/" $WorkspaceBackup

# =============================
# Backup Jobs
# =============================
$JobsBackup = Join-Path $BackupRoot "jobs"
New-Item -ItemType Directory -Path $JobsBackup -Force | Out-Null
try {
    $jobs = databricks jobs list --profile $DbProfile --output JSON | ConvertFrom-Json
    foreach ($job in $jobs) {
        $JobFile = Join-Path $JobsBackup ("job_" + $job.job_id + ".json")
        $job | ConvertTo-Json -Depth 10 | Out-File $JobFile -Force
    }
} catch {
    Write-Warning "Failed to backup jobs: $_"
}

# =============================
# Backup Clusters
# =============================
$ClustersBackup = Join-Path $BackupRoot "clusters"
New-Item -ItemType Directory -Path $ClustersBackup -Force | Out-Null
try {
    $clusters = databricks clusters list --profile $DbProfile --output JSON | ConvertFrom-Json
    foreach ($cluster in $clusters) {
        $ClusterFile = Join-Path $ClustersBackup ("cluster_" + $cluster.cluster_id + ".json")
        $cluster | ConvertTo-Json -Depth 10 | Out-File $ClusterFile -Force
    }
} catch {
    Write-Warning "Failed to backup clusters: $_"
}

# =============================
# Backup Cluster Policies
# =============================
$PoliciesBackup = Join-Path $BackupRoot "cluster-policies"
New-Item -ItemType Directory -Path $PoliciesBackup -Force | Out-Null
try {
    $policies = databricks cluster-policies list --profile $DbProfile --output JSON | ConvertFrom-Json
    foreach ($policy in $policies) {
        $PolicyFile = Join-Path $PoliciesBackup ("policy_" + $policy.policy_id + ".json")
        $policy | ConvertTo-Json -Depth 10 | Out-File $PolicyFile -Force
    }
} catch {
    Write-Warning "Failed to backup cluster policies: $_"
}

# =============================
# Backup Instance Pools
# =============================
$PoolsBackup = Join-Path $BackupRoot "instance-pools"
New-Item -ItemType Directory -Path $PoolsBackup -Force | Out-Null
try {
    $pools = databricks instance-pools list --profile $DbProfile --output JSON | ConvertFrom-Json
    foreach ($pool in $pools) {
        $PoolFile = Join-Path $PoolsBackup ("pool_" + $pool.instance_pool_id + ".json")
        $pool | ConvertTo-Json -Depth 10 | Out-File $PoolFile -Force
    }
} catch {
    Write-Warning "Failed to backup instance pools: $_"
}

# =============================
# Backup Secret Scopes and Secrets
# =============================
$SecretsBackup = Join-Path $BackupRoot "secrets"
New-Item -ItemType Directory -Path $SecretsBackup -Force | Out-Null
try {
    $scopes = databricks secrets list-scopes --profile $DbProfile --output JSON | ConvertFrom-Json
    foreach ($scope in $scopes) {
        $ScopeName = $scope.name
        $SecretsScopeBackup = Join-Path $SecretsBackup $ScopeName
        New-Item -ItemType Directory -Path $SecretsScopeBackup -Force | Out-Null
        try {
            $secrets = databricks secrets list-secrets --scope $ScopeName --profile $DbProfile --output JSON | ConvertFrom-Json
            foreach ($secret in $secrets) {
                $SecretFile = Join-Path $SecretsScopeBackup ($secret.key + ".txt")
                # Can't backup secret values directly due to security, just storing key names
                "SECRET_KEY_ONLY" | Out-File $SecretFile -Force
            }
        } catch {
            Write-Warning "Error listing secrets for scope ${ScopeName}: $_"
        }
    }
} catch {
    Write-Warning "Failed to list secret scopes: $_"
}

# =============================
# Backup Repos
# =============================
$ReposBackup = Join-Path $BackupRoot "repos"
New-Item -ItemType Directory -Path $ReposBackup -Force | Out-Null
try {
    $repos = databricks repos list --profile $DbProfile --output JSON | ConvertFrom-Json
    foreach ($repo in $repos) {
        $RepoFile = Join-Path $ReposBackup ("repo_" + $repo.id + ".json")
        $repo | ConvertTo-Json -Depth 10 | Out-File $RepoFile -Force
    }
} catch {
    Write-Warning "Failed to backup repos: $_"
}

# =============================
# Backup DBFS
# =============================
$DbfsBackup = Join-Path $BackupRoot "dbfs"
New-Item -ItemType Directory -Path $DbfsBackup -Force | Out-Null
Copy-DbfsSafe "/user" (Join-Path $DbfsBackup "user")

Write-Host "FULL BACKUP COMPLETE"
Write-Host "Backup location: $BackupRoot"