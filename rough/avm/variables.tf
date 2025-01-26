###################################################################################
## Non Production Terraform Variable List
## Contributor: Naresh Sharma
## Version: 0.0.1
###################################################################################

###################################################################################
## Global Settings Variables
###################################################################################
variable "client_id" {}

variable "client_secret" {}

variable "tenant_id" {}

variable "subscription_id" {}

###################################################################################
## global_settings Variables
###################################################################################
variable "global_settings" {
  description = "Global settings for infrastructure configuration."
  type = object({
    default_region = string
    prefixes       = list(string)
    environment    = string
    regions = object({
      primary_region   = string
      secondary_region = string
    })
    use_slug     = bool
    inherit_tags = bool
    tags         = map(string)
  })
}


###################################################################################
## Resource Group Variables
###################################################################################
variable "resource_group_name" {
  description = "rg"
  # type        = string
  default = {}
}
variable "data_sources" {}


###################################################################################
## Networking Variables
###################################################################################
variable "vnet_name" {
  description = "The name of the Virtual Network."
  type        = string
}

variable "address_space" {
  description = "The address space for the Virtual Network."
  type        = list(string)
}

variable "subnet_configs" {
  description = "A list of subnet configurations, including name and address prefixes."
  type = list(object({
    name            = string
    address_prefixes = list(string)
  }))
}

#################################################
variable "tags" {
  description = "A mapping of tags to assign to resources."
  type        = map(string)
  default     = {}
}

variable "location" {
  description = "The Azure location where resources will be deployed."
  # type        = string
  default = {}
}

###################################################################################
## Storage Variables
###################################################################################
variable "storage_accounts" {
  description = ""
  default     = {}
}

# variable "storage" {
#   description = ""
#   default     = {}
# }

# ###################################################################################
# ## API Management Svc Variables
# ###################################################################################
# variable "apim" {
#   description = ""
#   default     = {}
# }

###################################################################################
## Security Variables
###################################################################################

variable "keyvaults" {
  description = ""
  default     = {}
}

variable "provider_azurerm_features_keyvault" {
  description = ""
  default     = {}
}

# variable "security" {
#   description = ""
#   default     = {}
# }

###################################################################################
## Monitoring Variables
###################################################################################

variable "webapp" {
  description = ""
  default     = {}
}

###################################################################################
## Database Variables
###################################################################################
variable "database" {
  description = ""
  default     = {}
}
###################################################################################
## Monitoring Variables
###################################################################################
variable "diagnostics" {
  description = ""
  default     = {}
}

# variable "log_analytics" {
#   description = "Configuration object - Log Analytics resources."
#   default     = {}
# }

# variable "workspace_resource_id" {
#   description = "Configuration object - Log Analytics resources."
#   default     = {}
# }

# variable "destination_resource_id" {
#   description = "Configuration object - Log Analytics resources."
#   default     = {}
# }
