# =========================================================
# FULL SANITIZE + ORPHAN RESET SCRIPT
# Single commit, all history removed
# Run from OUTSIDE the repo
# =========================================================

# -----------------------------
# CONFIGURATION
# -----------------------------
$RepoUrl = "https://github.com/your-org/Azure_Terraform_NonProduction.git"  # Change this to your repo
$RepoFolder = "Azure_Terraform_NonProduction"
$FinalBranch = "main"

# -----------------------------
# SAFETY CHECK: Ensure folder doesn't exist
# -----------------------------
$FullRepoPath = Join-Path $PSScriptRoot $RepoFolder
if (Test-Path $FullRepoPath) {
    Write-Host "❌ Folder '$RepoFolder' already exists. Deleting it for a fresh start..."
    Remove-Item -Recurse -Force $FullRepoPath
}

# -----------------------------
# STEP 1: Clone fresh repo with working tree
# -----------------------------
Write-Host "📥 Cloning repo..."
git clone $RepoUrl $RepoFolder
Set-Location $FullRepoPath

# Disable pager
git config core.pager cat

# -----------------------------
# STEP 2: Fetch all remote branches
# -----------------------------
Write-Host "🔄 Fetching all remote branches..."
git fetch --all

# -----------------------------
# STEP 3: Create local branches safely
# -----------------------------
Write-Host "🌿 Creating local branches from remotes..."
$remoteBranches = git branch -r | Where-Object { $_ -notmatch 'HEAD' }
foreach ($r in $remoteBranches) {
    $rName = $r.Trim()
    $localName = ($rName -replace '^origin/', '') # keep slashes if needed
    if (-not (git show-ref --verify --quiet "refs/heads/$localName")) {
        git branch $localName $rName
        Write-Host "   Created local branch $localName from $rName"
    }
}

# -----------------------------
# STEP 4: Sanitize all primary.auto.tfvars files per branch
# -----------------------------
$branches = git branch --format="%(refname:short)"
foreach ($b in $branches) {
    Write-Host "🌿 Processing branch $b..."
    git checkout $b

    $files = Get-ChildItem -Path . -Recurse -Filter "primary.auto.tfvars" -ErrorAction SilentlyContinue
    if ($files.Count -eq 0) {
        Write-Host "   No primary.auto.tfvars found in $b"
        continue
    }

    foreach ($f in $files) {
        (Get-Content $f.FullName) `
            -replace 'client_id\s*=\s*".*"', 'client_id = ""' `
            -replace 'client_secret\s*=\s*".*"', 'client_secret = ""' `
            -replace 'tenant_id\s*=\s*".*"', 'tenant_id = ""' `
            -replace 'subscription_id\s*=\s*".*"', 'subscription_id = ""' |
            Set-Content $f.FullName
        git add $f.FullName
    }

    # Commit if there are changes
    if ((git status --porcelain) -ne "") {
        git commit -m "Sanitized sensitive values"
        Write-Host "   Changes committed in $b"
    } else {
        Write-Host "   Nothing to commit in $b"
    }
}

# -----------------------------
# STEP 5: Create a true orphan branch
# -----------------------------
Write-Host "🔥 Creating orphan branch CLEAN_START..."
git checkout --orphan CLEAN_START
git rm -rf --cached . 2>$null
git clean -fdx

# -----------------------------
# STEP 6: Restore sanitized files from first branch
# -----------------------------
Write-Host "📂 Restoring sanitized files from branch $($branches[0])..."
git checkout $branches[0] -- .

# -----------------------------
# STEP 7: Commit initial sanitized commit
# -----------------------------
git add .
git commit -m "Initial commit (sanitized)"

# -----------------------------
# STEP 8: Rename orphan branch to final branch
# -----------------------------
git branch -M $FinalBranch

# -----------------------------
# STEP 9: Delete all old local branches safely
# -----------------------------
Write-Host "🗑 Deleting old local branches..."
git branch | ForEach-Object {
    $b = $_.Trim() -replace '^\* ',''
    if ($b -ne $FinalBranch) {
        Write-Host "   Deleting $b"
        git branch -D $b
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

Write-Host "`n🛑 DONE — NO PUSH PERFORMED"
Write-Host "👉 Review carefully, then push manually when ready:"
Write-Host "git push --force origin main"
Write-Host "git push --force --prune origin '+refs/heads/*'"
