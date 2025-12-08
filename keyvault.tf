# Data source for current Azure client configuration
data "azurerm_client_config" "current" {}

# Azure Key Vault
resource "azurerm_key_vault" "kv" {
  name                        = "fsappsi-nonprd-kv-shrd"
  location                    = azurerm_resource_group.aks.location
  resource_group_name         = azurerm_resource_group.aks.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"

  # Disable public network access
  public_network_access_enabled = false

  # Network ACLs
  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
  }

  tags = {
    environment = "nonprd"
    project     = "fsappsi"
  }
}

# Private DNS Zone for Key Vault
resource "azurerm_private_dns_zone" "kv" {
  name                = "privatelink.vaultcore.usgovcloudapi.net"
  resource_group_name = azurerm_resource_group.aks.name

  tags = {
    environment = "nonprd"
    project     = "fsappsi"
  }
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "kv" {
  name                  = "kv-dns-link"
  resource_group_name   = azurerm_resource_group.aks.name
  private_dns_zone_name = azurerm_private_dns_zone.kv.name
  virtual_network_id    = azurerm_virtual_network.aks.id
  registration_enabled  = false

  tags = {
    environment = "nonprd"
    project     = "fsappsi"
  }
}

# Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "kv" {
  name                = "fsappsi-nonprd-kv-pe"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  subnet_id           = azurerm_subnet.pep.id

  private_service_connection {
    name                           = "kv-private-connection"
    private_connection_resource_id = azurerm_key_vault.kv.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "kv-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.kv.id]
  }

  tags = {
    environment = "nonprd"
    project     = "fsappsi"
  }
}

# Key Vault Access Policy for AKS Managed Identity
resource "azurerm_key_vault_access_policy" "aks_identity" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.aks_uami.principal_id

  secret_permissions = [
    "Get",
    "List"
  ]

  certificate_permissions = [
    "Get",
    "List"
  ]
}

# Key Vault Access Policy for Current User/Service Principal (for admin access)
resource "azurerm_key_vault_access_policy" "admin" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "Purge"
  ]

  certificate_permissions = [
    "Get",
    "List",
    "Create",
    "Update",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "Purge",
    "Import"
  ]

  key_permissions = [
    "Get",
    "List",
    "Create",
    "Update",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "Purge"
  ]
}
