# P3D K1 Deployment

[**English**](README.md) | [Русский](README_RU.md)

Automated deployment, configuration, Fluidd provisioning and health validation for rooted **Creality K1C** and **Creality K1 Max** printers.

P3D K1 Deployment turns a rooted K1-series printer into a repeatable, validated baseline with the approved Helper Script stack, working camera, Moonraker Timelapse, cleanup automation, organized Fluidd macros and QUICK/FULL health checks.

> This is an independent community project by P3D Service. It is not an official Creality or Guilouz product. It uses [Creality Helper Script](https://github.com/Guilouz/Creality-Helper-Script) as an external upstream and does not vendor its installer logic.

> [!WARNING]
> **Use at your own risk.** Rooting, firmware/configuration changes, forced motion, disassembly and mechanical/electrical adjustments can damage equipment, void warranty or cause injury. P3D Service and contributors are not responsible for consequences to the maximum extent permitted by applicable law. Read the full [Safety Disclaimer](DISCLAIMER.md).

## Current stable baseline

**v0.6.1**

Validated on:

- Creality K1C ×3
- Creality K1 Max ×1

v0.6.0 base FULL validation:

```
PASS: 56
WARN: 0
FAIL: 0
STATUS: PASS
```

v0.6.1 additionally includes the field-validated K1 Max CF0502 motherboard-fan fix.

Tested Creality Helper Script commit:

```
b46787a61b3ce2f04ec04d115a73a46c26814057
```

## What it does

`deploy.sh`:

- validates K1-series model and free space;
- installs or verifies Creality Helper Script;
- fail-closes on an unvalidated Helper Script revision;
- installs the approved module set;
- blocks the `Fans Control Macros` baseline;
- applies the K1 Max CF0502 motherboard-fan compatibility baseline;
- verifies/restores MJPEG camera runtime;
- disables stock Creality Timelapse;
- enables Moonraker Timelapse;
- validates/repairs ffmpeg path compatibility;
- installs timelapse disk cleanup and cron;
- installs automatic QUICK healthcheck at boot and daily;
- waits for real Moonraker API readiness;
- provisions Fluidd webcam settings;
- provisions Fluidd macro groups and visibility;
- runs FULL validation before declaring the printer ready.

## Approved Helper Script modules

1. Moonraker + Nginx
2. Fluidd
3. Entware
4. Klipper Gcode Shell Command
5. KAMP
6. Nozzle Cleaning Fan Control
7. Improved Shapers Calibrations
8. Useful Macros
9. Save Z-Offset Macros
10. M600 Support
11. Moonraker Timelapse

PrusaSlicer-specific KAMP helper macros remain disabled by default.

## Fluidd baseline

### Macro groups

```
PRINT         4
CALIBRATION   6
KAMP          2
TIMELAPSE     2
```

All other live Klipper macros stay installed but are hidden from the Fluidd dashboard.

### Webcam

Baseline:

```
service: mjpegstreamer-adaptive
stream_url: /webcam/?action=stream
snapshot_url: /webcam/?action=snapshot
target_fps: 15
target_fps_idle: 5
aspect_ratio: 4:3
```

Existing database-managed camera name and UID are preserved during reconcile. Relative URLs avoid binding the setup to a printer IP.

## Known issues / troubleshooting

If a **K1 Max** reports `CF0502`, `Mainboard fan exception` or `Motherboard fan running abnormal`, use the dedicated field-validated guide:

- [K1 Max CF0502 / motherboard fan exception](docs/en/K1_MAX_CF0502.md)

The v0.6.1 baseline keeps the motherboard fan above 0 RPM and validates the fix through healthcheck.

## Quick start

After enabling root access:

```bash
ssh root@PRINTER_IP
```

Recommended pinned bootstrap:

```bash
wget -q -O /tmp/p3d-k1-install.sh \
  https://raw.githubusercontent.com/P3DService/P3D-K1-Deployment/v0.6.1/install.sh

cat /tmp/p3d-k1-install.sh
sh /tmp/p3d-k1-install.sh
```

One-liner:

```bash
wget -qO- https://raw.githubusercontent.com/P3DService/P3D-K1-Deployment/v0.6.1/install.sh | sh
```

> Some stock BusyBox builds print `TLS certificate validation not implemented`. See [Troubleshooting](docs/en/TROUBLESHOOTING.md) for the security trade-off and recommended workflow.

## FRESH and RECONCILE

### FRESH

For a new or factory-reset printer:

```
factory reset / new printer
→ root
→ bootstrap
→ Helper Script stack
→ P3D compatibility fixes
→ Fluidd provisioning
→ FULL healthcheck
→ READY
```

### RECONCILE

For an existing configured printer:

```
existing printer
→ deploy
→ detect existing approved modules
→ add missing baseline pieces
→ preserve matching user state
→ FULL healthcheck
```

## Healthcheck

QUICK:

```bash
/usr/data/scripts/p3d-k1/healthcheck.sh --quick
```

FULL:

```bash
/usr/data/scripts/p3d-k1/healthcheck.sh --full
```

Current status:

```bash
cat /usr/data/scripts/p3d-k1/status
```

Health history:

```bash
tail -100 /usr/data/scripts/p3d-k1/healthcheck.log
```

Deployment log:

```bash
tail -100 /usr/data/scripts/p3d-k1/deploy.log
```

## Documentation

### English

- [Installation](docs/en/INSTALLATION.md)
- [Components](docs/en/COMPONENTS.md)
- [Healthcheck](docs/en/HEALTHCHECK.md)
- [Fluidd provisioning](docs/en/FLUIDD_PROVISIONING.md)
- [Architecture](docs/en/ARCHITECTURE.md)
- [Troubleshooting](docs/en/TROUBLESHOOTING.md)
- [K1 Max CF0502 / motherboard fan exception](docs/en/K1_MAX_CF0502.md)
- [TMC2209 overtemperature during cold calibration](docs/en/TMC2209_OVERHEAT.md)
- [K1 Max Bed Mesh tilt and Z synchronization](docs/en/BED_MESH_Z_SYNC.md)
- [Validation](docs/en/VALIDATION.md)
- [v0.6.1 release notes](docs/en/RELEASE_v0.6.1.md)
- [v0.6.0 release notes](docs/en/RELEASE_v0.6.0.md)

### Русский

- [Установка](docs/ru/INSTALLATION.md)
- [Компоненты](docs/ru/COMPONENTS.md)
- [Healthcheck](docs/ru/HEALTHCHECK.md)
- [Fluidd provisioning](docs/ru/FLUIDD_PROVISIONING.md)
- [Архитектура](docs/ru/ARCHITECTURE.md)
- [Troubleshooting](docs/ru/TROUBLESHOOTING.md)
- [TMC2209: перегрев во время холодной калибровки](docs/ru/TMC2209_OVERHEAT.md)
- [K1 Max: уклон Bed Mesh и синхронизация Z](docs/ru/BED_MESH_Z_SYNC.md)
- [Валидация](docs/ru/VALIDATION.md)
- [Release notes v0.6.0](docs/ru/RELEASE_v0.6.0.md)

## Community

Use GitHub Issues for:

- bug reports;
- compatibility reports;
- feature requests.

See [CONTRIBUTING.md](CONTRIBUTING.md) or [CONTRIBUTING_RU.md](CONTRIBUTING_RU.md).

## External monitoring

The project exposes local state through:

```
/usr/data/scripts/p3d-k1/status
/usr/data/scripts/p3d-k1/healthcheck.log
```

These files can be consumed by Home Assistant, dashboards or fleet-management systems without coupling this public repository to any private infrastructure.

## License

MIT. See [LICENSE](LICENSE).

## Credits

- [Creality](https://www.creality.com/)
- [Guilouz / Creality Helper Script](https://github.com/Guilouz/Creality-Helper-Script)
- Klipper
- Moonraker
- Fluidd
- KAMP

P3D Service — production 3D printing / CAD / reverse engineering.
