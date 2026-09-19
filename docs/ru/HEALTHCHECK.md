[English](../en/HEALTHCHECK.md) | **Русский**

# Healthcheck

`healthcheck.sh` — operational gate P3D K1 Deployment.

Есть два режима:

```bash
/usr/data/scripts/p3d-k1/healthcheck.sh --quick
/usr/data/scripts/p3d-k1/healthcheck.sh --full
```

## Результаты

Каждая проверка получает один из статусов:

- `PASS` — ожидаемое состояние подтверждено;
- `WARN` — система работает, но найдено отклонение, которое нужно проверить;
- `FAIL` — production baseline не подтверждён.

Итог:

```
PASS: N
WARN: N
FAIL: N
STATUS: PASS|WARN|FAIL
```

Exit codes:

- `0` — PASS;
- `1` — WARN;
- `2` — FAIL;
- `64` — неправильный аргумент запуска.

## QUICK

QUICK ориентирован на регулярный runtime monitoring.

Проверяются:

- модель K1-series;
- Klipper process;
- Moonraker process;
- Nginx process;
- Moonraker API;
- `klippy_connected`;
- Fluidd HTTP;
- `mjpg_streamer`;
- порт камеры 8080;
- реальный JPEG snapshot;
- `/opt/bin/ffmpeg`;
- Moonraker Timelapse component;
- `[timelapse]`;
- ffmpeg path;
- include `timelapse.cfg`;
- stock Creality Timelapse = OFF;
- ровно один `crond`;
- cleanup script;
- заполнение `/usr/data`;
- отсутствие Fans Control Macros;
- очевидные критические ошибки в свежем Moonraker log.

## FULL

FULL включает QUICK и дополнительно проверяет:

- Git revision Creality Helper Script;
- соответствие tested commit;
- наличие ожидаемых internal installer functions;
- K1 install menu;
- Moonraker/Nginx/Fluidd installation directories;
- Entware;
- Gcode Shell;
- KAMP;
- Nozzle Cleaning Fan Control;
- Improved Shapers;
- Useful Macros;
- Save Z-Offset;
- M600;
- camera boot service;
- cleanup cron boot service;
- P3D boot healthcheck hook;
- tracked Git state Moonraker;
- unexpected untracked files;
- `printer/info`;
- Klipper state ready/standby;
- KAMP include.

## Где смотреть результат

### SSH console

При ручном запуске весь результат выводится прямо в текущую SSH-сессию.

### Текущий короткий статус

```bash
cat /usr/data/scripts/p3d-k1/status
```

Пример:

```
PASS
```

### История healthcheck

```bash
cat /usr/data/scripts/p3d-k1/healthcheck.log
```

Последние 100 строк:

```bash
tail -100 /usr/data/scripts/p3d-k1/healthcheck.log
```

### Deployment log

```bash
cat /usr/data/scripts/p3d-k1/deploy.log
```

## Автоматические запуски

Deployment создаёт:

```
/etc/init.d/S99z_p3d_healthcheck
```

Он запускает QUICK примерно через 25 секунд после boot.

Кроме того, cron запускает QUICK ежедневно:

```
17 3 * * *
```

## Автоматизация и внешние системы

Файл:

```
/usr/data/scripts/p3d-k1/status
```

можно читать внешней системой мониторинга как простой contract `PASS/WARN/FAIL`.

Детальные причины доступны в `healthcheck.log`.

В будущем формат может быть расширен отдельным machine-readable JSON contract без необходимости раскрывать внутреннюю реализацию внешней системы мониторинга.
