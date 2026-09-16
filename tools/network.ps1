# network.ps1 - Network configuration and optimization for UZ801
# Usage:
#   .\network.ps1 status       - Show network status
#   .\network.ps1 apn          - Show/change APN settings
#   .\network.ps1 speedtest    - Run simple speed test
#   .\network.ps1 optimize     - Apply network optimizations

param(
    [Parameter(Position=0)]
    [string]$Action,
    
    [Parameter(Position=1)]
    [string]$Arg1
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

function Get-NetworkStatus() {
    Write-Host "=== UZ801 Network Status ===" -ForegroundColor Cyan
    
    # Cellular
    Write-Host "`n[Cellular]" -ForegroundColor Yellow
    $operator = & $ADB shell "getprop gsm.operator.alpha" 2>$null
    $network = & $ADB shell "getprop gsm.network.type" 2>$null
    $simState = & $ADB shell "getprop gsm.sim.state" 2>$null
    $roaming = & $ADB shell "getprop gsm.operator.isroaming" 2>$null
    
    Write-Host "  Operator: $operator"
    Write-Host "  Network: $network"
    Write-Host "  SIM State: $simState"
    Write-Host "  Roaming: $roaming"
    
    # IP addresses
    Write-Host "`n[IP Addresses]" -ForegroundColor Yellow
    & $ADB shell "ip addr show rmnet0" 2>$null | Select-String "inet "
    & $ADB shell "ip addr show br0" 2>$null | Select-String "inet "
    
    # WiFi
    Write-Host "`n[WiFi]" -ForegroundColor Yellow
    $wifiState = & $ADB shell "getprop wifi.interface" 2>$null
    Write-Host "  Interface: $wifiState"
    & $ADB shell "iw dev wlan0 info" 2>$null
    
    # DNS
    Write-Host "`n[DNS]" -ForegroundColor Yellow
    & $ADB shell "cat /etc/resolv.conf" 2>$null
    
    # Routing
    Write-Host "`n[Routes]" -ForegroundColor Yellow
    & $ADB shell "ip route show" 2>$null
}

function Get-APN() {
    Write-Host "Current APN settings:" -ForegroundColor Cyan
    & $ADB shell "content query --uri content://telephony/carriers/preferapn" 2>$null
}

function Optimize-Network() {
    Write-Host "Applying network optimizations..." -ForegroundColor Yellow
    
    # Increase TCP buffer sizes
    & $ADB shell "echo 4096 87380 6291456 > /proc/sys/net/ipv4/tcp_rmem" 2>$null
    & $ADB shell "echo 4096 65536 6291456 > /proc/sys/net/ipv4/tcp_wmem" 2>$null
    
    # Enable TCP window scaling
    & $ADB shell "echo 1 > /proc/sys/net/ipv4/tcp_window_scaling" 2>$null
    
    # Enable TCP timestamps
    & $ADB shell "echo 1 > /proc/sys/net/ipv4/tcp_timestamps" 2>$null
    
    # Enable TCP SACK
    & $ADB shell "echo 1 > /proc/sys/net/ipv4/tcp_sack" 2>$null
    
    # Increase max connections
    & $ADB shell "echo 4096 > /proc/sys/net/core/somaxconn" 2>$null
    
    # Disable reverse path filtering
    & $ADB shell "echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter" 2>$null
    
    Write-Host "[OK] Network optimizations applied" -ForegroundColor Green
    Write-Host "Note: These settings reset on reboot" -ForegroundColor Yellow
}

function Start-SpeedTest() {
    Write-Host "Running speed test (downloads 10MB file)..." -ForegroundColor Yellow
    
    # Check if we have curl or wget
    $hasCurl = & $ADB shell "which curl" 2>$null
    $hasWget = & $ADB shell "which wget" 2>$null
    
    if ($hasCurl) {
        & $ADB shell "curl -o /dev/null -w 'Speed: %{speed_download} bytes/sec\nTime: %{time_total}s\n' http://speedtest.tele2.net/10MB.zip" 2>$null
    } elseif ($hasWget) {
        & $ADB shell "wget -O /dev/null http://speedtest.tele2.net/10MB.zip 2>&1 | tail -5" 2>$null
    } else {
        Write-Host "Neither curl nor wget found. Installing curl..." -ForegroundColor Yellow
        & $ADB shell "apt-get install -y curl 2>/dev/null || yum install -y curl 2>/dev/null" 2>$null
        Write-Host "Try running speedtest again after install." -ForegroundColor Gray
    }
}

# Main
switch ($Action) {
    "status" { Get-NetworkStatus }
    "apn" { Get-APN }
    "optimize" { Optimize-Network }
    "speedtest" { Start-SpeedTest }
    default {
        Write-Host "=== UZ801 Network Tool ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor Yellow
        Write-Host "  .\network.ps1 status       - Show network status"
        Write-Host "  .\network.ps1 apn          - Show APN settings"
        Write-Host "  .\network.ps1 speedtest    - Run speed test"
        Write-Host "  .\network.ps1 optimize     - Apply optimizations"
    }
}
