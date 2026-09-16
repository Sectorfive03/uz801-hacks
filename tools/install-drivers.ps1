# install-drivers.ps1 - Install Qualcomm USB drivers for UZ801
# Run this as Administrator

$driversDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Qualcomm USB Driver Installer" -ForegroundColor Cyan
Write-Host "   for UZ801 4G LTE Dongle" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERROR] This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Check if device is connected
Write-Host "[1/3] Checking device connection..." -ForegroundColor Yellow
$device = Get-WmiObject Win32_PnPEntity | Where-Object { $_.DeviceID -match 'VID_05C6&PID_90B6' }
if ($device) {
    Write-Host "  [OK] UZ801 device found" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] UZ801 not found!" -ForegroundColor Red
    Write-Host "  Please connect the device via USB" -ForegroundColor Yellow
    exit 1
}

# Find devices needing drivers
Write-Host ""
Write-Host "[2/3] Scanning for devices needing drivers..." -ForegroundColor Yellow
$problemDevices = Get-WmiObject Win32_PnPEntity | Where-Object { 
    $_.DeviceID -match 'VID_05C6&PID_90B6' -and $_.Status -ne 'OK'
}

if ($problemDevices) {
    Write-Host "  Found $($problemDevices.Count) device(s) needing drivers:" -ForegroundColor Yellow
    foreach ($dev in $problemDevices) {
        Write-Host "    - $($dev.Name)" -ForegroundColor Gray
        Write-Host "      ID: $($dev.DeviceID)" -ForegroundColor DarkGray
    }
} else {
    Write-Host "  [OK] All devices have drivers installed" -ForegroundColor Green
    Write-Host ""
    Write-Host "Devices:" -ForegroundColor Yellow
    Get-WmiObject Win32_PnPEntity | Where-Object { $_.DeviceID -match 'VID_05C6&PID_90B6' } | 
        ForEach-Object { Write-Host "  $($_.Name) - Status: $($_.Status)" -ForegroundColor Gray }
}

# Install drivers
Write-Host ""
Write-Host "[3/3] Installing drivers..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Opening Device Manager..." -ForegroundColor Gray
Write-Host "  Please follow these steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. In Device Manager, find 'Other devices' or 'Unknown device'" -ForegroundColor Gray
Write-Host "  2. Right-click on 'Android' with yellow triangle" -ForegroundColor Gray
Write-Host "  3. Select 'Update driver'" -ForegroundColor Gray
Write-Host "  4. Choose 'Browse my computer for drivers'" -ForegroundColor Gray
Write-Host "  5. Click 'Browse' and select: $driversDir" -ForegroundColor Gray
Write-Host "  6. Check 'Include subfolders'" -ForegroundColor Gray
Write-Host "  7. Click 'Next' and wait for installation" -ForegroundColor Gray
Write-Host "  8. Repeat for any remaining unknown devices" -ForegroundColor Gray
Write-Host ""

# Open Device Manager
Start-Process "devmgmt.msc"

Read-Host "Press Enter when drivers are installed"

# Verify
Write-Host ""
Write-Host "Verifying installation..." -ForegroundColor Yellow
$remaining = Get-WmiObject Win32_PnPEntity | Where-Object { 
    $_.DeviceID -match 'VID_05C6&PID_90B6' -and $_.Status -ne 'OK'
}

if ($remaining) {
    Write-Host "  [WARN] Some devices still need drivers" -ForegroundColor Yellow
    Write-Host "  Try installing the other driver package" -ForegroundColor Gray
} else {
    Write-Host "  [OK] All drivers installed successfully!" -ForegroundColor Green
}

Write-Host ""
Write-Host "Driver files location: $driversDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "You can now try flashing Linux with: .\flash-linux.ps1" -ForegroundColor Green
