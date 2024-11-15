# App Service Plan + Slots
resource "azurerm_app_service_plan" "asp" {
  name                = "tf-asp"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  kind = "Windows"
  reserved = false

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "app" {
  name                = "tf-app-lobex"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.asp.id

  https_only = true

  site_config {
    always_on = false
    dotnet_framework_version = "v5.0"
    http2_enabled = true
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "app" {
  app_service_id = azurerm_app_service.app.id
  subnet_id      = azurerm_subnet.vnet.id
}

resource "azurerm_app_service_slot" "app-staging" {
  name                = "staging"
  app_service_name    = azurerm_app_service.app.name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.asp.id

  https_only = true

  site_config {
    always_on = false
    dotnet_framework_version = "v5.0"
    http2_enabled = true
    websockets_enabled = false
  }
}

resource "azurerm_app_service_slot_virtual_network_swift_connection" "app-staging" {
  slot_name      = azurerm_app_service_slot.app-staging.name
  app_service_id = azurerm_app_service.app.id
  subnet_id      = azurerm_subnet.vnet.id
}