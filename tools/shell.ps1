# shell.ps1 - Open interactive ADB shell on UZ801
# Usage: .\shell.ps1

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

Write-Host "=== UZ801 Interactive Shell ===" -ForegroundColor Cyan
Write-Host "Type 'exit' to leave the shell" -ForegroundColor Gray
Write-Host ""

# Verify connection
$devices = & $ADB devices 2>&1 | Select-String "device$"
if (-not $devices) {
    Write-Host "[ERROR] No device connected!" -ForegroundColor Red
    exit 1
}

# Open interactive shell as root
Write-Host "Connecting as root..." -ForegroundColor Yellow
& $ADB shell
