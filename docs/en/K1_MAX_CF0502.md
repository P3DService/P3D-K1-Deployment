[English](K1_MAX_CF0502.md) | [Русский](../ru/K1_MAX_CF0502.md)

# K1 Max CF0502 / motherboard fan exception

## Symptom

This guide applies when a rooted **Creality K1 Max** shows one of these messages:

- `CF0502`
- `Mainboard fan exception`
- `Motherboard fan running abnormal`

The failure may appear after printing, during idle, or after the printer has cooled down.

## Why it happens

In the validated P3D case, the K1 Max motherboard fan on `PB2` was controlled by a separate Klipper `[controller_fan board_fan]`.

That controller stopped the fan after `idle_timeout`. Creality's own `master-server` continued monitoring the motherboard-fan tachometer and raised fault code `502` after sustained zero RPM.

The fan itself, `PB2` output and `PC6` tach feedback were healthy.

## Recommended fix

Install or reconcile with **P3D K1 Deployment v0.6.1 or newer**.

After root access:

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

The deployment detects K1 Max and applies the validated board-fan baseline automatically.

## Expected board-fan behaviour after the fix

- idle floor: 50%
- full speed at MCU temperature >= 48 C
- return to 50% at MCU temperature <= 42 C
- 42-48 C: hysteresis band
- zero RPM is not part of normal operation

This keeps the motherboard cooled during cold calibration and motor activity while reducing idle noise compared with permanent 100% fan speed.

## Verify

In Fluidd Console:

```gcode
QUERY_FAN_CHECK
```

The important field is:

```text
fan1_speed
```

Expected result:

- idle: greater than 0 RPM; field validation was approximately 3200 RPM
- printing / hot MCU: higher RPM; field validation was approximately 4000 RPM

If `fan1_speed` remains `0` while the fan should be running, stop here and investigate hardware, wiring or tach feedback rather than suppressing CF0502.

## Healthcheck

```bash
/usr/data/scripts/p3d-k1/healthcheck.sh --full
```

For K1 Max the healthcheck verifies:

- the P3D CF0502 board-fan baseline is present;
- legacy `[controller_fan board_fan]` is absent;
- `PB2` is no longer tied to `heater_fans`.

## Field validation

Validated on K1 Max on 2026-09-21:

- PB2 output/control: PASS
- PC6 tach feedback: PASS
- idle fan feedback: approximately 3200 RPM
- printing fan feedback: approximately 4000 RPM
- print completed successfully
- 15+ minutes post-print idle: no CF0502 recurrence

## Related

- [Troubleshooting](TROUBLESHOOTING.md)
- [TMC2209 overtemperature during cold calibration](TMC2209_OVERHEAT.md)
