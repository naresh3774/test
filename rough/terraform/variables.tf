variable "dsc_config" {
  type = object({
    vm_names               = list(string)
    vm_resource_group      = string
    automation_account     = string
    automation_resource_rg = string
    keyvault_name          = string
  })
}