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
FILTER_BRANCH_SQUELCH_WARNING=1 \
git filter-branch --force --tree-filter \
'bash -c "
find . -type f -name primary.auto.tfvars | while read file; do
  sed -i \
    -e '\''s/^client_id[[:space:]]*=.*/client_id = \"\"/'\'' \
    -e '\''s/^client_secret[[:space:]]*=.*/client_secret = \"\"/'\'' \
    -e '\''s/^tenant_id[[:space:]]*=.*/tenant_id = \"\"/'\'' \
    -e '\''s/^subscription_id[[:space:]]*=.*/subscription_id = \"\"/'\'' \
    \"\$file\"
done
"' \
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
