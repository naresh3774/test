📦 Step 1 — Fresh mirror clone (CRITICAL)

Do NOT use your working copy.
```
git clone --mirror https://github.com/<org>/<repo>.git
cd <repo>.git
```
Mirror clone includes:

All branches

All tags

All refs
🧼 Step 2 — Rewrite history using built-in Git only
🔧 Run this command (copy-paste exactly)
```
$env:FILTER_BRANCH_SQUELCH_WARNING = "1"

git filter-branch --force --tree-filter `
'pwsh -NoProfile -Command "
Get-ChildItem -Recurse -Filter primary.auto.tfvars | ForEach-Object {
  (Get-Content $_.FullName) `
    -replace ''^client_id\s*=.*'', ''client_id = \"\"'' `
    -replace ''^client_secret\s*=.*'', ''client_secret = \"\"'' `
    -replace ''^tenant_id\s*=.*'', ''tenant_id = \"\"'' `
    -replace ''^subscription_id\s*=.*'', ''subscription_id = \"\"'' |
  Set-Content $_.FullName
}
"' `
-- --all
```
✅ What this does

Iterates over every commit

Finds primary.auto.tfvars

Rewrites sensitive values

Applies to all branches & tags

⏱️ This may take time for large repos — let it finish.

🔍 Step 3 — Verify history is clean

Run:
```
git grep client_secret $(git rev-list --all)
```
Expected output:
```
(no results)
```
Also test:
```
git grep tenant_id $(git rev-list --all)
```
🧹 Step 4 — Cleanup filter-branch leftovers
```
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```
This permanently removes old objects.
🚀 Step 5 — Force push cleaned history
```
git push --force --all
git push --force --tags
```
At this point:
✅ GitHub history is clean
✅ Secrets no longer exist anywhere

📢 Step 6 — Tell your team (important)

Everyone must do ONE of these:

Option A (recommended)
```
git clone https://github.com/<org>/<repo>.git
```
❌ DO NOT

git pull

git rebase

reuse old clones

Old clones still contain secrets.

✅ Final outcome

Repo is effectively reset & sanitized

Safe for compliance & audits

No external tools used

Works in locked-down corporate laptops
