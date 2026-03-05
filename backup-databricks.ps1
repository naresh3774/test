$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$root = "Databricks-Enterprise-Backup-$timestamp"

Write-Host "Creating backup folder $root"

New-Item -ItemType Directory -Path $root

$folders = @(
"workspace",
"jobs",
"clusters",
"repos",
"dbfs",
"secrets",
"policies",
"pools",
"permissions"
)

foreach ($f in $folders) {
    New-Item -ItemType Directory -Path "$root/$f"
}

############################################
Write-Host "Exporting Workspace Notebooks"
############################################

databricks workspace export_dir / "$root/workspace" --overwrite

############################################
Write-Host "Exporting Jobs"
############################################

$jobs = databricks jobs list --output JSON | ConvertFrom-Json

foreach ($job in $jobs.jobs) {

    $id = $job.job_id

    databricks jobs get --job-id $id --output JSON `
        | Out-File "$root/jobs/job-$id.json"

}

############################################
Write-Host "Exporting Clusters"
############################################

databricks clusters list --output JSON `
    | Out-File "$root/clusters/clusters.json"

############################################
Write-Host "Exporting Repos"
############################################

databricks repos list --output JSON `
    | Out-File "$root/repos/repos.json"

############################################
Write-Host "Exporting Cluster Policies"
############################################

databricks cluster-policies list --output JSON `
    | Out-File "$root/policies/policies.json"

############################################
Write-Host "Exporting Instance Pools"
############################################

databricks instance-pools list --output JSON `
    | Out-File "$root/pools/pools.json"

############################################
Write-Host "Exporting Secret Scopes"
############################################

$scopes = databricks secrets list-scopes --output JSON | ConvertFrom-Json

foreach ($scope in $scopes.scopes) {

    $name = $scope.name

    databricks secrets list --scope $name --output JSON `
        | Out-File "$root/secrets/$name.json"

}

############################################
Write-Host "Exporting Global Init Scripts"
############################################

databricks global-init-scripts list --output JSON `
    | Out-File "$root/global-init-scripts.json"

############################################
Write-Host "Exporting DBFS"
############################################

databricks fs cp -r dbfs:/ "$root/dbfs"

############################################
Write-Host "Backup Completed"
############################################

Write-Host "Backup location:"
Write-Host "$root"