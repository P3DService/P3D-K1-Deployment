[English](../en/FLUIDD_PROVISIONING.md) | **Русский**

# Fluidd Provisioning

Начиная с development-линии v0.6 проект умеет автоматически доводить Fluidd до готового рабочего состояния после deployment.

## Цель

После factory reset / root / одной команды пользователь получает не только установленный Klipper stack, но и готовый Fluidd:

- камера зарегистрирована;
- camera URL не зависит от IP;
- основные макросы сгруппированы;
- системные/restore макросы скрыты из dashboard, но не удалены;
- конфигурация проверяется FULL healthcheck.

## Камера

Moonraker webcam API используется как canonical storage.

Baseline:

```
enabled: true
location: printer
service: mjpegstreamer-adaptive
target_fps: 15
target_fps_idle: 5
stream_url: /webcam/?action=stream
snapshot_url: /webcam/?action=snapshot
aspect_ratio: 4:3
```

### Имя камеры

Имя камеры не используется как идентификатор устройства.

Если database-managed webcam уже существует:

- сохраняется существующий `name`;
- сохраняется её `uid`;
- обновляются только operational settings/URLs.

Поэтому пользователь может переименовывать принтер/hostname по своей системе нумерации — camera stream не ломается.

Если камеры ещё нет, создаётся:

```
<текущий-hostname>_camera
```

После создания последующее переименование hostname не требует переименования камеры.

## Почему относительные URL

Вместо:

```
http://192.168.x.x:8080/...
```

используются:

```
/webcam/?action=stream
/webcam/?action=snapshot
```

Helper Script Nginx проксирует `/webcam/` на локальный `mjpg_streamer`.

Это позволяет не привязывать конфигурацию Fluidd к DHCP/IP конкретного принтера.

## Macro groups

Baseline dashboard:

### PRINT

- PAUSE
- RESUME
- CANCEL_PRINT
- M600

### CALIBRATION

- BED_MESH_CALIBRATE
- INPUT_SHAPER_CALIBRATION
- BELTS_SHAPER_CALIBRATION
- TEST_RESONANCES_GRAPHS
- PID_HOTEND
- PID_BED

### KAMP

- KAMP_BED_MESH_SETTINGS
- KAMP_PURGE_LINE_SETTINGS

### TIMELAPSE

- GET_TIMELAPSE_SETUP
- TIMELAPSE_RENDER

Остальные обнаруженные `gcode_macro` получают `visible=false` в Fluidd storage.

Макросы не удаляются из Klipper config.

## Защита пользовательских настроек

Provisioning работает консервативно.

Если Fluidd уже содержит:

- точно такой же P3D layout, даже с другими автоматически созданными UUID категорий — он считается валидным и сохраняется;
- другой пользовательский layout — он **не перезаписывается автоматически**.

В последнем случае deployment/healthcheck возвращает WARN.

Для сознательной замены пользовательского layout:

```bash
P3D_K1_FLUIDD_FORCE=1 /usr/data/scripts/p3d-k1/deploy.sh
```

Перед provisioning создаётся backup:

```
/usr/data/scripts/p3d-k1/backups/fluidd-before-provision-YYYYMMDD-HHMMSS.json
```

## Проверка

FULL:

```bash
/usr/data/scripts/p3d-k1/healthcheck.sh --full
```

Fluidd provisioning helper отдельно:

```bash
/usr/data/moonraker/moonraker-env/bin/python \
  /usr/data/scripts/p3d-k1/fluidd_provision.py --check
```

В production release v0.6 эта логика должна быть field-validated перед публикацией.
