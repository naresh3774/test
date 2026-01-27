# =========================================================
# FINAL HISTORY RESET SCRIPT
# RUN FROM INSIDE THE REPO
# =========================================================

Write-Host "🚨 FINAL HISTORY RESET — LOCAL ONLY"
Write-Host "------------------------------------------------"

# ---- Safety: confirm inside git repo ----
git rev-parse --is-inside-work-tree 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Not inside a git repository. Abort."
    exit 1
}

# ---- Disable pager to avoid ':' hangs ----
git config core.pager cat

# ---- Show current state ----
Write-Host "`n📌 Current branch:"
git branch --show-current

Write-Host "`n📌 Current history (before):"
git log --oneline --decorate --max-count=10

# =========================================================
# STEP 1 — CREATE ORPHAN BRANCH (NO HISTORY)
# =========================================================
Write-Host "`n🔥 Creating orphan branch CLEAN_START..."
git checkout --orphan CLEAN_START

# =========================================================
# STEP 2 — REMOVE EVERYTHING FROM INDEX & WORKTREE
# =========================================================
Write-Host "🧹 Removing all tracked/untracked files..."
git reset --hard
git clean -fdx

# =========================================================
# STEP 3 — RESTORE SANITIZED FILES
# (working tree already has sanitized content)
# =========================================================
Write-Host "📦 Re-adding sanitized files..."
git add .

# =========================================================
# STEP 4 — CREATE SINGLE INITIAL COMMIT
# =========================================================
Write-Host "✅ Creating initial sanitized commit..."
git commit -m "Initial commit (sanitized)"

# =========================================================
# STEP 5 — DELETE ALL OTHER LOCAL BRANCHES
# =========================================================
Write-Host "`n🧹 Removing all old branches..."
git branch |
Where-Object { $_ -ne "CLEAN_START" } |
ForEach-Object {
    git branch -D $_
}

# =========================================================
# STEP 6 — RENAME CLEAN_START → main
# =========================================================
Write-Host "`n🔁 Renaming CLEAN_START to main..."
git branch -m main
git checkout main

# =========================================================
# STEP 7 — FINAL VERIFICATION
# =========================================================
Write-Host "`n✅ FINAL STATE"
Write-Host "-----------------------------"
git branch
git log --oneline

Write-Host "`n🔍 Verifying secrets are gone (should be EMPTY):"
git grep client_id
git grep client_secret
git grep tenant_id
git grep subscription_id

Write-Host "`n🛑 DONE — NO PUSH WAS PERFORMED"
Write-Host "👉 Review carefully, then push manually when ready."
