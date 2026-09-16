# explore.ps1 - Deep exploration of UZ801 device
# Usage: .\explore.ps1

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

$OUTDIR = "docs\device-dump"
New-Item -ItemType Directory -Force -Path $OUTDIR | Out-Null

Write-Host "=== UZ801 Deep Exploration ===" -ForegroundColor Cyan
Write-Host "Output directory: $OUTDIR" -ForegroundColor Gray

function Run-ADB($cmd, $outFile) {
    Write-Host "`n> $cmd" -ForegroundColor Yellow
    $result = & $ADB shell $cmd 2>&1
    Write-Host $result
    if ($outFile) {
        $result | Out-File -FilePath "$OUTDIR\$outFile" -Encoding UTF8
        Write-Host "  -> Saved to $OUTDIR\$outFile" -ForegroundColor Gray
    }
    return $result
}

# System info
Write-Host "`n[1/10] System Properties" -ForegroundColor Cyan
Run-ADB "getprop ro.product.model" "model.txt"
Run-ADB "getprop ro.product.device" "device.txt"
Run-ADB "getprop ro.hardware" "hardware.txt"
Run-ADB "getprop ro.board.platform" "platform.txt"
Run-ADB "getprop ro.build.display.id" "build-id.txt"
Run-ADB "getprop ro.build.version.release" "android-version.txt"
Run-ADB "getprop ro.build.version.sdk" "sdk-version.txt"
Run-ADB "getprop ro.build.fingerprint" "fingerprint.txt"

# CPU info
Write-Host "`n[2/10] CPU Information" -ForegroundColor Cyan
Run-ADB "cat /proc/cpuinfo" "cpuinfo.txt"

# Memory
Write-Host "`n[3/10] Memory Information" -ForegroundColor Cyan
Run-ADB "cat /proc/meminfo" "meminfo.txt"

# Partitions
Write-Host "`n[4/10] Partition Layout" -ForegroundColor Cyan
Run-ADB "cat /proc/partitions" "partitions.txt"
Run-ADB "ls -la /dev/block/bootdevice/by-name/" "block-devices.txt"

# Filesystem
Write-Host "`n[5/10] Filesystem" -ForegroundColor Cyan
Run-ADB "df" "disk-usage.txt"
Run-ADB "mount" "mount-points.txt"

# Network
Write-Host "`n[6/10] Network Configuration" -ForegroundColor Cyan
Run-ADB "ip addr show" "ip-addresses.txt"
Run-ADB "ip route show" "ip-routes.txt"
Run-ADB "cat /etc/resolv.conf" "dns-config.txt"

# Radio/Cellular
Write-Host "`n[7/10] Radio & Cellular" -ForegroundColor Cyan
Run-ADB "getprop | grep -E 'ril|radio|gsm|sim'" "radio-props.txt"

# WiFi
Write-Host "`n[8/10] WiFi Status" -ForegroundColor Cyan
Run-ADB "iwconfig wlan0" "iwconfig.txt"
Run-ADB "iw dev wlan0 info" "iw-dev.txt"
Run-ADB "cat /data/misc/wifi/wpa_supplicant.conf" "wpa-config.txt"

# Running services
Write-Host "`n[9/10] Running Services" -ForegroundColor Cyan
Run-ADB "ps | head -50" "processes.txt"

# Installed packages
Write-Host "`n[10/10] Installed Packages" -ForegroundColor Cyan
Run-ADB "pm list packages -f" "packages.txt"

Write-Host "`n=== Exploration Complete ===" -ForegroundColor Green
Write-Host "All data saved to: $OUTDIR" -ForegroundColor Cyan
Write-Host "Review the files to understand the device layout." -ForegroundColor Gray
