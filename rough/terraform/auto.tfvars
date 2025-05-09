# Add this block to define your config:
dsc_config = {
  vm_names               = [
    "esri-01",
    "esri-02",
    "esri-03",
    "esri-04",
    "esri-05",
    "esri-12",
    "esri-13"
  ]
  vm_resource_group      = "esri-nonprod-rg-shrd"
  automation_account     = "auto-acc-nonprd-aa-automation"
  automation_resource_rg = "auto-acc-nonprd-rg-automation"
}
