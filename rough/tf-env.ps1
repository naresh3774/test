# set_env.ps1

# Prompt user for environment
Write-Host "Please choose the environment:"
Write-Host "1. nonprod"
Write-Host "2. sandbox"
Write-Host "3. prod"

$choice = Read-Host "Enter the number corresponding to your environment"

# Map environment to Key Vault
switch ($choice) {
    1 {
        $envName = "nonprod"
        $keyVaultName = "ops-nonprod-kv"
    }
    2 {
        $envName = "sandbox"
        $keyVaultName = "ops-sandbox-kv"
    }
    3 {
        $envName = "prod"
        $keyVaultName = "ops-prod-kv"
    }
    default {
        Write-Host "❌ Invalid choice. Please select 1, 2, or 3."
        exit 1
    }
}

Write-Host "`n🔐 Logging into Azure with Managed Identity..."
az login --identity | Out-Null

Write-Host "🔎 Fetching secrets from Key Vault: $keyVaultName"

# Retrieve secrets
$clientId       = az keyvault secret show --vault-name $keyVaultName --name "client-id" --query value -o tsv
$clientSecret   = az keyvault secret show --vault-name $keyVaultName --name "client-secret" --query value -o tsv
$tenantId       = az keyvault secret show --vault-name $keyVaultName --name "tenant-id" --query value -o tsv
$subscriptionId = az keyvault secret show --vault-name $keyVaultName --name "subscription-id" --query value -o tsv

if (-not $clientId -or -not $clientSecret -or -not $tenantId -or -not $subscriptionId) {
    Write-Error "❌ One or more secrets are missing in Key Vault: $keyVaultName"
    exit 1
}

# Login using the Service Principal
az login --service-principal `
         --username $clientId `
         --password $clientSecret `
         --tenant $tenantId | Out-Null

az account set --subscription $subscriptionId

# Set Terraform environment variables
$env:ARM_CLIENT_ID       = $clientId
$env:ARM_CLIENT_SECRET   = $clientSecret
$env:ARM_TENANT_ID       = $tenantId
$env:ARM_SUBSCRIPTION_ID = $subscriptionId

Write-Host "`n✅ Environment '$envName' configured:"
Write-Host "  Key Vault: $keyVaultName"
Write-Host "  Subscription: $subscriptionId"
Write-Host "`n🚀 You can now run: terraform init && terraform apply"
