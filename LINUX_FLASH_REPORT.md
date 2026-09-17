# UZ801 Linux Flashing - Full Technical Report

## Device Info

- **Model**: UZ801
- **SoC**: Qualcomm MSM8916 (Snapdragon 410)
- **Android**: 4.4.4 KitKat (userdebug, test-keys)
- **Build**: V2.3.15.1
- **Root**: Yes (uid=0, ships rooted)
- **Board**: FY_UZ801 (version unknown, likely V2.x based on build string)
- **RAM**: ~388MB
- **Storage**: ~3.8GB eMMC
- **USB PID**: 90B6 (Android), 9008 (EDL)

## Current State

**Android is restored and working.** We used QFIL on Windows to flash the full stock firmware via EDL mode. Device boots normally now.

## What We're Trying To Do

Replace stock Android 4.4.4 with Debian Linux (OpenStick project) while keeping 4G/LTE and SMS working.

## What Was Tried (Chronological)

### Phase 1: Initial Exploration (Windows)
1. Connected via ADB - confirmed root access
2. Explored device: hardware, partitions, network, radio
3. Backed up critical partitions: modem.img (64MB), persist.img (32MB), boot.img (16MB), system.img (1.25MB)
4. Downloaded Qualcomm drivers (modem, diagnostics, Google USB)

### Phase 2: Fastboot Attempt (Windows)
1. `adb reboot bootloader` - **DOES NOT reliably enter fastboot** on this device. Device usually boots to Android instead.
2. At one point fastboot WAS detected (`a85d0d9 fastboot`) and we successfully flashed `aboot.bin` via `fastboot flash aboot aboot.bin`
3. After that, fastboot became unreliable - device would not enter bootloader mode
4. `fastboot oem dump` commands fail with "unknown command" - stock bootloader doesn't support OEM commands

### Phase 3: EDL Attempt - bkerler/edl (Windows)
1. `adb reboot edl` - device enters EDL mode (shows as QHSUSB__BULK / Qualcomm HS-USB QDLoader 9008)
2. Installed bkerler/edl tool (V3.62), downloaded `MSM8916.mbn` firehose programmer
3. **EDL reads work**: `python edl.py printgpt` succeeds, can read GPT table
4. **EDL writes HANG**: `python edl.py w <file>` times out. Sahara protocol connects, firehose loads, but write commands never complete. This is a Windows-specific issue (pyusb/libusb on Windows).

### Phase 4: EDL Attempt - bkerler/edl (Linux)
1. Booted to Linux
2. Same issue - EDL reads work but writes hang with protocol timeout
3. AI suggested the partition may have been corrupted by previous failed flash attempts

