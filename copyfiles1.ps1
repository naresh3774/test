# Disable progress bar globally (prevents hangs in Azure RunCommand)
$ProgressPreference = 'SilentlyContinue'

# Ensure Deploy folder exists
$deployFolder = "$env:SystemDrive\Deploy"
if (-not (Test-Path $deployFolder)) {
    New-Item -Path $deployFolder -ItemType Directory -Force | Out-Null
    Write-Output "Created $deployFolder"
}

function Download-ArcGISFile {
    param (
        [string]$FileName,
        [string]$Url,
        [int]$MaxRetries = 3
    )

    $destination = Join-Path $deployFolder $FileName
    $attempt = 1
    $success = $false

    while (-not $success -and $attempt -le $MaxRetries) {
        Write-Output "[$attempt/$MaxRetries] Downloading $FileName from $Url"

        try {
            # Use BITS for reliability (handles binary files better)
            Start-BitsTransfer -Source $Url -Destination $destination -ErrorAction Stop

            Write-Output "Completed: $FileName -> $destination"
            $success = $true
        }
        catch {
            Write-Output "Attempt $attempt failed for $FileName. Error: $_"
            Start-Sleep -Seconds 5
            $attempt++
        }
    }

    if (-not $success) {
        Write-Output "Failed to download $FileName after $MaxRetries attempts."
    }
}

# Detect VM hostname
$vmName = $env:COMPUTERNAME.ToLower()
Write-Output "VM Name: $vmName"

# Download mapping.json
$mappingUrl   = "https://esrinonprodstshrd.z2.web.core.usgovcloudapi.net/arcgis-server/mapping.json"
$mappingLocal = Join-Path $deployFolder "mapping.json"

Write-Output "Downloading mapping.json from $mappingUrl"
try {
    Start-BitsTransfer -Source $mappingUrl -Destination $mappingLocal -ErrorAction Stop
    Write-Output "Downloaded mapping.json -> $mappingLocal"
}
catch {
    Write-Output "Failed to download mapping.json. Error: $_"
    exit 1
}

# Parse mapping.json
try {
    $mapping = Get-Content $mappingLocal | ConvertFrom-Json
}
catch {
    Write-Output "Failed to parse mapping.json. Error: $_"
    exit 1
}

# Download files for this VM
if ($mapping.$vmName) {
    $files = $mapping.$vmName
    Write-Output "Found $($files.Count) files to download for $vmName"

    foreach ($file in $files) {
        Download-ArcGISFile -FileName $file.Name -Url $file.Url
    }

    Write-Output "All files for $vmName processed."
}
else {
    Write-Output "No files assigned to $vmName in mapping.json."
}