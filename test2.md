
```
C:\Users\NareshSharma\workspace\terraform_cleanup\
│
├─ full-sanitize-reset.ps1   ← script lives here (GOOD)
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
pwsh -NoProfile -ExecutionPolicy Bypass -File .\full-sanitize-reset.ps1
```

```
git log --oneline
# ONE commit only

git branch
# main

git grep client_secret
# no output
```

```
git grep client_id
git grep client_secret
git grep tenant_id
git grep subscription_id
# ALL SHOULD RETURN NOTHING
```



```
git rev-parse --is-inside-work-tree
```
Push with:
```
git push --force origin main
git push --force --prune origin "+refs/heads/*"
git push --force --tags
```
