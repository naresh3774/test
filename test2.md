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


Push with:
```
git push --force origin main
git push --force --prune origin "+refs/heads/*"
git push --force --tags
```
