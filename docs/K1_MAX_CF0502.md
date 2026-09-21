# K1 Max CF0502 motherboard-fan compatibility

## Symptom

Creality firmware may raise `CF0502` / `motherboard fan running abnormal` on K1 Max after the printer becomes idle.

## Root cause

The validated failure mode was caused by a P3D-specific `[controller_fan board_fan]` configuration on `PB2`.

That controller kept the motherboard fan running while heaters or steppers were active, then stopped it after `idle_timeout`. Creality's own `master-server` independently monitors the motherboard-fan tachometer and raises fault code `502` after sustained zero RPM.

The stock K1 Max configuration ties `PB2` to the hotend heater-fan `multi_pin`. The P3D fix keeps `PB2` independent, but never allows the motherboard fan to stop.

## P3D baseline

The K1 Max board fan is configured as a PWM output with a temperature-aware controller:

- idle floor: 50%
- full speed at MCU temperature >= 48 C
- return to idle floor at MCU temperature <= 42 C
- 42-48 C is a hysteresis band
- shutdown value: 100%
- control interval: 5 seconds
- zero RPM is not part of normal operation

This preserves motherboard cooling during cold calibration and motor activity while avoiding unnecessary full-speed fan noise in idle.

## Field validation

Validated on K1 Max, 2026-09-21:

- PB2 output/control: PASS
- tach feedback on PC6: PASS
- idle fan feedback after fix: approximately 3200 RPM
- printing fan feedback after fix: approximately 4000 RPM
- completed print: PASS
- 15+ minutes post-print idle: no CF0502 recurrence

## Safety / compatibility

- This change is K1 Max-specific.
- `Fans Control Macros` remains forbidden by the P3D baseline.
- Deployment refuses an unknown K1 Max fan mapping instead of guessing.
- A pre-change backup is written as `printer.cfg.p3d-pre-cf0502-fix` when the patch is first applied.
