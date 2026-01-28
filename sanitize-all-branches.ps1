# ================= CONFIG =================
$RepoUrl = "https://github.com/YOUR_ORG/YOUR_REPO.git"
$RepoDir = "repo"
$TargetFile = "primary.auto.tfvars"

$SensitivePatterns = @(
    '^\s*client_id\s*=.*$',
    '^\s*client_secret\s*=.*$',
    '^\s*tenant_id\s*=.*$',
    '^\s*subscription_id\s*=.*$'
)

$SanitizeLog = "..\sanitize.log"
$SummaryLog  = "..\summary.log"
$PushLog     = "..\push.log"

# ================= INIT =================
git clone $RepoUrl $RepoDir
cd $RepoDir

git fetch --all
$Branches = git branch -r | Where-Object { $_ -notmatch "HEAD" } | ForEach-Object {
    $_.Trim().Replace("origin/","")
}

"Starting sanitization: $(Get-Date)" | Out-File $SanitizeLog
"Branch Summary:" | Out-File $SummaryLog
"" | Out-File $PushLog

# ================= PROCESS BRANCHES =================
foreach ($Branch in $Branches) {

    "Processing branch: $Branch" | Tee-Object -FilePath $SummaryLog -Append

    git checkout -B $Branch origin/$Branch | Out-Null

    # --- CREATE ORPHAN ---
    $TempBranch = "sanitize-temp-$Branch"
    git checkout --orphan $TempBranch | Out-Null

    git rm -rf . | Out-Null

    # --- COPY FILES FROM ORIGINAL BRANCH ---
    git checkout $Branch -- . | Out-Null

    # --- SANITIZE INSIDE ORPHAN ---
    if (Test-Path $TargetFile) {
        $Content = Get-Content $TargetFile
        $OriginalCount = $Content.Count

        foreach ($Pattern in $SensitivePatterns) {
            $Content = $Content | Where-Object { $_ -notmatch $Pattern }
        }

        $Content | Set-Content $TargetFile
        $NewCount = $Content.Count

        "[$Branch] Sanitized $TargetFile (lines: $OriginalCount → $NewCount)" |
            Tee-Object -FilePath $SanitizeLog -Append
    }
    else {
        "[$Branch] $TargetFile not found" |
            Tee-Object -FilePath $SanitizeLog -Append
    }

    # --- FAIL-FAST SAFETY CHECK ---
    $PostCheck = Get-Content $TargetFile | Select-String -Pattern `
    'client_id\s*=|client_secret\s*=|tenant_id\s*=|subscription_id\s*='

    if ($PostCheck) {
        Write-Error "[$Branch] ❌ Sensitive values still detected after sanitization. Aborting."
        exit 1
    }

    # --- COMMIT CLEAN STATE ---
    git add .
    git commit -m "Initial clean commit (sanitized for branch $Branch)" | Out-Null

    # --- REPLACE ORIGINAL BRANCH LOCALLY ---
    git branch -D $Branch | Out-Null
    git branch -m $TempBranch $Branch

    "[$Branch] Sanitized successfully" | Tee-Object -FilePath $SummaryLog -Append
}

# ================= PUSH CONTROL =================
Write-Host ""
Write-Host "All branches sanitized locally."
Write-Host "You may now checkout and VERIFY any branch."
Write-Host ""

$PushChoice = Read-Host "Do you want to push changes now? (yes / no)"
if ($PushChoice -ne "yes") {
    Write-Host "No branches pushed."
    exit
}

$Mode = Read-Host "Push one branch or all? (one / all)"

if ($Mode -eq "one") {
    $BranchName = Read-Host "Enter branch name to push"
    git push origin $BranchName --force
    "Pushed branch: $BranchName" | Out-File $PushLog -Append
}
elseif ($Mode -eq "all") {
    foreach ($Branch in $Branches) {
        git push origin $Branch --force
        "Pushed branch: $Branch" | Out-File $PushLog -Append
    }
}

Write-Host "Push complete."
