# register_dsc_nodes
resource "null_resource" "register_dsc_nodes" {
  count = length(var.dsc_config.vm_names)

  provisioner "local-exec" {
    command = <<-EOT
      $clientId = az keyvault secret show --vault-name ${var.dsc_config.keyvault_name} --name client-id --query value -o tsv
      $clientSecret = az keyvault secret show --vault-name ${var.dsc_config.keyvault_name} --name client-secret --query value -o tsv
      $tenantId = az keyvault secret show --vault-name ${var.dsc_config.keyvault_name} --name tenant-id --query value -o tsv

      az login --service-principal -u $clientId -p $clientSecret --tenant $tenantId

      az vm run-command invoke `
        --command-id RunPowerShellScript `
        --name ${var.dsc_config.vm_names[count.index]} `
        --resource-group ${var.dsc_config.vm_resource_group} `
        --scripts @scripts/register_dsc_remote.ps1 `
        --parameters `
          "AutomationAccountName=${var.dsc_config.automation_account}" `
          "AutomationResourceGroup=${var.dsc_config.automation_resource_rg}" `
          "NodeConfigurationName=Gis20CopyScripts.${var.dsc_config.vm_names[count.index]}" `
          "VmName=${var.dsc_config.vm_names[count.index]}" `
          "VmResourceGroup=${var.dsc_config.vm_resource_group}" `
          "KeyVaultName=${var.dsc_config.keyvault_name}"
    EOT

    interpreter = ["PowerShell", "-Command"]
  }
}

# install_dsc_prerequisites
resource "null_resource" "install_dsc_prerequisites" {
  count = length(var.dsc_config.vm_names)

  provisioner "local-exec" {
    command = <<-EOT
      $clientId = az keyvault secret show --vault-name ${var.dsc_config.keyvault_name} --name client-id --query value -o tsv
      $clientSecret = az keyvault secret show --vault-name ${var.dsc_config.keyvault_name} --name client-secret --query value -o tsv
      $tenantId = az keyvault secret show --vault-name ${var.dsc_config.keyvault_name} --name tenant-id --query value -o tsv

      az login --service-principal -u $clientId -p $clientSecret --tenant $tenantId

      az vm run-command invoke `
        --command-id RunPowerShellScript `
        --name ${var.dsc_config.vm_names[count.index]} `
        --resource-group ${var.dsc_config.vm_resource_group} `
        --scripts @scripts/prerequisites.ps1 `
        --parameters `
          "VmName=${var.dsc_config.vm_names[count.index]}" `
          "VmResourceGroup=${var.dsc_config.vm_resource_group}"
    EOT

    interpreter = ["PowerShell", "-Command"]
  }

  depends_on = [null_resource.register_dsc_nodes]
}
