param (
    [string]$AutomationAccountName,
    [string]$AutomationResourceGroup,
    [string]$NodeConfigurationName
)

Import-Module Az.Accounts
Import-Module Az.Automation
Import-Module Az.Compute

$vm = Get-AzVM -Name $env:COMPUTERNAME

Write-Host "Registering VM '$($vm.Name)' with DSC Configuration '$NodeConfigurationName'"

Register-AzAutomationDscNode `
    -AzureVMName $vm.Name `
    -NodeConfigurationName $NodeConfigurationName `
    -AzureVMResourceGroup $vm.ResourceGroupName `
    -AutomationAccountName $AutomationAccountName `
    -ResourceGroupName $AutomationResourceGroup
