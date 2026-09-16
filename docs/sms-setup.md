# SMS & Call Setup Guide - UZ801

## Overview

The UZ801 has full telephony support:
- SMS/MMS capability
- Voice calls (if SIM supports it)
- VoLTE (if carrier supports it)
- Data (already working)

## Sending SMS from Windows

### Method 1: PowerShell Script (Recommended)
```powershell
# Send SMS
.\tools\sms.ps1 send "+381601234567" "Hello from PC!"

# List received SMS
.\tools\sms.ps1 list

# Watch for new SMS
.\tools\sms.ps1 watch
```

### Method 2: Direct ADB Commands
```bash
# Send SMS
adb shell content insert --uri content://sms \
  --bind address:s:"+381601234567" \
  --bind body:s:"Hello World" \
  --bind type:i:2

# Read all SMS
adb shell content query --uri content://sms \
  --projection _id:address:body:date

# Delete SMS
adb shell content delete --uri content://sms --where "_id=123"
```

### Method 3: Android Intents
```bash
# Open SMS app with pre-filled message
adb shell am start -a android.intent.action.SENDTO \
  -d "sms:+381601234567" \
  --es sms_body "Hello"
```

## Making Phone Calls

### From ADB
```bash
# Make a call
adb shell am start -a android.intent.action.CALL -d tel:+381601234567

# Open dialer with number
adb shell am start -a android.intent.action.DIAL -d tel:+381601234567
```

### Auto-Answer (Advanced)
```bash
# Auto-answer incoming calls
adb shell service call telecom 1 i32 1

# End call
adb shell service call telecom 1 i32 0
```

## Reading SMS Programmatically

### Export SMS to PC
```bash
# Export all SMS as XML
adb shell content query --uri content://sms --xml > sms_backup.xml

# Export as CSV
adb shell content query --uri content://sms \
  --projection _id:address:body:date:type > sms_backup.csv
```

### Watch for Verification Codes
```powershell
# Monitor for new SMS containing codes
.\tools\sms.ps1 watch
# Then look for patterns like:
# "Your verification code is 123456"
# "Код подтверждения: 123456"
```

## Carrier Configuration

### Check Current APN
```bash
adb shell content query --uri content://telephony/carriers/preferapn
```

### Set APN for Your Carrier
```bash
# Add new APN
adb shell content insert --uri content://telephony/carriers \
  --bind name:s:"My Carrier" \
  --bind apn:s:"internet" \
  --bind mcc:i:220 \
  --bind mnc:i:01 \
  --bind type:s:"default,supl,mms"

# Set as preferred
adb shell content update --uri content://telephony/carriers/preferapn \
  --bind apn_id:i:<apn_id>
```

### Common Serbian APNs
| Carrier | APN | MCC | MNC |
|---------|-----|-----|-----|
| Yettel | internet | 220 | 01 |
| A1 | internet | 220 | 01 |
| MTS | internet | 220 | 02 |

## VoLTE Setup

### Check VoLTE Support
```bash
# Check IMS registration
adb shell getprop persist.radio.calls.on.ims

# Check VoLTE setting
adb shell settings get global volte_vt_enabled
```

### Enable VoLTE
```bash
adb shell settings put global volte_vt_enabled 1
adb shell setprop persist.radio.calls.on.ims 1
```

## Troubleshooting

### SMS Not Sending
1. Check SIM state: `adb shell getprop gsm.sim.state`
2. Check signal: `adb shell getprop gsm.signalstrength`
3. Check APN: `adb shell content query --uri content://telephony/carriers/preferapn`
4. Check SMS center: `adb shell getprop gsm.sim.operator.numeric`

### No Cellular Service
1. Check airplane mode: `adb shell settings get global airplane_mode_on`
2. Check radio: `adb shell getprop gsm.network.type`
3. Check operator: `adb shell getprop gsm.operator.alpha`
4. Toggle radio: `adb shell cmd phone radio power on`

### Call Quality Issues
1. Check signal strength
2. Enable HD voice: `adb shell settings put global enhanced_4g_mode_enabled 1`
3. Check codec: `adb shell dumpsys telephony.registry | grep -i codec`

## Integration with Windows

### Task Scheduler (Auto-Forward SMS)
Create a task that runs `.\tools\sms.ps1 watch` and forwards to email/Telegram.

### PowerShell GUI
```powershell
# Simple SMS window
Add-Type -AssemblyName System.Windows.Forms
$form = New-Object System.Windows.Forms.Form
$form.Text = "UZ801 SMS"
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Multiline = $true
$textBox.Dock = 'Fill'
$form.Controls.Add($textBox)
$form.Show()
```

### Monitor Script
```powershell
# Save as monitor-sms.ps1
while ($true) {
    $sms = adb shell content query --uri content://sms --projection body --sort 'date DESC' --limit 1
    if ($sms -match "verification|code|код") {
        # Forward to Telegram/email/etc
        Write-Host "VERIFICATION CODE FOUND: $sms"
    }
    Start-Sleep -Seconds 5
}
```
