resource "null_resource" "register_dsc_nodes" {
  provisioner "local-exec" {
    command = "pwsh ./scripts/register_all_dsc.ps1 -vmNames ${join(",", var.dsc_config.vm_names)} -vmRG ${var.dsc_config.vm_resource_group} -aan ${var.dsc_config.automation_account} -aarg ${var.dsc_config.automation_resource_rg}"
  }

  # Remove broken depends_on for now. Optionally wait on a known resource
  triggers = {
    always_run = "${timestamp()}"
  }
}

#  Optional: Safe Dependency Alternative

# If you know the name of one actual resource being created by CAF (e.g., a public IP or NIC), you can depend on that:

# depends_on = [
#   azurerm_network_interface.example_vm2_nic0
# ]
