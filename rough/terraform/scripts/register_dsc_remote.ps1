param(
    [string]$AutomationAccountName,
    [string]$AutomationResourceGroup,
    [string]$NodeConfigurationName,
    [string]$VmName,
    [string]$VmResourceGroup,
    [string]$KeyVaultName
)

# Fetch credentials from Key Vault
$AppId = az keyvault secret show --vault-name $KeyVaultName --name "sp-client-id" --query value -o tsv
$Password = az keyvault secret show --vault-name $KeyVaultName --name "sp-client-secret" --query value -o tsv
$Tenant = az keyvault secret show --vault-name $KeyVaultName --name "sp-tenant-id" --query value -o tsv

# Login with SP
az login --service-principal -u $AppId -p $Password --tenant $Tenant

# Run DSC registration
Register-AzAutomationDscNode `
    -AzureVMName $VmName `
    -NodeConfigurationName $NodeConfigurationName `
    -AzureVMResourceGroup $VmResourceGroup `
    -AutomationAccountName $AutomationAccountName `
    -ResourceGroupName $AutomationResourceGroup
