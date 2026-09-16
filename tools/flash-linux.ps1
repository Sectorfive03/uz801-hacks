# flash-linux.ps1 - Flash Linux to UZ801 with driver installation
# This script handles the Windows driver issue and flashes Debian/OpenWRT

param(
    [Parameter(Position=0)]
    [string]$Method = "auto"
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $scriptDir
$downloadDir = "$projectDir\downloads\openstick\openstick"
$driversDir = "$projectDir\drivers"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   UZ801 Linux Flash Tool" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# STEP 1: Check prerequisites
# ============================================
Write-Host "[1/5] Checking prerequisites..." -ForegroundColor Yellow

$adb = "adb"
$adbPaths = @(
    "adb",
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
    "$env:ProgramFiles\Android\platform-tools\adb.exe",
    "$env:USERPROFILE\Android\Sdk\platform-tools\adb.exe"
)
foreach ($p in $adbPaths) {
    if (Test-Path $p -ErrorAction SilentlyContinue) {
        $adb = $p
        break
    }
}

# Check ADB
$devices = & $adb devices 2>&1 | Select-String "device$"
if ($devices) {
    Write-Host "  [OK] ADB device connected" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] No ADB device found!" -ForegroundColor Red
    Write-Host "  Please connect the device via USB and enable ADB" -ForegroundColor Yellow
    exit 1
}

# Check OpenStick files
if (Test-Path "$downloadDir\debian\boot.img") {
    Write-Host "  [OK] OpenStick image found" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] OpenStick image not found at $downloadDir" -ForegroundColor Red
    Write-Host "  Please download from: https://wvthoog.nl/openstick/" -ForegroundColor Yellow
    exit 1
}

# ============================================
# STEP 2: Install drivers (if needed)
# ============================================
Write-Host ""
Write-Host "[2/5] Checking Qualcomm USB drivers..." -ForegroundColor Yellow

$qualcommDevices = Get-WmiObject Win32_PnPEntity | Where-Object { 
    $_.DeviceID -match 'VID_05C6' -and $_.Status -ne 'OK' 
}

if ($qualcommDevices) {
    Write-Host "  Found devices needing drivers:" -ForegroundColor Yellow
    $qualcommDevices | ForEach-Object { Write-Host "    - $($_.Name)" -ForegroundColor Gray }
    
    Write-Host ""
    Write-Host "  To install drivers:" -ForegroundColor Yellow
    Write-Host "  1. Open Device Manager" -ForegroundColor Gray
    Write-Host "  2. Right-click the 'Android' device with yellow triangle" -ForegroundColor Gray
    Write-Host "  3. Select 'Update driver'" -ForegroundColor Gray
    Write-Host "  4. Choose 'Browse my computer'" -ForegroundColor Gray
    Write-Host "  5. Browse to: $driversDir" -ForegroundColor Gray
    Write-Host "  6. Check 'Include subfolders'" -ForegroundColor Gray
    Write-Host "  7. Click Next" -ForegroundColor Gray
    
    $installDrivers = Read-Host "`nPress Enter when drivers are installed (or 'skip' to continue)"
} else {
    Write-Host "  [OK] All Qualcomm devices have drivers" -ForegroundColor Green
}

# ============================================
# STEP 3: Try Fastboot method
# ============================================
Write-Host ""
Write-Host "[3/5] Attempting Fastboot mode..." -ForegroundColor Yellow

$fastboot = "$downloadDir\fastboot.exe"
if (-not (Test-Path $fastboot)) {
    $fastboot = "fastboot"
}

# Reboot to bootloader
Write-Host "  Rebooting device to bootloader..." -ForegroundColor Gray
& $adb reboot bootloader 2>&1
Start-Sleep -Seconds 10

