**English** | [Русский](../ru/BED_MESH_Z_SYNC.md)

# K1 Max: large Bed Mesh tilt, repeated probing and Z synchronization

This document records a field-validated troubleshooting case on a rooted **Creality K1 Max**.

> **Safety:** this procedure includes mechanical adjustment and, in one optional method, forced Z motion against the lower stop. Read [DISCLAIMER.md](../../DISCLAIMER.md) before doing anything. The forced-motion method is potentially destructive if used incorrectly.

## Symptoms

The printer showed a very large front-to-back Bed Mesh slope.

Typical behavior:

- the normal 6×6 mesh probes 36 points;
- most points are sampled every ~5–7 seconds;
- after the apparent last point, Bed Mesh can continue for several more minutes;
- the console looks as if the calibration is hanging;
- the saved mesh may show several millimeters of front-to-back difference.

In the validated case, the initial mesh was approximately:

- front area: around **-1 mm**;
- rear area: around **+3.2 mm**;
- overall raw range: about **4.3 mm**.

## Why Bed Mesh can take 10+ minutes

The long pause was not a UI freeze.

The Creality PRTouch implementation internally detected too much geometric slope and started a large `RE_PROBE_POINT` pass. In the captured log it marked **30 points** for re-probing, then repeated the set multiple times.

Useful log markers:

```text
[BED_MESH_POST_PROC]
[RE_PROBE_POINT] ... len:30
[RUN_TO_NEXT]
```

So a calibration that appears to pause for many minutes may actually be repeatedly validating suspicious geometry.

## Important distinction: tilt vs warped bed

Do not assume that a 3–4 mm Bed Mesh range means the aluminum plate itself is warped by 3–4 mm.

A large, smooth front-to-back slope usually points first to **Z synchronization / screw phase mismatch**.

After the Z axes were synchronized in this field case, the large slope disappeared and the remaining mesh looked mostly like a smooth shallow bowl.

## Preferred method: mechanical Z-belt synchronization

The preferred service method is mechanical:

1. Power the printer off and unplug it.
2. Remove the bottom cover carefully.
3. Identify the Z belt, the three Z pulleys/screws and the spring-loaded tensioner.
4. Mark the current belt/pulley positions.
5. Loosen and temporarily hold the tensioner in the belt-slack position.
6. Adjust the required Z pulley relative to the belt in small tooth increments.
7. Restore spring tension and tighten the tensioner.
8. Reassemble, home and re-run Bed Mesh.

Direction depends on printer orientation and which side is high. Confirm the actual table movement before making a large correction.

In the validated case the dominant error was rear-high relative to the front, so the rear Z pulley was adjusted in the direction that lowered the rear of the bed.

### Do not apply a fixed tooth count blindly

The relationship between one apparent tooth/click and measured Bed Mesh correction depends on the mechanism, pulley, belt engagement and which Z point moves.

On this specific printer:

- a controlled hard-stop click changed front-to-back average slope by roughly **0.35–0.37 mm**;
- a manual multi-tooth adjustment produced a larger but not perfectly linear correction.

Treat those values as field observations, not a universal calibration constant.

## Optional experimental method: controlled lower-stop tooth skip

This method was field-tested, but it is **not the preferred service method**.

It deliberately moves Z into the lower mechanical stop until a belt/pulley tooth skips.

Use it only if:

- `[force_move] enable_force_move: true` is present;
- you understand that Klipper position tracking becomes invalid after `FORCE_MOVE`;
- you accept the risk of belt, pulley, motor or frame damage.

### Field-tested sequence

Home first:

```gcode
G28
```

Move close to the bottom using normal kinematics:

```gcode
G90
G1 Z290 F1200
G1 Z300 F600
```

Then approach the lower stop slowly:

```gcode
FORCE_MOVE STEPPER=stepper_z DISTANCE=4 VELOCITY=2
```

Continue in small steps:

```gcode
FORCE_MOVE STEPPER=stepper_z DISTANCE=0.5 VELOCITY=1
```

Repeat **one command at a time**.

At the first distinct belt/pulley click:

1. stop issuing `FORCE_MOVE`;
2. disable motors;
3. restart firmware;
4. home again;
5. measure Bed Mesh again.

```gcode
M84
FIRMWARE_RESTART
G28
BED_MESH_CALIBRATE
```

Do not intentionally create a long burst of ratcheting clicks.

## Field results

The validated printer improved progressively from a severe mechanical tilt to a nearly neutral front-to-back plane.

Observed checkpoints:

