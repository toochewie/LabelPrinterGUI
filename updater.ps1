# updater.ps1

$ErrorActionPreference = 'Stop'
$repoOwner = "Chewie610"
$repoName = "LabelPrinterGUI"
$htaFile = "LabelPrinterGUI.hta"
$excludeDir = "Printing"

Write-Host "Checking for updates..."

# Function to extract version from the HTA file
function Get-VersionFromHTA($path) {
    $versionLine = Get-Content $path | Where-Object { $_ -match 'const\s+APP_VERSION\s*=\s*".*";' }
    if ($versionLine -match '"([^"]+)"') {
        return [version]$matches[1]
    } else {
        throw "Version not found in HTA."
    }
}

# Get local version
$localVersion = Get-VersionFromHTA $htaFile
Write-Host "Local version: $localVersion"

# Download latest repo as ZIP
$tempPath = "$env:TEMP\LabelPrinterUpdate"
$zipPath = "$tempPath\repo.zip"
$extractPath = "$tempPath\unzipped"

Remove-Item $tempPath -Recurse -Force -ErrorAction Ignore
New-Item -ItemType Directory -Path $tempPath | Out-Null

$zipUrl = "https://github.com/$repoOwner/$repoName/archive/refs/heads/main.zip"

Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath

# Extract ZIP
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $extractPath)

# Get remote version from downloaded HTA
$remoteHTA = Get-ChildItem $extractPath -Recurse -Filter $htaFile | Select-Object -First 1
$remoteVersion = Get-VersionFromHTA $remoteHTA.FullName
Write-Host "Remote version: $remoteVersion"

# Compare versions
if ($remoteVersion -le $localVersion) {
    [System.Windows.Forms.MessageBox]::Show("You're already up to date. ($localVersion)", "No Update Needed")
    exit 0
}

# Copy new files (except 'Printing' folder)
$sourceRoot = $remoteHTA.Directory.Parent.FullName
$destRoot = Get-Location

Get-ChildItem $sourceRoot -Recurse | ForEach-Object {
    $relativePath = $_.FullName.Substring($sourceRoot.Length).TrimStart('\')
    if ($relativePath -like "$excludeDir*") {
        return
    }

    $dest = Join-Path $destRoot $relativePath
    if ($_.PSIsContainer) {
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
    } else {
        Copy-Item $_.FullName -Destination $dest -Force
    }
}

# Restart the app
Start-Process "$destRoot\$htaFile"
[System.Windows.Forms.MessageBox]::Show("Updated to version $remoteVersion!", "Update Successful")

# Exit old instance
exit 0
