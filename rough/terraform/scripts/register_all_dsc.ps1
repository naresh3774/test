param (
  [string] $vmNames,
  [string] $vmRG,
  [string] $aan,
  [string] $aarg
)

$vmList = $vmNames.Split(',')

foreach ($vm in $vmList) {
    Write-Host "Waiting for VM: $vm to be in running state..."
    do {
        $status = (Get-AzVM -Name $vm -ResourceGroupName $vmRG -Status).Statuses[-1].Code
        Start-Sleep -Seconds 10
    } while ($status -ne "PowerState/running")

    $NodeDscCfg = "Gis20CopyScripts." + $vm

    Write-Host "Registering $vm for DSC..."
    Register-AzAutomationDscNode `
        -AzureVMName $vm `
        -NodeConfigurationName $NodeDscCfg `
        -AzureVMResourceGroup $vmRG `
        -AutomationAccountName $aan `
        -ResourceGroupName $aarg
}