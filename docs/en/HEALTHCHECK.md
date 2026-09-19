**English** | [Русский](../ru/HEALTHCHECK.md)

# Healthcheck

`healthcheck.sh` is the operational gate for P3D K1 Deployment.

Two modes are available:

```bash
/usr/data/scripts/p3d-k1/healthcheck.sh --quick
/usr/data/scripts/p3d-k1/healthcheck.sh --full
```

## Status model

Each check is reported as:

- `PASS` — expected state confirmed;
- `WARN` — printer is operational but something differs from baseline;
- `FAIL` — production baseline is not confirmed.

Summary:

```
PASS: N
WARN: N
FAIL: N
STATUS: PASS|WARN|FAIL
```

Exit codes:

- `0` PASS
- `1` WARN
- `2` FAIL
- `64` invalid arguments

## QUICK

Designed for regular runtime monitoring. It checks:

- K1-series model;
- Klipper, Moonraker and Nginx processes;
- Moonraker API and Klippy connection;
- Fluidd HTTP;
- mjpg_streamer and camera port;
- direct camera snapshot;
- Fluidd `/webcam/` proxy snapshot;
- ffmpeg;
- Moonraker Timelapse;
- stock Creality Timelapse disabled;
- crond;
- cleanup script;
- `/usr/data` usage;
- Fans Control Macros absence;
- recent critical Moonraker errors.

## FULL

FULL includes QUICK and additionally validates:

- tested Helper Script revision;
- required Helper Script installer functions;
- approved component artifacts;
- Moonraker Git state;
- KAMP integration;
- Moonraker printer API;
- boot services and P3D hooks;
- Fluidd webcam and macro provisioning baseline.

## Where results are stored

Manual runs print directly to SSH.

Current short status:

```bash
cat /usr/data/scripts/p3d-k1/status
```

Healthcheck history:

```bash
cat /usr/data/scripts/p3d-k1/healthcheck.log
```

Last 100 lines:

```bash
tail -100 /usr/data/scripts/p3d-k1/healthcheck.log
```

Deployment log:

```bash
cat /usr/data/scripts/p3d-k1/deploy.log
```

## Automatic runs

Deployment creates:

```
/etc/init.d/S99z_p3d_healthcheck
```

QUICK runs after boot and once daily via cron.

The simple `status` file can be consumed by external monitoring systems without coupling this repository to any specific fleet manager.
