# Define the input variable:

variable "dsc_config" {
  description = "DSC configuration for Azure Automation registration"
  type = object({
    vm_names               = list(string)
    vm_resource_group      = string
    automation_account     = string
    automation_resource_rg = string
  })
}