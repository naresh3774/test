# =========================================================
# FINAL HISTORY RESET — GUARANTEED SINGLE COMMIT
# SCRIPT STAYS OUTSIDE REPO
# =========================================================

Write-Host "🔥 Resetting git history to a single clean commit"

# Ensure we are inside repo
git rev-parse --is-inside-work-tree 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Run this script FROM INSIDE the repo directory."
    exit 1
}

# Disable pager
git config core.pager cat

# ---------------------------------------------------------
# STEP 1: CREATE ORPHAN BRANCH (NO HISTORY)
# ---------------------------------------------------------
git checkout --orphan CLEAN_START

# ---------------------------------------------------------
# STEP 2: REMOVE ALL FILES FROM INDEX ONLY
# (do NOT delete working tree)
# ---------------------------------------------------------
git rm -rf --cached . 2>$null

# ---------------------------------------------------------
# STEP 3: ADD ALL CURRENT FILES (SANITIZED)
# ---------------------------------------------------------
git add .

# ---------------------------------------------------------
# STEP 4: CREATE SINGLE INITIAL COMMIT
# ---------------------------------------------------------
git commit -m "Initial commit (sanitized)"

# ---------------------------------------------------------
# STEP 5: FORCE main TO POINT HERE
# ---------------------------------------------------------
git branch -M main
git checkout main

# ---------------------------------------------------------
# STEP 6: VERIFY
# ---------------------------------------------------------
Write-Host "`n✅ FINAL STATE"
git log --oneline
git branch

Write-Host "`n🔍 Verifying secrets are gone (expect NO output):"
git grep client_id
git grep client_secret
git grep tenant_id
git grep subscription_id

Write-Host "`n🛑 DONE — NO PUSH PERFORMED"
Write-Host "👉 If git log shows ONE commit, you are safe to push."
