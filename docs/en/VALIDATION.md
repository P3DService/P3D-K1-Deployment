**English** | [Русский](../ru/VALIDATION.md)

# Field validation

## Release baseline

P3D K1 Deployment v0.6.0.

Tested Creality Helper Script commit:

```
b46787a61b3ce2f04ec04d115a73a46c26814057
```

## v0.5 baseline validation

RECONCILE was validated on three configured K1C printers.

FRESH deployment after factory reset was validated on one K1 Max.

Repeat deployment/idempotency was validated on the same K1 Max.

The final v0.5 FULL gate reached:

```
PASS: 54
WARN: 0
FAIL: 0
STATUS: PASS
```

The public pinned v0.5.1 bootstrap was also validated on K1C.

## Fluidd provisioning v0.6.0

Validated on:

```
K1C-1   PASS
K1C-2   PASS
K1C-3   PASS
K1Max-1 PASS
```

Confirmed on all four printers:

- Fluidd camera works through relative `/webcam/` URLs;
- existing camera name/UID is preserved on reconcile;
- K1 Max webcam creation works automatically;
- macro groups are provisioned;
- non-baseline macros are hidden without being removed from Klipper;
- Fluidd provisioning FULL gate passes.

Final result:

```
PASS: 56
WARN: 0
FAIL: 0
STATUS: PASS
```

Visual dashboard result:

```
PRINT         4
CALIBRATION   6
KAMP          2
TIMELAPSE     2
```

No uncategorized/system macro block remains visible.

## What “validated” means

These results describe the tested fleet and firmware state. They do not guarantee identical behavior on:

- other Creality firmware versions;
- other hardware revisions;
- changed Helper Script commits;
- printers with unrelated third-party modifications.

This is why deployment remains fail-closed and ends with FULL validation.
