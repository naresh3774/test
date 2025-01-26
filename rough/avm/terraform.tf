terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.71.0"
    }
  }
  required_version = ">= 1.5.4"

  backend "azurerm" {
    resource_group_name  = "tfstate-rg-shared"
    storage_account_name = "tfstatestgshared"
    container_name       = "tfstate-shared"
    key                  = "test/avm.test.tfstate"
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
  alias                      = "vhub"
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
  client_id                  = var.client_id
  client_secret              = var.client_secret
  tenant_id                  = var.tenant_id
  subscription_id            = var.subscription_id
}
