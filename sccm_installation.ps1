# ===========================================
# Install SCCM (ConfigMgr) on Windows Server 2022
# Includes: Windows ADK + WinPE Add-on
# ===========================================

# ---------- Variables ----------
$SiteCode        = "P01"                         
$SiteName        = "Primary Site"                
$SMSInstallDir   = "C:\Program Files\Microsoft Configuration Manager"
$SQLServerName   = "CM01.contoso.com"            
$DatabaseName    = "CM_P01"                      
$ManagementPoint = "CM01.contoso.com"            
$DistributionPoint = "CM01.contoso.com"
$ProductKey      = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"  
$SCCMISOPath     = "D:\"                         
$ConfigFilePath  = "C:\ConfigMgrSetup.ini"
$PrereqPath      = "C:\SCCM_Prereqs"
$DownloadPath    = "C:\Installers"

# Microsoft ADK URLs (latest as of 2025 – update if needed)
$ADKUrl    = "https://go.microsoft.com/fwlink/?linkid=2271337"   # Windows ADK setup
$WinPEUrl  = "https://go.microsoft.com/fwlink/?linkid=2271338"   # WinPE add-on setup

$ADKInstaller    = Join-Path $DownloadPath "adksetup.exe"
$WinPEInstaller  = Join-Path $DownloadPath "adkwinpesetup.exe"

# ---------- Step 1: Create folders ----------
if (!(Test-Path $DownloadPath)) { New-Item -Path $DownloadPath -ItemType Directory | Out-Null }
if (!(Test-Path $PrereqPath))   { New-Item -Path $PrereqPath   -ItemType Directory | Out-Null }

# ---------- Step 2: Install Required Windows Features ----------
Write-Host "Installing required Windows Server features..." -ForegroundColor Cyan

Install-WindowsFeature Web-Windows-Auth, Web-ISAPI-Ext, Web-Metabase, Web-WMI, Web-Net-Ext45, Web-Asp-Net45, Web-Dyn-Compression -IncludeAllSubFeature -IncludeManagementTools
Install-WindowsFeature BITS, RDC
Install-WindowsFeature Net-Framework-Core, NET-Framework-Features, NET-Framework-45-Core, NET-Framework-45-Features
Install-WindowsFeature UpdateServices, UpdateServices-DB, UpdateServices-RSAT, UpdateServices-UI

Write-Host "Windows features installed." -ForegroundColor Green

# ---------- Step 3: Download ADK + WinPE ----------
Write-Host "Downloading Windows ADK and WinPE Add-on..." -ForegroundColor Cyan

Invoke-WebRequest -Uri $ADKUrl   -OutFile $ADKInstaller   -UseBasicParsing
Invoke-WebRequest -Uri $WinPEUrl -OutFile $WinPEInstaller -UseBasicParsing

Write-Host "ADK and WinPE downloaded." -ForegroundColor Green

# ---------- Step 4: Install Windows ADK ----------
Write-Host "Installing Windows ADK..." -ForegroundColor Cyan

Start-Process $ADKInstaller -ArgumentList "/quiet /norestart /ceip off /features OptionId.DeploymentTools OptionId.UserStateMigrationTool" -Wait

Write-Host "Windows ADK installed." -ForegroundColor Green

# ---------- Step 5: Install WinPE Add-on ----------
Write-Host "Installing Windows ADK WinPE Add-on..." -ForegroundColor Cyan

Start-Process $WinPEInstaller -ArgumentList "/quiet /norestart" -Wait

Write-Host "WinPE Add-on installed." -ForegroundColor Green

# ---------- Step 6: Create ConfigMgrSetup.ini ----------
Write-Host "Creating SCCM unattended config file at $ConfigFilePath" -ForegroundColor Cyan

$ConfigFileContent = @"
[Identification]
Action=InstallPrimarySite

[Options]
ProductID=$ProductKey
SiteCode=$SiteCode
SiteName=$SiteName
SMSInstallDir=$SMSInstallDir
SDKServer=$ManagementPoint
RoleCommunicationProtocol=HTTPorHTTPS
ClientsUsePKICert=0
PrerequisiteComp=1
PrerequisitePath=$PrereqPath
ManagementPoint=$ManagementPoint
DistributionPoint=$DistributionPoint

[SQLConfig]
SQLServerName=$SQLServerName
DatabaseName=$DatabaseName
SQLSSBPort=4022

[CloudConnector]
EnableCloudConnector=0

[Hierarchy]
JoinMANAGED=0
"@

$ConfigFileContent | Out-File -FilePath $ConfigFilePath -Encoding ASCII -Force

Write-Host "Config file created." -ForegroundColor Green

# ---------- Step 7: Run SCCM Setup ----------
$SetupExe = Join-Path -Path $SCCMISOPath -ChildPath "SMSSETUP\BIN\X64\Setup.exe"

if (Test-Path $SetupExe) {
    Write-Host "Starting SCCM unattended installation..." -ForegroundColor Cyan
    Start-Process $SetupExe -ArgumentList "/script $ConfigFilePath" -Wait -NoNewWindow
    Write-Host "SCCM installation complete (check logs in C:\ConfigMgrSetup.log)." -ForegroundColor Green
} else {
    Write-Host "ERROR: Cannot find Setup.exe at $SetupExe. Check SCCM ISO path." -ForegroundColor Red
}
