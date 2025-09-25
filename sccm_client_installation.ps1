# ===========================================
# Install SCCM Client Agent (Local Install)
# ===========================================

$SiteCode     = "P01"                       # Your SCCM site code
$MPServer     = "CM01.contoso.com"          # Your SCCM Management Point
$ClientSource = "\\CM01\SMS_$SiteCode\Client"   # UNC path to SCCM client source

$ClientMSI    = Join-Path $ClientSource "ccmsetup.exe"

if (Test-Path $ClientMSI) {
    Write-Host "Starting SCCM client installation from $ClientSource..." -ForegroundColor Cyan
    Start-Process $ClientMSI -ArgumentList "/mp:$MPServer SMSSITECODE=$SiteCode SMSMP=$MPServer CCMLOGMAXSIZE=5242880 CCMLOGLEVEL=0" -Wait
    Write-Host "SCCM client installation initiated. Check logs at C:\Windows\CCM\Logs\ccmsetup.log." -ForegroundColor Green
} else {
    Write-Host "ERROR: Cannot find SCCM client installer at $ClientSource" -ForegroundColor Red
}
