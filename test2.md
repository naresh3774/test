✅ How to use this script

Replace <org>/<repo> in $RepoUrl with your GitHub repo URL.

Make sure sanitize.ps1 exists in $WorkFolder (or same folder as full-cleanup.ps1).

Open PowerShell and run:
```
pwsh -NoProfile -File full-cleanup.ps1
```
Dry-run shows which files would be modified.

Type yes when prompted to proceed with full history rewrite.

After completion, verify output shows SUCCESS: No secrets found in history.

Push with:
```
git push --force --all
git push --force --tags
```
