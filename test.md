az resource show \
--name <workspace-name> \
--resource-group <rg> \
--resource-type Microsoft.Databricks/workspaces \
> workspace_arm_config.json



pip install databricks-cli

databricks configure --token

Host: https://adb-xxxx.azuredatabricks.us
Token: <your-token>

databricks auth login --host https://adb-xxxx.azuredatabricks.us


databricks workspace ls /



.\backup-databricks.ps1
