# =========================================================
# SANITIZE ALL BRANCHES + SINGLE COMMIT
# Logs full changes line by line
# Adds summary table
# Interactive push per branch
# =========================================================

# -----------------------------
# CONFIGURATION
# -----------------------------
$RepoUrl = "https://github.com/your-org/Azure_Terraform_NonProduction.git"  # Update
$RepoFolder = "Azure_Terraform_NonProduction"
$LogFolder = Join-Path $PSScriptRoot "logs"
$SanitizeLog = Join-Path $LogFolder "sanitize_all_branches.log"
$SummaryLog = Join-Path $LogFolder "sanitize_summary.log"

# Clear previous logs
if (Test-Path $LogFolder) { Remove-Item -Recurse -Force $LogFolder }
New-Item -ItemType Directory -Path $LogFolder | Out-Null
"" | Out-File $SanitizeLog
"" | Out-File $SummaryLog

# -----------------------------
# SAFETY CHECK
# -----------------------------
$FullRepoPath = Join-Path $PSScriptRoot $RepoFolder
if (Test-Path $FullRepoPath) {
    Write-Host "❌ Folder '$RepoFolder' already exists. Deleting for fresh start..."
    Remove-Item -Recurse -Force $FullRepoPath
}

# -----------------------------
# STEP 1: Clone repo
# -----------------------------
Write-Host "📥 Cloning repo..."
git clone $RepoUrl $RepoFolder
Set-Location $FullRepoPath
git config core.pager cat
Add-Content $SanitizeLog "$(Get-Date) - Cloned repo $RepoUrl"

# -----------------------------
# STEP 2: Fetch all remote branches
# -----------------------------
Write-Host "🔄 Fetching all remote branches..."
git fetch --all
Add-Content $SanitizeLog "$(Get-Date) - Fetched all remote branches"

# -----------------------------
# STEP 3: Create local branches
# -----------------------------
Write-Host "🌿 Creating local branches..."
$remoteBranches = git branch -r | Where-Object { $_ -notmatch 'HEAD' }
foreach ($r in $remoteBranches) {
    $rName = $r.Trim()
    $localName = ($rName -replace '^origin/', '')
    if (-not (git show-ref --verify --quiet "refs/heads/$localName")) {
        git branch $localName $rName
        Add-Content $SanitizeLog "$(Get-Date) - Created local branch $localName from $rName"
    }
}

# -----------------------------
# STEP 4: Sanitize and rewrite each branch
# -----------------------------
$branches = git branch --format="%(refname:short)"
$summaryData = @()

foreach ($b in $branches) {
    Write-Host "🌿 Processing branch $b..."
    Add-Content $SanitizeLog "`n$(Get-Date) - Processing branch $b"

    git checkout $b

    # Find all primary.auto.tfvars
    $files = Get-ChildItem -Path . -Recurse -Filter "primary.auto.tfvars" -ErrorAction SilentlyContinue
    $filesChanged = 0
    $linesChanged = 0

    if ($files.Count -eq 0) {
        Write-Host "   No primary.auto.tfvars found in $b"
        Add-Content $SanitizeLog "   No primary.auto.tfvars found in $b"
    } else {
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
                Add-Content $SanitizeLog "   Sanitized file: $($f.FullName)"

                $filesChanged++
                # Count line changes
                for ($i=0; $i -lt [Math]::Max($contentBefore.Count, $contentAfter.Count); $i++) {
                    $beforeLine = if ($i -lt $contentBefore.Count) { $contentBefore[$i] } else { "" }
                    $afterLine  = if ($i -lt $contentAfter.Count)  { $contentAfter[$i] } else { "" }
                    if ($beforeLine -ne $afterLine) { 
                        $linesChanged++
                        Add-Content $SanitizeLog "       Line $($i+1): '$beforeLine' => '$afterLine'"
                    }
                }
            }
        }
    }

    # -----------------------------
    # STEP 4a: Create fresh single commit
    # -----------------------------
    $TempBranch = "${b}_SANITIZE_TEMP"

    git checkout --orphan $TempBranch
    git rm -rf --cached . 2>$null
    git clean -fdx

    git checkout $b -- .
    git add .
    git commit -m "Initial commit (sanitized for branch $b)"
    Add-Content $SanitizeLog "   Created single sanitized commit on $TempBranch"

    git branch -f $b $TempBranch
    git checkout $b
    git branch -D $TempBranch
    Add-Content $SanitizeLog "   Overwrote branch $b with sanitized commit"

    # -----------------------------
    # Add to summary
    # -----------------------------
    $summaryData += [PSCustomObject]@{
        Branch = $b
        FilesSanitized = $filesChanged
        LinesChanged  = $linesChanged
    }

    # -----------------------------
    # STEP 4b: Interactive push
    # -----------------------------
    $push1 = Read-Host "Do you want to push branch '$b' to origin? (yes/no)"
    if ($push1 -eq "yes") {
        $push2 = Read-Host "ARE YOU SURE? This will overwrite remote branch '$b' (yes/no)"
        if ($push2 -eq "yes") {
            Write-Host "🚀 Pushing sanitized branch $b..."
            git push --force origin $b
            Add-Content $SanitizeLog "$(Get-Date) - Pushed sanitized branch $b to remote"
            Write-Host "✅ Branch $b pushed"
        } else {
            Write-Host "❌ Skipped pushing branch $b"
            Add-Content $SanitizeLog "$(Get-Date) - Skipped pushing branch $b"
        }
    } else {
        Write-Host "❌ Skipped pushing branch $b"
        Add-Content $SanitizeLog "$(Get-Date) - Skipped pushing branch $b"
    }
}

# -----------------------------
# STEP 5: Write summary log
# -----------------------------
Add-Content $SummaryLog "Branch Sanitization Summary"
Add-Content $SummaryLog "==========================="
$summaryData | Sort-Object Branch | ForEach-Object {
    Add-Content $SummaryLog ("Branch: {0}, Files Sanitized: {1}, Lines Changed: {2}" -f $_.Branch, $_.FilesSanitized, $_.LinesChanged)
}

# -----------------------------
# STEP 6: Final verification
# -----------------------------
Write-Host "`n✅ ALL BRANCHES SANITIZED"
Write-Host "Branches:"
git branch
Write-Host "`nLogs saved to: $SanitizeLog"
Write-Host "Summary saved to: $SummaryLog"
Write-Host "`nReview carefully. Push has been interactive for each branch."
