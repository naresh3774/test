resource "null_resource" "register_dsc_nodes" {
  count = length(var.dsc_config.vm_names)

  provisioner "local-exec" {
    command = "az login --service-principal -u $(az keyvault secret show --vault-name ${var.dsc_config.keyvault_name} --name client-id --query value -o tsv) -p $(az keyvault secret show --vault-name ${var.dsc_config.keyvault_name} --name client-secret --query value -o tsv) --tenant $(az keyvault secret show --vault-name ${var.dsc_config.keyvault_name} --name tenant-id --query value -o tsv) && az vm run-command invoke --command-id RunPowerShellScript --name ${var.dsc_config.vm_names[count.index]} --resource-group ${var.dsc_config.vm_resource_group} --scripts @scripts/register_dsc_remote.ps1 --parameters \"AutomationAccountName=${var.dsc_config.automation_account}\" \"AutomationResourceGroup=${var.dsc_config.automation_resource_rg}\" \"NodeConfigurationName=Gis20CopyScripts.${var.dsc_config.vm_names[count.index]}\" \"VmName=${var.dsc_config.vm_names[count.index]}\" \"VmResourceGroup=${var.dsc_config.vm_resource_group}\" \"KeyVaultName=${var.dsc_config.keyvault_name}\""
    interpreter = ["PowerShell", "-Command"]
  }
}

