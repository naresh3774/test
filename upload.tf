# fetch the storage account key dynamically using the azurerm_storage_account data block.

data "azurerm_storage_account" "example" {
  name                = "examplestorage"
  resource_group_name = "example-rg"
}

output "primary_access_key" {
  value = data.azurerm_storage_account.example.primary_access_key
}



## Download helloworld.ps1 on the Source VM from its source location (e.g., a web URL or file share).
resource "azurerm_virtual_machine_extension" "download_script" {
  name                 = "download-script"
  virtual_machine_id   = azurerm_virtual_machine.source_vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"Invoke-WebRequest -Uri '<SOURCE_URL>' -OutFile 'C:\\temp\\helloworld.ps1'\""
  })
}

## Upload helloworld.ps1 to Azure Blob Storage
resource "azurerm_virtual_machine_extension" "upload_script" {
  name                 = "upload-script"
  virtual_machine_id   = azurerm_virtual_machine.source_vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = <<EOF
    "powershell -ExecutionPolicy Unrestricted -Command \"
      $storageAccountName = 'azurestorageaccount';
      $storageAccountKey = '<STORAGE_ACCOUNT_KEY>';
      $destinationUri = 'https://azurestorageaccount.blob.core.windows.net/files/helloworld.ps1';
      azcopy login --account-name $storageAccountName --account-key $storageAccountKey;
      azcopy copy 'C:\\temp\\helloworld.ps1' $destinationUri;
    "
    EOF
  })
}

### Execute the Script on the Target VM
resource "azurerm_virtual_machine_extension" "execute_script" {
  name                 = "execute-script"
  virtual_machine_id   = azurerm_virtual_machine.target_vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    fileUris         = ["https://azurestorageaccount.blob.core.windows.net/files/helloworld.ps1"]
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -File helloworld.ps1"
  })
}
