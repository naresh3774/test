$ErrorActionPreference = "Continue"

# Fetch all branches first
git fetch --all --prune | Out-Null

# Get all remote branches except HEAD
$branches = git for-each-ref --format="%(refname:short)" refs/remotes/origin/ |
    Where-Object { $_ -notmatch "HEAD" } |
    ForEach-Object { $_ -replace "^origin/", "" }

foreach ($branch in $branches) {
    Write-Host "`n=== Processing branch: $branch ==="

    # Checkout branch (create local tracking branch if needed)
    if (-not (git branch --list $branch)) {
        git checkout -b $branch origin/$branch | Out-Null
    } else {
        git checkout $branch | Out-Null
    }

    # Find primary.auto.tfvars anywhere in this branch
    $files = Get-ChildItem -Recurse -Filter primary.auto.tfvars -ErrorAction SilentlyContinue

    if (-not $files) {
        Write-Host "No primary.auto.tfvars in this branch (skipping)"
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

Write-Host "`n✅ Finished processing all branches"
