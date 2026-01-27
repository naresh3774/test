$branches = git for-each-ref --format="%(refname:short)" refs/heads/

foreach ($branch in $branches) {
    Write-Host "Processing branch $branch"
    git checkout $branch | Out-Null

    Get-ChildItem -Recurse -Filter primary.auto.tfvars -ErrorAction SilentlyContinue | ForEach-Object {
        $content = Get-Content $_.FullName
        $content = $content -replace 'client_id\s*=.*', 'client_id = ""'
        $content = $content -replace 'client_secret\s*=.*', 'client_secret = ""'
        $content = $content -replace 'tenant_id\s*=.*', 'tenant_id = ""'
        $content = $content -replace 'subscription_id\s*=.*', 'subscription_id = ""'
        Set-Content $_.FullName $content
    }

    git add .
    git commit -m "Sanitize primary.auto.tfvars" -q
}