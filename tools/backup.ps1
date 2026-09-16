# backup.ps1 - Backup UZ801 device partitions
# Usage: .\backup.ps1
# WARNING: This creates large files (several GB total)

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

$BACKUP_DIR = "backups\$(Get-Date -Format 'yyyy-MM-dd_HHmmss')"
New-Item -ItemType Directory -Force -Path $BACKUP_DIR | Out-Null

Write-Host "=== UZ801 Backup Tool ===" -ForegroundColor Cyan
Write-Host "Backup directory: $BACKUP_DIR" -ForegroundColor Gray
Write-Host ""

# Critical partitions to backup (safe to dump, won't brick if only reading)
$partitions = @(
    @{ Name = "modem";    Block = "mmcblk0p1";  Size = "64MB";   Priority = "CRITICAL" },
    @{ Name = "sbl1";     Block = "mmcblk0p2";  Size = "512KB";  Priority = "CRITICAL" },
    @{ Name = "aboot";    Block = "mmcblk0p4";  Size = "1MB";    Priority = "CRITICAL" },
    @{ Name = "rpm";      Block = "mmcblk0p6";  Size = "512KB";  Priority = "CRITICAL" },
    @{ Name = "tz";       Block = "mmcblk0p8";  Size = "512KB";  Priority = "CRITICAL" },
    @{ Name = "hyp";      Block = "mmcblk0p10"; Size = "512KB";  Priority = "HIGH" },
    @{ Name = "splash";   Block = "mmcblk0p18"; Size = "10MB";   Priority = "LOW" },
    @{ Name = "boot";     Block = "mmcblk0p22"; Size = "16MB";   Priority = "HIGH" },
    @{ Name = "system";   Block = "mmcblk0p23"; Size = "800MB";  Priority = "HIGH" },
    @{ Name = "persist";  Block = "mmcblk0p24"; Size = "32MB";   Priority = "CRITICAL" },
    @{ Name = "cache";    Block = "mmcblk0p25"; Size = "128MB";  Priority = "LOW" },
    @{ Name = "recovery"; Block = "mmcblk0p26"; Size = "16MB";   Priority = "MEDIUM" },
    @{ Name = "userdata"; Block = "mmcblk0p27"; Size = "2.5GB";  Priority = "MEDIUM" }
)

Write-Host "Partitions to backup:" -ForegroundColor Yellow
foreach ($p in $partitions) {
    $color = switch ($p.Priority) {
        "CRITICAL" { "Red" }
        "HIGH" { "Yellow" }
        "MEDIUM" { "Cyan" }
        "LOW" { "Gray" }
    }
    Write-Host ("  {0,-12} ({1,-8}) - {2}" -f $p.Name, $p.Size, $p.Priority) -ForegroundColor $color
}

Write-Host ""
$confirm = Read-Host "Start backup? (y/n)"
if ($confirm -ne "y") {
    Write-Host "Backup cancelled." -ForegroundColor Red
    exit
}

# Create md5sums file
$md5File = "$BACKUP_DIR\md5sums.txt"

foreach ($p in $partitions) {
    $outFile = "$BACKUP_DIR\$($p.Name).img"
    $blockPath = "/dev/block/bootdevice/by-name/$($p.Name)"
    
    Write-Host "`nBacking up $($p.Name) ($($p.Size))..." -ForegroundColor Yellow
    
    # Check if partition exists
    $exists = & $ADB shell "ls $blockPath 2>/dev/null"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Partition not found at $blockPath, skipping..." -ForegroundColor Gray
        continue
    }
    
    # Dump partition
    $start = Get-Date
    & $ADB shell "dd if=$blockPath of=/sdcard/$($p.Name).img bs=4096" 2>&1
    & $ADB pull "/sdcard/$($p.Name).img" $outFile 2>&1
    & $ADB shell "rm /sdcard/$($p.Name).img" 2>&1
    
    $end = Get-Date
    $duration = ($end - $start).TotalSeconds
    $size = (Get-Item $outFile).Length / 1MB
    
    Write-Host ("  Done: {0:N1} MB in {1:N1}s" -f $size, $duration) -ForegroundColor Green
    
    # Calculate MD5
    $md5 = (Get-FileHash -Algorithm MD5 -Path $outFile).Hash
    "$md5  $($p.Name).img" | Out-File -Append -FilePath $md5File
    Write-Host "  MD5: $md5" -ForegroundColor Gray
}

# Also backup build.prop and key configs
Write-Host "`nBacking up configuration files..." -ForegroundColor Yellow
& $ADB shell "cat /system/build.prop" | Out-File -FilePath "$BACKUP_DIR\build.prop" -Encoding UTF8
& $ADB shell "cat /proc/version" | Out-File -FilePath "$BACKUP_DIR\kernel-version.txt" -Encoding UTF8
& $ADB shell "cat /proc/partitions" | Out-File -FilePath "$BACKUP_DIR\partitions.txt" -Encoding UTF8
& $ADB shell "getprop" | Out-File -FilePath "$BACKUP_DIR\all-properties.txt" -Encoding UTF8

Write-Host "`n=== Backup Complete ===" -ForegroundColor Green
Write-Host "All files saved to: $BACKUP_DIR" -ForegroundColor Cyan
Write-Host "MD5 checksums: $md5File" -ForegroundColor Gray
Write-Host ""
Write-Host "IMPORTANT: Keep these backups safe!" -ForegroundColor Yellow
Write-Host "If you brick the device, these can restore it." -ForegroundColor Yellow
