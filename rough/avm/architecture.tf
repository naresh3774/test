# Resource_group
module "avm-res-resources-resourcegroup" {
  source   = "Azure/avm-res-resources-resourcegroup/azurerm"
  version  = "0.2.0"
  name     = "${var.global_settings.prefixes[0]}-rg-${var.global_settings.environment}-${var.resource_group_name}"
  location = var.global_settings.regions.primary_region
  tags     = var.global_settings.tags
}

# virtual network
module "vnet" {
  source              = "Azure/avm-res-network-virtualnetwork/azurerm"
  version             = "0.7.1"
  name                = "${var.global_settings.prefixes[0]}-vnet-${var.global_settings.environment}-${var.vnet_name}"
  # enable_telemetry    = true
  resource_group_name = "${var.global_settings.prefixes[0]}-rg-${var.global_settings.environment}-${var.resource_group_name}"
  location            = var.global_settings.regions.primary_region

  address_space = var.address_space
}


