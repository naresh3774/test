$PROFILE="dev-databricks"

$DATE=Get-Date -Format "yyyyMMdd-HHmmss"
$BACKUP_DIR="Databricks-Full-Backup-$DATE"

Write-Host "Creating backup directory $BACKUP_DIR"
New-Item -ItemType Directory -Path $BACKUP_DIR

####################################
# WORKSPACE NOTEBOOKS
####################################

Write-Host "Backing up workspace notebooks..."

databricks workspace export-dir / "$BACKUP_DIR/workspace" -p $PROFILE

####################################
# JOBS
####################################

Write-Host "Backing up jobs..."

databricks jobs list -p $PROFILE -o json | Out-File "$BACKUP_DIR/jobs.json"

####################################
# CLUSTERS
####################################

Write-Host "Backing up clusters..."

databricks clusters list -p $PROFILE -o json | Out-File "$BACKUP_DIR/clusters.json"

####################################
# REPOS
####################################

Write-Host "Backing up repos..."

databricks repos list -p $PROFILE -o json | Out-File "$BACKUP_DIR/repos.json"

####################################
# SECRET SCOPES
####################################

Write-Host "Backing up secret scopes..."

databricks secrets list-scopes -p $PROFILE -o json | Out-File "$BACKUP_DIR/secret_scopes.json"

####################################
# INSTANCE POOLS
####################################

Write-Host "Backing up instance pools..."

databricks instance-pools list -p $PROFILE -o json | Out-File "$BACKUP_DIR/instance_pools.json"

####################################
# CLUSTER POLICIES
####################################

Write-Host "Backing up cluster policies..."

databricks cluster-policies list -p $PROFILE -o json | Out-File "$BACKUP_DIR/cluster_policies.json"

####################################
# GLOBAL INIT SCRIPTS
####################################

Write-Host "Backing up global init scripts..."

databricks global-init-scripts list -p $PROFILE -o json | Out-File "$BACKUP_DIR/global_init_scripts.json"

####################################
# DBFS
####################################

Write-Host "Backing up DBFS..."

New-Item -ItemType Directory -Path "$BACKUP_DIR/dbfs"

databricks fs cp -r dbfs:/ "$BACKUP_DIR/dbfs" -p $PROFILE

####################################

Write-Host "--------------------------------"
Write-Host "FULL BACKUP COMPLETED"
Write-Host "Backup location: $BACKUP_DIR"
Write-Host "--------------------------------"