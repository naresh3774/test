# Define your new IP ranges
$newIpRules = @(
    "192.168.0.0/24",
    "10.0.0.0/16"
)

# Loop through all subscriptions
$azSubs = Get-AzSubscription

foreach ($sub in $azSubs) {
    Set-AzContext -SubscriptionId $sub.Id

    $storageAccounts = Get-AzStorageAccount
    foreach ($account in $storageAccounts) {
        $resourceGroupName = $account.ResourceGroupName
        $storageAccountName = $account.StorageAccountName

        Write-Output "Updating IP rules for Storage Account: $storageAccountName in Subscription: $($sub.Name)"

        # Remove all existing IP rules and add new ones
        $ipRuleObjects = $newIpRules | ForEach-Object {
            New-Object -TypeName Microsoft.Azure.Commands.Management.Storage.Models.PSIpRule -ArgumentList $_, "Allow"
        }

        Update-AzStorageAccountNetworkRuleSet `
            -ResourceGroupName $resourceGroupName `
            -Name $storageAccountName `
            -IpRule $ipRuleObjects `
            -DefaultAction Deny
    }
}
