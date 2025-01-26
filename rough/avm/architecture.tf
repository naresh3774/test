module "avm-res-resources-resourcegroup" {
  source   = "Azure/avm-res-resources-resourcegroup/azurerm"
  version  = "0.2.0"
  name     = "${var.global_settings.prefixes[0]}-rg-${var.global_settings.environment}-${var.resource_group_name}"
  location = var.global_settings.regions.primary_region
  tags     = var.global_settings.tags
}

