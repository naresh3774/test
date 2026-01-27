# =========================================================
# FULL SANITIZE + ORPHAN RESET
# No separate backup folder needed
# =========================================================

# -------- CONFIGURATION --------
$RepoUrl = "https://github.com/your-org/Azure_Terraform_NonProduction.git"
$RepoFolder = "Azure_Terraform_NonProduction"
$FinalBranch = "main"

# -------- SAFETY: run outside repo --------
if (Test-Path $RepoFolder) {
    Write-Host "❌ $RepoFolder already exists. Please delete it or run from a different folder."
    exit 1
}

# -------- STEP 1: Clone repo locally --------
Write-Host "📥 Cloning repo..."
git clone --mirror $RepoUrl $RepoFolder
Set-Location $RepoFolder

# -------- STEP 2: Bring all branches locally --------
Write-Host "🔄 Fetching all branches..."
git fetch --all
git branch -r | ForEach-Object {
    $remoteBranch = $_.Trim()
    if ($remoteBranch -match "^origin/") {
        $localBranch = $remoteBranch -replace "^origin/", ""
        git branch $localBranch $_
    }
}

# -------- STEP 3: Sanitize all primary.auto.tfvars in each branch --------
$branches = git branch --format="%(refname:short)"
foreach ($b in $branches) {
    Write-Host "🌿 Processing branch $b..."
    git checkout $b
    Get-ChildItem -Path . -Recurse -Filter "primary.auto.tfvars" | ForEach-Object {
        (Get-Content $_.FullName) `
            -replace 'client_id\s*=\s*".*"', 'client_id = ""' `
            -replace 'client_secret\s*=\s*".*"', 'client_secret = ""' `
            -replace 'tenant_id\s*=\s*".*"', 'tenant_id = ""' `
            -replace 'subscription_id\s*=\s*".*"', 'subscription_id = ""' |
            Set-Content $_.FullName
        git add $_.FullName
    }
    # Commit changes if any
    if ((git status --porcelain) -ne "") {
        git commit -m "Sanitized sensitive values"
    } else {
        Write-Host "   Nothing to commit in $b"
    }
}

# -------- STEP 4: Create orphan branch --------
Write-Host "🔥 Creating orphan branch CLEAN_START..."
git checkout --orphan CLEAN_START
git rm -rf --cached .
git clean -fdx

# -------- STEP 5: Restore sanitized working tree --------
# Copy all files from current checked-out branch
git checkout $branches[0] -- .

# -------- STEP 6: Stage and commit --------
git add .
git commit -m "Initial commit (sanitized)"

# -------- STEP 7: Rename orphan branch to main --------
git branch -M $FinalBranch

# -------- STEP 8: Clean up local branches --------
git branch | Where-Object { $_ -ne $FinalBranch } | ForEach-Object { git branch -D $_ }

# -------- STEP 9: Verify --------
Write-Host "`n✅ FINAL STATE"
git log --oneline
git branch
Write-Host "`n🔍 Checking secrets (should return nothing):"
git grep client_id
git grep client_secret
git grep tenant_id
git grep subscription_id

Write-Host "`n🛑 DONE — NO PUSH PERFORMED"
Write-Host "👉 Review carefully, then push manually when ready."
