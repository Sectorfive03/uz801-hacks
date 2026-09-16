# connect.ps1 - Connect to UZ801 device via ADB
# Usage: .\connect.ps1

$ADB = "adb"
# Auto-detect ADB path
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

Write-Host "=== UZ801 Device Connector ===" -ForegroundColor Cyan
Write-Host "Using ADB: $ADB" -ForegroundColor Gray

# Kill existing server
& $ADB kill-server 2>$null
Start-Sleep -Milliseconds 500

# Start server
& $ADB start-server
Start-Sleep -Seconds 1

# List devices
Write-Host "`nScanning for devices..." -ForegroundColor Yellow
$devices = & $ADB devices -l 2>&1
Write-Host $devices

# Check if our device is connected
$deviceLine = & $ADB devices 2>&1 | Select-String "device$"
if ($deviceLine) {
    $serial = ($deviceLine -split "`t")[0]
    Write-Host "`n[OK] Device connected: $serial" -ForegroundColor Green
    
    # Quick info dump
    Write-Host "`n--- Device Info ---" -ForegroundColor Cyan
    $model = & $ADB -s $serial shell getprop ro.product.model 2>$null
    $android = & $ADB -s $serial shell getprop ro.build.version.release 2>$null
    $root = & $ADB -s $serial shell id 2>$null
    Write-Host "Model: $model"
    Write-Host "Android: $android"
    Write-Host "User: $root"
    
    # Test shell access
    $whoami = & $ADB -s $serial shell whoami 2>$null
    if ($whoami -match "root") {
        Write-Host "`n[ROOT] Full root access confirmed!" -ForegroundColor Green
    } else {
        Write-Host "`n[WARN] Not running as root (current: $whoami)" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n[ERROR] No device found!" -ForegroundColor Red
    Write-Host "Check:" -ForegroundColor Yellow
    Write-Host "  1. Device is plugged in via USB"
    Write-Host "  2. USB cable supports data (not charge-only)"
    Write-Host "  3. Try: USB debugging is enabled (it should be by default)"
}