# Check fastboot
$fastbootDevices = & $fastboot devices 2>&1
if ($fastbootDevices -match "fastboot") {
    Write-Host "  [OK] Fastboot mode detected!" -ForegroundColor Green
    
    # Run flash script
    Write-Host "  Flashing Linux..." -ForegroundColor Yellow
    
    # Backup modem calibration
    Write-Host "  Backing up modem calibration data..." -ForegroundColor Gray
    & $fastboot oem dump fsc 2>&1
    & $fastboot get_staged "$downloadDir\base\fsc.bin" 2>&1
    & $fastboot oem dump fsg 2>&1
    & $fastboot get_staged "$downloadDir\base\fsg.bin" 2>&1
    & $fastboot oem dump modemst1 2>&1
    & $fastboot get_staged "$downloadDir\base\modemst1.bin" 2>&1
    & $fastboot oem dump modemst2 2>&1
    & $fastboot get_staged "$downloadDir\base\modemst2.bin" 2>&1
    
    # Flash base partitions
    Write-Host "  Flashing base partitions..." -ForegroundColor Gray
    & $fastboot flash partition "$downloadDir\base\gpt_both0.bin" 2>&1
    & $fastboot flash hyp "$downloadDir\base\hyp.mbn" 2>&1
    & $fastboot flash rpm "$downloadDir\base\rpm.mbn" 2>&1
    & $fastboot flash sbl1 "$downloadDir\base\sbl1.mbn" 2>&1
    & $fastboot flash tz "$downloadDir\base\tz.mbn" 2>&1
    & $fastboot flash fsc "$downloadDir\base\fsc.bin" 2>&1
    & $fastboot flash fsg "$downloadDir\base\fsg.bin" 2>&1
    & $fastboot flash modemst1 "$downloadDir\base\modemst1.bin" 2>&1
    & $fastboot flash modemst2 "$downloadDir\base\modemst2.bin" 2>&1
    & $fastboot flash aboot "$downloadDir\base\aboot.bin" 2>&1
    & $fastboot flash cdt "$downloadDir\base\sbc_1.0_8016.bin" 2>&1
    
    # Erase and flash boot/rootfs
    & $fastboot erase boot 2>&1
    & $fastboot erase rootfs 2>&1
    & $fastboot reboot 2>&1
    Start-Sleep -Seconds 8
    
    # Re-enter fastboot for final flash
    & $fastboot devices 2>&1
    & $fastboot -S 200M flash rootfs "$downloadDir\debian\rootfs.img" 2>&1
    & $fastboot flash boot "$downloadDir\debian\boot.img" 2>&1
    
    Write-Host ""
    Write-Host "  [OK] Flash complete!" -ForegroundColor Green
    & $fastboot reboot 2>&1
    
} else {
    Write-Host "  [WARN] Fastboot not detected" -ForegroundColor Yellow
    Write-Host "  This is a known Windows driver issue" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Trying EDL mode instead..." -ForegroundColor Yellow
    
    # Reboot to EDL
    & $adb reboot edl 2>&1
    Start-Sleep -Seconds 5
    
    Write-Host ""
    Write-Host "  Device should now be in EDL mode (Qualcomm HS-USB QDLoader 9008)" -ForegroundColor Yellow
    Write-Host "  If not detected, you may need to short D+ to GND on the USB connector" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  To flash via EDL:" -ForegroundColor Cyan
    Write-Host "  1. Install Python 3" -ForegroundColor Gray
    Write-Host "  2. Run: pip install edl" -ForegroundColor Gray
    Write-Host "  3. Run: python edl.py wf stock-uz801.bin" -ForegroundColor Gray
    Write-Host "  4. Or download pre-built EDL flasher from AlienWolfX releases" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Alternative: Install Qualcomm drivers and try fastboot again" -ForegroundColor Yellow
    Write-Host "  Drivers are in: $driversDir" -ForegroundColor Gray
}

# ============================================
# STEP 4: Verify
# ============================================
Write-Host ""
Write-Host "[4/5] Waiting for device to boot..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host "  Checking device..." -ForegroundColor Gray
$devices = & $adb devices 2>&1
Write-Host $devices

Write-Host ""
Write-Host "[5/5] Done!" -ForegroundColor Green
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Next Steps:" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "After Linux boots:" -ForegroundColor Yellow
Write-Host "  1. Connect to WiFi: SSID '4G-UFI-XX', Password '1234567890'" -ForegroundColor Gray
Write-Host "  2. SSH: ssh user@192.168.100.1 (password: 1)" -ForegroundColor Gray
Write-Host "  3. Or via USB: ssh user@192.168.200.1" -ForegroundColor Gray
Write-Host ""
Write-Host "Configure 4G/LTE:" -ForegroundColor Yellow
Write-Host "  sudo nmcli connection modify lte gsm.apn 'your-apn'" -ForegroundColor Gray
Write-Host "  sudo nmcli connection up lte" -ForegroundColor Gray
Write-Host ""
Write-Host "Enable SMS:" -ForegroundColor Yellow
Write-Host "  sudo apt install gammu" -ForegroundColor Gray
Write-Host "  gammu getsms" -ForegroundColor Gray
Write-Host ""
