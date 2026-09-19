**English** | [Русский](../ru/ARCHITECTURE.md)

# Architecture

## Goal

P3D K1 Deployment is a thin orchestration and validation layer on top of Creality Helper Script and the stock K1-series system.

It does not fork Helper Script. Instead it:

1. pins a tested upstream commit;
2. loads the upstream installer functions;
3. calls only the approved subset in a controlled order;
4. applies P3D compatibility and safety logic;
5. validates real runtime state.

## Deployment flow

```
rooted K1-series
      ↓
preflight
      ↓
Helper Script revision/API gate
      ↓
approved component install/reconcile
      ↓
camera + timelapse + ffmpeg
      ↓
cleanup + cron + boot healthcheck
      ↓
Moonraker restart
      ↓
Moonraker API readiness
      ↓
Fluidd provisioning
      ↓
FULL healthcheck
      ↓
PASS / WARN / FAIL
```

## Why upstream is pinned

Helper Script installer functions are internal implementation details rather than a stable public API.

Automatic mutation therefore proceeds only with the tested commit:

```
b46787a61b3ce2f04ec04d115a73a46c26814057
```

A different revision causes fail-closed behavior until compatibility is revalidated.

## Runtime readiness

Old BusyBox/init scripts may return misleading exit codes. Moonraker readiness is therefore validated against the actual API:

```
GET http://127.0.0.1:7125/server/info
```

with a timeout.

## BusyBox compatibility

The target is stock Creality userspace. Scripts avoid GNU-only assumptions whenever possible.

For example, tested K1 Max BusyBox `grep` supports `-r` but not GNU `-R`.

## Idempotency

Before installing any approved component, deployment checks its expected installation artifact. Existing baseline components are preserved.

The final FULL healthcheck remains authoritative.

## External monitoring boundary

Local health state is exposed via:

```
/usr/data/scripts/p3d-k1/status
/usr/data/scripts/p3d-k1/healthcheck.log
```

External systems may consume this state, but they are intentionally outside this public repository.
