# This is the actual null_resource using the local-exec provisioner:

resource "null_resource" "register_dsc_nodes" {
  provisioner "local-exec" {
    command = "pwsh ./scripts/register_all_dsc.ps1 -vmNames ${join(',', var.dsc_config.vm_names)} -vmRG ${var.dsc_config.vm_resource_group} -aan ${var.dsc_config.automation_account} -aarg ${var.dsc_config.automation_resource_rg}"
  }

  depends_on = [
    module.virtual_machines # Adjust if your module is named differently
  ]
}
