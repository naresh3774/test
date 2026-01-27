<#
.SYNOPSIS
  Full secret cleanup script for Terraform repos.
.DESCRIPTION
  1. Backup repo as a mirror.
  2. Dry-run to see which files will be sanitized.
  3. Confirm before rewriting full history.
  4. Clean all branches.
  5. Cleanup old refs and garbage.
  6. Verify secrets removed.
.NOTES
  Author: Automated PowerShell Cleanup
#>

# -------------------------
# CONFIGURATION
# -------------------------
$RepoUrl = "https://github.com/<org>/<repo>.git"   # Replace with your repo URL
$BackupFolder = "C:\Users\NareshSharma\workspace\Azure_Terraform_Backup.git"
$WorkFolder   = "C:\Users\NareshSharma\workspace\Azure_Terraform_Clean"
$SanitizeScript = "sanitize.ps1"   # Place this in $WorkFolder or same folder as this script
$SecretPatterns = @("client_id","client_secret","tenant_id","subscription_id")

# -------------------------
# Step 1: Backup
# -------------------------
Write-Host "`n[Step 1] Creating backup (mirror clone)..." -ForegroundColor Cyan
if (!(Test-Path $BackupFolder)) {
    git clone --mirror $RepoUrl $BackupFolder
} else {
    Write-Host "Backup folder exists, skipping clone."
}

# -------------------------
# Step 2: Normal clone for working tree
# -------------------------
Write-Host "`n[Step 2] Cloning repo for local work..." -ForegroundColor Cyan
if (!(Test-Path $WorkFolder)) {
    git clone $RepoUrl $WorkFolder
} else {
    Write-Host "Work folder exists, skipping clone."
}
Set-Location $WorkFolder

# -------------------------
# Step 3: Dry-run
# -------------------------
Write-Host "`n[Step 3] Running dry-run to see affected files..." -ForegroundColor Cyan

Get-ChildItem -Recurse -Filter primary.auto.tfvars | ForEach-Object {
    $content = Get-Content $_.FullName
    $new = $content
    $new = $new -replace '^client_id\s*=.*','client_id = ""'
    $new = $new -replace '^client_secret\s*=.*','client_secret = ""'
    $new = $new -replace '^tenant_id\s*=.*','tenant_id = ""'
    $new = $new -replace '^subscription_id\s*=.*','subscription_id = ""'

    if ($content -ne $new) {
        Write-Host "Would modify: $($_.FullName)" -ForegroundColor Yellow
    }
}

Write-Host "`nDry-run complete. No files are modified yet." -ForegroundColor Cyan

# -------------------------
# Step 4: Confirm before full cleanup
# -------------------------
$confirm = Read-Host "`nDo you want to proceed with FULL history cleanup? This rewrites all branches and is irreversible! (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Aborting script." -ForegroundColor Red
    exit
}

# -------------------------
# Step 5: Full history rewrite
# -------------------------
Write-Host "`n[Step 5] Rewriting full history..." -ForegroundColor Cyan

# Abort any previous filter-branch
git filter-branch --abort 2>$null
$env:FILTER_BRANCH_SQUELCH_WARNING = "1"

git filter-branch -f --tree-filter "pwsh -NoProfile -File $SanitizeScript" -- --all

# -------------------------
# Step 6: Cleanup old refs and garbage
# -------------------------
Write-Host "`n[Step 6] Cleaning old refs and garbage..." -ForegroundColor Cyan
rmdir /s /q .git\refs\original
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# -------------------------
# Step 7: Verification
# -------------------------
Write-Host "`n[Step 7] Verifying secrets are gone..." -ForegroundColor Cyan
$found = $false
foreach ($pattern in $SecretPatterns) {
    if (git grep $pattern $(git rev-list --all)) {
        Write-Host "WARNING: Found $pattern in history!" -ForegroundColor Red
        $found = $true
    }
}

if (-not $found) {
    Write-Host "SUCCESS: No secrets found in history!" -ForegroundColor Green
}

# -------------------------
# Step 8: Push instructions
# -------------------------
Write-Host "`n[Step 8] To update GitHub, run these commands:" -ForegroundColor Yellow
Write-Host "git push --force --all" -ForegroundColor Yellow
Write-Host "git push --force --tags" -ForegroundColor Yellow
Write-Host "`nIMPORTANT: All team members must re-clone after this push." -ForegroundColor Yellow
