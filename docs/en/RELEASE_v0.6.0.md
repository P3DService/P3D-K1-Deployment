[English](https://github.com/P3DService/P3D-K1-Deployment/blob/v0.6.0/docs/en/RELEASE_v0.6.0.md) | [Русский](https://github.com/P3DService/P3D-K1-Deployment/blob/v0.6.0/docs/ru/RELEASE_v0.6.0.md)

# Release v0.6.0

New stable P3D K1 Deployment baseline.

The main addition is **automatic Fluidd provisioning**. After root access and one bootstrap command, the printer gets the validated Helper Script stack plus a ready-to-use Fluidd dashboard.

## Highlights

### Macro provisioning

Automatically provisions and validates:

```
PRINT         4
CALIBRATION   6
KAMP          2
TIMELAPSE     2
```

All other live Klipper macros remain installed but are hidden from the Fluidd dashboard with `visible:false`.

### Webcam provisioning

Moonraker webcam is created or normalized with:

```
service: mjpegstreamer-adaptive
stream_url: /webcam/?action=stream
snapshot_url: /webcam/?action=snapshot
target_fps: 15
target_fps_idle: 5
aspect_ratio: 4:3
```

Existing database-managed camera name and UID are preserved.

Relative URLs remove dependency on the printer IP address.

### User configuration protection

- matching category layouts preserve existing Fluidd UUIDs;
- custom layouts are not overwritten automatically;
- forced replacement requires `P3D_K1_FLUIDD_FORCE=1`;
- Fluidd state is backed up before provisioning.

## Healthcheck

FULL now also validates:

- Fluidd `/webcam/` proxy snapshot;
- webcam provisioning baseline;
- macro grouping/visibility baseline;
- Fluidd provisioning helper/runtime.

Validated result:

```
PASS: 56
WARN: 0
FAIL: 0
STATUS: PASS
```

## Field validation

- Creality K1C ×3 — PASS
- Creality K1 Max ×1 — PASS
- macro grouping — PASS
- hiding non-baseline macros — PASS
- existing camera name preservation — PASS
- automatic camera creation on K1 Max — PASS

Tested Helper Script commit:

```
b46787a61b3ce2f04ec04d115a73a46c26814057
```

## Install

```bash
wget -q -O /tmp/p3d-k1-install.sh \
  https://raw.githubusercontent.com/P3DService/P3D-K1-Deployment/v0.6.0/install.sh

cat /tmp/p3d-k1-install.sh
sh /tmp/p3d-k1-install.sh
```

One-liner:

```bash
wget -qO- https://raw.githubusercontent.com/P3DService/P3D-K1-Deployment/v0.6.0/install.sh | sh
```

## Healthcheck locations

```bash
/usr/data/scripts/p3d-k1/healthcheck.sh --quick
/usr/data/scripts/p3d-k1/healthcheck.sh --full
cat /usr/data/scripts/p3d-k1/status
tail -100 /usr/data/scripts/p3d-k1/healthcheck.log
```
