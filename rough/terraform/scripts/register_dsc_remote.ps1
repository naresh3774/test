param (
    [string]$AutomationAccountName,
    [string]$AutomationResourceGroup,
    [string]$NodeConfigurationName
)

Write-Host "Running on VM to register for DSC: $NodeConfigurationName"

Register-AzAutomationDscNode `
    -AzureVMName $env:COMPUTERNAME `
    -NodeConfigurationName $NodeConfigurationName `
    -AzureVMResourceGroup (Get-AzVM -Name $env:COMPUTERNAME).ResourceGroupName `
    -AutomationAccountName $AutomationAccountName `
    -ResourceGroupName $AutomationResourceGroup
