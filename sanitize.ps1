Get-ChildItem -Recurse -Filter primary.auto.tfvars | ForEach-Object {
    $content = Get-Content $_.FullName

    $content = $content -replace '^client_id\s*=.*',        'client_id = ""'
    $content = $content -replace '^client_secret\s*=.*',    'client_secret = ""'
    $content = $content -replace '^tenant_id\s*=.*',        'tenant_id = ""'
    $content = $content -replace '^subscription_id\s*=.*',  'subscription_id = ""'

    Set-Content $_.FullName $content
}