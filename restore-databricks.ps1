$root = "Databricks-Enterprise-Backup-20260305-110000"

############################################
Write-Host "Restoring Workspace"
############################################

databricks workspace import_dir "$root/workspace" /

############################################
Write-Host "Restoring Instance Pools"
############################################

$pools = Get-Content "$root/pools/pools.json" | ConvertFrom-Json

foreach ($p in $pools.instance_pools) {

    $p | ConvertTo-Json -Depth 10 | Out-File temp_pool.json

    databricks instance-pools create --json-file temp_pool.json

}

############################################
Write-Host "Restoring Clusters"
############################################

$clusters = Get-Content "$root/clusters/clusters.json" | ConvertFrom-Json

foreach ($c in $clusters.clusters) {

    $c | ConvertTo-Json -Depth 10 | Out-File temp_cluster.json

    databricks clusters create --json-file temp_cluster.json

}

############################################
Write-Host "Restoring Jobs"
############################################

$jobs = Get-ChildItem "$root/jobs/*.json"

foreach ($j in $jobs) {

    databricks jobs create --json-file $j.FullName

}

############################################
Write-Host "Restoring Repos"
############################################

$repos = Get-Content "$root/repos/repos.json" | ConvertFrom-Json

foreach ($r in $repos.repos) {

    databricks repos create `
        --url $r.url `
        --provider $r.provider `
        --path $r.path

}

############################################
Write-Host "Restoring DBFS"
############################################

databricks fs cp -r "$root/dbfs" dbfs:/

Write-Host "Restore Completed"