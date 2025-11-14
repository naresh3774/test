# Quick Network Connectivity Verification for AKS
# This script checks route table, DNS, and basic connectivity issues

Write-Host "🔍 AKS Network Connectivity Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$firewallName = "avd-nonprod-fw"
$firewallRG = "avd-nonprd-rg-network"
$vnetName = "avd-nonprd-vnet-shrd"
$aksSubnetName = "aks-subnet"
$vnetRG = "avd-nonprd-rg-network"

Write-Host "🌐 Step 1: Checking route table association..." -ForegroundColor Yellow
$routeTable = az network vnet subnet show --vnet-name $vnetName --name $aksSubnetName --resource-group $vnetRG --query "routeTable.id" -o tsv

if ($routeTable) {
    Write-Host "✅ Route table associated: $routeTable" -ForegroundColor Green
    
    # Check routes in the route table
    $routeTableName = ($routeTable -split '/')[-1]
    $routeTableRG = ($routeTable -split '/')[4]
    Write-Host "📋 Routes in route table:"
    az network route-table route list --route-table-name $routeTableName --resource-group $routeTableRG --output table
} else {
    Write-Host "❌ No route table associated with AKS subnet!" -ForegroundColor Red
    Write-Host "🔧 Fix: Associate route table with AKS subnet"
}

Write-Host "`n🌍 Step 2: Checking DNS configuration..." -ForegroundColor Yellow
$vnetDns = az network vnet show --name $vnetName --resource-group $vnetRG --query "dhcpOptions.dnsServers" -o tsv

if ($vnetDns) {
    Write-Host "📋 Custom DNS servers configured: $vnetDns" -ForegroundColor Yellow
    Write-Host "⚠️ Ensure these DNS servers can resolve package repositories" -ForegroundColor Yellow
} else {
    Write-Host "✅ Using Azure default DNS (168.63.129.16)" -ForegroundColor Green
}

Write-Host "`n🔥 Step 3: Checking firewall status..." -ForegroundColor Yellow

# First fix Azure CLI extension warning
az config set extension.dynamic_install_allow_preview=true 2>$null

# Check if firewall exists
try {
    $firewallExists = az network firewall show --name $firewallName --resource-group $firewallRG --query "name" -o tsv 2>$null
    
    if ($firewallExists) {
        Write-Host "✅ Firewall exists: $firewallExists" -ForegroundColor Green
        
        # Get firewall details
        $firewallState = az network firewall show --name $firewallName --resource-group $firewallRG --query "provisioningState" -o tsv 2>$null
        $firewallIP = az network firewall show --name $firewallName --resource-group $firewallRG --query "ipConfigurations[0].properties.privateIPAddress" -o tsv 2>$null
        
        Write-Host "📋 Firewall status: $firewallState" -ForegroundColor Cyan
        Write-Host "📋 Firewall private IP: $firewallIP" -ForegroundColor Cyan
        
        if (-not $firewallIP) {
            Write-Host "⚠️ Could not retrieve firewall private IP - checking public IP instead..." -ForegroundColor Yellow
            $publicIP = az network firewall show --name $firewallName --resource-group $firewallRG --query "ipConfigurations[0].properties.publicIPAddress.id" -o tsv 2>$null
            if ($publicIP) {
                $publicIPName = ($publicIP -split '/')[-1]
                $publicIPAddress = az network public-ip show --name $publicIPName --resource-group $firewallRG --query "ipAddress" -o tsv 2>$null
                Write-Host "📋 Firewall public IP: $publicIPAddress" -ForegroundColor Cyan
            }
        }
        
        # Check firewall rules quickly
        Write-Host "📋 Checking firewall rule collections..."
        $appRules = az network firewall application-rule list --firewall-name $firewallName --resource-group $firewallRG --query "length(@)" -o tsv 2>$null
        $netRules = az network firewall network-rule list --firewall-name $firewallName --resource-group $firewallRG --query "length(@)" -o tsv 2>$null
        
        Write-Host "   Application rule collections: $appRules" -ForegroundColor Cyan
        Write-Host "   Network rule collections: $netRules" -ForegroundColor Cyan
        
    } else {
        Write-Host "❌ CRITICAL: Firewall '$firewallName' not found in resource group '$firewallRG'!" -ForegroundColor Red
        Write-Host "🔧 Verify firewall name and resource group are correct" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Error checking firewall: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "🔧 Check Azure CLI login and permissions" -ForegroundColor Yellow
}

Write-Host "`n🌐 Step 4: Checking NSG rules on AKS subnet..." -ForegroundColor Yellow
$nsgId = az network vnet subnet show --vnet-name $vnetName --name $aksSubnetName --resource-group $vnetRG --query "networkSecurityGroup.id" -o tsv

if ($nsgId) {
    Write-Host "⚠️ NSG attached to AKS subnet: $nsgId" -ForegroundColor Yellow
    $nsgName = ($nsgId -split '/')[-1]
    $nsgRG = ($nsgId -split '/')[4]
    Write-Host "📋 NSG rules that might block traffic:"
    az network nsg rule list --nsg-name $nsgName --resource-group $nsgRG --query "[?direction=='Outbound' && access=='Deny']" --output table
} else {
    Write-Host "✅ No NSG attached to AKS subnet (default allow)" -ForegroundColor Green
}

Write-Host "`n🔍 Step 5: Checking service endpoints..." -ForegroundColor Yellow
$serviceEndpoints = az network vnet subnet show --vnet-name $vnetName --name $aksSubnetName --resource-group $vnetRG --query "serviceEndpoints[].service" -o tsv

if ($serviceEndpoints) {
    Write-Host "📋 Service endpoints enabled: $serviceEndpoints" -ForegroundColor Cyan
} else {
    Write-Host "ℹ️ No service endpoints enabled" -ForegroundColor Blue
}

Write-Host "`n📊 Step 6: Summary of potential issues..." -ForegroundColor Yellow
Write-Host "===========================================" -ForegroundColor Cyan

if (-not $routeTable) {
    Write-Host "❌ CRITICAL: No route table associated with AKS subnet" -ForegroundColor Red
}

if ($nsgId) {
    Write-Host "⚠️ WARNING: NSG attached - check for blocking rules" -ForegroundColor Yellow
}

if ($vnetDns) {
    Write-Host "⚠️ WARNING: Custom DNS - ensure it can resolve package repos" -ForegroundColor Yellow
}

Write-Host "`n🔧 Recommended fixes if VMExtension still fails:" -ForegroundColor Cyan
Write-Host "1. Ensure route table routes 0.0.0.0/0 to firewall IP ($firewallIP)" -ForegroundColor White
Write-Host "2. Check firewall rules are in 'Allow' collections with correct priority" -ForegroundColor White
Write-Host "3. Verify no NSG rules blocking outbound HTTP/HTTPS" -ForegroundColor White
Write-Host "4. Consider adding service endpoints for Microsoft.ContainerRegistry" -ForegroundColor White

Write-Host "`n✅ Network verification complete!" -ForegroundColor Green