$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$root = "Databricks-Backup-$timestamp"

New-Item -ItemType Directory -Path $root

Write-Host "Exporting workspace archive..."

databricks workspace export / "$root/workspace_backup.dbc" --format DBC

Write-Host "Exporting clusters..."

databricks clusters list > "$root/clusters.txt"

Write-Host "Exporting jobs..."

databricks jobs list > "$root/jobs.txt"

Write-Host "Exporting repos..."

databricks repos list > "$root/repos.txt"

Write-Host "Exporting secret scopes..."

databricks secrets list-scopes > "$root/secrets.txt"

Write-Host "Exporting DBFS..."

databricks fs cp -r dbfs:/ "$root/dbfs"

Write-Host "Backup completed at $root"