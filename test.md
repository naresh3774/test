az resource show \
--name <workspace-name> \
--resource-group <rg> \
--resource-type Microsoft.Databricks/workspaces \
> workspace_arm_config.json

Remove-Item Env:ARM_CLIENT_ID
Remove-Item Env:ARM_CLIENT_SECRET
Remove-Item Env:ARM_TENANT_ID
Remove-Item Env:ARM_ENVIRONMENT

pip install databricks-cli

databricks configure --token

Host: https://adb-xxxx.azuredatabricks.us
Token: <your-token>

databricks auth login --host https://adb-xxxx.azuredatabricks.us


databricks workspace ls /



.\backup-databricks.ps1
