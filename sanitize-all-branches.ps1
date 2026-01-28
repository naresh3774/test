# ================= CONFIG =================

$RepoUrl   = "PASTE_YOUR_GIT_REPO_URL_HERE"
$RepoName  = "Azure_Terraform_NonProduction"
$BasePath  = Get-Location
$RepoPath  = Join-Path $BasePath $RepoName

$SanitizeLog = Join-Path $BasePath "sanitize_changes.log"
$HistoryLog  = Join-Path $BasePath "history_reset.log"

# Sensitive keys to REMOVE
$SensitivePatterns = @(
    '^\s*client_id\s*=.*$',
    '^\s*client_secret\s*=.*$',
    '^\s*tenant_id\s*=.*$',
    '^\s*subscription_id\s*=.*$'
)

# =========================================

Write-Host "`n=== Terraform Full Branch Sanitize + History Reset ===`n"

# Safety check
if (Test-Path "$RepoPath\.git") {
    Write-Error "❌ Repo already exists. DELETE it first for a clean run."
    exit 1
}

# Init logs
"" | Set-Content $SanitizeLog
"" | Set-Content $HistoryLog

# Clone repo
git clone $RepoUrl
Set-Location $RepoPath

# Fetch all branches
git fetch --all --prune

# Get all remote branches except HEAD
$RemoteBranches = git branch -r |
    Where-Object { $_ -notmatch 'HEAD' } |
    ForEach-Object { $_.Trim() }

foreach ($Remote in $RemoteBranches) {

    $Branch = $Remote -replace '^origin/', ''
    Write-Host "`n--- Processing branch: $Branch ---"

    # Checkout branch locally
    git checkout -B $Branch $Remote | Out-Null

    # Create orphan temp branch
    $TempBranch = "${Branch}_SANITIZE_TEMP"
    git checkout --orphan $TempBranch | Out-Null

    # Remove index but keep files
    git rm -rf --cached . | Out-Null

    # ================= SANITIZATION =================

    $TfvarsFiles = Get-ChildItem -Recurse -Filter "primary.auto.tfvars" -File

    foreach ($file in $TfvarsFiles) {

        $Original = Get-Content $file.FullName
        $Sanitized = $Original

        foreach ($pattern in $SensitivePatterns) {
            $Sanitized = $Sanitized | Where-Object { $_ -notmatch $pattern }
        }

        if ($Original.Count -ne $Sanitized.Count) {
            Set-Content -Path $file.FullName -Value $Sanitized
            Add-Content $SanitizeLog "[$Branch] Sanitized: $($file.FullName)"
        }
    }

    # ================= VERIFICATION =================

    $Leaks = Get-ChildItem -Recurse -Filter "primary.auto.tfvars" -File |
        Select-String -Pattern 'client_id\s*=|client_secret\s*=|tenant_id\s*=|subscription_id\s*='

    if ($Leaks) {
        Write-Error "❌ Secrets still found in $Branch. Aborting."
        $Leaks | ForEach-Object {
            Add-Content $SanitizeLog "[$Branch] LEAK: $($_.Path):$($_.LineNumber)"
        }
        exit 1
    }

    # ================= COMMIT =================

    git add . | Out-Null
    git commit -m "Initial commit (sanitized for branch $Branch)" | Out-Null
    Add-Content $HistoryLog "[$Branch] History reset to single clean commit"

    # Replace original branch
    git branch -D $Branch | Out-Null
    git branch -m $Branch | Out-Null

    # ================= PUSH CONFIRM =================

    Write-Host ""
    $confirm = Read-Host "Do you want to PUSH branch '$Branch' to origin? (yes/no)"
    if ($confirm -eq "yes") {
        $confirm2 = Read-Host "⚠️  FINAL CONFIRM — This rewrites remote history. Type YES to continue"
        if ($confirm2 -eq "YES") {
            git push origin $Branch --force
            Write-Host "✅ Pushed $Branch"
        } else {
            Write-Host "Skipped push for $Branch"
        }
    } else {
        Write-Host "Skipped push for $Branch"
    }
}

Write-Host "`n=== DONE ==="
Write-Host "Sanitize log : $SanitizeLog"
Write-Host "History log  : $HistoryLog"
