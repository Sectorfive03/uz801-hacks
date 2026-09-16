# install-fastboot-driver.ps1 - Install fastboot driver for UZ801
# Run this AFTER the device is in fastboot/bootloader mode

$driverInf = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "..\drivers\google-usb\usb_driver\android_winusb.inf"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Fastboot Driver Installer for UZ801" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if device is in fastboot mode
Write-Host "[1/3] Checking if device is in fastboot mode..." -ForegroundColor Yellow

$fastbootDevice = Get-WmiObject Win32_PnPEntity | Where-Object { 
    $_.DeviceID -match 'VID_05C6' -and $_.Status -ne 'OK' -and $_.Name -match 'Android|Unknown'
}

if ($fastbootDevice) {
    Write-Host "  [OK] Found device needing driver:" -ForegroundColor Green
    Write-Host "  Name: $($fastbootDevice.Name)" -ForegroundColor Gray
    Write-Host "  ID: $($fastbootDevice.DeviceID)" -ForegroundColor Gray
} else {
    Write-Host "  [INFO] No unknown Android device found" -ForegroundColor Yellow
    Write-Host "  Device may already have a driver, or is not in fastboot mode" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  To enter fastboot mode:" -ForegroundColor Yellow
    Write-Host "  1. Make sure ADB is working" -ForegroundColor Gray
    Write-Host "  2. Run: adb reboot bootloader" -ForegroundColor Gray
    Write-Host "  3. Then run this script again" -ForegroundColor Gray
    exit
}

Write-Host ""
Write-Host "[2/3] Installing Fastboot Driver..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Follow these steps in Device Manager:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Right-click on '$($fastbootDevice.Name)' under 'Other devices'" -ForegroundColor White
Write-Host "  2. Select 'Update driver'" -ForegroundColor White
Write-Host "  3. Select 'Browse my computer for drivers'" -ForegroundColor White
Write-Host "  4. Click 'Let me pick from a list...'" -ForegroundColor White
Write-Host "  5. Click 'Have Disk...'" -ForegroundColor White
Write-Host "  6. Click 'Browse...' and navigate to:" -ForegroundColor White
Write-Host "     $driverInf" -ForegroundColor Green
Write-Host "  7. Click 'Open', then 'OK'" -ForegroundColor White
Write-Host "  8. Select 'Android Bootloader Interface'" -ForegroundColor White
Write-Host "  9. Click 'Next' and 'Yes' if prompted about unsigned driver" -ForegroundColor White
Write-Host "  10. Wait for installation to complete" -ForegroundColor White
Write-Host ""

# Open Device Manager
Write-Host "  Opening Device Manager..." -ForegroundColor Gray
Start-Process "devmgmt.msc"

Read-Host "Press Enter after driver is installed"

# Verify
Write-Host ""
Write-Host "[3/3] Verifying installation..." -ForegroundColor Yellow

$fastboot = "fastboot"
$devices = & $fastboot devices 2>&1

if ($devices -match "fastboot") {
    Write-Host "  [OK] Fastboot is working!" -ForegroundColor Green
    Write-Host "  Device: $devices" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  You can now flash Linux with:" -ForegroundColor Cyan
    Write-Host "  .\flash-linux.ps1" -ForegroundColor Green
} else {
    Write-Host "  [WARN] Fastboot still not detecting device" -ForegroundColor Yellow
    Write-Host "  Try unplugging and replugging the USB cable" -ForegroundColor Gray
    Write-Host "  Then run: fastboot devices" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Driver file: $driverInf" -ForegroundColor Gray
