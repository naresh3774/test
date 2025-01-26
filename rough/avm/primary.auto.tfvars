###################################################################################
## NEW Stack Configuration List
###################################################################################
#########################################
## Azure Cloud Authentication Variables
#########################################
subscription_id = ""
tenant_id       = ""
client_id       = ""
client_secret   = ""

#########################################
## General Settings Variables
#########################################
global_settings = {
  default_region = "primary_region"
  prefixes       = ["avm", "nonprod"]
  environment    = "nonprod"
  regions = {
    primary_region   = "eastus"
    secondary_region = "eastus 2"
  }
  use_slug     = true
  inherit_tags = true
  tags = {
    Organization        = "NELLC"
    Application_Team    = "AVM"
    Workload            = "Fast Speed"
    Environment         = "nonprod"
    Stage               = "DEV"
    Data_Classification = "Personal"
  }
}


#########################################
## Data Sources
#########################################
data_sources = {

  # resource_groups = {
  #   rg-web = {
  #     name               = "rg-web"
  #     location           = "East US"
  #     resource_groups_id = "/subscriptions/4eb539ed-b133-48f0-a763-688d923a81d2/resourceGroups/rg-web"
  #     tags = {
  #       Purpose = "devops"
  #     }
  #   }
  # }
}

# Resource Group
resource_group_name = "shrd"
location            = "East US"

# virtual network
vnet_name           = "my-vnet"
address_space  = ["10.0.0.0/16"]
