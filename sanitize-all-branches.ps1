# ----------------- CONFIG -----------------
# $Branch should be set in the loop per branch
# $SanitizeLog = path to log file

$SensitivePatterns = @('client_id', 'client_secret', 'tenant_id', 'subscription_id')

# Recursively find all primary.auto.tfvars files
$TfvarsFiles = Get-ChildItem -Recurse -Filter "primary.auto.tfvars" -File

foreach ($file in $TfvarsFiles) {

    $Original = Get-Content $file.FullName
    $Sanitized = @()

    for ($i = 0; $i -lt $Original.Count; $i++) {
        $line = $Original[$i]
        $lineUpdated = $line

        foreach ($pattern in $SensitivePatterns) {
            if ($line -match "^\s*$pattern\s*=") {
                # Replace everything after = with empty quotes
                $lineUpdated = ($line -replace '=\s*".*"', '= ""')
                Add-Content $SanitizeLog ("[$Branch] $($file.FullName): Line $($i+1) sanitized -> $lineUpdated")
            }
        }

        $Sanitized += $lineUpdated
    }

    # Write back sanitized content
    Set-Content -Path $file.FullName -Value $Sanitized
}

# ----------------- VERIFY -----------------
$Leaks = Get-ChildItem -Recurse -Filter "primary.auto.tfvars" -File |
    Select-String -Pattern 'client_id\s*=\s*".+"\|client_secret\s*=\s*".+"\|tenant_id\s*=\s*".+"\|subscription_id\s*=\s*".+"'

if ($Leaks) {
    Write-Error "[$Branch] ❌ Secrets still found! See log for details. Aborting branch."
    $Leaks | ForEach-Object { 
        Add-Content $SanitizeLog ("[$Branch] LEAK: $($_.Path):$($_.LineNumber) -> $($_.Line)")
    }
    exit 1
}
