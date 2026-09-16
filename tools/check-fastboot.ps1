# check-fastboot.ps1 - Check fastboot status and flash if ready

$fastboot = "fastboot"

Write-Host "=== Checking Fastboot Status ===" -ForegroundColor Cyan

# Check for fastboot device
$devices = & $fastboot devices 2>&1

if ($devices -match "fastboot") {
    Write-Host "[OK] Fastboot is working!" -ForegroundColor Green
    Write-Host "Device: $devices" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Ready to flash Linux!" -ForegroundColor Green
    Write-Host ""
    
    $flash = Read-Host "Flash Linux now? (y/n)"
    if ($flash -eq "y") {
        & "$PSScriptRoot\flash-linux.ps1"
    }
} else {
    Write-Host "[INFO] Fastboot not detecting device yet" -ForegroundColor Yellow
    Write-Host ""
    
    # Check what Windows sees
    Write-Host "Windows USB devices:" -ForegroundColor Yellow
    Get-WmiObject Win32_PnPEntity | Where-Object { 
        $_.DeviceID -match 'VID_18D1|VID_05C6' -or 
        ($_.Name -match 'Android|Qualcomm' -and $_.PNPClass -eq 'USB')
    } | Select-Object Name, DeviceID, Status | Format-Table -AutoSize
    
    Write-Host ""
    Write-Host "If device shows 'Android' under 'Other devices':" -ForegroundColor Yellow
    Write-Host "  Driver is NOT installed yet" -ForegroundColor Red
    Write-Host "  Run: .\tools\install-fastboot-driver.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "If device shows 'Android Bootloader Interface' under 'Android Device':" -ForegroundColor Yellow
    Write-Host "  Driver IS installed" -ForegroundColor Green
    Write-Host "  Try: Unplug and replug USB, then run this script again" -ForegroundColor Gray
}
