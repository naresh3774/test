$ErrorActionPreference = "Continue"

# Get ALL remote branches except HEAD
$branches = git for-each-ref --format="%(refname:short)" refs/remotes/origin/ |
    Where-Object { $_ -notmatch "HEAD" } |
    ForEach-Object { $_ -replace "^origin/", "" }

foreach ($branch in $branches) {
    Write-Host "`n=== Processing branch: $branch ==="

    # Create local branch if missing
    if (-not (git branch --list $branch)) {
        git checkout -b $branch origin/$branch | Out-Null
    } else {
        git checkout $branch | Out-Null
    }

    $files = Get-ChildItem -Recurse -Filter primary.auto.tfvars -ErrorAction SilentlyContinue

    if ($files.Count -eq 0) {
        Write-Host "No primary.auto.tfvars found"
        continue
    }

    foreach ($file in $files) {
        Write-Host "Sanitizing $($file.FullName)"

        $content = Get-Content $file.FullName
        $content = $content -replace 'client_id\s*=.*', 'client_id = ""'
        $content = $content -replace 'client_secret\s*=.*', 'client_secret = ""'
        $content = $content -replace 'tenant_id\s*=.*', 'tenant_id = ""'
        $content = $content -replace 'subscription_id\s*=.*', 'subscription_id = ""'

        Set-Content $file.FullName $content
    }

    git add .
    git commit -m "Sanitize primary.auto.tfvars" -q
}

Write-Host "`n✅ Sanitization completed for all branches"
