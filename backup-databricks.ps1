param(
    [string]$DbProfile = "dev-databricks"
)

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupRoot = Join-Path $PWD "Databricks-Full-Backup-$timestamp"

$WorkspaceDir = Join-Path $BackupRoot "workspace"
$DbfsDir = Join-Path $BackupRoot "dbfs"
$ConfigDir = Join-Path $BackupRoot "config"

New-Item -ItemType Directory -Force -Path $WorkspaceDir | Out-Null
New-Item -ItemType Directory -Force -Path $DbfsDir | Out-Null
New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null

Write-Host ""
Write-Host "==========================================="
Write-Host "Databricks Enterprise Backup Starting"
Write-Host "Profile: $DbProfile"
Write-Host "Backup folder: $BackupRoot"
Write-Host "==========================================="
Write-Host ""

# ---------------------------------------------------
# WORKSPACE BACKUP (.DBC)
# ---------------------------------------------------

Write-Host "Exporting workspace as DBC..."

$workspaceFile = Join-Path $WorkspaceDir "workspace_backup.dbc"

try {
    databricks workspace export / $workspaceFile `
        --format DBC `
        --profile $DbProfile
}
catch {
    Write-Warning "Workspace export failed"
}

# ---------------------------------------------------
# JOBS
# ---------------------------------------------------

Write-Host "Exporting jobs..."

try {
    databricks jobs list `
        --output JSON `
        --profile $DbProfile |
    Out-File (Join-Path $ConfigDir "jobs.json") -Encoding utf8
}
catch {
    Write-Warning "Jobs export failed"
}

# ---------------------------------------------------
# CLUSTERS
# ---------------------------------------------------

Write-Host "Exporting clusters..."

try {
    databricks clusters list `
        --output JSON `
        --profile $DbProfile |
    Out-File (Join-Path $ConfigDir "clusters.json") -Encoding utf8
}
catch {
    Write-Warning "Clusters export failed"
}

# ---------------------------------------------------
# CLUSTER POLICIES
# ---------------------------------------------------

Write-Host "Exporting cluster policies..."

try {
    databricks cluster-policies list `
        --output JSON `
        --profile $DbProfile |
    Out-File (Join-Path $ConfigDir "cluster-policies.json") -Encoding utf8
}
catch {
    Write-Warning "Cluster policies export failed"
}

# ---------------------------------------------------
# SECRET SCOPES (names only)
# ---------------------------------------------------

Write-Host "Exporting secret scopes..."

try {
    databricks secrets list-scopes `
        --output JSON `
        --profile $DbProfile |
    Out-File (Join-Path $ConfigDir "secret-scopes.json") -Encoding utf8
}
catch {
    Write-Warning "Secret scopes export failed"
}

# ---------------------------------------------------
# REPOS
# ---------------------------------------------------

Write-Host "Exporting repos..."

try {
    databricks repos list `
        --output JSON `
        --profile $DbProfile |
    Out-File (Join-Path $ConfigDir "repos.json") -Encoding utf8
}
catch {
    Write-Warning "Repos export failed"
}

# ---------------------------------------------------
# INSTANCE POOLS
# ---------------------------------------------------

Write-Host "Exporting instance pools..."

try {
    databricks instance-pools list `
        --output JSON `
        --profile $DbProfile |
    Out-File (Join-Path $ConfigDir "instance-pools.json") -Encoding utf8
}
catch {
    Write-Warning "Instance pools export failed"
}

# ---------------------------------------------------
# GLOBAL INIT SCRIPTS
# ---------------------------------------------------

Write-Host "Exporting global init scripts..."

try {
    databricks global-init-scripts list `
        --output JSON `
        --profile $DbProfile |
    Out-File (Join-Path $ConfigDir "global-init-scripts.json") -Encoding utf8
}
catch {
    Write-Warning "Global init scripts export failed"
}

# ---------------------------------------------------
# DBFS BACKUP
# ---------------------------------------------------

Write-Host "Checking DBFS FileStore..."

try {
    databricks fs ls dbfs:/FileStore --profile $DbProfile | Out-Null
    databricks fs cp -r dbfs:/FileStore $DbfsDir --profile $DbProfile
}
catch {
    Write-Host "FileStore not present, skipping..."
}

# ---------------------------------------------------
# CREATE ZIP
# ---------------------------------------------------

Write-Host ""
Write-Host "Compressing backup..."

$ZipFile = "$BackupRoot.zip"

Compress-Archive `
    -Path "$BackupRoot\*" `
    -DestinationPath $ZipFile `
    -Force

Write-Host ""
Write-Host "==========================================="
Write-Host "BACKUP COMPLETE"
Write-Host "Backup ZIP:"
Write-Host $ZipFile
Write-Host "==========================================="