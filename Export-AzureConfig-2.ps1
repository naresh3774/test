# Set your resource group
$resourceGroup = "your-resource-group-name"

# Create output folder with timestamp
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputFolder = ".\cfg\$resourceGroup-$timestamp"
New-Item -ItemType Directory -Force -Path $outputFolder | Out-Null

# Export ARM template
Export-AzResourceGroup `
  -ResourceGroupName $resourceGroup `
  -IncludeParameterDefaultValue `
  -Path "$outputFolder\$resourceGroup-template.json"

# Convert ARM to Bicep
az bicep decompile `
  --file "$outputFolder\$resourceGroup-template.json" `
  --out "$outputFolder\$resourceGroup-template.bicep"

# Create placeholder HCL folder
$hclFolder = "$outputFolder\hcl"
New-Item -ItemType Directory -Force -Path $hclFolder | Out-Null

# Convert each resource manually using Bicep knowledge (example below)
# NOTE: Automating full bicep-to-terraform conversion without external tools is not 1:1 exact, but here’s a basic example you can expand:
$bicepFile = Get-Content "$outputFolder\$resourceGroup-template.bicep" -Raw
$bicepFile | Out-File "$hclFolder\$resourceGroup-main.tf"

# Optionally zip everything
Compress-Archive -Path "$outputFolder\*" -DestinationPath "$outputFolder.zip"
