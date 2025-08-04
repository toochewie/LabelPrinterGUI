# updater.ps1
$repo = "Chewie610/LabelPrinterGUI"
$branch = "main"
$htaFile = "LabelPrinter.hta"
$tempZip = "$env:TEMP\LabelPrinterUpdate.zip"
$extractPath = "$env:TEMP\LabelPrinterUpdate"
$remoteVersionURL = "https://raw.githubusercontent.com/$repo/$branch/version.txt"
$zipURL = "https://github.com/$repo/archive/refs/heads/$branch.zip"

function Compare-SemanticVersion($v1, $v2) {
    $a = $v1.Split('.')
    $b = $v2.Split('.')
    for ($i = 0; $i -lt [Math]::Max($a.Length, $b.Length); $i++) {
        $num1 = if ($i -lt $a.Length) { [int]$a[$i] } else { 0 }
        $num2 = if ($i -lt $b.Length) { [int]$b[$i] } else { 0 }
        if ($num1 -lt $num2) { return -1 }
        if ($num1 -gt $num2) { return 1 }
    }
    return 0
}

function Show-Message($msg) {
    $msgScript = "$env:TEMP\popup.vbs"
    Set-Content -Path $msgScript -Value "MsgBox ""$msg"", vbInformation, ""Label Printer Updater"""
    Start-Process "wscript.exe" -ArgumentList "`"$msgScript`""
}

# 1. Read version from HTA
if (!(Test-Path $htaFile)) {
    Show-Message "Could not find HTA file: $htaFile"
    exit 1
}
$htaContent = Get-Content $htaFile -Raw
if ($htaContent -match 'APP_VERSION\s*=\s*"([0-9\.]+)"') {
    $localVersion = $matches[1]
} else {
    Show-Message "Could not find APP_VERSION in HTA."
    exit 1
}

# 2. Fetch remote version
try {
    $remoteVersion = (Invoke-RestMethod -Uri $remoteVersionURL -UseBasicParsing).Trim()
} catch {
    Show-Message "Failed to contact GitHub for update."
    exit 1
}

# 3. Compare versions
$cmp = Compare-SemanticVersion $localVersion $remoteVersion
if ($cmp -ge 0) {
    Show-Message "You're already up to date. Version: $localVersion"
    exit 0
}

# 4. Download update
try {
    Invoke-WebRequest -Uri $zipURL -OutFile $tempZip
    Expand-Archive -Path $tempZip -DestinationPath $extractPath -Force
} catch {
    Show-Message "Failed to download or extract update."
    exit 1
}

# 5. Copy files, skipping the Printing folder
$extractedRoot = Join-Path $extractPath "$($repo.Split('/')[1])-$branch"
Get-ChildItem -Path $extractedRoot -Recurse | ForEach-Object {
    $relativePath = $_.FullName.Substring($extractedRoot.Length + 1)
    if ($relativePath -like "Printing\*" -or $relativePath -ieq "Printing") {
        return  # skip anything inside or named "Printing"
    }

    $destPath = Join-Path "." $relativePath
    $destDir = Split-Path $destPath

    if (!(Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir | Out-Null
    }

    Copy-Item -Path $_.FullName -Destination $destPath -Force
}

# 6. Cleanup
Remove-Item $tempZip -Force
Remove-Item $extractPath -Recurse -Force

# 7. Show message and restart HTA
Show-Message "Updated to version $remoteVersion successfully."
Start-Process "mshta.exe" "$htaFile"
exit
