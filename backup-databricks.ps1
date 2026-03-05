$PROFILE="dev-databricks"

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BACKUP="Databricks-Enterprise-Backup-$timestamp"

Write-Host "Creating backup directory $BACKUP"

New-Item -ItemType Directory -Path $BACKUP
New-Item -ItemType Directory -Path "$BACKUP/workspace"
New-Item -ItemType Directory -Path "$BACKUP/dbfs"
New-Item -ItemType Directory -Path "$BACKUP/secrets"

#########################################
# Workspace Notebooks
#########################################

Write-Host "Exporting workspace notebooks..."

databricks workspace export-dir / "$BACKUP/workspace" `
-p $PROFILE `
--overwrite

#########################################
# Jobs
#########################################

Write-Host "Exporting jobs..."

databricks jobs list `
-p $PROFILE `
-o json > "$BACKUP/jobs.json"

#########################################
# Clusters
#########################################

Write-Host "Exporting clusters..."

databricks clusters list `
-p $PROFILE `
-o json > "$BACKUP/clusters.json"

#########################################
# Repos
#########################################

Write-Host "Exporting repos..."

databricks repos list `
-p $PROFILE `
-o json > "$BACKUP/repos.json"

#########################################
# Instance Pools
#########################################

Write-Host "Exporting instance pools..."

databricks instance-pools list `
-p $PROFILE `
-o json > "$BACKUP/instance_pools.json"

#########################################
# Cluster Policies
#########################################

Write-Host "Exporting cluster policies..."

databricks cluster-policies list `
-p $PROFILE `
-o json > "$BACKUP/cluster_policies.json"

#########################################
# Global Init Scripts
#########################################

Write-Host "Exporting global init scripts..."

databricks global-init-scripts list `
-p $PROFILE `
-o json > "$BACKUP/global_init_scripts.json"

#########################################
# Secret Scopes
#########################################

Write-Host "Exporting secret scopes..."

$scopes = databricks secrets list-scopes `
-p $PROFILE `
-o json | ConvertFrom-Json

foreach ($scope in $scopes.scopes) {

    $scopeName = $scope.name

    Write-Host "Exporting secrets from scope $scopeName"

    databricks secrets list-secrets $scopeName `
    -p $PROFILE `
    -o json > "$BACKUP/secrets/$scopeName.json"

}

#########################################
# DBFS (safe locations only)
#########################################

Write-Host "Exporting DBFS user files..."

databricks fs cp `
dbfs:/user `
"$BACKUP/dbfs/user" `
--recursive `
-p $PROFILE

#########################################

Write-Host ""
Write-Host "================================="
Write-Host "ENTERPRISE BACKUP COMPLETED"
Write-Host "Backup location: $BACKUP"
Write-Host "================================="