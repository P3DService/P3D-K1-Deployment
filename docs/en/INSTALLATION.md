**English** | [Русский](../ru/INSTALLATION.md)

# Installation

## Before you start

Current validated models:

- Creality K1C
- Creality K1 Max

Requirements:

- compatible Creality firmware;
- root access already enabled;
- SSH access to the printer;
- internet access from the printer;
- at least ~250 MB free under `/usr/data`.

## Recommended installation

After enabling root access, connect over SSH:

```bash
ssh root@PRINTER_IP
```

Download the pinned release bootstrap, review it, then run it:

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

The bootstrap downloads the matching `deploy.sh`, `healthcheck.sh`, `fluidd_provision.py` and `VERSION`, installs them to:

```
/usr/data/scripts/p3d-k1/
```

and starts deployment.

## FRESH scenario

For a new or factory-reset printer:

```
factory reset / new printer
→ root
→ bootstrap
→ Helper Script
→ approved modules
→ P3D compatibility fixes
→ Fluidd provisioning
→ FULL healthcheck
→ PASS / WARN / FAIL
```

The deployment:

1. validates K1-series model and free space;
2. installs or verifies Creality Helper Script;
3. pins the tested Helper Script commit;
4. installs the approved component set;
5. verifies camera runtime;
6. disables stock Creality Timelapse;
7. configures Moonraker Timelapse + ffmpeg;
8. installs cleanup + cron;
9. installs boot QUICK healthcheck;
10. waits for Moonraker API readiness;
11. provisions Fluidd webcam and macro layout;
12. runs FULL validation.

## RECONCILE scenario

The same deployment can be run on an already configured printer. Existing approved components are detected and not reinstalled.

A final FULL healthcheck still runs after reconciliation.

## Manual copy fallback

Modern macOS OpenSSH uses SFTP for `scp` by default. A factory-reset K1 may not have `/usr/libexec/sftp-server`.

Use legacy SCP mode:

```bash
ssh root@PRINTER_IP 'mkdir -p /usr/data/scripts/p3d-k1'

scp -O deploy.sh healthcheck.sh fluidd_provision.py \
  root@PRINTER_IP:/usr/data/scripts/p3d-k1/
```

Then:

```bash
ssh root@PRINTER_IP
chmod +x /usr/data/scripts/p3d-k1/*.sh
/usr/data/scripts/p3d-k1/deploy.sh
```

## Successful result

```
PASS: 56
WARN: 0
FAIL: 0
STATUS: PASS

P3D K1 DEPLOYMENT: PASS
```

## After reboot

QUICK healthcheck is started automatically after boot and also runs daily.

Current status:

```bash
cat /usr/data/scripts/p3d-k1/status
```

Recent health log:

```bash
tail -100 /usr/data/scripts/p3d-k1/healthcheck.log
```

If deployment stops, save `deploy.log` and run FULL healthcheck before making manual changes.
