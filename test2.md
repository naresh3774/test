```
pwsh -NoProfile -File sanitize-all-history.ps1
```

Push with:
```
git push --force --all
git push --force --tags
```
```
git branch | Where-Object { $_ -notmatch "fresh-start" } | ForEach-Object {
    git branch -D $_.Trim()
}
```

```
git for-each-ref --format="%(refname:short)" refs/heads/ |
Where-Object { $_ -ne "CLEAN_START" } |
ForEach-Object { git branch -D $_ }
```


```
git branch | Where-Object { $_ -ne "CLEAN_START" } | ForEach-Object { git branch -D $_ }
```


```
git branch | Where-Object { $_ -ne "CLEAN_START" } | ForEach-Object { git branch -D $_ }
```