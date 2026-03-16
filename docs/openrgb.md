# OpenRGB Lighting Control

This system uses [OpenRGB](https://openrgb.org/) to manage RGB lighting across the motherboard, RAM, GPU, and other peripherals, avoiding the need for proprietary manufacturer software.

## System Configuration
For OpenRGB to function properly and detect all devices (especially RAM over SMBus), the following system configurations are in place:

1. **I2C/SMBus Kernel Module:** The `i2c-dev` module is loaded on boot. (Configured in `/usr/lib/modules-load.d/openrgb.conf`)
2. **Udev Rules:** Udev rules are applied to grant user-space access to the lighting controllers. (Installed at `/usr/lib/udev/rules.d/60-openrgb.rules`)

## Persistence (Systemd Service)
By default, some hardware (like Motherboards and GPUs) will revert to their factory "Rainbow" effect when the system loses power.

To ensure the lighting state is persistent across reboots, a systemd service is configured to apply a default profile during the boot process.

*   **Profile Location:** `/etc/openrgb/default.orp`
*   **Service File:** `/etc/systemd/system/openrgb.service`

### Changing the Default Boot Lighting
If you want to change what your lights do when the computer turns on (e.g., change from "Off" to a specific static color), simply update the default profile:

1. Configure your lights how you want them using the OpenRGB GUI (`openrgb --gui`) or CLI.
2. Save over the default profile with your new settings:
   ```bash
   sudo openrgb --noautoconnect --save-profile /etc/openrgb/default.orp
   ```
   *(Using `sudo` is required because the file is in `/etc/` so the systemd service can read it at boot).*

## Command Line Usage (Quick Reference)

The OpenRGB CLI can be used for automation and quick changes without opening the GUI.

*Note: Add `--noautoconnect` to commands if you aren't running a persistent OpenRGB server. This suppresses the harmless "Connection attempt failed" warning.*

### Discovering Devices
List all detected RGB devices and their supported modes/zones:
```bash
openrgb --list-devices
```

### Controlling Colors & Modes
**Set a specific device to a static color (Hex format):**
```bash
openrgb --noautoconnect --device <ID> --color <HEX_COLOR>
```
*(Example: `openrgb --noautoconnect --device 0 --color FF0000` sets device 0 to Red)*

**Set all devices to a static color:**
```bash
openrgb --noautoconnect --color <HEX_COLOR>
```

**Change a device's mode:**
Some hardware devices (like GPUs) will ignore `--color` commands if their mode is currently set to a built-in hardware animation (like "Rainbow Wave"). You must set the mode to "Direct" or "Off" first.
```bash
# Turn off hardware animation/lighting
openrgb --noautoconnect --device <ID> --mode "Off"

# Set to Direct mode (allows manual color control)
openrgb --noautoconnect --device <ID> --mode "Direct"
```

### Loading Profiles Manually
**Load a saved profile from the CLI:**
```bash
openrgb --noautoconnect --profile <path_to_profile.orp>
```
