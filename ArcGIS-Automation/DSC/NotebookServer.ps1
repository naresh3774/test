# =============================
# DSC Notebook Server Script
# =============================

$Config = Import-PowerShellDataFile -Path "C:\ArcGIS-Automation\Config\config.psd1"

# -----------------------------
# Pre-checks
# -----------------------------
if (-not (Get-CimInstance Win32_OperatingSystem | Where-Object {$_.Caption -like '*2022*'})) {
    Write-Error "Windows Server 2022 is required."
    exit
}

# Login using VM's system-assigned managed identity
az login --identity

# Verify Key Vault secrets
$secrets = @($Config.PortalAdminSecretName, $Config.PortalPasswordSecretName, $Config.CertPasswordSecretName)
foreach ($s in $secrets) {
    if (-not (az keyvault secret show --vault-name $Config.KeyVaultName --name $s --query value -o tsv)) {
        Write-Error "Secret $s not found in Key Vault."
        exit
    }
}

# Verify Storage blobs
$blobs = @($Config.NotebookInstallerBlob, $Config.NotebookLicenseBlob, $Config.NotebookCertBlob)
foreach ($b in $blobs) {
    if (-not (az storage blob exists --account-name esari-nonprd --container-name $Config.StorageContainer --name $b --auth-mode login | ConvertFrom-Json).exists) {
        Write-Error "Blob $b does not exist in storage."
        exit
    }
}

# -----------------------------
# Docker check/install
# -----------------------------
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Docker..."
    Install-Package -Name 'mirantis-container-runtime' -Force
}

# -----------------------------
# Download installer, license, certificate
# -----------------------------
$TempDir = "C:\Temp"
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

foreach ($file in $blobs) {
    az storage blob download --account-name esari-nonprd --container-name $Config.StorageContainer --name $file --file "$TempDir\$file" --auth-mode login
}

# -----------------------------
# Pull secrets from Key Vault
# -----------------------------
$PortalAdmin = az keyvault secret show --vault-name $Config.KeyVaultName --name $Config.PortalAdminSecretName --query value -o tsv
$PortalPassword = az keyvault secret show --vault-name $Config.KeyVaultName --name $Config.PortalPasswordSecretName --query value -o tsv
$CertPassword = az keyvault secret show --vault-name $Config.KeyVaultName --name $Config.CertPasswordSecretName --query value -o tsv

$SecureCertPassword = ConvertTo-SecureString $CertPassword -AsPlainText -Force

# -----------------------------
# Import certificate
# -----------------------------
Import-PfxCertificate -FilePath "$TempDir\$($Config.NotebookCertBlob)" -CertStoreLocation Cert:\LocalMachine\My -Password $SecureCertPassword
Remove-Item "$TempDir\$($Config.NotebookCertBlob)" -Force

# -----------------------------
# Install Notebook Server silently
# -----------------------------
Start-Process -FilePath "$TempDir\$($Config.NotebookInstallerBlob)" -ArgumentList "/qb /norestart /log C:\Temp\NotebookInstall.log" -Wait
Remove-Item "$TempDir\$($Config.NotebookInstallerBlob)" -Force

# -----------------------------
# Apply license
# -----------------------------
& "C:\Program Files\ArcGIS\NotebookServer\tools\authorizeSoftware.bat" /f "$TempDir\$($Config.NotebookLicenseBlob)"
Remove-Item "$TempDir\$($Config.NotebookLicenseBlob)" -Force

# -----------------------------
# Create primary site
# -----------------------------
if ($Config.IsPrimary) {
    & "C:\Program Files\ArcGIS\NotebookServer\tools\notebookservertools.exe" CreateSite -PortalUrl $Config.PortalUrl -AdminUsername $PortalAdmin -AdminPassword $PortalPassword -HttpsPort 11443 -SiteName "NotebookSite"
}

Write-Host "Notebook Server setup completed successfully."