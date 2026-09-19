**English** | [Русский](../ru/TROUBLESHOOTING.md)

# Troubleshooting

## SSH: REMOTE HOST IDENTIFICATION HAS CHANGED

Factory reset may change the printer SSH host key.

```bash
ssh-keygen -R PRINTER_IP
ssh root@PRINTER_IP
```

Confirm that the IP really belongs to the intended printer before accepting the new fingerprint.

## scp: /usr/libexec/sftp-server: not found

Factory-reset K1-series firmware may not provide an SFTP server.

Use legacy SCP mode:

```bash
scp -O deploy.sh healthcheck.sh fluidd_provision.py \
  root@PRINTER_IP:/usr/data/scripts/p3d-k1/
```

## Helper Script revision differs

Deployment intentionally stops when the current Helper Script commit differs from the validated baseline.

Do not bypass this gate blindly. Upstream paths, functions or side effects may have changed.

## Fans Control Macros detected

The current baseline refuses to continue when:

```
/usr/data/printer_data/config/Helper-Script/fans-control.cfg
```

is present. Remove that module through Helper Script before retrying.

## Moonraker API unavailable after restart

Deployment waits for API readiness. Manual test:

```bash
wget -q -T 3 -O /tmp/server_info.json \
  'http://127.0.0.1:7125/server/info' \
  && echo "MOONRAKER API OK" \
  || echo "MOONRAKER API FAIL"
```

## Timelapse: ffmpeg not found

Check:

```bash
which ffmpeg
ls -l /opt/bin/ffmpeg
/usr/bin/ffmpeg -version | head
```

On validated firmware the stock binary is `/usr/bin/ffmpeg`, while Moonraker Timelapse expects `/opt/bin/ffmpeg`. Deployment creates a compatibility symlink when required.

## Camera works in Creality App but not in Fluidd

Direct snapshot:

```bash
wget -O /tmp/test.jpg 'http://127.0.0.1:8080/?action=snapshot'
ls -lh /tmp/test.jpg
```

Fluidd/Nginx proxy snapshot:

```bash
wget -O /tmp/test-fluidd.jpg 'http://127.0.0.1:4408/webcam/?action=snapshot'
ls -lh /tmp/test-fluidd.jpg
```

Process/port:

```bash
ps | grep '[m]jpg_streamer'
netstat -lnt | grep 8080
```

## Moonraker reports untracked timelapse.py

Expected third-party component:

```
moonraker/components/timelapse.py
```

Healthcheck allow-lists it.

## wget: TLS certificate validation not implemented

Some stock K1 BusyBox builds print:

```
wget: note: TLS certificate validation not implemented
```

This is a limitation of the built-in BusyBox wget. It does not mean the download failed, but TLS trust is weaker than with a full CA-validating client.

Recommended workflow:

```bash
wget -q -O /tmp/p3d-k1-install.sh \
  https://raw.githubusercontent.com/P3DService/P3D-K1-Deployment/v0.6.0/install.sh

cat /tmp/p3d-k1-install.sh
sh /tmp/p3d-k1-install.sh
```

If a full TLS-validating client is available in your environment, prefer it for bootstrap download.

## Fluidd custom macro layout is preserved

If deployment reports that a custom Fluidd layout was preserved, this is intentional.

To explicitly replace it with the P3D baseline:

```bash
P3D_K1_FLUIDD_FORCE=1 /usr/data/scripts/p3d-k1/deploy.sh
```

A backup is created before provisioning.

## TMC2209 overtemperature during cold calibration

If `stepper_x` / `stepper_y` reports overtemperature during Bed Mesh, Input Shaper or resonance calibration while the hotend is cold, see the field-validated K1 Max fix:

- [TMC2209 overtemperature during cold calibration](TMC2209_OVERHEAT.md)

The validated case was caused by the mainboard fan being grouped with the hotend fan and therefore switching off below the hotend temperature threshold.

## Collect diagnostics

```bash
/usr/data/scripts/p3d-k1/healthcheck.sh --full
tail -100 /usr/data/scripts/p3d-k1/healthcheck.log
tail -100 /usr/data/scripts/p3d-k1/deploy.log
```
