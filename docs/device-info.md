# Device Info - UZ801

## Hardware

| Spec | Value |
|------|-------|
| Model | UZ801 |
| SoC | Qualcomm MSM8916 (Snapdragon 410) |
| CPU | Quad-core ARM Cortex-A53 @ 1.2GHz |
| GPU | Adreno 306 |
| RAM | ~388MB (512MB nominal) |
| Storage | ~3.8GB eMMC |
| Board | FY_UZ801 (check silkscreen: V2.1, V3.0, or V3.2) |
| Android | 4.4.4 KitKat (userdebug, test-keys) |
| Build | V2.3.15.1 |

## Root Access

```
uid=0(root) - confirmed
```

No exploit needed. Device ships with root enabled.

## USB Configuration

### Interface Layout

| Interface | Purpose | Status |
|-----------|---------|--------|
| MI_00 | Remote NDIS (network) | Working |
| MI_02 | Android (ADB?) | Error (no driver) |
| MI_03 | Android (serial?) | Error (no driver) |
| MI_04 | ADB Interface | Working |

### USB Properties

```
persist.sys.usb.config=rndis,serial_smd,diag,adb
```

All interfaces enabled: RNDIS (network), serial, diagnostics, ADB.

## Network Configuration

### Default IPs

| Interface | IP | Purpose |
|-----------|----|---------|
| USB RNDIS | 192.168.100.1 | Device gateway (default) |
| USB Tethering | 192.168.100.122 | Host IP from device |
| WiFi Hotspot | 192.168.43.1 | Android hotspot |

### Web Interface

- **URL**: http://192.168.100.1
- **Login**: admin / admin
- **ADB Enable**: http://192.168.100.1/usbdebug.html
- **IMEI Change**: Possible via web UI (!)

### WiFi

- **Default SSID**: 4G-UFI-XX (where XX = last 4 of MAC)
- **Default Password**: 1234567890
- **Standard**: 802.11n (2.4GHz, 150 Mbps)

## Key Properties

```bash
ro.build.type=userdebug
ro.build.tags=test-keys
ro.product.model=UZ801
ro.build.version.release=4.4.4
persist.adb.tcp.port=7628
```

## Diag Port

- **Path**: `/dev/diag`
- **Group**: qcom_diag
- **Enable**: `setprop sys.usb.config rndis,serial_smd,diag,adb`
- **Use with**: [QCsuper](https://github.com/nicman23/qcsuper) for network analysis

## EDL Mode (Emergency Download)

### Entering EDL

1. **ADB**: `adb reboot edl`
2. **Hardware**: Short D+ to GND on USB while plugging in

### Device Info (EDL)

| Field | Value |
|-------|-------|
| HWID | 0x007050e100000000 (MSM8916) |
| PK_HASH | 0xcc3153a80293939b... |
| Serial | 0x1234567a |
| Unfused | Yes (any loader works) |

### Known Issues

- **EDL reads work**: `edl printgpt` succeeds
- **EDL writes hang**: `edl w` times out on Windows (try Linux)

## Partition Layout

Key partitions (from `adb shell ls /dev/block/bootdevice/by-name/`):

| Partition | Size | Risk | Purpose |
|-----------|------|------|---------|
| modem | 64MB | CRITICAL | Baseband firmware, IMEI |
| persist | 32MB | CRITICAL | WiFi/BT calibration |
| boot | 16MB | HIGH | Kernel + ramdisk |
| system | 1.25GB | HIGH | Android OS |
| recovery | 16MB | MEDIUM | Recovery mode |
| cache | varies | LOW | App cache |
| userdata | varies | LOW | User data |

## What We Backed Up

From `backups/stock-2026-09-16/`:

- `modem.img` (64MB) - Baseband firmware
- `persist.img` (32MB) - WiFi/BT calibration data
- `boot.img` (16MB) - Android kernel
- `system.img` (1.25MB) - Android system (partial)

## Fastboot Status

- `fastboot devices` sometimes detects device
- `adb reboot bootloader` does NOT reliably enter fastboot
- `fastboot oem dump` fails - stock bootloader doesn't support OEM commands
- Driver: "Android Bootloader Interface" (Google USB driver)

## LTE / Cellular

| Field | Value |
|-------|-------|
| Network type | LTE |
| SIM state | READY |
| Cellular IP | 10.131.8.206/30 |
| Operator | Carrier-dependent |
| LTE Bands | 1, 3, 5 (may vary) |
| CS Fallback | Yes (voice calls) |
