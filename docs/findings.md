# Research Findings - UZ801 Hack Project

## Summary

The UZ801 is a **well-documented, community-supported** device. Multiple people have successfully hacked it. You don't need to reinvent the wheel.

## What We Found (Our Device)

### Hardware
- **Model**: UZ801
- **SoC**: Qualcomm MSM8916 (Snapdragon 410)
- **Board**: FY_UZ801_V3.31
- **RAM**: ~388MB (512MB nominal)
- **Storage**: ~3.8GB eMMC
- **Android**: 4.4.4 KitKat (userdebug, test-keys)
- **Root**: YES - `uid=0(root)`

### Network
- **Network**: LTE
- **SIM**: READY
- **Device Gateway**: 192.168.100.1

### USB Interfaces
```
MI_00: Remote NDIS (network) - OK
MI_02: Android (needs driver) - Error
MI_03: Android (needs driver) - Error
MI_04: ADB Interface - OK
```

### Key Properties
```
ro.build.type=userdebug          # Developer build
ro.build.tags=test-keys          # No secure boot
persist.sys.usb.config=rndis,serial_smd,diag,adb   # All interfaces enabled
persist.adb.tcp.port=7628        # ADB over TCP
```

## Community Findings

### EDL Mode (Emergency Download)
- Device enters EDL by shorting D+ to GND on USB
- Or via `adb reboot edl`
- Shows as `QHSUSB__BULK` in dmesg
- edl tool works with autodetection (no loader needed)
- **HWID**: 0x007050e100000000 (MSM8916)
- **PK_HASH**: 0xcc3153a80293939b90d02d3bf8b23e0292e452fef662c74998421adad42a380f
- **Serial**: 0x1234567a
- **Unfused device** - any loader works

### Web Interface
- **URL**: http://192.168.100.1
- **Login**: admin / admin
- **ADB Enable**: http://192.168.100.1/usbdebug.html
- **IMEI change**: Possible via web UI (!)
- **Default WiFi**: SSID `4G-UFI-XX`, Password `1234567890`

### Screenshots Work
```bash
# Set screen timeout to max
adb shell settings put system screen_off_timeout 2147483647

# Wake screen
adb shell input keyevent 26

# Take screenshot
adb shell screencap /sdcard/Download/screen.png
adb pull /sdcard/Download/screen.png

# Set locale to English
adb shell "setprop persist.sys.locale en-US; setprop ctl.restart zygote"
```

### scrcpy
- **scrcpy NOT supported** (requires API 21 / Android 5.0)
- Device is Android 4.4.4 (API 19)
- Use screencap + am start for UI interaction instead

### Qualcomm Settings App
Device has `com.qualcomm.qualcommsettings` app:
```bash
adb shell am start -n 'com.qualcomm.qualcommsettings/.QualcommSettings'
```

### Diag Port
- `/dev/diag` exists with qcom_diag group
- Can be enabled via: `setprop sys.usb.config rndis,serial_smd,diag,adb`
- Use with [QCsuper](https://github.com/nicman23/qcsuper) for network analysis

### LTE Band Support
- Band 1, 3, 5 (may vary by region/firmware)
- CS Fallback for voice calls

### Stock Firmware Blobs
Available at:
- https://github.com/OpenStick/stick-blobs/tree/main/stock-uz801
- https://github.com/Mio-sha512/openstick-stuff/releases

## Board Versions

| Version | Status | Notes |
|---------|--------|-------|
| V2.1 | Works | Older, may have issues |
| V3.0 | **Best** | Most stable for Linux |
| V3.2 | Works | May have modem issues in Linux |

## What Works in Linux

### Debian Bookworm (OpenStick)
- [x] SSH over USB (RNDIS) - IP 192.168.200.1
- [x] WiFi hotspot
- [x] 4G/LTE via NetworkManager
- [x] USB Gadget support (HID, Mass Storage, ECM, ACM)
- [x] Tor integration
- [x] Bettercap MITM
- [x] Rubber Ducky HID injection
- [ ] scrcpy (needs Android 5+)
- [ ] GPU acceleration (Adreno 306 needs freedreno)

### OpenWrt
- [x] Basic networking
- [x] WiFi
- [x] 4G/LTE via ModemManager
- [ ] GPU acceleration
- [ ] Some vendor-specific features

## Security Implications

### For Device Owner (Good)
- Full root access without exploits
- ADB shell available
- Can modify system
- Can install custom firmware

### Security Concerns (for the vendor)
1. **ADB over TCP enabled** - Anyone on network can connect
2. **userdebug build** - Full debugging enabled
3. **test-keys** - No secure boot chain
4. **IMEI changeable** via web UI (potentially illegal in some countries)
5. **Diag port exposed** - Can read/write modem firmware
6. **No authentication** for root shell

## Performance Expectations

| Metric | Value |
|--------|-------|
| CPU | ~400 DMIPS single, ~1600 DMIPS quad |
| RAM | 388MB (usable) |
| Storage | 3.8GB eMMC |
| WiFi | 150 Mbps (802.11n 2.4GHz) |
| LTE | 150 Mbps down, 50 Mbps up |
| USB | 480 Mbps theoretical |

### What It Can Handle
- [x] Web server (nginx/lighttpd)
- [x] DNS server (dnsmasq/unbound)
- [x] VPN server (wireguard/openvpn)
- [x] Ad blocker (pi-hole)
- [x] File server (samba/minidlna)
- [ ] Desktop Linux (too little RAM)
- [ ] Media transcoding (too slow)
- [ ] Home Assistant (might be tight)

## Key Commands Reference

```bash
# Device info
adb shell getprop ro.product.model
adb shell getprop ro.build.version.release
adb shell id

# Network
adb shell ip addr show
adb shell getprop gsm.operator.alpha
adb shell getprop gsm.sim.state

# SMS
adb shell content query --uri content://sms
adb shell content insert --uri content://sms --bind address:s:+1234567890 --bind body:s:Hello --bind type:i:2

# Phone calls
adb shell am start -a android.intent.action.CALL -d tel:+1234567890

# USB gadget
adb shell setprop sys.usb.config rndis,serial_smd,diag,adb
```
