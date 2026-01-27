# =========================================================
# FULL SANITIZE + ORPHAN RESET SCRIPT with LOGGING
# Single commit, all history removed
# Run from OUTSIDE the repo
# =========================================================

# -----------------------------
# CONFIGURATION
# -----------------------------
$RepoUrl = "https://github.com/your-org/Azure_Terraform_NonProduction.git"  # Update this
$RepoFolder = "Azure_Terraform_NonProduction"
$FinalBranch = "main"

$LogFolder = Join-Path $PSScriptRoot "logs"
if (-not (Test-Path $LogFolder)) { New-Item -ItemType Directory -Path $LogFolder }

$SanitizeLog = Join-Path $LogFolder "sanitize_changes.log"
$HistoryLog  = Join-Path $LogFolder "history_cleanup.log"

# Clear previous logs
"" | Out-File $SanitizeLog
"" | Out-File $HistoryLog

# -----------------------------
# SAFETY CHECK
# -----------------------------
$FullRepoPath = Join-Path $PSScriptRoot $RepoFolder
if (Test-Path $FullRepoPath) {
    Write-Host "❌ Folder '$RepoFolder' already exists. Deleting it for a fresh start..."
    Remove-Item -Recurse -Force $FullRepoPath
}

# -----------------------------
# STEP 1: Clone fresh repo
# -----------------------------
Write-Host "📥 Cloning repo..."
git clone $RepoUrl $RepoFolder
Set-Location $FullRepoPath
git config core.pager cat

Add-Content $HistoryLog "$(Get-Date) - Cloned repo $RepoUrl into $RepoFolder"

# -----------------------------
# STEP 2: Fetch all remote branches
# -----------------------------
Write-Host "🔄 Fetching all remote branches..."
git fetch --all
Add-Content $HistoryLog "$(Get-Date) - Fetched all remote branches"

# -----------------------------
# STEP 3: Create local branches safely
# -----------------------------
Write-Host "🌿 Creating local branches..."
$remoteBranches = git branch -r | Where-Object { $_ -notmatch 'HEAD' }
foreach ($r in $remoteBranches) {
    $rName = $r.Trim()
    $localName = ($rName -replace '^origin/', '') # keep slashes if needed
    if (-not (git show-ref --verify --quiet "refs/heads/$localName")) {
        git branch $localName $rName
        Add-Content $HistoryLog "$(Get-Date) - Created local branch $localName from $rName"
    }
}

# -----------------------------
# STEP 4: Sanitize all primary.auto.tfvars files per branch
# -----------------------------
$branches = git branch --format="%(refname:short)"
foreach ($b in $branches) {
    Write-Host "🌿 Processing branch $b..."
    Add-Content $SanitizeLog "$(Get-Date) - Processing branch $b"
    git checkout $b

    $files = Get-ChildItem -Path . -Recurse -Filter "primary.auto.tfvars" -ErrorAction SilentlyContinue
    if ($files.Count -eq 0) {
        Write-Host "   No primary.auto.tfvars found in $b"
        Add-Content $SanitizeLog "   No primary.auto.tfvars found in $b"
        continue
    }

    foreach ($f in $files) {
        $contentBefore = Get-Content $f.FullName
        $contentAfter = $contentBefore `
            -replace 'client_id\s*=\s*".*"', 'client_id = ""' `
            -replace 'client_secret\s*=\s*".*"', 'client_secret = ""' `
            -replace 'tenant_id\s*=\s*".*"', 'tenant_id = ""' `
            -replace 'subscription_id\s*=\s*".*"', 'subscription_id = ""'

        if ($contentBefore -ne $contentAfter) {
            Set-Content $f.FullName $contentAfter
            git add $f.FullName
            Add-Content $SanitizeLog "   Sanitized $($f.FullName)"
        }
    }

    # Commit if changes exist
    if ((git status --porcelain) -ne "") {
        git commit -m "Sanitized sensitive values"
        Add-Content $SanitizeLog "   Changes committed in $b"
    } else {
        Add-Content $SanitizeLog "   Nothing to commit in $b"
    }
}

# -----------------------------
# STEP 5: Create a true orphan branch
# -----------------------------
Write-Host "🔥 Creating orphan branch CLEAN_START..."
git checkout --orphan CLEAN_START
git rm -rf --cached . 2>$null
git clean -fdx
Add-Content $HistoryLog "$(Get-Date) - Orphan branch CLEAN_START created"

# -----------------------------
# STEP 6: Restore sanitized files from first branch
# -----------------------------
Write-Host "📂 Restoring sanitized files from branch $($branches[0])..."
git checkout $branches[0] -- .
Add-Content $HistoryLog "$(Get-Date) - Restored sanitized files from branch $($branches[0])"

# -----------------------------
# STEP 7: Commit initial sanitized commit
# -----------------------------
git add .
git commit -m "Initial commit (sanitized)"
Add-Content $HistoryLog "$(Get-Date) - Initial commit (sanitized) created"

# -----------------------------
# STEP 8: Rename orphan branch to final branch
# -----------------------------
git branch -M $FinalBranch
Add-Content $HistoryLog "$(Get-Date) - Renamed orphan branch to $FinalBranch"

# -----------------------------
# STEP 9: Delete all old local branches safely
# -----------------------------
Write-Host "🗑 Deleting old local branches..."
git branch | ForEach-Object {
    $b = $_.Trim() -replace '^\* ',''
    if ($b -ne $FinalBranch) {
        Write-Host "   Deleting $b"
        git branch -D $b
        Add-Content $HistoryLog "$(Get-Date) - Deleted old local branch $b"
    }
}

# -----------------------------
# STEP 10: Verification
# -----------------------------
Write-Host "`n✅ FINAL STATE"
git branch
git log --oneline

Write-Host "`n🔍 Checking secrets (should return nothing):"
git grep client_id
git grep client_secret
git grep tenant_id
git grep subscription_id

Add-Content $HistoryLog "$(Get-Date) - Verification done. Only $FinalBranch remains with sanitized commit."

Write-Host "`n🛑 DONE — NO PUSH PERFORMED"
Write-Host "Logs saved to: $SanitizeLog and $HistoryLog"
Write-Host "👉 Review carefully, then push manually when ready:"
Write-Host "git push --force origin main"
Write-Host "git push --force --prune origin '+refs/heads/*'"
