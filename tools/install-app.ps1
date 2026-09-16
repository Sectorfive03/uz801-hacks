# install-app.ps1 - Install APK files on UZ801 via ADB
# Usage: .\install-app.ps1 <path-to-apk>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$ApkPath
)

$ADB = "adb"
$adbPaths = @(
    "adb",
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
    "$env:ProgramFiles\Android\platform-tools\adb.exe",
    "$env:USERPROFILE\Android\Sdk\platform-tools\adb.exe"
)
foreach ($p in $adbPaths) {
    if (Test-Path $p -ErrorAction SilentlyContinue) {
        $ADB = $p
        break
    }
}

if (-not (Test-Path $ApkPath)) {
    Write-Host "[ERROR] APK file not found: $ApkPath" -ForegroundColor Red
    exit 1
}

Write-Host "=== UZ801 App Installer ===" -ForegroundColor Cyan
Write-Host "APK: $ApkPath" -ForegroundColor Gray

# Check device
$devices = & $ADB devices 2>&1 | Select-String "device$"
if (-not $devices) {
    Write-Host "[ERROR] No device connected!" -ForegroundColor Red
    exit 1
}

Write-Host "Installing..." -ForegroundColor Yellow
& $ADB install -r $ApkPath

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] App installed successfully!" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Installation failed" -ForegroundColor Red
    Write-Host "Try: Enable 'Unknown sources' in Settings > Security" -ForegroundColor Yellow
}
