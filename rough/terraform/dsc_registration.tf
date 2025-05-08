resource "null_resource" "register_dsc_nodes" {
  count = length(var.dsc_config.vm_names)

  provisioner "local-exec" {
    command = "az vm run-command invoke --command-id RunPowerShellScript --name ${element(var.dsc_config.vm_names, count.index)} --resource-group ${var.dsc_config.vm_resource_group} --scripts @scripts/register_dsc_remote.ps1 --parameters \"AutomationAccountName=${var.dsc_config.automation_account}\" \"AutomationResourceGroup=${var.dsc_config.automation_resource_rg}\" \"NodeConfigurationName=Gis20CopyScripts.${element(var.dsc_config.vm_names, count.index)}\""
  }

  triggers = {
    vm = element(var.dsc_config.vm_names, count.index)
  }
}


