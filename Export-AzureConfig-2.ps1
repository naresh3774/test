# Set resource group
$resourceGroup = "your-resource-group-name"

# Timestamp for output folders/files
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$exportFolder = ".\cfg\$resourceGroup-$timestamp"
$jsonFile     = "$exportFolder\$resourceGroup-template.json"
$bicepFile    = "$exportFolder\$resourceGroup-template.bicep"
$zipFile      = "$resourceGroup-export-$timestamp.zip"
$hclFile      = "$exportFolder\$resourceGroup.tf"

# Create folder
New-Item -Path $exportFolder -ItemType Directory -Force | Out-Null

# Export ARM template of the resource group
Export-AzResourceGroup -ResourceGroupName $resourceGroup -IncludeComments -OutputFolder $exportFolder -Force

# Convert ARM JSON to Bicep
az bicep decompile --file $jsonFile --out $bicepFile

# Create basic HCL Terraform skeleton from ARM JSON
$json = Get-Content -Path $jsonFile | ConvertFrom-Json

$resources = $json.resources
$hclContent = ""

foreach ($res in $resources) {
    $type = $res.type.Replace("Microsoft.", "azurerm_").Replace("/", "_").ToLower()
    $name = $res.name
    $location = $res.location

    $hclContent += @"
resource "$type" "$name" {
  name     = "$name"
  location = "$location"
  # resource_group_name = "$resourceGroup"
  # other attributes...
}

"@
}

# Save HCL skeleton
$hclContent | Out-File -FilePath $hclFile -Encoding utf8

# Zip the export folder
Compress-Archive -Path "$exportFolder\*" -DestinationPath $zipFile -Force

# Output result
Write-Host "`n✅ Export complete:"
Write-Host "   ARM JSON:       $jsonFile"
Write-Host "   Bicep file:     $bicepFile"
Write-Host "   HCL skeleton:   $hclFile"
Write-Host "   ZIP archive:    $zipFile"
