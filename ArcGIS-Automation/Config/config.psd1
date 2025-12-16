@{
    # =============================
    # ENVIRONMENT SETTINGS
    # =============================
    Environment = "dev"       # dev | test | stage | prod
    IsHA        = $false      # Single-node, HA disabled
    IsPrimary   = $true       # Only one node

    # =============================
    # AZURE STORAGE (Installer + License + Certificate)
    # =============================
    StorageAccountUrl = "https://esari-nonprd.blob.core.windows.net"
    StorageContainer  = "$web"
    NotebookInstallerBlob = "ArcGIS_Notebook_Server_11_3_Windows.exe"
    NotebookLicenseBlob   = "NotebookServer_Prod.ecp"
    NotebookCertBlob      = "notebook.pfx"

    # =============================
    # AZURE KEY VAULT (Secrets)
    # =============================
    KeyVaultName           = "keyvault-ops"
    PortalAdminSecretName  = "portal-admin-username"
    PortalPasswordSecretName = "portal-admin-password"
    CertPasswordSecretName = "notebook-cert-password"

    # =============================
    # ARCGIS ENDPOINTS
    # =============================
    PortalUrl          = "https://portal.company.com/portal"
    NotebookExternalUrl = "https://notebook.company.com:11443/arcgis"
    PrimaryNotebookUrl = ""  # Not used for single-node
}
