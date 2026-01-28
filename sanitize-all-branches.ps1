# ----------------------------------------
# Full Repo Sanitization Script
# ----------------------------------------
# Run this from OUTSIDE the repo folder
# Example: C:\Users\NareshSharma\workspace\terraform_cleanup
# ----------------------------------------

param(
    [string]$RepoUrl = "git@github.com:YourOrg/Azure_Terraform_NonProduction.git",
    [string]$LocalPath = "Azure_Terraform_NonProduction",
    [string]$SanitizeLog = "sanitize_log.txt"
)

# Clear previous log
if (Test-Path $SanitizeLog) { Remove-Item $SanitizeLog }

# ----------------- 1. Clone fresh repo -----------------
Write-Host "Cloning repo to $LocalPath ..."
if (Test-Path $LocalPath) { Remove-Item -Recurse -Force $LocalPath }
git clone $RepoUrl $LocalPath

Set-Location $LocalPath

# ----------------- 2. Fetch all branches -----------------
Write-Host "Fetching all remote branches ..."
git fetch --all

$RemoteBranches = git branch -r | ForEach-Object { $_.Trim() } | Where-Object { $_ -notmatch 'HEAD' }

Write-Host "Found branches:"
$RemoteBranches

# ----------------- 3. Loop over each branch -----------------
foreach ($RemoteBranch in $RemoteBranches) {

    # Clean local branch name
    $Branch = $RemoteBranch -replace '^origin/', ''
    Write-Host "`nProcessing branch: $Branch"

    # Checkout remote branch locally
    git checkout -B $Branch $RemoteBranch

    # Create a temporary orphan branch for clean history
    $TempBranch = "${Branch}_SANITIZE_TEMP"
    git checkout --orphan $TempBranch

    # Remove all files (clean start)
    git rm -rf * | Out-Null

    # ----------------- 4. Copy files from original branch -----------------
    git checkout $Branch -- . 

    # ----------------- 5. Recursively sanitize primary.auto.tfvars -----------------
    $SensitivePatterns = @('client_id','client_secret','tenant_id','subscription_id')
    $TfvarsFiles = Get-ChildItem -Recurse -Filter "primary.auto.tfvars" -File

    foreach ($file in $TfvarsFiles) {
        $Original = Get-Content $file.FullName
        $Sanitized = @()

        for ($i = 0; $i -lt $Original.Count; $i++) {
            $line = $Original[$i]
            $lineUpdated = $line

            foreach ($pattern in $SensitivePatterns) {
                if ($line -match "^\s*$pattern\s*=") {
                    $lineUpdated = ($line -replace '=\s*".*"', '= ""')
                    Add-Content $SanitizeLog ("[$Branch] $($file.FullName): Line $($i+1) sanitized -> $lineUpdated")
                }
            }
            $Sanitized += $lineUpdated
        }

        # Write sanitized content back
        Set-Content -Path $file.FullName -Value $Sanitized
    }

    # ----------------- 6. Commit sanitized branch -----------------
    git add .
    git commit -m "Initial commit (sanitized for branch $Branch)" | Out-Null

    # ----------------- 7. Replace old branch with sanitized branch -----------------
    git branch -M $Branch

    # ----------------- 8. Optional: push per branch -----------------
    $PushChoice = Read-Host "Do you want to push branch '$Branch' to origin now? (yes/no)"
    if ($PushChoice -eq "yes") {
        git push origin $Branch --force
        Write-Host "Branch '$Branch' pushed successfully."
    } else {
        Write-Host "Branch '$Branch' not pushed. Verify locally first."
    }
}

Write-Host "`n✅ All branches processed. Logs saved in $SanitizeLog"
Write-Host "You can verify each branch locally before doing final push --all."