### Phase 5: QFIL on Windows (What Finally Worked)
1. Power-cycled device (cold: unplug USB, wait 10s, hold reset while plugging in)
2. Opened QFIL (QPST v2.0.3.5) at `C:\Program Files (x86)\Qualcomm\QPST\bin\QFIL.exe`
3. Selected "Flat Build"
4. Programmer: `C:\Users\Sectorfive\Documents\stock-uz801\prog_emmc_firehose_8916.mbn`
5. Load XML: `rawprogram0.xml` then `patch0.xml` (both from `C:\Users\Sectorfive\Documents\stock-uz801\`)
6. Port showed COM3 (Qualcomm HS-USB QDLoader 9008)
7. Clicked "Download"
8. **rawprogram0.xml flash SUCCEEDED** (writes all 26 partitions including boot, aboot, modem, system, etc.)
9. patch0.xml step failed ("XML packet not formed correctly") but this is post-flash and didn't affect the result
10. Device stayed in EDL after flash (needed power cycle)
11. Unplugged USB, waited 5s, plugged back in WITHOUT holding reset
12. **DEVICE BOOTED TO ANDROID** - LED went red then blue, ADB interface appeared

## Stock Firmware Files Used

All in `C:\Users\Sectorfive\Documents\stock-uz801\`:

```
prog_emmc_firehose_8916.mbn    - Firehose programmer for MSM8916
rawprogram0.xml                 - Partition layout (26 partitions)
patch0.xml                      - Post-flash patches (empty, not critical)
modem.bin      (64MB)           - Baseband firmware
sbl1.bin       (512KB)          - Secondary bootloader
aboot.bin      (1MB)            - Android bootloader
rpm.bin        (512KB)          - Resource Power Manager
tz.bin         (512KB)          - TrustZone
hyp.bin        (512KB)          - Hypervisor
boot.bin       (16MB)           - Android kernel + ramdisk
persist.bin    (32MB)           - WiFi/BT calibration
recovery.bin   (16MB)           - Recovery mode
splash.bin     (10MB)           - Boot splash screen
fsg.bin        (1.5MB)          - Filesystem for modem
modemst1/2.bin (1.5MB each)     - Modem storage
misc.bin       (1MB)            - Misc (boot control)
pad.bin        (1MB)            - Padding
DDR.bin        (32KB)           - DDR training data
sec.bin        (16KB)           - Security
fsc.bin        (1KB)            - Filesystem config
ssd.bin        (8KB)            - SSD config
gpt_main0.bin  (4.6KB)          - Primary GPT
gpt_backup0.bin (3.6KB)         - Backup GPT
```

## Backups We Made

In `backups/stock-2026-09-16/`:
- `modem.img` (64MB) - baseband firmware
- `persist.img` (32MB) - WiFi/BT calibration
- `boot.img` (16MB) - Android kernel
- `system.img` (1.25MB) - Android system (partial)

## Key Findings

### What Works
- ADB root shell
- EDL mode (via `adb reboot edl`)
- EDL reads via bkerler/edl
- QFIL flash of full stock firmware
- Fastboot (when device enters bootloader mode)
- SMS, calls, 4G/LTE, WiFi

### What Doesn't Work
- `adb reboot bootloader` - unreliable, usually boots to Android instead
- bkerler/edl writes on Windows - hangs on firehose protocol
- bkerler/edl writes on Linux - same hang issue
- `fastboot oem dump` - stock bootloader doesn't support OEM commands
- scrcpy - requires Android 5.0+, device is 4.4.4

### Critical: Fastboot Entry
The device does NOT reliably enter fastboot via `adb reboot bootloader`. The only reliable ways to enter fastboot:
1. **Hold reset button for 5 seconds** while plugging in USB
2. **If Android is running**: Try `adb reboot bootloader` (works sometimes)
3. **From EDL**: Not possible - EDL and fastboot are separate modes

## How to Flash Linux Without Bricking

### Prerequisites (on Windows)
1. QFIL/QPST installed (for emergency recovery)
2. Stock firmware in `stock-uz801/` folder (for emergency recovery)
3. ADB and fastboot in PATH
4. OpenStick Debian image downloaded

### Recommended Flash Procedure

**IMPORTANT: Always keep the stock firmware ready for QFIL recovery.**

#### Step 1: Enter Fastboot
Since `adb reboot bootloader` is unreliable:
1. Try `adb reboot bootloader` first
2. If it boots to Android instead, try: Hold reset button 5s while plugging in USB
3. Verify: `fastboot devices` should show the device

#### Step 2: Flash OpenStick
```bash
fastboot flash boot openstick-boot.img
fastboot flash system openstick-rootfs.img
fastboot reboot
```

#### Step 3: If It Doesn't Boot
1. Enter EDL: `adb reboot edl` (or hold reset 10s while plugging in)
2. Open QFIL, load stock firmware (prog_emmc_firehose_8916.mbn + rawprogram0.xml + patch0.xml)
3. Flash to restore Android
4. Power cycle, try again

### What NOT To Do
1. **DO NOT flash aboot.bin via EDL** unless you know what you're doing - this is the Android bootloader
2. **DO NOT interrupt a QFIL flash** - this corrupts partitions
3. **DO NOT use `fastboot flash aboot`** with non-matching firmware - this was what caused our brick
4. **DO NOT delete/wipe the boot partition** without having a replacement ready
5. **DO NOT try bkerler/edl writes on Windows** - they hang and can leave device in bad state
6. **DO NOT use `adb reboot edl` followed by immediate flash** - power cycle first after any failed attempt

### Emergency Recovery (If Device Is Bricked)

**The device is NEVER truly bricked** as long as EDL mode works.

1. Cold power cycle: Unplug USB, wait 10s
2. Hold reset button while plugging in USB (enters EDL)
3. Open QFIL (C:\Program Files (x86)\Qualcomm\QPST\bin\QFIL.exe)
4. Flat Build → Browse → prog_emmc_firehose_8916.mbn
5. Load XML → rawprogram0.xml, then patch0.xml
6. Port should show COM3 (9008)
7. Click Download
8. After flash completes: Unplug, wait 5s, plug back in normally
9. Device should boot to Android

### Sahara Protocol Issue
The PBL (Primary BootLoader) in EDL mode only allows ONE Sahara session. If it fails or times out:
- Device locks down and rejects all further commands
- **Must do cold power cycle** (unplug USB completely, wait 5-10s) to reset
- Hold reset button while plugging back in to re-enter EDL
- Then flash IMMEDIATELY - don't try command-line tools first, use QFIL GUI

## Advice for Linux AI

1. **Use QFIL on Windows** for flashing, not bkerler/edl - the Windows pyusb/libusb stack has issues with EDL writes
2. **Keep stock firmware folder** (`stock-uz801/`) as emergency recovery - never delete it
3. **Fastboot is unreliable** on this device - plan for EDL-based recovery
4. **The board version is likely V2.x** (build string V2.3.15.1) - not V3.0 which community says is best for Linux
5. **Before attempting Linux flash**: Make sure fastboot mode can be entered reliably. If not, try holding the physical reset button.
6. **After any failed flash**: Power cycle completely before trying again. Don't chain flash attempts.
7. **Test fastboot first**: Before downloading OpenStick images, verify `fastboot devices` works. If it doesn't, you need to solve the fastboot entry problem before attempting to flash.
