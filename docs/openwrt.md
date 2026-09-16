# OpenWrt / Debian on UZ801 - Community-Proven Methods

## Overview

The UZ801 has **excellent** community support. Multiple people have successfully installed Linux on this device.

## Recommended: OpenStick Project

The **OpenStick** project by HandsomeYinyang is the most mature solution:
- [GitHub releases](https://github.com/OpenStick/OpenStick/releases)
- [Build guide](https://github.com/kinsamanka/OpenStick-Builder)
- Pre-built images for Debian Bookworm and OpenWrt

### Which Board Version Do You Have?

Check the PCB silkscreen:
- `FY_UZ801_V2.1` - Older, works but may have issues
- `FY_UZ801_V3.0` - **Most stable** for Linux
- `FY_UZ801_V3.2` - Works but may have modem issues

### Method 1: Pre-built Images (Easiest)

#### Step 1: Backup Stock Firmware
```bash
# Via ADB
adb reboot edl

# Clone edl tool
git clone https://github.com/bkerler/edl.git
cd edl
pip install -r requirements.txt

# Full backup
python edl.py rf stock-uz801.bin

# Individual partitions
python edl.py rl stock-uz801 --genxml
```

#### Step 2: Download OpenStick Image
From [OpenStick releases](https://github.com/OpenStick/OpenStick/releases):
- `openstick-bookworm.img` - Debian Bookworm (recommended)
- `openstick-openwrt.img` - OpenWrt

#### Step 3: Flash
```bash
# Enter fastboot
adb reboot bootloader

# Verify fastboot
fastboot devices

# Flash
fastboot flash boot openstick-boot.img
fastboot flash system openstick-rootfs.img
fastboot reboot
```

#### Step 4: First Boot
- Connect to WiFi: `4G-UFI-XX` (password: `1234567890`)
- SSH: `ssh user@192.168.100.1` (password: `1`)
- Or via USB: `ssh user@192.168.200.1`

### Method 2: Custom Build (Advanced)

See [OpenStick Builder](https://github.com/kinsamanka/OpenStick-Builder) for building custom images.

## Debian Bookworm Features

When running Debian on the UZ801, you get:

### USB Gadgets
The kernel supports USB gadget modes:
- **RNDIS** - Virtual Ethernet (default, for USB tethering)
- **HID** - Keyboard/Mouse injection (Rubber Ducky style)
- **Mass Storage** - USB drive emulation
- **ECM/ACM** - Network/Serial devices
- **FFS** - FunctionFS for custom gadgets

```bash
# List available gadgets
ls /usr/local/etc/gt/templates/

# Load a gadget
sudo gt load --path /usr/local/etc/gt/templates hid.scheme

# Or use gc tool
sudo gc -a rndis
sudo gc -e
```

### 4G/LTE Setup
```bash
# Install modem manager
sudo apt install modemmanager

# Configure APN
sudo nmcli connection modify lte gsm.apn "your-apn"

# Connect
sudo nmcli connection up lte

# Check status
sudo mmcli -m 0
```

### WiFi Hotspot
```bash
# Create hotspot
sudo nmcli device wifi hotspot ifname wlan0 ssid "MyHotspot" password "1234567890"

# Or use the default one
sudo nmcli connection up hotspot
```

### SSH Access
```bash
# Over USB (RNDIS)
ssh user@192.168.200.1

# Over WiFi
ssh user@192.168.100.1

# Over 4G (if port forwarded)
ssh user@<cellular-ip>
```

## OpenWrt Features

### Basic Setup
```bash
# Update packages
opkg update

# Install essentials
opkg install luci luci-i18n-en-base
opkg install nano htop tmux

# Configure WiFi
uci set wireless.radio0.disabled=0
uci commit wireless
wifi
```

### 4G/LTE via ModemManager
```bash
opkg install modemmanager
mmcli -L
mmcli -m 0
```

## Advanced Use Cases

### Remote Pentesting Device
From the OpenStick guide, you can:
1. **Tor integration** - SSH over Tor for anonymity
2. **Bettercap MITM** - Network traffic analysis
3. **Rubber Ducky** - HID keyboard injection
4. **TCPDump/Tshark** - Packet capture

### Tor Hidden SSH
```bash
# Install Tor
sudo apt install tor

# Configure hidden service
echo "HiddenServiceDir /var/lib/tor/ssh/" >> /etc/tor/torrc
echo "HiddenServicePort 22 127.0.0.1:22" >> /etc/tor/torrc
systemctl restart tor

# Get onion address
sudo cat /var/lib/tor/ssh/hostname

# Connect from another PC
torify ssh user@<onion-address>
```

### USB HID (Rubber Ducky)
```bash
# Load HID gadget
sudo gt load --path /usr/local/etc/gt/templates hid.scheme

# Use DroidDucky for payloads
cd ~/ducky
sudo ./droidducky.sh payloads/rickroll.txt
```

### MITM with Bettercap
```bash
# Load ECM gadget
sudo gt load --path /usr/local/etc/gt/templates ecm.scheme

# Start Bettercap
sudo bettercap -iface usb0 -caplet https-ui

# Sniff traffic
net.sniff on
```

### Mass Storage Device
```bash
# Create disk image
dd if=/dev/zero of=mass.img count=50 bs=1M
fdisk mass.img  # Create partition
mkfs.vfat mass.img

# Load mass storage gadget
sudo gt load --path /usr/local/etc/gt/templates mass.scheme
```

## Known Issues

### Modem Stuck Offline
From OpenWrt forum: Some boards have issues with `DeviceNotReady` error.

**Fix**: Replace `/lib/firmware` with firmware from stock `modem.bin` partition.

### v3.2 Board Issues
The v3.2 board may have different device tree. Use v3.0 images if possible.

### WiFi Client Isolation
WiFi clients may not see each other. Fix with:
```bash
# Disable client isolation
uci set wireless.@wifi-iface[0].isolate=0
uci commit wireless
wifi
```

## Recovery

### If Linux Won't Boot
1. Enter fastboot: Hold reset button while plugging in USB (5 seconds)
2. Flash Android back:
   ```bash
   fastboot flash boot backups/stock/boot.img
   fastboot flash system backups/stock/system.img
   fastboot reboot
   ```

### If Fastboot Won't Work
1. Enter EDL mode (short D+ to GND)
2. Flash stock firmware:
   ```bash
   python edl.py wf stock-uz801.bin
   ```

## Resources

- [OpenStick guide](https://wvthoog.nl/openstick/) - Most comprehensive
- [AlienWolfX wiki](https://github.com/AlienWolfX/UZ801-USB-MODEM/wiki) - Detailed procedures
- [OpenWrt forum](https://forum.openwrt.org/t/uf896-qualcomm-msm8916-lte-router-384mib-ram-2-4gib-flash-android-openwrt/131712) - Community discussion
- [postmarketOS](https://wiki.postmarketos.org/wiki/Zhihe_series_LTE_dongles_(generic-zhihe)) - Linux support status
- [msm8916-mainline](https://github.com/msm8916-mainline) - Mainline kernel project
