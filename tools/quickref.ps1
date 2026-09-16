# quickref.ps1 - Quick reference for UZ801 commands
# Usage: .\quickref.ps1 [command]

param(
    [Parameter(Position=0)]
    [string]$Command = "help"
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

switch ($Command) {
    "info" {
        Write-Host "=== UZ801 Device Info ===" -ForegroundColor Cyan
        & $ADB shell getprop ro.product.model
        & $ADB shell getprop ro.build.version.release
        & $ADB shell id
        & $ADB shell getprop gsm.operator.alpha
        & $ADB shell getprop gsm.sim.state
    }
    "screenshot" {
        Write-Host "Taking screenshot..." -ForegroundColor Yellow
        & $ADB shell settings put system screen_off_timeout 2147483647
        & $ADB shell input keyevent 26
        Start-Sleep -Seconds 1
        & $ADB shell screencap /sdcard/Download/screen.png
        & $ADB pull /sdcard/Download/screen.png
        Write-Host "[OK] Saved to screen.png" -ForegroundColor Green
    }
    "sms" {
        Write-Host "Listing SMS..." -ForegroundColor Yellow
        & $ADB shell "content query --uri content://sms --projection _id:address:body:date --sort 'date DESC' --limit 10"
    }
    "send" {
        $num = Read-Host "Phone number"
        $msg = Read-Host "Message"
        & $ADB shell "content insert --uri content://sms --bind address:s:'$num' --bind body:s:'$msg' --bind type:i:2"
        Write-Host "[OK] SMS sent" -ForegroundColor Green
    }
    "call" {
        $num = Read-Host "Phone number"
        & $ADB shell "am start -a android.intent.action.CALL -d tel:$num"
    }
    "network" {
        Write-Host "=== Network Status ===" -ForegroundColor Cyan
        & $ADB shell "ip addr show rmnet0" 2>$null | Select-String "inet "
        & $ADB shell "ip addr show br0" 2>$null | Select-String "inet "
        & $ADB shell getprop gsm.network.type
    }
    "diag" {
        Write-Host "Enabling diag port..." -ForegroundColor Yellow
        & $ADB shell "setprop sys.usb.config rndis,serial_smd,diag,adb"
        & $ADB shell "ls -la /dev/diag*"
    }
    "english" {
        Write-Host "Setting locale to English..." -ForegroundColor Yellow
        & $ADB shell "setprop persist.sys.locale en-US"
        & $ADB shell "setprop ctl.restart zygote"
        Write-Host "[OK] Locale changed" -ForegroundColor Green
    }
    "reboot" {
        Write-Host "Reboot options:" -ForegroundColor Yellow
        Write-Host "  1. Normal reboot"
        Write-Host "  2. Recovery"
        Write-Host "  3. Fastboot"
        Write-Host "  4. EDL (Emergency Download)"
        $choice = Read-Host "Choice (1-4)"
        switch ($choice) {
            "1" { & $ADB reboot }
            "2" { & $ADB reboot recovery }
            "3" { & $ADB reboot bootloader }
            "4" { & $ADB reboot edl }
        }
    }
    default {
        Write-Host "=== UZ801 Quick Reference ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor Yellow
        Write-Host "  .\quickref.ps1 info        - Device info"
        Write-Host "  .\quickref.ps1 screenshot  - Take screenshot"
        Write-Host "  .\quickref.ps1 sms         - List SMS"
        Write-Host "  .\quickref.ps1 send        - Send SMS"
        Write-Host "  .\quickref.ps1 call        - Make call"
        Write-Host "  .\quickref.ps1 network     - Network status"
        Write-Host "  .\quickref.ps1 diag        - Enable diag port"
        Write-Host "  .\quickref.ps1 english     - Set English locale"
        Write-Host "  .\quickref.ps1 reboot      - Reboot options"
        Write-Host ""
        Write-Host "Direct ADB commands:" -ForegroundColor Yellow
        Write-Host "  adb shell                        - Root shell"
        Write-Host "  adb shell getprop                - All properties"
        Write-Host "  adb shell input tap 100 100       - Tap screen"
        Write-Host "  adb shell input keyevent 26      - Power button"
    }
}
