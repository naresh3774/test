param(
  [string]$AutomationAccountName,
  [string]$AutomationResourceGroup,
  [string]$NodeConfigurationName,
  [string]$VmName,
  [string]$VmResourceGroup,
  [string]$KeyVaultName
)

# Import necessary modules
Import-Module Az.Accounts
Import-Module Az.Automation
Import-Module Az.KeyVault

# Login using SP credentials from Key Vault
$clientId = (az keyvault secret show --name "client-id" --vault-name $KeyVaultName --query "value" -o tsv)
$clientSecret = (az keyvault secret show --name "client-secret" --vault-name $KeyVaultName --query "value" -o tsv)
$tenantId = (az keyvault secret show --name "tenant-id" --vault-name $KeyVaultName --query "value" -o tsv)

az login --service-principal -u $clientId -p $clientSecret --tenant $tenantId | Out-Null

# Register VM with DSC
Register-AzAutomationDscNode `
  -ResourceGroupName $VmResourceGroup `
  -AutomationAccountName $AutomationAccountName `
  -AzureVMName $VmName `
  -NodeConfigurationName $NodeConfigurationName `
  -ConfigurationMode "ApplyAndAutoCorrect" `
  -RebootNodeIfNeeded $true `
  -ActionAfterReboot "ContinueConfiguration"
