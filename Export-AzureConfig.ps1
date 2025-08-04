# Set your target resource group
$resourceGroup = "your-resource-group-name"

# Create timestamped output file
$outputFile = "AzureConfigAudit_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss")

# Start the file clean
"" | Out-File -FilePath $outputFile -Encoding utf8

Function Write-Log {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp | $message" | Out-File -FilePath $outputFile -Append
}

# App Services
Write-Log "`n📦 App Services (Web Apps) Configuration"
$webApps = az webapp list --resource-group $resourceGroup --query "[].name" -o tsv
foreach ($app in $webApps) {
    Write-Log "`n🔷 App Service: $app"
    az webapp config show --name $app --resource-group $resourceGroup --output json | Out-File -Append $outputFile
    Write-Log "`n🔹 App Settings:"
    az webapp config appsettings list --name $app --resource-group $resourceGroup --output json | Out-File -Append $outputFile
}

# Storage Accounts
Write-Log "`n🗃 Storage Accounts Configuration"
$storageAccounts = az storage account list --resource-group $resourceGroup --query "[].name" -o tsv
foreach ($storage in $storageAccounts) {
    Write-Log "`n🔷 Storage Account: $storage"
    az storage account show --name $storage --resource-group $resourceGroup --output json | Out-File -Append $outputFile
    Write-Log "`n🔹 Network Rules:"
    az storage account network-rule list --account-name $storage --resource-group $resourceGroup --output json | Out-File -Append $outputFile
}

# SQL Servers
Write-Log "`n🧠 SQL Servers Configuration"
$sqlServers = az sql server list --resource-group $resourceGroup --query "[].name" -o tsv
foreach ($sql in $sqlServers) {
    Write-Log "`n🔷 SQL Server: $sql"
    az sql server show --name $sql --resource-group $resourceGroup --output json | Out-File -Append $outputFile
    Write-Log "`n🔹 Firewall Rules:"
    az sql server firewall-rule list --name $sql --resource-group $resourceGroup --output json | Out-File -Append $outputFile
}

# Key Vaults
Write-Log "`n🔐 Key Vaults Configuration"
$keyVaults = az keyvault list --resource-group $resourceGroup --query "[].name" -o tsv
foreach ($kv in $keyVaults) {
    Write-Log "`n🔷 Key Vault: $kv"
    az keyvault show --name $kv --resource-group $resourceGroup --output json | Out-File -Append $outputFile
    Write-Log "`n🔹 Secrets:"
    az keyvault secret list --vault-name $kv --query "[].id" -o json | Out-File -Append $outputFile
}

# Virtual Networks
Write-Log "`n🌐 Virtual Networks and Subnets"
$vnets = az network vnet list --resource-group $resourceGroup --query "[].name" -o tsv
foreach ($vnet in $vnets) {
    Write-Log "`n🔷 VNet: $vnet"
    az network vnet show --name $vnet --resource-group $resourceGroup --output json | Out-File -Append $outputFile
    Write-Log "`n🔹 Subnets:"
    az network vnet subnet list --vnet-name $vnet --resource-group $resourceGroup --output json | Out-File -Append $outputFile
}

Write-Host "`n✅ Config export completed."
Write-Host "📄 Output saved to: $outputFile" -ForegroundColor Green
