[English](RELEASE_v0.6.1.md) | [Русский](../ru/RELEASE_v0.6.1.md)

# Release v0.6.1

Patch release focused on the **Creality K1 Max CF0502 motherboard-fan false fault** and user-facing discoverability.

## Fixed

- K1 Max: prevents `CF0502` / `motherboard fan running abnormal` caused by the previous P3D `[controller_fan board_fan]` reaching 0 RPM after idle timeout.
- K1 Max board fan now uses the field-validated PWM baseline:
  - 50% idle floor
  - 100% at MCU >= 48 C
  - return to 50% at MCU <= 42 C
  - zero RPM is not part of normal operation
- Stock/legacy K1 Max fan mappings are reconciled fail-closed.
- A pre-change `printer.cfg` backup is preserved.
- Healthcheck validates the new K1 Max board-fan baseline.

## User support

Added a dedicated searchable user guide for:

- `CF0502`
- `Mainboard fan exception`
- `Motherboard fan running abnormal`

See [K1 Max CF0502 / motherboard fan exception](K1_MAX_CF0502.md).

## Field validation

- idle tach: approximately 3200 RPM
- printing tach: approximately 4000 RPM
- completed print: PASS
- 15+ minutes post-print idle: no CF0502 recurrence

## Install

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
