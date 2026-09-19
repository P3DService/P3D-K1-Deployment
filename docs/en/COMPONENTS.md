**English** | [Русский](../ru/COMPONENTS.md)

# Baseline components

P3D K1 Deployment intentionally installs a small validated production baseline rather than every available Helper Script module.

## Installed components

### Moonraker + Nginx
Moonraker exposes Klipper APIs. Nginx serves Fluidd and proxies Moonraker/webcam endpoints.

### Fluidd
Primary web UI. The deployment also provisions webcam settings and macro grouping.

### Entware
Package layer used by Helper Script and Moonraker Timelapse dependencies.

### Klipper Gcode Shell Command
Enables shell-backed Klipper macros required by some extensions.

### KAMP
Klipper Adaptive Meshing & Purging. PrusaSlicer-specific helper macros remain disabled by default.

### Nozzle Cleaning Fan Control
Separate Helper Script component for nozzle-cleaning behavior.

> This is not the same as `Fans Control Macros`.

### Improved Shapers Calibrations
Adds input-shaper, belt and resonance calibration workflows.

### Useful Macros
General utility macros provided by Helper Script.

### Save Z-Offset Macros
Adds Z-offset save/restore helpers.

### M600 Support
Adds filament-change support.

### Moonraker Timelapse
Moonraker component used as the baseline timelapse implementation.

## Stock Creality Timelapse

Stock Creality Timelapse is disabled in:

```
/usr/data/creality/userdata/config/user_print_refer.json
```

A first-change backup is kept as:

```
user_print_refer.json.p3d-original
```

## Fans Control Macros deny-list

`Fans Control Macros` is deliberately excluded.

On the P3D K1C test fleet its installation coincided with a fan error during printing. After removal the issue disappeared, so the current baseline treats it as a safety deny-list item.

This is a conservative project decision, not a universal claim about every K1-series firmware/hardware combination.
