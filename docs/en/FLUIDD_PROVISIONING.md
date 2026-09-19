**English** | [Русский](../ru/FLUIDD_PROVISIONING.md)

# Fluidd provisioning

v0.6.0 automatically prepares Fluidd so the printer is ready for calibration without manual UI setup.

## Webcam baseline

Moonraker webcam API is used as canonical storage:

```
enabled: true
location: printer
service: mjpegstreamer-adaptive
target_fps: 15
target_fps_idle: 5
stream_url: /webcam/?action=stream
snapshot_url: /webcam/?action=snapshot
aspect_ratio: 4:3
```

Relative URLs avoid binding the configuration to a specific DHCP/IP address.

### Webcam naming

Camera name is a display label, not device identity.

If a database-managed webcam already exists:

- existing `uid` is preserved;
- existing `name` is preserved;
- only operational settings are normalized.

If none exists, a camera is created as:

```
<current-hostname>_camera
```

Changing the hostname later does not break the camera.

## Macro groups

Baseline dashboard:

### PRINT
- PAUSE
- RESUME
- CANCEL_PRINT
- M600

### CALIBRATION
- BED_MESH_CALIBRATE
- INPUT_SHAPER_CALIBRATION
- BELTS_SHAPER_CALIBRATION
- TEST_RESONANCES_GRAPHS
- PID_HOTEND
- PID_BED

### KAMP
- KAMP_BED_MESH_SETTINGS
- KAMP_PURGE_LINE_SETTINGS

### TIMELAPSE
- GET_TIMELAPSE_SETUP
- TIMELAPSE_RENDER

All other live Klipper `gcode_macro` objects remain installed but are explicitly stored as `visible:false` in Fluidd.

## Protecting user layouts

Provisioning is conservative:

- semantically matching P3D layouts are accepted even when Fluidd-generated category UUIDs differ;
- custom layouts are preserved and produce WARN;
- forced replacement requires explicit opt-in:

```bash
P3D_K1_FLUIDD_FORCE=1 /usr/data/scripts/p3d-k1/deploy.sh
```

A backup is written before changes:

```
/usr/data/scripts/p3d-k1/backups/fluidd-before-provision-YYYYMMDD-HHMMSS.json
```

## Validation

FULL healthcheck validates the webcam and macro provisioning baseline.

Standalone check:

```bash
/usr/data/moonraker/moonraker-env/bin/python \
  /usr/data/scripts/p3d-k1/fluidd_provision.py --check
```
