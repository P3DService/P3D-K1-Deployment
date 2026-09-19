**English** | [Русский](../ru/TMC2209_OVERHEAT.md)

# TMC2209 overtemperature during cold calibration

This guide documents a field-validated fix for TMC2209 overtemperature warnings on a rooted **Creality K1 Max**.

## Scope

Validated on:

- Creality K1 Max
- rooted firmware
- Klipper/Fluidd stack using the Creality K1 pin layout shown below

The exact pin mapping must be checked before applying this to another K1-series revision. The failure mode may be relevant to other K1-series printers, but this fix was field-validated on K1 Max.

## Symptoms

Typical symptoms:

- Fluidd reports that `stepper_x` or `stepper_y` is overheating;
- the warning appears during cold calibration such as `BED_MESH_CALIBRATE`, `SHAPER_CALIBRATE` or resonance tests;
- the hotend is cold or below 40 °C;
- main MCU temperature rises unusually high during calibration;
- TMC dump may show:

```text
otpw=1(OvertempWarning!)
t120=1
```

On the validated printer, MCU temperature reached approximately **75–78 °C** before the fix.

## Diagnosis

The original fan configuration was:

```ini
[multi_pin heater_fans]
pins = nozzle_mcu:PB5,PB2

[heater_fan hotend_fan]
pin = multi_pin:heater_fans
heater = extruder
heater_temp = 40
```

In this configuration:

- `nozzle_mcu:PB5` controls the hotend heatsink fan;
- bare `PB2` resolves to the main MCU and controls the electronics/mainboard fan on the tested K1 Max;
- both outputs are grouped under one `heater_fan`;
- therefore both fans are switched off when the extruder is below 40 °C.

That creates a bad case during cold calibration: the X/Y drivers can run at normal current while the electronics fan is off.

A simple confirmation test is to heat the hotend slightly above the threshold:

```gcode
M104 S50
```

On the validated printer, enabling the grouped fan caused MCU temperature to fall. After:

```gcode
M104 S0
```

and cooling below 40 °C, MCU temperature started rising again.

## Fix

Back up `printer.cfg` first.

Change the fan configuration so that only the hotend fan remains tied to extruder temperature, while the mainboard fan becomes a Klipper `controller_fan`.

Validated configuration:

```ini
[multi_pin heater_fans]
pins = nozzle_mcu:PB5

[heater_fan hotend_fan]
pin = multi_pin:heater_fans
heater = extruder
heater_temp = 40

[controller_fan board_fan]
pin = PB2
max_power = 1.0
shutdown_speed = 1.0
fan_speed = 1.0
idle_timeout = 180
idle_speed = 1.0
heater = extruder, heater_bed
stepper = stepper_x, stepper_y, stepper_z, extruder
```

Then restart Klipper:

```gcode
RESTART
```

## Verification

### 1. Cold stepper test

With the hotend below 40 °C:

```gcode
SET_STEPPER_ENABLE STEPPER=stepper_x ENABLE=1
```

Expected result:

- Board Fan: 100%
- Hotend Fan: OFF

Then:

```gcode
M84
```

The board fan should continue running for the configured idle timeout and then stop.

### 2. Bed mesh test

Run:

```gcode
BED_MESH_CALIBRATE
```

On the validated printer:

- maximum MCU temperature: **47.4 °C**
- no TMC overtemperature warnings

### 3. Resonance / Input Shaper test

Run the same resonance test that previously triggered the warning.

On the validated printer:

- maximum MCU temperature: **47.69 °C**
- no `stepper_x` or `stepper_y` overtemperature warnings

### 4. Check TMC status

After the test:

```gcode
DUMP_TMC STEPPER=stepper_x
DUMP_TMC STEPPER=stepper_y
```

The important thermal flags should be absent:

```text
otpw=1
ot=1
t120=1
```

If `ola=1(OpenLoad_A!)` / `olb=1(OpenLoad_B!)` appears while the motor is disabled and `enn=1`, do not treat that alone as proof of a wiring fault.

## Result

Observed before/after on the validated K1 Max:

| Test | Before | After |
| --- | ---: | ---: |
| MCU temperature under calibration load | ~75–78 °C | 47.4–47.69 °C |
| TMC overtemperature warning | Yes | No |
| Board fan during cold calibration | Off | 100% |

## Notes

- Do not lower X/Y motor current as the first response if the cooling fan is not running.
- Do not blindly copy the `PB2` mapping to hardware with a different board or firmware layout.
- If the board fan does not physically spin after the change, stop the test and inspect the fan, connector and airflow with power removed.
