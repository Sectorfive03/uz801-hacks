# Recovery Procedures - UZ801

## Overview

The UZ801 is **very recoverable** thanks to Qualcomm EDL mode. Even if you completely brick the device, you can always restore it.

## Recovery Methods (Easiest to Hardest)

### Method 1: ADB Reboot (Soft Recovery)
```bash
# If device is responsive
adb reboot

# If stuck in bootloop
adb reboot recovery
adb reboot bootloader
adb reboot edl
```

### Method 2: Fastboot (Medium Recovery)
```bash
# Enter fastboot mode
adb reboot bootloader

# Or hold reset button for 5 seconds while plugging in USB

# Verify
fastboot devices

# Flash specific partitions
fastboot flash boot backups/boot.img
fastboot flash system backups/system.img

# Reboot
fastboot reboot
```

### Method 3: EDL Mode (Hard Recovery)

**Always works**, even with completely dead device.

#### Entering EDL Mode
1. **Via ADB**: `adb reboot edl`
2. **Via Fastboot**: `fastboot oem reboot-edl`
3. **Hardware test points**:
   - Open device case
   - Find EDL test points on PCB (usually labeled)
   - Short them while connecting USB
   - Device shows as `Qualcomm HS-USB QDLoader 9008`

#### EDL Tool Setup
```bash
# Clone the tool
git clone https://github.com/bkerler/edl.git
cd edl
pip install -r requirements.txt

# Verify device detected
python edl.py
# Should show: Device detected, Mode: sahara or firehose
```

#### Restore from Full Backup
```bash
# Single file restore
python edl.py wf stock-uz801.bin
```

#### Restore Individual Partitions
```bash
# Restore boot partition
python edl.py wf boot.img --partition=boot

# Restore system partition
python edl.py wf system.img --partition=system

# Restore modem partition (CRITICAL - contains IMEI)
python edl.py wf modem.img --partition=modem
```

#### Create Full Backup (Before Bricking)
```bash
# Full eMMC dump (~3.7GB)
python edl.py rf stock-uz801.bin

# Compress
bzip2 -9 stock-uz801.bin

# Individual partitions
python edl.py rl stock-uz801_backup --genxml
```

## Partition Recovery Guide

### What Each Partition Does
| Partition | Risk Level | Recovery |
|-----------|-----------|----------|
| **modem** | CRITICAL | Contains IMEI and baseband. Loss = no cellular |
| **tz** | CRITICAL | TrustZone. Corruption = hard brick |
| **sbl1** | CRITICAL | Bootloader. Corruption = hard brick |
| **persist** | CRITICAL | WiFi/BT calibration. Loss = WiFi/BT dead |
| **boot** | HIGH | Kernel. Can restore via recovery/fastboot |
| **system** | HIGH | Android OS. Can restore via recovery/fastboot |
| **recovery** | MEDIUM | Recovery partition. Can restore via EDL |
| **cache** | LOW | Cache. Safe to wipe |
| **userdata** | LOW | User data. Safe to wipe |

### Restore Critical Partitions
```bash
# If modem is broken (no cellular)
python edl.py wf modem.img --partition=modem

# If WiFi/BT is broken
python edl.py wf persist.img --partition=persist

# If device won't boot at all
python edl.py wf sbl1.img --partition=sbl1
python edl.py wf aboot.img --partition=aboot
python edl.py wf tz.img --partition=tz
python edl.py wf rpm.img --partition=rpm
```

## Stock Firmware Recovery

### Download Stock Blobs
Pre-made stock firmware available at:
- https://github.com/OpenStick/stick-blobs/tree/main/stock-uz801
- https://github.com/Mio-sha512/openstick-stuff/releases

### Restore to Stock
```bash
# Download stock firmware
# (from stock blobs repo or your own backup)

# Flash via EDL
python edl.py wf stock-uz801.bin

# Or flash individual partitions
python edl.py wf modem.img --partition=modem
python edl.py wf boot.img --partition=boot
python edl.py wf system.img --partition=system
```

## Common Issues and Fixes

### Device Shows `QHSUSB__BULK` (EDL Mode)
This is normal! Device is in EDL mode waiting for flashing.

### Device Not Detected in EDL
1. Try different USB port
2. Install Qualcomm USB drivers
3. Check Device Manager for unknown device
4. Try: `python edl.py printgpt` to verify connection

### After Flashing, Device Won't Boot
1. Enter fastboot: Hold reset button while plugging in USB
2. Flash boot partition: `fastboot flash boot boot.img`
3. If that fails, go to EDL and flash everything

### Modem Works in Android but Not in Linux
The modem firmware in `/lib/firmware` may not match your board version.

**Fix**: Copy firmware from stock `modem.bin` partition:
```bash
# From Android
adb shell dd if=/dev/block/bootdevice/by-name/modem of=/sdcard/modem.bin
adb pull /sdcard/modem.bin

# In Linux, copy to /lib/firmware/
sudo cp modem.bin /lib/firmware/
```

### WiFi/BT Not Working
The `persist` partition contains calibration data. If lost, WiFi/BT won't work.

**Fix**: Restore persist partition from backup.

## Prevention Checklist

Before modifying anything:
- [ ] Run `.\tools\backup.ps1` (ADB backup)
- [ ] Run EDL full backup (`edl rf stock-uz801.bin`)
- [ ] Store backups off-device (PC, cloud)
- [ ] Verify backup integrity (md5sums)
- [ ] Document what you changed
- [ ] Test changes in /tmp first (ramfs)

## Emergency Contacts

### If Nothing Works
1. **EDL mode** - Always accessible via test points
2. **Serial console** - Solder UART pins, get shell
3. **JTAG** - Last resort, direct flash access
4. **Replace** - It's $13, sometimes cheaper than time

### Useful URLs
- EDL tool: https://github.com/bkerler/edl
- Stock firmware: https://github.com/OpenStick/stick-blobs
- Recovery guide: https://github.com/AlienWolfX/UZ801-USB-MODEM/wiki/Recovery
