# UZ801 Linux Hack

Hack a $13 4G LTE USB dongle to run Debian Linux.

**Device**: UZ801 (Qualcomm MSM8916 / Snapdragon 410)
**Goal**: Replace stock Android 4.4.4 with Debian Linux, keeping 4G/LTE and SMS working.

## Status

| Component | Status |
|-----------|--------|
| Device rooted | Confirmed |
| ADB access | Working |
| Stock firmware backed up | Done |
| EDL mode accessible | Confirmed (QHSUSB__BULK) |
| EDL reads (GPT) | Working |
| EDL writes | **Hanging** - read works, write timeouts |
| Fastboot | Unreliable - `adb reboot bootloader` doesn't enter fastboot |
| Linux installed | **Not yet** |

## Hardware

| Spec | Value |
|------|-------|
| Model | UZ801 |
| SoC | Qualcomm MSM8916 (Snapdragon 410) |
| RAM | ~388MB (512MB nominal) |
| Storage | ~3.8GB eMMC |
| Android | 4.4.4 (userdebug, test-keys) |
| Root | Yes - uid=0 |
| USB | RNDIS + ADB |
| Carrier | Any (uses standard SIM) |

### USB Interfaces

```
MI_00: Remote NDIS (network) - OK
MI_02: Android (needs driver) - Error
MI_03: Android (needs driver) - Error
MI_04: ADB Interface - OK
```

### Default Network Config

- **Gateway**: 192.168.100.1
- **Web UI**: http://192.168.100.1 (admin / admin)
- **WiFi**: SSID `4G-UFI-XX`, Password `1234567890`
- **ADB enable**: http://192.168.100.1/usbdebug.html

## Prerequisites

- Windows or Linux PC
- USB cable with data support
- Qualcomm USB drivers (for EDL mode)
- ADB and fastboot installed

### Windows

```powershell
# ADB/fastboot - download from https://developer.android.com/tools/releases/platform-tools
# Qualcomm drivers - see drivers/ folder or run:
.\tools\install-drivers.ps1
```

### Linux (Debian/Ubuntu)

```bash
sudo apt install adb fastboot android-tools-adb
sudo usermod -aG plugdev $USER
# Log out and back in for group to take effect
```

## Quick Start

### 1. Connect

```powershell
# Windows
.\tools\connect.ps1

# Linux
adb devices
adb shell id  # Should show uid=0(root)
```

### 2. Backup Stock Firmware

```powershell
# Windows
.\tools\backup.ps1

# Linux
adb shell dd if=/dev/block/bootdevice/by-name/modem of=/sdcard/modem.img
adb pull /sdcard/modem.img
```

### 3. Explore Device

```powershell
# Windows
.\tools\explore.ps1

# Linux - see docs/findings.md for key commands
adb shell getprop ro.product.model
adb shell cat /proc/version
```

## Installing Linux (OpenStick)

**Recommended**: Use the [OpenStick project](https://github.com/OpenStick/OpenStick/releases) for pre-built Debian images.

### Step 1: Get the Image

Download from [OpenStick releases](https://github.com/OpenStick/OpenStick/releases):
- `openstick-bookworm.img` - Debian Bookworm (recommended)

### Step 2: Enter Fastboot

**Important**: `adb reboot bootloader` may not work reliably on UZ801. Try:

```powershell
# Method 1: ADB (may or may not work)
adb reboot bootloader

# Method 2: Physical button
# Hold reset button for 5 seconds while plugged in
```

### Step 3: Flash

```bash
fastboot devices  # Verify connection

fastboot flash boot openstick-boot.img
fastboot flash system openstick-rootfs.img
fastboot reboot
```

### Alternative: EDL Mode

If fastboot doesn't work, EDL mode is always available:

```bash
# Enter EDL
adb reboot edl

# Flash via bkerler/edl tool
git clone https://github.com/bkerler/edl.git
cd edl && pip install -r requirements.txt
python edl.py w openstick-bookworm.img
```

### After First Boot

- WiFi: `4G-UFI-XX` (password: `1234567890`)
- SSH: `ssh user@192.168.100.1` (password: `1`)
- USB: `ssh user@192.168.200.1`

## Tools

PowerShell scripts for Windows (also works on Linux with `adb` in PATH):

| Script | Purpose |
|--------|---------|
| `connect.ps1` | Connect to device via ADB |
| `explore.ps1` | Deep device exploration |
| `backup.ps1` | Backup stock firmware partitions |
| `shell.ps1` | Open ADB shell as root |
| `sms.ps1` | Send/receive SMS via ADB |
| `network.ps1` | Network status and configuration |
| `install-app.ps1` | Install APK files |
| `quickref.ps1` | Quick command reference |
| `flash-linux.ps1` | Flash Linux image |
| `install-drivers.ps1` | Install Qualcomm drivers (Windows) |
| `install-fastboot-driver.ps1` | Install fastboot driver (Windows) |
| `check-fastboot.ps1` | Check fastboot status |

## Documentation

- [Device Info](docs/device-info.md) - Hardware, USB config, known facts
- [Research Findings](docs/findings.md) - Community findings, what works in Linux
- [OpenWrt / Debian](docs/openwrt.md) - Linux installation guide
- [Recovery](docs/recovery.md) - EDL recovery, restoring stock firmware
- [SMS Setup](docs/sms-setup.md) - SMS and call configuration

## Stock Firmware Backups

Critical partitions backed up from our device:

- `backups/stock-2026-09-16/modem.img` - Baseband (contains IMEI)
- `backups/stock-2026-09-16/persist.img` - WiFi/BT calibration
- `backups/stock-2026-09-16/boot.img` - Android kernel
- `backups/stock-2026-09-16/system.img` - Android system (partial)

**Warning**: Never flash stock partitions from a different board version.

## Known Issues

1. **Fastboot unreliable**: `adb reboot bootloader` often boots to Android instead of fastboot
2. **EDL writes hang**: Reads work, but writes timeout (Windows issue - try Linux)
3. **Board version unknown**: Device shows `V2.3.15.1` but community says V3.0 is best
4. **No scrcpy**: Android 4.4.4 is too old (requires API 21+)

## Recovery

The device is **always recoverable** via EDL mode:

```bash
# Enter EDL (hardware)
# Open device, short D+ to GND on USB while plugging in
# Or: adb reboot edl (if ADB works)

# Restore stock firmware
python edl.py wf stock-uz801.bin
```

See [Recovery Guide](docs/recovery.md) for details.

## Resources

- [OpenStick](https://github.com/OpenStick/OpenStick) - Main Linux project for MSM8916 sticks
- [bkerler/edl](https://github.com/bkerler/edl) - EDL flash tool
- [AlienWolfX Wiki](https://github.com/AlienWolfX/UZ801-USB-MODEM/wiki) - UZ801 guide
- [OpenWrt Forum](https://forum.openwrt.org/t/uf896-qualcomm-msm8916-lte-router-384mib-ram-2-4gib-flash-android-openwrt/131712) - Community discussion
- [postmarketOS](https://wiki.postmarketos.org/wiki/Zhihe_series_LTE_dongles_(generic-zhihe)) - Linux support

## License

This is a research/hacking project. Use at your own risk.
