$PROFILE="dev-databricks"

$DATE=Get-Date -Format "yyyyMMdd-HHmmss"
$BACKUP="Databricks-Full-Backup-$DATE"

Write-Host "Creating backup directory $BACKUP"
New-Item -ItemType Directory -Path $BACKUP

####################################
# WORKSPACE NOTEBOOKS
####################################

Write-Host "Backing up workspace..."

databricks workspace export-dir / "$BACKUP/workspace" -p $PROFILE

####################################
# JOBS
####################################

Write-Host "Backing up jobs..."

databricks jobs list -o json -p $PROFILE | Out-File "$BACKUP/jobs.json"

####################################
# CLUSTERS
####################################

Write-Host "Backing up clusters..."

databricks clusters list -o json -p $PROFILE | Out-File "$BACKUP/clusters.json"

####################################
# REPOS
####################################

Write-Host "Backing up repos..."

databricks repos list -o json -p $PROFILE | Out-File "$BACKUP/repos.json"

####################################
# SECRET SCOPES + SECRETS
####################################

Write-Host "Backing up secret scopes..."

$scopes = databricks secrets list-scopes -o json -p $PROFILE | ConvertFrom-Json

$secretDir="$BACKUP/secrets"
New-Item -ItemType Directory -Path $secretDir

foreach ($scope in $scopes.scopes) {

    $scopeName=$scope.name

    Write-Host "Exporting secrets from scope $scopeName"

    databricks secrets list-secrets $scopeName -o json -p $PROFILE |
    Out-File "$secretDir/$scopeName.json"

}

####################################
# INSTANCE POOLS
####################################

Write-Host "Backing up instance pools..."

databricks instance-pools list -o json -p $PROFILE |
Out-File "$BACKUP/pools.json"

####################################
# CLUSTER POLICIES
####################################

Write-Host "Backing up cluster policies..."

databricks cluster-policies list -o json -p $PROFILE |
Out-File "$BACKUP/policies.json"

####################################
# GLOBAL INIT SCRIPTS
####################################

Write-Host "Backing up global init scripts..."

databricks global-init-scripts list -o json -p $PROFILE |
Out-File "$BACKUP/init_scripts.json"

####################################
# DBFS
####################################

Write-Host "Backing up DBFS..."

New-Item -ItemType Directory "$BACKUP/dbfs"

databricks fs cp -r dbfs:/FileStore "$BACKUP/dbfs/FileStore" -p $PROFILE
databricks fs cp -r dbfs:/mnt "$BACKUP/dbfs/mnt" -p $PROFILE
databricks fs cp -r dbfs:/user "$BACKUP/dbfs/user" -p $PROFILE

####################################

Write-Host ""
Write-Host "===================================="
Write-Host "BACKUP COMPLETE"
Write-Host "Location: $BACKUP"
Write-Host "===================================="