| State | Result |
| --- | --- |
| Initial cold mesh | ~4.3 mm raw range, severe front-to-back slope |
| After Z synchronization work | cold Fluidd deviation ~0.79 mm |
| Final 80 °C stabilized mesh | Fluidd deviation **0.6332 mm** |
| Final 80 °C raw probe range | **~0.620 mm** |
| Final front vs rear average difference | **~0.107 mm** |

At the final hot measurement, the remaining geometry was mostly a smooth bed-shape variation rather than Z-axis tilt.

## Measure the final mesh hot

Mechanical Z synchronization can be diagnosed cold, but the final production mesh should be evaluated at the real operating temperature.

Recommended workflow:

1. set the normal bed temperature for the material;
2. allow the bed to thermally stabilize;
3. home;
4. run Bed Mesh;
5. save the profile only after reviewing the result.

Example:

```gcode
M140 S80
M190 S80
G28
BED_MESH_CALIBRATE
SAVE_CONFIG
```

A large aluminum bed can change shape while heating. The validated K1 Max improved from about **0.79 mm Fluidd deviation cold** to **0.6332 mm at 80 °C**.

## Practical acceptance

For a 300×300 mm consumer printer, a smooth hot mesh around **0.5–0.8 mm total variation** can be perfectly usable with Klipper compensation.

Do not keep adjusting synchronized Z screws just to remove a smooth central bowl. Once front-to-back and left-to-right tilt are small, further Z synchronization cannot flatten the plate itself and can reintroduce tilt.

Validate with a large first-layer print before making additional mechanical changes.


## 2026-09-29 addendum: PRTouch dives into the bed at X295 Y5

The same K1 Max later developed a separate edge-case during `BED_MESH_CALIBRATE`: at the front-right corner the nozzle visibly pushed the bed down, while the console reported a single point near **-3.1 mm** next to otherwise normal values.

Representative values:

```text
(237, 5)   +0.137
(295, 5)   -3.106   <- anomaly
(295, 63)  +0.293
```

No mechanical bed play or crack was found during manual inspection.

### Verify the four pressure channels

PRTouch v2 exposes four pressure channels, `pres0..pres3`. The command:

```gcode
READ_PRES
```

reads them without moving the axes.

Manual corner loading produced this mapping:

| Bed corner | Primary channel |
| --- | --- |
| Front-left | CH0 |
| Front-right | CH1 |
| Rear-left | CH2 |
| Rear-right | CH3 |

The front-right `CH1` sensor was healthy: manual loading changed its reading by roughly **746k**, and after release it returned to baseline within about **0.2%**. That strongly argues against a dead load cell or static wiring fault.

### What klippy.log showed

At `X295 Y5`, PRTouch did not produce one random bad sample. It repeatedly returned approximately:

```text
-2.712
-3.063
-3.113
-3.106
-3.153
```

The algorithm initially selected the expected front-right channel, `best_ch=1`, then switched to `best_ch=2` during retries while the result remained near -3 mm.

The very next point, `X295 Y63`, measured normally at about **+0.293 mm**.

That pattern points to a dynamic PRTouch edge-case at the physical probing boundary rather than a failed sensor.

### Practical workaround: keep 10 mm away from the extreme edge

Original mesh:

```ini
[bed_mesh]
mesh_min: 5,5
mesh_max: 295,295
probe_count: 6,6
```

was changed to:

```ini
[bed_mesh]
mesh_min: 15,15
mesh_max: 285,285
probe_count: 6,6
```

The resulting 6x6 coordinates are:

```text
15, 69, 123, 177, 231, 285
```

After this change, the -3 mm outlier disappeared completely and the front-right region probed without forcing the bed downward.

### Re-synchronize Z after removing the probing edge-case

With the false edge point removed, the real bed geometry became visible: the front-to-back tilt was about **1.5 mm**.

On this printer, the previously field-tested lower-stop click method was used again. After **4 controlled single clicks**, average front-to-back tilt dropped to about **0.1-0.2 mm**.

Do not copy the number "4 clicks" to another printer blindly; this is a field result from one specific K1 Max.

### Final 80 °C result

After thermal stabilization at **80 °C** and re-running Bed Mesh with the `15..285` bounds:

- minimum raw probe: **0.1278 mm**
- maximum raw probe: **0.7516 mm**
- raw range: **~0.624 mm**
- average residual front-to-back tilt: **~0.16 mm**
- no further front-right PRTouch dive occurred

The combined workaround was therefore: **avoid the outermost 10 mm of the probing region, then re-synchronize Z based on the corrected mesh**.
