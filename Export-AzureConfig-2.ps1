# Set your resource group
$resourceGroup = "your-resource-group-name"

# Timestamped output file names
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$jsonOutputFile = "full_config_$timestamp.json"
$hclOutputFile = "terraform_skeleton_$timestamp.tf"

# Initialize files
@() | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonOutputFile -Encoding utf8
"" | Out-File -FilePath $hclOutputFile -Encoding utf8

# Get all resources in the resource group
$resources = az resource list --resource-group $resourceGroup | ConvertFrom-Json

foreach ($resource in $resources) {
    $id = $resource.id
    $type = $resource.type
    $name = $resource.name
    $location = $resource.location
    $provider = ($type -split "/")[0]
    $resourceType = ($type -split "/")[1]

    # Get full config
    $config = az resource show --ids $id | ConvertFrom-Json
    $config | ConvertTo-Json -Depth 10 | Out-File -Append -FilePath $jsonOutputFile -Encoding utf8

    # Create Terraform resource type format
    $tfResourceType = $type.Replace("Microsoft.", "azurerm_").Replace("/", "_").ToLower()

    # Basic Terraform HCL skeleton
    $hcl = @"
resource "$tfResourceType" "$name" {
  name     = "$name"
  location = "$location"
  # resource_group_name = "$resourceGroup"
  # other attributes to be filled
}
"@

    # Append to HCL file
    $hcl | Out-File -Append -FilePath $hclOutputFile -Encoding utf8
}

Write-Host "`n✅ JSON config exported to: $jsonOutputFile"
Write-Host "✅ Terraform HCL skeleton exported to: $hclOutputFile"
