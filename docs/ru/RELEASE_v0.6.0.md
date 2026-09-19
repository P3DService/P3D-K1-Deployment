[English](../en/RELEASE_v0.6.0.md) | **Русский**

# Release v0.6.0

Новый stable baseline P3D K1 Deployment.

Главное изменение релиза — **автоматический Fluidd provisioning**. После root и одной команды принтер получает не только Helper Script stack, но и подготовленный Fluidd с камерой и рабочими группами макросов.

## Что нового

### Fluidd macro provisioning

Автоматически создаются/сверяются группы:

```
PRINT         4
CALIBRATION   6
KAMP          2
TIMELAPSE     2
```

Baseline macros:

**PRINT**
- PAUSE
- RESUME
- CANCEL_PRINT
- M600

**CALIBRATION**
- BED_MESH_CALIBRATE
- INPUT_SHAPER_CALIBRATION
- BELTS_SHAPER_CALIBRATION
- TEST_RESONANCES_GRAPHS
- PID_HOTEND
- PID_BED

**KAMP**
- KAMP_BED_MESH_SETTINGS
- KAMP_PURGE_LINE_SETTINGS

**TIMELAPSE**
- GET_TIMELAPSE_SETUP
- TIMELAPSE_RENDER

Остальные live Klipper macros остаются в конфигурации, но получают `visible:false` в Fluidd dashboard.

### Webcam provisioning

Moonraker webcam теперь автоматически создаётся или нормализуется.

Baseline:

```
service: mjpegstreamer-adaptive
stream_url: /webcam/?action=stream
snapshot_url: /webcam/?action=snapshot
target_fps: 15
target_fps_idle: 5
aspect_ratio: 4:3
```

Relative URLs устраняют привязку к IP принтера.

Если webcam уже существует:
- сохраняется её `uid`;
- сохраняется существующий `name`;
- обновляются только operational settings.

Если webcam отсутствует — создаётся автоматически с именем `<hostname>_camera`.

### Защита пользовательской конфигурации

- Если Fluidd layout семантически совпадает с P3D baseline, существующие category UUID сохраняются.
- Если обнаружен другой custom layout, он не перезаписывается автоматически.
- Для принудительной замены:
  ```bash
  P3D_K1_FLUIDD_FORCE=1 /usr/data/scripts/p3d-k1/deploy.sh
  ```
- Перед provisioning создаётся backup Fluidd state.

## Healthcheck

FULL теперь дополнительно проверяет:

- Fluidd `/webcam/` proxy snapshot;
- webcam baseline;
- macro grouping/visibility baseline;
- Fluidd provisioning helper/runtime.

Итог validated FULL:

```
PASS: 56
WARN: 0
FAIL: 0
STATUS: PASS
```

## Field validation

Проверено:

- Creality K1C ×3 — PASS
- Creality K1 Max ×1 — PASS
- camera provisioning — PASS
- macro grouping — PASS
- non-baseline macro hiding — PASS
- existing camera name preservation — PASS
- automatic camera creation on K1 Max — PASS

Creality Helper Script commit:

```
b46787a61b3ce2f04ec04d115a73a46c26814057
```

## Установка

После root-доступа:

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

## Где смотреть healthcheck

QUICK:

```bash
/usr/data/scripts/p3d-k1/healthcheck.sh --quick
```

FULL:

```bash
/usr/data/scripts/p3d-k1/healthcheck.sh --full
```

Краткий статус:

```bash
cat /usr/data/scripts/p3d-k1/status
```

Лог:

```bash
tail -100 /usr/data/scripts/p3d-k1/healthcheck.log
```

## Ограничения

- Требуется root.
- Baseline привязан к указанной revision Creality Helper Script.
- Новая firmware/hardware revision требует повторной validation.
- Проект не является официальным продуктом Creality или Guilouz.
