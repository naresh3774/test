# =====================================================
# FULL SANITIZE + HISTORY RESET SCRIPT
# MUST BE RUN FROM OUTSIDE ANY GIT REPO
# =====================================================

Set-Location -Path $PSScriptRoot

# -------- CONFIG (EDIT ONLY THIS SECTION) --------
$RepoUrl  = "<PUT_YOUR_REPO_URL_HERE>"
$WorkDir  = "Azure_Terraform_NonProduction"
$FinalBranch = "main"

$VarsToClean = @(
  "client_id",
  "client_secret",
  "tenant_id",
  "subscription_id"
)
# -------------------------------------------------

# -------- SAFETY CHECK: MUST BE OUTSIDE A GIT REPO --------
git rev-parse --is-inside-work-tree 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Error "❌ You are inside a git repository. Run this script OUTSIDE the repo."
    exit 1
}

# -------- STEP 1: CLONE FRESH --------
Write-Host "`n🚀 Cloning repository..."
git clone $RepoUrl $WorkDir
cd $WorkDir

# -------- STEP 2: FETCH EVERYTHING --------
Write-Host "`n📥 Fetching all remotes..."
git fetch --all --prune

# -------- STEP 3: CREATE LOCAL COPIES OF ALL REMOTE BRANCHES --------
Write-Host "`n🌿 Bringing all remote branches locally..."
$RemoteBranches = git branch -r |
    Where-Object { $_ -notmatch 'HEAD' } |
    ForEach-Object { $_.Trim() }

foreach ($rb in $RemoteBranches) {
    $local = $rb -replace '^origin/', ''
    Write-Host "  → $local"
    git checkout -B $local $rb | Out-Null
}

# -------- STEP 4: SANITIZE EVERY BRANCH --------
$LocalBranches = git branch | ForEach-Object { $_.Trim() }

foreach ($branch in $LocalBranches) {
    Write-Host "`n🧼 Sanitizing branch: $branch"
    git checkout $branch | Out-Null

    $Files = Get-ChildItem -Recurse -Filter "primary.auto.tfvars" -ErrorAction SilentlyContinue

    if (-not $Files) {
        Write-Host "   ⚠ No primary.auto.tfvars found"
        continue
    }

    foreach ($file in $Files) {
        Write-Host "   ✏ Cleaning $($file.FullName)"
        $content = Get-Content $file.FullName

        foreach ($v in $VarsToClean) {
            $content = $content -replace "($v\s*=\s*).+", '$1""'
        }

        Set-Content -Path $file.FullName -Value $content
    }

    git add .
    git commit -m "Sanitize secrets in primary.auto.tfvars" | Out-Null
}

# -------- STEP 5: WIPE HISTORY COMPLETELY --------
Write-Host "`n🔥 Creating brand-new history..."
git checkout --orphan CLEAN_START
git rm -rf . | Out-Null

# Copy sanitized content from first branch
$SourceBranch = $LocalBranches | Select-Object -First 1
Write-Host "📦 Copying sanitized content from $SourceBranch"
git checkout $SourceBranch -- .

git add .
git commit -m "Initial commit (sanitized)"

# -------- STEP 6: REMOVE ALL OLD BRANCHES --------
Write-Host "`n🧹 Removing old branches..."
git branch |
Where-Object { $_ -ne "CLEAN_START" } |
ForEach-Object { git branch -D $_ }

git branch -m $FinalBranch
git checkout $FinalBranch

# -------- STEP 7: VERIFY --------
Write-Host "`n✅ FINAL VERIFICATION"
git log --oneline
git branch

Write-Host "`n🔍 Searching for secrets (should return NOTHING)..."
git grep client_id
git grep client_secret
git grep tenant_id
git grep subscription_id

Write-Host "`n🛑 STOPPED BEFORE PUSH"
Write-Host "👉 Review files and history. Push manually when ready."
