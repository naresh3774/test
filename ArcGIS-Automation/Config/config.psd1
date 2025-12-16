@{
    Environment = "dev"               # dev | test | stage | prod
    IsHA        = $true               # true = multi-node HA
    IsPrimary   = $true               # true = primary node, false = HA secondary

    StorageAccountUrl = "https://esari-nonprd.blob.core.windows.net"
    StorageContainer  = "$web"
    NotebookInstallerBlob = "ArcGIS_Notebook_Server_11_3_Windows.exe"
    NotebookLicenseBlob   = "NotebookServer_Prod.ecp"
    NotebookCertBlob      = "notebook.pfx"

    KeyVaultName           = "keyvault-ops"
    PortalAdminSecretName  = "portal-admin-username"
    PortalPasswordSecretName = "portal-admin-password"
    CertPasswordSecretName = "notebook-cert-password"

    PortalUrl          = "https://portal.company.com/portal"
    NotebookExternalUrl = "https://notebook.company.com:11443/arcgis"
    PrimaryNotebookUrl = "https://notebook-primary.company.com"
}