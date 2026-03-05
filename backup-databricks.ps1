$PROFILE="dev-databricks"

$DATE=Get-Date -Format "yyyyMMdd-HHmmss"
$BACKUP="Databricks-Enterprise-Backup-$DATE"

Write-Host "Creating backup directory $BACKUP"
New-Item -ItemType Directory -Path $BACKUP

#################################################
# WORKSPACE
#################################################

Write-Host "Exporting workspace notebooks..."

databricks workspace export-dir / "$BACKUP/workspace" -p $PROFILE

#################################################
# JOBS
#################################################

Write-Host "Exporting jobs..."

databricks jobs list -p $PROFILE -o json > "$BACKUP/jobs.json"

#################################################
# CLUSTERS
#################################################

Write-Host "Exporting clusters..."

databricks clusters list -p $PROFILE -o json > "$BACKUP/clusters.json"

#################################################
# REPOS
#################################################

Write-Host "Exporting repos..."

databricks repos list -p $PROFILE -o json > "$BACKUP/repos.json"

#################################################
# SECRET SCOPES
#################################################

Write-Host "Exporting secrets..."

New-Item -ItemType Directory "$BACKUP/secrets"

$scopes = databricks secrets list-scopes -p $PROFILE -o json | ConvertFrom-Json

foreach ($scope in $scopes.scopes) {

    $scopeName = $scope.name

    Write-Host "Exporting secrets from scope $scopeName"

    databricks secrets list-secrets $scopeName -p $PROFILE -o json > "$BACKUP/secrets/$scopeName.json"

}

#################################################
# INSTANCE POOLS
#################################################

Write-Host "Exporting instance pools..."

databricks instance-pools list -p $PROFILE -o json > "$BACKUP/instance_pools.json"

#################################################
# CLUSTER POLICIES
#################################################

Write-Host "Exporting cluster policies..."

databricks cluster-policies list -p $PROFILE -o json > "$BACKUP/cluster_policies.json"

#################################################
# GLOBAL INIT SCRIPTS
#################################################

Write-Host "Exporting global init scripts..."

databricks global-init-scripts list -p $PROFILE -o json > "$BACKUP/init_scripts.json"

#################################################
# DBFS USER FILES
#################################################

Write-Host "Exporting DBFS user files..."

New-Item -ItemType Directory "$BACKUP/dbfs"

try {
    databricks fs cp -r dbfs:/FileStore "$BACKUP/dbfs/FileStore" -p $PROFILE
} catch {}

try {
    databricks fs cp -r dbfs:/mnt "$BACKUP/dbfs/mnt" -p $PROFILE
} catch {}

#################################################

Write-Host "--------------------------------"
Write-Host "ENTERPRISE BACKUP COMPLETED"
Write-Host "Backup location: $BACKUP"
Write-Host "--------------------------------"