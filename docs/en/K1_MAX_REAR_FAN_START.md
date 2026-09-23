[English](K1_MAX_REAR_FAN_START.md) | [Русский](../ru/K1_MAX_REAR_FAN_START.md)

# K1 Max rear/chamber fan does not start at reduced speed

## Symptom

On a rooted **Creality K1 Max**, the rear/chamber fan may be shown as enabled on the printer screen while the physical fan is not rotating.

A manual change such as `0% -> 100%` immediately starts the fan.

This can raise chamber temperature during printing even though the UI appears to show rear-fan activity.

## Validated mapping

For the validated K1 Max configuration:

- rear/chamber fan: `output_pin fan1`
- physical pin: `PC0`
- normal control path: stock `M106 P1 S...` / `M107 P1`

## Root cause hypothesis

The validated symptom is consistent with the rear fan sometimes failing to start directly from rest at reduced PWM.

Klipper's `output_pin fan1` reports the commanded PWM value, not physical RPM. Therefore the UI can show a non-zero fan command even when the motor did not actually begin rotating.

The printer has no independent tachometer feedback for this `fan1` path.

## P3D fix

P3D adds a minimal kick-start only to the stock `M106 P1` path.

When all of the following are true:

- fan = `P1`
- requested value is greater than 0
- requested value is below full power
- current `output_pin fan1` value is 0

the macro sends:

1. 100% power
2. waits 500 ms
3. applies the original requested fan value

The existing chamber control and `printer.cfg` are otherwise left unchanged.

## Manual verification

Stop the rear fan:

```gcode
M107 P1
```

Then request approximately 50% from the user-facing scale:

```gcode
M106 P1 S128
```

Expected behaviour:

- brief full-power start
- settles to the requested speed
- fan continues rotating

Because the stock K1 Max macro applies `fan1_min`, the actual PWM value reported by Moonraker can be higher than the percentage shown on the printer screen.

## Fluidd display note

Fluidd may show **Chamber Fan: Off** while the physical rear fan is running from `M106 P1`.

That card represents the separate `temperature_fan chamber_fan` object, not the current `output_pin fan1` command.

To inspect the commanded rear-fan value directly:

```bash
wget -qO- 'http://127.0.0.1:7125/printer/objects/query?output_pin%20fan1'
```

## Field validation

Validated on K1 Max on 2026-09-23:

- rear fan mapping `fan1 -> PC0`: confirmed
- manual `0 -> 100%`: fan starts
- `M107 P1`: fan stops
- patched `M106 P1 S128`: fan starts from rest and keeps rotating
- printer screen shows the requested fan percentage
- production print: chamber temperature reached the control threshold, rear fan started automatically and operated normally — PASS

## Safety boundary

If the fan still does not rotate after a full-power kick, do not mask the problem in software. Check the fan, connector, wiring and power stage.
