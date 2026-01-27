
```
C:\Users\NareshSharma\workspace\terraform_cleanup\
│
├─ sanitize_all_branches.ps1   ← script lives here (GOOD)
│
└─ Azure_Terraform_NonProduction\   ← will be created by script
```

You will start here:
```
cd C:\Users\NareshSharma\workspace\terraform_cleanup
```
```
git rev-parse --is-inside-work-tree
```
```
rm -Recurse -Force Azure_Terraform_NonProduction
```

```
pwsh -NoProfile -ExecutionPolicy Bypass -File .\sanitize_all_branches.ps1
```

```
# Switch to a branch
git checkout nonprod/elms

# Check the sensitive fields
git grep client_id
git grep client_secret
git grep tenant_id
git grep subscription_id
```

```
git push --force origin nonprod/elms
git push --force origin nonprod/aar
# repeat for all branches
```
