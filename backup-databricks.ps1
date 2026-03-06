$profile = "dev-databricks"

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupRoot = "C:\Users\NareshSharma\workspace\databricks"
$backupDir = "$backupRoot\Databricks-Full-Backup-$timestamp"

Write-Host "Databricks Enterprise Backup Starting"
Write-Host "Profile: $profile"
Write-Host "Backup folder: $backupDir"

New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

# folders
$workspaceDir = "$backupDir\workspace"
$configDir = "$backupDir\configs"
$dbfsDir = "$backupDir\dbfs"

New-Item -ItemType Directory -Force -Path $workspaceDir | Out-Null
New-Item -ItemType Directory -Force -Path $configDir | Out-Null
New-Item -ItemType Directory -Force -Path $dbfsDir | Out-Null

############################################################
# Workspace Backup (.DBC)
############################################################

Write-Host "Exporting workspace as DBC ..."

databricks workspace export-dir / $workspaceDir --profile $profile

############################################################
# Jobs
############################################################

Write-Host "Exporting jobs ..."

$jobs = databricks jobs list --output JSON --profile $profile
$jobs | Out-File "$configDir\jobs.json"

############################################################
# Clusters
############################################################

Write-Host "Exporting clusters ..."

$clusters = databricks clusters list --output JSON --profile $profile
$clusters | Out-File "$configDir\clusters.json"

############################################################
# Cluster Policies
############################################################

Write-Host "Exporting cluster policies ..."

$policies = databricks cluster-policies list --output JSON --profile $profile
$policies | Out-File "$configDir\cluster-policies.json"

############################################################
# Secret Scopes
############################################################

Write-Host "Exporting secret scopes ..."

$secrets = databricks secrets list-scopes --output JSON --profile $profile
$secrets | Out-File "$configDir\secret-scopes.json"

############################################################
# Repos
############################################################

Write-Host "Exporting repos ..."

$repos = databricks repos list --output JSON --profile $profile
$repos | Out-File "$configDir\repos.json"

############################################################
# Instance Pools
############################################################

Write-Host "Exporting instance pools ..."

$pools = databricks instance-pools list --output JSON --profile $profile
$pools | Out-File "$configDir\instance-pools.json"

############################################################
# Global Init Scripts
############################################################

Write-Host "Exporting global init scripts ..."

$init = databricks global-init-scripts list --output JSON --profile $profile
$init | Out-File "$configDir\global-init-scripts.json"

############################################################
# DBFS Backup
############################################################

Write-Host "Checking DBFS root ..."

try {
    databricks fs ls dbfs:/ --profile $profile | Out-Null
    Write-Host "Exporting DBFS files ..."
    databricks fs cp -r dbfs:/ $dbfsDir --profile $profile
}
catch {
    Write-Host "DBFS not accessible, skipping"
}

############################################################
# Compress Backup
############################################################

Write-Host "Compressing backup ..."

$zipPath = "$backupDir.zip"

Compress-Archive -Path $backupDir -DestinationPath $zipPath

Write-Host ""
Write-Host "BACKUP COMPLETE"
Write-Host "Backup ZIP:"
Write-Host $zipPath