The Azure_Terraform_NonProduction repository has been fully sanitized:

All sensitive values in primary.auto.tfvars (client_id, client_secret, tenant_id, subscription_id) are now blank.

Commit history has been rewritten — every branch now has a single clean commit.

The changes have been pushed to remote.

Important next steps for everyone:

Delete any old local copies of the repository — they contain old secrets and history.

Re-clone the repository fresh from remote:

git clone <repo_url>


Verify your branches locally before continuing any work.

Notes:

All branch names and deployment code remain the same.

A log of all sanitized changes is available (sanitize_log.txt) in the repo.

Any credentials previously stored locally or in old branches should be rotated.