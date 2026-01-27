# ============================================
# VERIFY ALL BRANCHES ARE SANITIZED
# READ-ONLY / SAFE
# ============================================

$ErrorFound = $false
$RepoRoot = Get-Location
$LogFile = Join-Path $RepoRoot "..\verify_sanitization.log"

"" | Out-File $LogFile
Add-Content $LogFile "Sanitization Verification Report"
Add-Content $LogFile "================================"
Add-Content $LogFile "Run Time: $(Get-Date)"
Add-Content $LogFile ""

$branches = git branch --format="%(refname:short)"

foreach ($branch in $branches) {
    Write-Host "🔍 Checking branch: $branch"
    git checkout $branch | Out-Null

    $files = Get-ChildItem -Recurse -Filter "primary.auto.tfvars" -ErrorAction SilentlyContinue

    if ($files.Count -eq 0) {
        Add-Content $LogFile "[$branch] No primary.auto.tfvars found"
        continue
    }

    foreach ($file in $files) {
        $lines = Get-Content $file.FullName
        $lineNumber = 0

        foreach ($line in $lines) {
            $lineNumber++

            if (
                ($line -match 'client_id\s*=\s*"(?!\s*")') -or
                ($line -match 'client_secret\s*=\s*"(?!\s*")') -or
                ($line -match 'tenant_id\s*=\s*"(?!\s*")') -or
                ($line -match 'subscription_id\s*=\s*"(?!\s*")')
            ) {
                $ErrorFound = $true
                Add-Content $LogFile "❌ [$branch] $($file.FullName):$lineNumber => $line"
            }
        }
    }
}

Add-Content $LogFile ""
if ($ErrorFound) {
    Add-Content $LogFile "❌ RESULT: UNSANITIZED VALUES FOUND"
    Write-Host "`n❌ UNSANITIZED VALUES FOUND"
    Write-Host "See log: $LogFile"
    exit 1
} else {
    Add-Content $LogFile "✅ RESULT: ALL BRANCHES SANITIZED"
    Write-Host "`n✅ ALL BRANCHES ARE CLEAN"
    Write-Host "Verification log: $LogFile"
    exit 0
}
