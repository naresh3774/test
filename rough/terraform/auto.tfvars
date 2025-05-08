# Add this block to define your config:
dsc_config = {
  vm_names               = [
    "esri-nonprod-vm-fsazdevgis20001",
    "esri-nonprod-vm-fsazdevgis20002",
    "esri-nonprod-vm-fsazdevgis20003",
    "esri-nonprod-vm-fsazdevgis20004",
    "esri-nonprod-vm-fsazdevgis20005",
    "esri-nonprod-vm-fsazdevgis20012",
    "esri-nonprod-vm-fsazdevgis20013"
  ]
  vm_resource_group      = "esri-nonprod-rg-shrd"
  automation_account     = "auto-acc-nonprd-aa-automation"
  automation_resource_rg = "auto-acc-nonprd-rg-automation"
}
