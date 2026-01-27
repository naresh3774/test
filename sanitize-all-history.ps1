<#
.SYNOPSIS
    Full history secret scrub for Terraform repo
.DESCRIPTION
    - Scans all commits on all branches
    - Finds all primary.auto.tfvars files in all folders
    - Replaces client_id, client_secret, tenant_id, subscription_id with ""
    - Cleans old refs and garbage
    - Verifies that secrets are gone
    - Leaves pushing to GitHub manual
#>

# -------------------------
# CONFIGURATION
# -------------------------
$SecretPatterns = @("client_id","client_secret","tenant_id","subscription_id")

# -------------------------
# Step 0: Confirm running in normal clone
# -------------------------
if (!(Test-Path ".git")) {
    Write-Host "ERROR: Not a git repository. Clone the repo normally, not bare/mirror." -ForegroundColor Red
    exit
}

# -------------------------
# Step 1: Rewrite full history
# -------------------------
Write-Host "`n[Step 1] Rewriting full history across all branches..." -ForegroundColor Cyan
$env:FILTER_BRANCH_SQUELCH_WARNING="1"

git filter-branch -f --tree-filter "powershell -NoProfile -Command ^
  Get-ChildItem -Recurse -Filter primary.auto.tfvars | ForEach-Object { ^
      $c = Get-Content $_.FullName; ^
      $c = $c -replace '^client_id\s*=.*','client_id = ""'; ^
      $c = $c -replace '^client_secret\s*=.*','client_secret = ""'; ^
      $c = $c -replace '^tenant_id\s*=.*','tenant_id = ""'; ^
      $c = $c -replace '^subscription_id\s*=.*','subscription_id = ""'; ^
      Set-Content $_.FullName $c ^
  }" -- --all

# -------------------------
# Step 2: Cleanup old refs and garbage
# -------------------------
Write-Host "`n[Step 2] Cleaning old refs and garbage..." -ForegroundColor Cyan
if (Test-Path ".git\refs\original") {
    Remove-Item -Recurse -Force .git\refs\original
}

git reflog expire --expire=now --all
git gc --prune=now --aggressive

# -------------------------
# Step 3: Verification
# -------------------------
Write-Host "`n[Step 3] Verifying secrets are gone..." -ForegroundColor Cyan

$found = $false
foreach ($pattern in $SecretPatterns) {
    $matches = Get-ChildItem -Recurse -Filter primary.auto.tfvars | Select-String -Pattern $pattern
    if ($matches) {
        Write-Host "WARNING: Found '$pattern' in the following files:" -ForegroundColor Red
        $matches | ForEach-Object { Write-Host $_.Path }
        $found = $true
    }
}

if (-not $found) {
    Write-Host "`nSUCCESS: No secrets found in any primary.auto.tfvars!" -ForegroundColor Green
} else {
    Write-Host "`nSome secrets still exist! Check the warnings above." -ForegroundColor Red
}

Write-Host "`nDone. You can now manually review and push with:" -ForegroundColor Yellow
Write-Host "git push --force --all" -ForegroundColor Yellow
Write-Host "git push --force --tags" -ForegroundColor Yellow
Write-Host "`nRemember: all team members will need to re-clone after push." -ForegroundColor Yellow