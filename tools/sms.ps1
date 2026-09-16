# sms.ps1 - Send and receive SMS from Windows via UZ801
# Usage:
#   .\sms.ps1 send "+381601234567" "Hello from PC"
#   .\sms.ps1 list              # List recent SMS
#   .\sms.ps1 read <id>         # Read specific SMS
#   .\sms.ps1 watch             # Watch for new SMS in real-time

param(
    [Parameter(Position=0)]
    [string]$Action,
    
    [Parameter(Position=1)]
    [string]$Arg1,
    
    [Parameter(Position=2)]
    [string]$Arg2
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

function Send-SMS($number, $message) {
    Write-Host "Sending SMS to $number..." -ForegroundColor Yellow
    # Use Android's am command to launch SMS with intent
    & $ADB shell "am start -a android.intent.action.SENDTO -d 'sms:$number' --es sms_body '$message' --ez exit_on_sent true" 2>&1
    Start-Sleep -Seconds 2
    # Alternative: Use service call (requires root)
    & $ADB shell "content insert --uri content://sms --bind address:s:$number --bind body:s:'$message' --bind type:i:2" 2>&1
    Write-Host "[OK] SMS sent (or queued)" -ForegroundColor Green
}

function Get-SMSList() {
    Write-Host "Recent SMS messages:" -ForegroundColor Cyan
    & $ADB shell "content query --uri content://sms --projection _id:address:body:date:type --sort 'date DESC' --limit 20" 2>&1
}

function Read-SMS($id) {
    Write-Host "SMS #$id:" -ForegroundColor Cyan
    & $ADB shell "content query --uri content://sms/$id" 2>&1
}

function Watch-SMS() {
    Write-Host "Watching for new SMS... (Ctrl+C to stop)" -ForegroundColor Yellow
    Write-Host "Tip: Send an SMS to this SIM card now" -ForegroundColor Gray
    
    # Get current count
    $before = & $ADB shell "content query --uri content://sms --projection _id --sort 'date DESC' --limit 1" 2>&1
    $lastId = 0
    if ($before -match '_id=(\d+)') {
        $lastId = [int]$Matches[1]
    }
    Write-Host "Current latest SMS ID: $lastId" -ForegroundColor Gray
    
    while ($true) {
        Start-Sleep -Seconds 3
        $current = & $ADB shell "content query --uri content://sms --projection _id:address:body:date --sort 'date DESC' --limit 1" 2>&1
        if ($current -match '_id=(\d+)') {
            $currentId = [int]$Matches[1]
            if ($currentId -gt $lastId) {
                Write-Host "`n[NEW SMS] $current" -ForegroundColor Green
                $lastId = $currentId
            }
        }
    }
}

# Main
switch ($Action) {
    "send" {
        if (-not $Arg1 -or -not $Arg2) {
            Write-Host "Usage: .\sms.ps1 send <number> <message>" -ForegroundColor Red
            exit 1
        }
        Send-SMS $Arg1 $Arg2
    }
    "list" {
        Get-SMSList
    }
    "read" {
        if (-not $Arg1) {
            Write-Host "Usage: .\sms.ps1 read <sms_id>" -ForegroundColor Red
            exit 1
        }
        Read-SMS $Arg1
    }
    "watch" {
        Watch-SMS
    }
    default {
        Write-Host "=== UZ801 SMS Tool ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor Yellow
        Write-Host "  .\sms.ps1 send <number> <message>  - Send SMS"
        Write-Host "  .\sms.ps1 list                     - List recent SMS"
        Write-Host "  .\sms.ps1 read <id>                - Read specific SMS"
        Write-Host "  .\sms.ps1 watch                    - Watch for new SMS"
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor Yellow
        Write-Host '  .\sms.ps1 send "+381601234567" "Hello!"'
        Write-Host "  .\sms.ps1 list"
        Write-Host "  .\sms.ps1 watch"
    }
}
